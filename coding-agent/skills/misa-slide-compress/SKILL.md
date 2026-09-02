---
name: misa-slide-compress
description: Keynote（.key）、PowerPoint（.pptx）、スライドのPDFを、フルHD投影と印刷に耐える画質を保ったまま軽量化する。バックアップと前後比較の検証込み。プレゼン資料の容量削減・軽量化、Keynoteのファイルサイズを減らす、pptxの圧縮、PDFの最適化で使う。スライドの書き出しや作り直しには使わない。
---

# プレゼン資料の容量削減

`.key` / `.pptx` / `.pdf` を軽量化する。**フルHD投影と印刷に耐える画質を保つ**のが基準で、
Web表示用まで落とさない。実測値は `references/quality-benchmarks.md`、症状別の対処は `references/troubleshooting.md`。

## Workflow

1. **バックアップを取る**（必ず最初。同期対象外のローカル領域へ）。
   `ditto "$SRC" "$HOME/Desktop/slide_backup_$(date +%Y%m%d)"`。
   iCloud Drive上のファイルはバックアップ先を **iCloud外**（`~/Desktop` 等）にする。
   処理中にKeynoteが自動保存でバックアップ側を書き換えるのを防げる
2. **`.key` を処理**（`scripts/keynote-batch.sh`。単体なら `scripts/keynote-reduce.sh`）
3. **`.pptx` を処理**（`scripts/pptx-optimize.py`）
4. **`.pdf` を処理**（`scripts/pdf-optimize.sh`。必ず**バックアップの原本から**掛ける）
5. **検証**（`scripts/verify.sh <backup_root> <work_root>`）。ここまで終わるまでバックアップを消さない
6. **更新日時を戻す**（アーカイブでは原本の日時に価値がある）。
   `touch -t "$(date -r "$ORIG_MTIME" +%Y%m%d%H%M.%S)" "$FILE"`

## Keynote (.key)

`ファイルサイズを減らす` はAppleScript辞書に無いので**GUIスクリプティング必須**。
`scripts/keynote-reduce.sh <file.key>` が1ファイル分、`scripts/keynote-batch.sh` が一括処理を
担当する（後者はロック検出・`caffeinate`・mtime復元・Keynote定期再起動を内包）。

実行前に次の3つを満たすこと。満たさないと全件がまとめて失敗する。

- **システム設定 > プライバシーとセキュリティ > アクセシビリティ** でスクリプトを起動するアプリ
  （Claude.app / ターミナル）を許可する。無いと `-1728 補助アクセスは許可されません` で止まる
- **画面をロックせず、バッチ実行中はMacを操作しない**
- **Keynoteで開いている書類が無いことを確認する。** 残っているのに `close every document saving no`
  を投げると**利用者の未保存の作業を捨てる**

縮小は **画像をスライド上の表示サイズ基準の倍率にリサイズ**し、JPEGで再エンコードする処理。
テキストはベクターのままなので無劣化。倍率・品質・投影時の見え方は
`references/quality-benchmarks.md` を正とする。**テーマ付属画像（`Data/PresetImageFill*.jpg`）は
対象外**なので、これが容量の大半を占める資料はほとんど縮まない。

「開けませんでした」などで詰まったら `references/troubleshooting.md`。

## PowerPoint (.pptx)

`scripts/pptx-optimize.py <in.pptx> <out.pptx> [--dpi 350] [--drop-cropped]`。
**PowerPointもLibreOfficeも不要**で、Python + Pillow だけで完結する。`.docx` / `.xlsx` も同じ構造。
`.pptx` はZIPで、画像は `ppt/media/` に素のファイルとして入っている。**OOXMLでは画像の表示サイズは
図形の `<a:ext cx cy>`（EMU）で決まりピクセル数と無関係**なので、解像度を落としてもレイアウトは
1ptも動かず、Keynoteのようにレンダリングして検証する必要がない。

| やること | 既定 | 備考 |
| --- | --- | --- |
| 過剰解像度の画像を目標ppiまで縮小 | ON | 使用箇所ごとの表示サイズ×dpiで必要画素を計算。複数箇所で使われていれば最も厳しい箇所に合わせる |
| 孤児メディアの削除 | ON | どの `.rels` からも参照されていないパート。OPC上、到達不可能なので安全 |
| `docProps/thumbnail.*` の削除 | ON | Finderのプレビュー用だけ |
| JPEGのEXIF/GPS除去 | ON | セグメントを落とすだけで圧縮データには触れない＝可逆 |
| トリミング領域の物理削除 | **OFF** | `--drop-cropped`。**後からトリミングを広げ直せなくなる**ので明示指定制 |
| 非表示スライドの削除 | しない | 表示に戻せなくなる。背後に隠れた画像も、重なり順や不透明度の解釈が要り誤判定が危険 |
| PNG→JPEG変換 | しない | `[Content_Types].xml` と `.rels` の書き換えが必要で透過も失う |

