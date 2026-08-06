# ffmpegレシピ・罠・検証

## 書き出し設定

```
-c:v libx264 -profile:v high -crf 16 -preset medium -g 60 -pix_fmt yuv420p
-c:a aac -b:a 192k -ar 48000 -movflags +faststart
```

| 項目 | 値 | 理由 |
| --- | --- | --- |
| `-pix_fmt yuv420p` | **必須** | フィルタ内で `format=yuv420p` を通していても、その後にPNG(RGBA)を overlayすると自動で4:4:4に戻る。指定しないと `High 4:4:4 Predictive` で出力され、ハードウェアデコーダ非対応の環境で再生できない |
| `-crf 16` | 4〜5Mbps | YouTubeは再エンコードするので、渡す素材は高品質な方が有利 |
| `-g 60` | 2秒 | YouTube推奨のGOP |
| `-ar 48000` | | YouTube推奨。アップ時の再サンプリングを避ける |

書き出したら**必ず `ffprobe` で pix_fmt を確認する**。

## 骨格（4シーン＋エンドカード）

```sh
CC="fps=30,scale=886:1926,crop=886:1920,setsar=1"   # 実機収録1206×2622 → 886×1920
ffmpeg -y -i <収録.mp4> -i <プレビュー.mp4> \
  -i cap1.png -i cap2.png -i cap3.png -i patch.png -i gear_patch.png \
  -framerate 30 -loop 1 -t 5 -i endcard.png -i bgm.mp3 \
  -i n1.wav -i n2.wav -i n3.wav -i n4.wav -i n5.wav \
  -filter_complex "\
[0:v]trim=<s>:<e>,setpts=PTS-STARTPTS,${CC}[s1];\
[0:v]trim=<s>:<e>,setpts=PTS-STARTPTS,${CC}[s2];\
[0:v]trim=<s>:<e>,setpts=PTS-STARTPTS,${CC}[s3];\
[1:v]trim=<s>:<e>,setpts=PTS-STARTPTS,fps=30,setsar=1[s4];\
[s1][s2][s3][s4]concat=n=4:v=1:a=0,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=<背景色>,setsar=1,settb=AVTB[v0];\
[v0][5:v]overlay=115:1785:enable='gte(t,<ホーム開始>)'[vp];\
[vp][6:v]overlay=455:1630:enable='gte(t,<ホーム開始>)'[vg];\
[vg][2:v]overlay=(main_w-overlay_w)/2:256:enable='lte(t,<終>)'[c1];\
[c1][3:v]overlay=(main_w-overlay_w)/2:256:enable='between(t,<始>,<終>)'[c2];\
[c2][4:v]overlay=(main_w-overlay_w)/2:256:enable='between(t,<始>,<終>)',format=yuv420p,settb=AVTB[c3];\
[7:v]setsar=1,format=yuv420p,settb=AVTB[e];\
[c3][e]xfade=transition=fade:duration=0.5:offset=<本編尺-0.5>,format=yuv420p[v];\
[9:a]adelay=450|450[n1];[10:a]adelay=<ms>|<ms>[n2];[11:a]adelay=<ms>|<ms>[n3];\
[12:a]adelay=<ms>|<ms>[n4];[13:a]adelay=<ms>|<ms>[n5];\
[n1][n2][n3][n4][n5]amix=inputs=5:normalize=0,volume=5.0dB,apad,atrim=0:<総尺>,asplit=2[nar][sc];\
[8:a]atrim=0:<総尺>,volume=0.32,afade=t=out:st=<総尺-1.5>:d=1.5,aformat=sample_rates=44100:channel_layouts=stereo[bgm];\
[bgm][sc]sidechaincompress=threshold=0.02:ratio=8:attack=20:release=500[duck];\
[duck][nar]amix=inputs=2:normalize=0,alimiter=limit=0.89:level=disabled,aformat=sample_rates=48000:channel_layouts=stereo[a]" \
  -map "[v]" -map "[a]" -t <総尺> \
  -c:v libx264 -profile:v high -crf 16 -preset medium -g 60 -pix_fmt yuv420p \
  -c:a aac -b:a 192k -ar 48000 -movflags +faststart out.mp4
```

総尺 = 本編尺 - 0.5 + エンドカード尺。`-t <総尺>` を付けないと `apad` で無限に伸びる。

## 罠

| 症状 | 原因と対処 |
| --- | --- |
| `xfade` が `Failed to configure output pad` で失敗 | 入力のタイムベース不一致。**両方の入力に `settb=AVTB`** を付ける。`concat` で組んだ映像で必ず起きる |
| 出力が `High 4:4:4 Predictive` になる | `-pix_fmt yuv420p` の指定漏れ（上記） |
| `alimiter` を通すと音量が勝手に上がる | **既定で自動レベル調整が入る**。`alimiter=limit=0.89:level=disabled` と書く |
| `drawbox` の色が指定と違う | YUVのレンジ変換。**単色PNGを作って overlay する** |
| 文字が描画できない | ローカルのffmpegに `drawtext` が入っていない。**PillowでPNG化して overlay** |
| zshで `$VAR[v]` が空になる | 添字と解釈される。**`${VAR}`** と書く |
| zshで `set -- $spec` が分割されない | **`set -- ${=spec}`** と書く |
| 音がぶつ切りになる | シーン境界は映像0.35秒のクロスフェード＋`acrossfade` で繋ぐ |

## 検証

```sh
# 形式（pix_fmt が yuvj420p / yuv420p であること）
ffprobe -v error -show_entries stream=codec_name,profile,pix_fmt,width,height,r_frame_rate,sample_rate \
  -show_entries format=duration -of default=nw=1 out.mp4

# ラウドネス（I が -14 前後、Peak が -1 前後）
ffmpeg -i out.mp4 -af ebur128=peak=true -f null - 2>&1 | grep -E "^ +I:| +LRA:| +Peak:"

# 目視確認用のタイル画像（必ず Read して見る）
for t in 0.5 4.5 8.0 13.0 18.0; do
  ffmpeg -y -ss $t -i out.mp4 -frames:v 1 -vf scale=220:391 f_$t.png
done
python3 -c "
from PIL import Image
ts=['0.5','4.5','8.0','13.0','18.0']
out=Image.new('RGB',(220*len(ts),391),(255,255,255))
for i,t in enumerate(ts): out.paste(Image.open(f'f_{t}.png'),(220*i,0))
out.save('tile.png')"
```

チェック項目: 1フレーム目にキャプションがあるか / パッチが対象を隠せているか（座標は
padの前後でズレる）/ シーンの切れ目が中途半端でないか / エンドカードの文字組み。

## 受け渡し

完成品は `SendUserFile` で渡し、**あわせて `~/Downloads/<アプリ名>_<用途>/` にもコピー**する。
スクラッチパッドはOSに消されることがあるため、比較検討が続く間はDownloads側を正とする。
