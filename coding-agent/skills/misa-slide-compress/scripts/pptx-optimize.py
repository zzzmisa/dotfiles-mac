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
    画像のピクセル数とは無関係なので、図形の寸法は保つ。crop・グループ・色や画質は別途検証する。
  * 目標ppiを下回っている画像には一切触らない。拡大は絶対にしない。
  * 1枚でも小さくならなければ元のバイト列をそのまま使う。
  * --drop-cropped 以外はスライドXMLを書き換えない。
"""
import argparse, io, math, os, posixpath, re, sys, zipfile
import urllib.parse
import xml.etree.ElementTree as ET
import xml.parsers.expat
from PIL import Image

EMU = 914400
RASTER = (".png", ".jpg", ".jpeg", ".gif", ".bmp", ".tiff")


NS = {"a": "http://schemas.openxmlformats.org/drawingml/2006/main",
      "p": "http://schemas.openxmlformats.org/presentationml/2006/main",
      "r": "http://schemas.openxmlformats.org/officeDocument/2006/relationships"}


def build_rels(z):
    """XML の属性順・名前空間・相対/絶対 Target に依存せず内部参照を集める。"""
    per_part, referenced = {}, set()
    for n in z.namelist():
        if not n.endswith(".rels"):
            continue
        base = posixpath.dirname(posixpath.dirname(n))
        table = {}
        for rel in ET.fromstring(z.read(n)):
            if rel.get("TargetMode") == "External":
                continue
            tgt = urllib.parse.unquote(urllib.parse.urlsplit(rel.attrib["Target"]).path)
            full = posixpath.normpath(posixpath.join(base, tgt)).lstrip("/")
            table[rel.attrib["Id"]] = full
            referenced.add(full)
        per_part[n] = table
    return per_part, referenced


def usages(z, per_part):
    """通常の picture の表示寸法だけ解釈し、他の使い方は縮小不可として残す。"""
    out = {}
    for part in z.namelist():
        if not part.startswith("ppt/") or not part.endswith(".xml"):
            continue
        rels_name = posixpath.join(posixpath.dirname(part), "_rels", posixpath.basename(part) + ".rels")
        rels = per_part.get(rels_name, {})
        root = ET.fromstring(z.read(part))
        parents = {child: parent for parent in root.iter() for child in parent}
        recognized = set()
        for pic in root.findall(".//p:pic", NS):
            blip = pic.find("p:blipFill/a:blip", NS)
            if blip is None:
                continue
            rid = blip.get("{%s}embed" % NS["r"])
            media = rels.get(rid)
            if not media:
                continue
            recognized.add(blip)
            ext = pic.find("p:spPr/a:xfrm/a:ext", NS)
            grouped, ancestor = False, parents.get(pic)
            while ancestor is not None:
                grouped |= ancestor.tag == "{%s}grpSp" % NS["p"]
                ancestor = parents.get(ancestor)
            dw, dh = (None, None)
            tiled = pic.find("p:blipFill/a:tile", NS) is not None
            if ext is not None and not grouped and not tiled:
                dw, dh = int(ext.attrib["cx"]) / EMU, int(ext.attrib["cy"]) / EMU
                if dw <= 0 or dh <= 0:
                    dw, dh = None, None
            sr = pic.find("p:blipFill/a:srcRect", NS)
            crop = tuple(int(sr.get(k, 0)) / 100000 for k in ("l", "t", "r", "b")) if sr is not None else None
            if crop and (min(crop) < 0 or crop[0] + crop[2] >= 1 or crop[1] + crop[3] >= 1):
                dw, dh = None, None
            out.setdefault(media, []).append({"part": part, "w": dw, "h": dh, "crop": crop})
        # 背景・図形塗り・未知の XML 参照も数える。通常 picture だけ見て縮めない。
        for node in root.iter():
            for key, rid in node.attrib.items():
                if key.startswith("{%s}" % NS["r"]) and rid in rels and node not in recognized:
                    out.setdefault(rels[rid], []).append({"part": part, "w": None, "h": None, "crop": None})
    # 解釈できなかった参照元があれば縮小を抑止する。
    for rels_name, table in per_part.items():
        owner = posixpath.join(posixpath.dirname(posixpath.dirname(rels_name)),
                               posixpath.basename(rels_name)[:-5])
        for media in set(table.values()):
            if not any(u["part"] == owner for u in out.get(media, [])):
                out.setdefault(media, []).append({"part": owner, "w": None, "h": None, "crop": None})
    return out


def clear_crop_attributes(raw, target_ids):
    """対象 picture の srcRect 開始タグだけ変更し、名前空間宣言を含む他の XML を保持する。"""
    parser = xml.parsers.expat.ParserCreate(namespace_separator="}")
    pictures, patches = [], []

    def start(name, attrs):
        if name == NS["p"] + "}pic":
            pictures.append({"rid": None, "rects": []})
        if not pictures:
            return
        if name == NS["a"] + "}blip":
            pictures[-1]["rid"] = attrs.get(NS["r"] + "}embed")
        if name == NS["a"] + "}srcRect":
            offset = parser.CurrentByteIndex
            # srcRect の属性値は数値。XML パーサーが対象要素を特定してから字句変更する。
            tag = re.match(rb"<[^>]+>", raw[offset:]).group()
            # crop 属性だけ除去し、この要素で宣言された xmlns なども保持する。
            replacement = re.sub(rb'\s+(?:l|t|r|b)\s*=\s*(?:"[^"]*"|\'[^\']*\')', b"", tag)
            pictures[-1]["rects"].append((offset, len(tag), replacement))

    def end(name):
        if name == NS["p"] + "}pic":
            pic = pictures.pop()
            if pic["rid"] in target_ids:
                patches.extend(pic["rects"])

    parser.StartElementHandler, parser.EndElementHandler = start, end
    parser.Parse(raw, True)
    for offset, length, replacement in sorted(patches, reverse=True):
        raw = raw[:offset] + replacement + raw[offset + length:]
    return raw


def strip_jpeg_metadata(raw):
    """JPEG の EXIF/IPTC 等を除去。色に影響する ICC(APP2)/Adobe(APP14) は保持する。"""
    if raw[:2] != b"\xff\xd8":
        return raw
    try:
        if Image.open(io.BytesIO(raw)).getexif().get(274, 1) != 1:
            return raw  # 向きを変える EXIF は除去しない
    except Exception:
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
        if seg_len < 2 or i + 2 + seg_len > n:
            return raw
        if marker in (0xE1, 0xED, 0xEF) or marker == 0xFE:
            i += 2 + seg_len; continue          # Exif / IPTC / Photoshop / コメントを捨てる
        out += raw[i:i + 2 + seg_len]; i += 2 + seg_len
    return raw


def reencode(raw, ext, target_px, quality, crop_box):
    """縮小/トリミングした画像バイト列を返す。小さくできなければ None。"""
    try:
        im = Image.open(io.BytesIO(raw))
        im.load()
    except Exception:
        return None
    if getattr(im, "n_frames", 1) > 1 or im.getexif().get(274, 1) != 1:
        return None
    orig_mode = im.mode
    icc = im.info.get("icc_profile")
    if crop_box:
        im = im.crop(crop_box)
    if target_px and (im.width > target_px[0] or im.height > target_px[1]):
        im = im.resize((max(1, target_px[0]), max(1, target_px[1])), Image.LANCZOS)
    buf = io.BytesIO()
    try:
        if ext in (".jpg", ".jpeg"):
            if im.mode not in ("RGB", "L", "CMYK"):
                im = im.convert("RGB")
            im.save(buf, "JPEG", quality=quality, optimize=True, icc_profile=icc)   # EXIFは渡さない=除去
        elif ext == ".png":
            if im.mode != orig_mode:
                im = im.convert(orig_mode)
            im.save(buf, "PNG", optimize=True, icc_profile=icc)
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

    if args.dpi <= 0 or not 1 <= args.quality <= 100:
        ap.error("dpi は正の整数、quality は 1〜100 を指定してください")
    if args.dst and (os.path.realpath(args.src) == os.path.realpath(args.dst) or
                     (os.path.exists(args.dst) and os.path.samefile(args.src, args.dst))):
        ap.error("原本とは別の出力先を指定してください")

    z = zipfile.ZipFile(args.src)
    names = z.namelist()
    per_part, referenced = build_rels(z)
    use = usages(z, per_part)

    media = [n for n in names if n.startswith("ppt/media/")]
    orphans = [] if args.keep_orphans else [n for n in media if n not in referenced]
    thumbs = [] if args.keep_thumbnail else [n for n in names if n.startswith("docProps/thumbnail") and n not in referenced]
    declared = {e.get("PartName", "").lstrip("/") for e in ET.fromstring(z.read("[Content_Types].xml"))}
    orphans = [n for n in orphans if n not in declared]
    thumbs = [n for n in thumbs if n not in declared]
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
            if crop_box[2] <= crop_box[0] or crop_box[3] <= crop_box[1]:
                report.append((n, len(raw), len(raw), "%dx%d" % (W, H), "crop が1画素未満のため据置"))
                continue
            srcrect_fix.setdefault(us[0]["part"], []).append(n)
            note = "トリミング破棄"

        # 各使用箇所の crop を個別に反映し、縦横比を保った単一倍率で縮小する。
        avail_w, avail_h = (crop_box[2] - crop_box[0], crop_box[3] - crop_box[1]) if crop_box else (W, H)
        scale = 0.0
        for u in us:
            l, t, r, b = u["crop"] or (0, 0, 0, 0)
            fw, fh = (1, 1) if crop_box else (1 - l - r, 1 - t - b)
            scale = max(scale, u["w"] * args.dpi / (avail_w * fw),
                        u["h"] * args.dpi / (avail_h * fh))
        scale = min(1.0, scale)
        target = (max(1, math.ceil(avail_w * scale)), max(1, math.ceil(avail_h * scale))) if scale < 1 else None
        if target is None and not crop_box:
            note = "目標ppi以下のため据置"

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
        rels = per_part.get(posixpath.join(posixpath.dirname(part), "_rels", posixpath.basename(part) + ".rels"), {})
        target_ids = {rid for rid, media in rels.items() if media in imgs}
        xml_patch[part] = clear_crop_attributes(z.read(part), target_ids)

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

    with zipfile.ZipFile(args.dst, "x", zipfile.ZIP_DEFLATED, compresslevel=9) as out:
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
