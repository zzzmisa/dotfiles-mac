#!/usr/bin/env python3
"""PowerPoint (.pptx) の容量を削減する。PowerPointもLibreOfficeも不要。

  pptx-optimize.py <in.pptx> <out.pptx> [options]

  --dpi N            目標解像度（既定 350 = 印刷基準）。投影のみなら 200 程度でよい
  --quality N        JPEG品質（既定 88）
  --keep-orphans     どこからも参照されていないメディアを残す（既定は削除）
  --drop-cropped     トリミングで見えていない領域を物理削除し srcRect を消す
                     （後からトリミングを広げ直せなくなるため既定はオフ）
  --keep-thumbnail   docProps/thumbnail.* を残す（既定は削除）
  --dry-run          書き出さずに削減見込みだけ表示

設計上の原則:
  * パート名と拡張子を絶対に変えない（JPEG->JPEG, PNG->PNG）。
    OOXMLでは画像の表示サイズは図形の <a:ext cx cy>（EMU）で決まり、
    画像のピクセル数とは無関係なので、解像度を下げてもレイアウトは1ptも動かない。
  * 目標ppiを下回っている画像には一切触らない。拡大は絶対にしない。
  * 1枚でも小さくならなければ元のバイト列をそのまま使う。
  * --drop-cropped 以外はスライドXMLを書き換えない。
"""
import argparse, io, os, posixpath, re, sys, zipfile
from PIL import Image

EMU = 914400
RASTER = (".png", ".jpg", ".jpeg", ".gif", ".bmp", ".tiff")


def build_rels(z):
    """全 .rels を読み、(rels_part -> {Id: 絶対パート名}) と参照先の集合を返す。"""
    per_part, referenced = {}, set()
    for n in z.namelist():
        if not n.endswith(".rels"):
            continue
        base = posixpath.dirname(posixpath.dirname(n))
        table = {}
        for m in re.finditer(r'Id="([^"]+)"[^>]*?Target="([^"]+)"([^>]*)', z.read(n).decode("utf-8", "replace")):
            rid, tgt, rest = m.group(1), m.group(2), m.group(3)
            if tgt.startswith("http") or 'TargetMode="External"' in rest:
                continue
            full = posixpath.normpath(posixpath.join(base, tgt))
            table[rid] = full
            referenced.add(full)
        per_part[n] = table
    return per_part, referenced


def usages(z, per_part):
    """各メディアの使われ方を集める。
    returns: {media: [ {part, disp_w_in, disp_h_in, crop(l,t,r,b) or None}, ... ]}"""
    out = {}
    for part in z.namelist():
        if not re.fullmatch(r"ppt/(slides|slideLayouts|slideMasters|notesSlides)/[^/]+\.xml", part):
            continue
        rels = per_part.get(posixpath.join(posixpath.dirname(part), "_rels", posixpath.basename(part) + ".rels"), {})
        xml = z.read(part).decode("utf-8", "replace")
        for pic in re.findall(r"<p:pic\b.*?</p:pic>", xml, re.S):
            e = re.search(r'r:embed="([^"]+)"', pic)
            if not e:
                continue
            media = rels.get(e.group(1))
            if not media:
                continue
            sr = re.search(r"<a:srcRect([^/>]*)/>", pic)
            crop = None
            if sr:
                a = dict(re.findall(r'(\w+)="(-?\d+)"', sr.group(1)))
                if a:
                    crop = tuple(int(a.get(k, 0)) / 100000 for k in ("l", "t", "r", "b"))
            ext = re.search(r'<a:ext cx="(\d+)" cy="(\d+)"\s*/>', pic)
            dw, dh = (int(ext.group(1)) / EMU, int(ext.group(2)) / EMU) if ext else (None, None)
            out.setdefault(media, []).append({"part": part, "w": dw, "h": dh, "crop": crop})
    return out


def strip_jpeg_metadata(raw):
    """JPEGのAPP1(Exif)/APP13等を落とす。圧縮データには一切触らないので完全に可逆。"""
    if raw[:2] != b"\xff\xd8":
        return raw
    out, i, n = bytearray(b"\xff\xd8"), 2, len(raw)
    while i < n - 1:
        if raw[i] != 0xFF:
            break
        marker = raw[i + 1]
        if marker in (0xD8, 0x01) or 0xD0 <= marker <= 0xD7:
            out += raw[i:i + 2]; i += 2; continue
        if marker == 0xDA:                      # 走査開始。以降は末尾までそのまま
            out += raw[i:]; return bytes(out)
        seg_len = int.from_bytes(raw[i + 2:i + 4], "big")
        if marker in (0xE1, 0xE2, 0xED, 0xEE, 0xEF) or marker == 0xFE:
            i += 2 + seg_len; continue          # Exif / IPTC / Photoshop / コメントを捨てる
        out += raw[i:i + 2 + seg_len]; i += 2 + seg_len
    return bytes(out) if len(out) > 2 else raw


