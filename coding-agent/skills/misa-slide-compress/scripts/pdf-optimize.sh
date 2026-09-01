#!/bin/bash
# PDFを2方式で最適化し、良い方を採用して出力する。
#
#   pdf-optimize.sh <in.pdf> <out.pdf> [dpi]      # dpi 既定 300
#
# 方式A: Ghostscriptで画像を指定dpiにダウンサンプル＋高品質JPEG再圧縮（非可逆）
# 方式B: qpdfのみ（可逆）。画像は一切触らず、重複除去・Flate再圧縮・
#        オブジェクトストリーム化・リニアライズだけ行う
#
# 非可逆のAは「可逆のBより10%以上小さい」ときだけ採用する。
# スクリーンショット主体のPDFではAがFlate画像をJPEGに変換して逆に増えるため。
#
# 終了コード: 0=出力あり / 1=失敗 / 2=どちらの方式でも縮まなかった（出力なし）
set -u

IN="${1:?usage: pdf-optimize.sh <in.pdf> <out.pdf> [dpi]}"
OUT="${2:?usage: pdf-optimize.sh <in.pdf> <out.pdf> [dpi]}"
DPI="${3:-300}"

command -v gs   >/dev/null || { echo "ghostscript が必要です: brew install ghostscript"; exit 1; }
command -v qpdf >/dev/null || { echo "qpdf が必要です: brew install qpdf"; exit 1; }

before=$(stat -f%z "$IN")
A=$(mktemp -t pdfoptA).pdf
B=$(mktemp -t pdfoptB).pdf
A0=$(mktemp -t pdfoptA0).pdf
trap 'rm -f "$A" "$B" "$A0"' EXIT

# --- 方式A ---------------------------------------------------------------------
gs -q -dNOPAUSE -dBATCH -dSAFER -sDEVICE=pdfwrite -sOutputFile="$A0" \
  -dCompatibilityLevel=1.7 \
  -dDetectDuplicateImages=true \
  -dCompressFonts=true -dSubsetFonts=true -dEmbedAllFonts=true \
  -dDownsampleColorImages=true -dColorImageDownsampleType=/Bicubic \
  -dColorImageResolution="$DPI" -dColorImageDownsampleThreshold=1.2 \
  -dDownsampleGrayImages=true -dGrayImageDownsampleType=/Bicubic \
  -dGrayImageResolution="$DPI" -dGrayImageDownsampleThreshold=1.2 \
  -dDownsampleMonoImages=true -dMonoImageDownsampleType=/Subsample -dMonoImageResolution=1200 \
  -dAutoFilterColorImages=true -dAutoFilterGrayImages=true \
  -dColorConversionStrategy=/LeaveColorUnchanged \
  -c "<</ColorACSImageDict <</QFactor 0.15 /Blend 1 /ColorTransform 1 /HSamples [1 1 1 1] /VSamples [1 1 1 1]>> /GrayACSImageDict <</QFactor 0.15 /Blend 1 /HSamples [1 1 1 1] /VSamples [1 1 1 1]>> >> setdistillerparams" \
  -f "$IN" >/dev/null 2>&1 \
  && qpdf --object-streams=generate --recompress-flate --compression-level=9 --linearize "$A0" "$A" >/dev/null 2>&1
[ -s "$A" ] || cp "$A0" "$A" 2>/dev/null || :

# --- 方式B ---------------------------------------------------------------------
qpdf --object-streams=generate --recompress-flate --compression-level=9 --linearize "$IN" "$B" >/dev/null 2>&1
[ -s "$B" ] || rm -f "$B"

sa=$([ -s "$A" ] && stat -f%z "$A" || echo 0)
sb=$([ -s "$B" ] && stat -f%z "$B" || echo 0)

pick=""; size=0; mode=""
if [ "$sa" -gt 0 ] && [ "$sb" -gt 0 ]; then
  if [ "$sa" -lt "$((sb * 90 / 100))" ]; then pick="$A"; size=$sa; mode="A:${DPI}ppi再圧縮"
  else pick="$B"; size=$sb; mode="B:可逆"; fi
elif [ "$sa" -gt 0 ]; then pick="$A"; size=$sa; mode="A:${DPI}ppi再圧縮"
elif [ "$sb" -gt 0 ]; then pick="$B"; size=$sb; mode="B:可逆"
else echo "FAILED"; exit 1; fi

# ページ数が変わっていたら採用しない
p1=$(pdfinfo "$IN"   2>/dev/null | awk '/^Pages:/{print $2}')
p2=$(pdfinfo "$pick" 2>/dev/null | awk '/^Pages:/{print $2}')
[ -n "$p2" ] && [ "$p1" = "$p2" ] || { echo "SKIP: ページ数 $p1→$p2"; exit 1; }

[ "$size" -lt "$before" ] || { echo "SKIP: 縮小できず ($before→$size)"; exit 2; }

cp "$pick" "$OUT"
pct=$(echo "scale=1; ($size-$before)*100/$before" | bc)
echo "$before -> $size (${pct}%) $mode"
exit 0