### 鉄則

- **パート名と拡張子を変えない。** `image1.jpeg` は `image1.jpeg` のまま中身だけ差し替える
- **目標ppiを下回る画像には触らない。拡大は絶対にしない。** 実測例では同じファイル内に
  790 ppi の写真と 59 ppi の図が同居していた。一律圧縮は後者の画質を落とすだけで容量も減らない
- **解像度を変えないJPEGは再圧縮しない。** 既に非可逆なものを再エンコードすると劣化するだけ。
  メタデータの可逆除去にとどめる。PNGは可逆なので再最適化してよい
- 検証は `[Content_Types].xml` と全 `.rels` が**バイト単位で不変**、パート構成が一致、
  全画像がデコード可能、の3点（`--drop-cropped` のときだけスライドXMLの `srcRect` が変わる）

**効くのは過剰解像度の縮小とトリミング破棄**。「孤児画像の削除」は宣伝されがちだが、PowerPointは
画像を消すと実体も片付けるので、孤児が溜まるのは他ツールを経由した場合が主（実測でも0件だった）。

## PDF

`scripts/pdf-optimize.sh <in.pdf> <out.pdf> [dpi]`。既定300dpi（印刷基準）。
**2方式を両方試して良い方を採る**のが要点。

| 方式 | 内容 | 効く資料 |
| --- | --- | --- |
| A | Ghostscriptで画像を300dpiにダウンサンプル＋高品質JPEG（QFactor 0.15）。非可逆 | 写真主体 |
| B | qpdfのみ。重複オブジェクト除去・Flate再圧縮・オブジェクトストリーム化・リニアライズ。**可逆** | スクショ主体 |

**Aは可逆Bより10%以上小さいときだけ採用する。** スクリーンショット主体のPDFでは
GhostscriptがFlate画像をJPEGに変換して**逆に増える**（方式別の削減率は
`references/quality-benchmarks.md`、方式Aの副作用は `references/troubleshooting.md`）。

フォントは `-dSubsetFonts=true -dEmbedAllFonts=true` でサブセット埋め込みを維持する。
**埋め込みを外さないこと**（他環境で表示が崩れる）。

## 検証

`scripts/verify.sh` が以下を突き合わせる。**ページ数・スライド数・埋め込みフォントは
1件でも不一致なら採用しない。**

- `.pdf` — ページ数 / 抽出テキストの文字多重集合 / 未埋め込みフォントの有無
- `.key` — ZIP整合性 / Keynoteで開けるか / スライド数

方式Aの `.pdf` は文字差が出ることがある（描画は正常）。判断は `references/troubleshooting.md`。

画質を目視で確かめるときは、**投影解像度でレンダリングして等倍で並べる**。
`pdftoppm -r 384`（3840px相当 = 4K）と `-r 192`（1080p相当）を撮り、差分bboxを取って
その領域だけcrop比較する。全体の縮小画像を見比べても差は分からない。

## 原則

- **バックアップ無しで実行しない。** 縮小は元に戻せない。macOSの版履歴はあてにできない
  （実測で3ファイルとも「バージョンを戻す > 書類なし」で復元不可だった）
- **PDFは常にバックアップの原本から処理する。** 作業ファイルに二度掛けすると多重圧縮になる
- **縮まなかったら原本を維持する。** `.key` も `.pdf` も、処理後にサイズを比較して増えていたら
  バックアップから戻す。Keynoteの縮小でも増えることがあり、原本が無ければ取り返せない
  （`keynote-batch.sh` は自動で戻し、`pdf-optimize.sh` は縮まなければ出力しない）
- **画像内の文字（UIスクショ等）を含む資料は4K投影に注意。** 劣化が最も見える箇所

## References

- `references/quality-benchmarks.md` — 実測値（解像度・JPEG品質・投影時の必要px・削減率）
- `references/troubleshooting.md` — 症状別の対処と運用上の落とし穴