def reencode(raw, ext, target_px, quality, crop_box):
    """縮小/トリミングした画像バイト列を返す。小さくできなければ None。"""
    try:
        im = Image.open(io.BytesIO(raw))
        im.load()
    except Exception:
        return None
    orig_mode = im.mode
    if crop_box:
        im = im.crop(crop_box)
    if target_px and (im.width > target_px[0] or im.height > target_px[1]):
        im = im.resize((max(1, target_px[0]), max(1, target_px[1])), Image.LANCZOS)
    buf = io.BytesIO()
    try:
        if ext in (".jpg", ".jpeg"):
            if im.mode not in ("RGB", "L", "CMYK"):
                im = im.convert("RGB")
            im.save(buf, "JPEG", quality=quality, optimize=True)   # EXIFは渡さない=除去
        elif ext == ".png":
            if im.mode != orig_mode:
                im = im.convert(orig_mode)
            im.save(buf, "PNG", optimize=True)
        else:
            return None
    except Exception:
        return None
    out = buf.getvalue()
    return out if len(out) < len(raw) else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src"); ap.add_argument("dst", nargs="?")
    ap.add_argument("--dpi", type=int, default=350)
    ap.add_argument("--quality", type=int, default=88)
    ap.add_argument("--keep-orphans", action="store_true")
    ap.add_argument("--drop-cropped", action="store_true")
    ap.add_argument("--keep-thumbnail", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()
    if not args.dry_run and not args.dst:
        ap.error("出力先を指定してください（または --dry-run）")

    z = zipfile.ZipFile(args.src)
    names = z.namelist()
    per_part, referenced = build_rels(z)
    use = usages(z, per_part)

    media = [n for n in names if n.startswith("ppt/media/")]
    orphans = [] if args.keep_orphans else [n for n in media if n not in referenced]
    thumbs = [] if args.keep_thumbnail else [n for n in names if n.startswith("docProps/thumbnail")]
    drop = set(orphans) | set(thumbs)

    new_bytes, srcrect_fix, report = {}, {}, []
    for n in media:
        if n in drop:
            continue
        ext = os.path.splitext(n)[1].lower()
        if ext not in RASTER:
            continue
        raw = z.read(n)
        try:
            W, H = Image.open(io.BytesIO(raw)).size
        except Exception:
            continue
        us = use.get(n, [])
        # 表示サイズが不明な使われ方が1つでもあれば縮小しない（安全側）
        if not us or any(u["w"] is None for u in us):
            report.append((n, len(raw), len(raw), "%dx%d" % (W, H), "表示サイズ不明のため据置"))
            continue

        crop_box, note = None, ""
        # トリミング破棄は「パッケージ全体で1箇所だけ使われ、切り抜きが1つ」のときのみ
        if args.drop_cropped and len(us) == 1 and us[0]["crop"]:
            l, t, r, b = us[0]["crop"]
            crop_box = (int(W * l), int(H * t), int(W * (1 - r)), int(H * (1 - b)))
            srcrect_fix.setdefault(us[0]["part"], []).append(n)
            note = "トリミング破棄"

        # 各使用箇所で必要な画素数の最大値をとる（最も要求の厳しい箇所に合わせる）
        need_w = need_h = 0
        for u in us:
            need_w = max(need_w, int(round(u["w"] * args.dpi)))
            need_h = max(need_h, int(round(u["h"] * args.dpi)))
        avail_w, avail_h = (crop_box[2] - crop_box[0], crop_box[3] - crop_box[1]) if crop_box else (W, H)
        if not crop_box and us[0]["crop"]:
            l, t, r, b = us[0]["crop"]
            avail_w, avail_h = int(W * (1 - l - r)), int(H * (1 - t - b))
            need_w = int(round(need_w / max(1e-6, 1 - l - r)))
            need_h = int(round(need_h / max(1e-6, 1 - t - b)))
        target = (min(need_w, avail_w), min(need_h, avail_h)) if need_w and need_h else None
        if target and (target[0] >= avail_w and target[1] >= avail_h) and not crop_box:
            target = None          # すでに目標以下 -> 触らない
            note = note or "目標ppi以下のため据置"

        if target is None and crop_box is None:
            # 解像度を変えないなら JPEG は再圧縮しない（劣化するだけ）。
            # PNGは可逆なので再最適化してよい。
            if ext in (".jpg", ".jpeg"):
                stripped = strip_jpeg_metadata(raw)
                if len(stripped) < len(raw):
                    new_bytes[n] = stripped
                    report.append((n, len(raw), len(stripped), "%dx%d" % (W, H), "解像度据置・メタデータ除去のみ"))
                else:
                    report.append((n, len(raw), len(raw), "%dx%d" % (W, H), note or "据置"))
                continue
            out = reencode(raw, ext, None, args.quality, None)
            if out is None:
                report.append((n, len(raw), len(raw), "%dx%d" % (W, H), note or "据置"))
            else:
                new_bytes[n] = out
                report.append((n, len(raw), len(out), "%dx%d" % (W, H), "解像度据置・PNG可逆再圧縮"))
            continue

        out = reencode(raw, ext, target, args.quality, crop_box)
        if out is None:
            report.append((n, len(raw), len(raw), "%dx%d" % (W, H), note or "縮小できず据置"))
            if crop_box:
                srcrect_fix.get(us[0]["part"], []).remove(n)
            continue
        new_bytes[n] = out
        report.append((n, len(raw), len(out), "%dx%d -> %dx%d" % (W, H, *(target or (avail_w, avail_h))), note or "縮小"))

    # トリミングを物理削除した画像は srcRect を無効化する
    xml_patch = {}
    for part, imgs in srcrect_fix.items():
        if not imgs:
            continue
        xml = z.read(part).decode("utf-8")
        rels = per_part.get(posixpath.join(posixpath.dirname(part), "_rels", posixpath.basename(part) + ".rels"), {})
        rid_of = {v: k for k, v in rels.items()}
        for m in imgs:
            rid = rid_of.get(m)
            if not rid:
                continue
            def strip(mo):
                return mo.group(0) if f'r:embed="{rid}"' not in mo.group(0) else re.sub(r"<a:srcRect[^/>]*/>", "<a:srcRect/>", mo.group(0))
            xml = re.sub(r"<p:pic\b.*?</p:pic>", strip, xml, flags=re.S)
        xml_patch[part] = xml.encode("utf-8")

    before = os.path.getsize(args.src)
    print("%-22s %11s %11s  %-24s %s" % ("パート", "前", "後", "解像度", "備考"))
    for n, b, a, d, note in sorted(report, key=lambda r: -r[1]):
        print("%-22s %11d %11d  %-24s %s" % (posixpath.basename(n), b, a, d, note))
    for n in orphans:
        print("%-22s %11d %11d  %-24s %s" % (posixpath.basename(n), z.getinfo(n).file_size, 0, "-", "孤児のため削除"))
    for n in thumbs:
        print("%-22s %11d %11d  %-24s %s" % (posixpath.basename(n), z.getinfo(n).file_size, 0, "-", "サムネイル削除"))

    saved = sum(b - a for _, b, a, _, _ in report) + sum(z.getinfo(n).file_size for n in drop)
    print("\n展開サイズで約 %d バイト削減見込み（元ファイル %d バイト）" % (saved, before))
    if args.dry_run:
        return 0

    with zipfile.ZipFile(args.dst, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as out:
        for zi in z.infolist():                      # 元の並び順を保つ
            if zi.filename in drop:
                continue
            data = new_bytes.get(zi.filename) or xml_patch.get(zi.filename) or z.read(zi.filename)
            out.writestr(zi.filename, data)

    # 検証
    with zipfile.ZipFile(args.dst) as v:
        got, want = set(v.namelist()), set(names) - drop
        assert got == want, "パート構成が変化しました: %s" % (got ^ want)
        for n in v.namelist():
            if n.startswith("ppt/media/") and os.path.splitext(n)[1].lower() in RASTER:
                Image.open(io.BytesIO(v.read(n))).load()
        for n in ("[Content_Types].xml",):
            assert v.read(n) == z.read(n), "%s が変化しました" % n
        untouched = [n for n in v.namelist() if n.endswith(".rels")]
        for n in untouched:
            assert v.read(n) == z.read(n), "%s が変化しました" % n
    after = os.path.getsize(args.dst)
    print("結果: %d -> %d バイト (%.1f%%)" % (before, after, (after - before) * 100 / before))
    return 0


if __name__ == "__main__":
    sys.exit(main())
