# TTS（読み上げ音声の生成環境）

テキストから読み上げ音声を作るための汎用環境。用途は問わない
（販促動画のナレーション、デモ動画・解説動画の音声、下読みの確認など）。

この環境を前提にしたエージェントスキルの例: `zzzmisa-shorts-video`（YouTube Shorts販促動画）。

| 用途 | ツール | ライセンス | クレジット |
| --- | --- | --- | --- |
| 日本語 | AivisSpeech + 音声合成モデル「まお」 | ACML 1.0 | 任意（推奨 `AivisSpeech: まお`） |
| 英語・中国語ほか | Qwen3-TTS `Qwen3-TTS-12Hz-0.6B-CustomVoice` | Apache 2.0 | 不要 |

どちらも**商用利用可**。有料アプリの宣伝動画に使える。

## セットアップ

`installer.sh` を実行する（`dotfiles-mac/installer.sh` からも呼ばれる）。
Qwen3-TTS用のvenvは `~/.venvs/qwen-tts` に作られる。

AivisSpeechはHomebrewで配布されていないため手動インストール。
**Apple Developer IDで署名されていない**ので初回起動時にGatekeeperにブロックされる。
「ゴミ箱に入れる」を押さないこと。システム設定 → プライバシーとセキュリティ →
「このまま開く」で許可する（macOS 15以降は右クリック「開く」では回避できない）。

## 使い方

### 日本語（AivisSpeech）

アプリを起動しておくと、VOICEVOX互換のAPIが `http://127.0.0.1:10101` で待ち受ける。

```sh
curl -s "http://127.0.0.1:10101/speakers" | python3 -m json.tool | head   # 話者とstyle idの確認
```

```python
import json, urllib.parse, urllib.request
B, sid = "http://127.0.0.1:10101", 888753763  # まお／おちつき
q = urllib.request.urlopen(urllib.request.Request(
    f"{B}/audio_query?text={urllib.parse.quote('読ませたい文')}&speaker={sid}", method="POST")).read()
wav = urllib.request.urlopen(urllib.request.Request(
    f"{B}/synthesis?speaker={sid}", data=q,
    headers={"Content-Type": "application/json"}, method="POST")).read()
open("out.wav", "wb").write(wav)
```

- **読点「、」はポーズを作らない**。直前の句にモーラとして取り込まれるだけなので、
  間が不自然なら半角スペースに置き換えるか削る（`/audio_query` の結果を見ると
  どう区切られたか分かる）
- 固有名詞（アプリ名など）は辞書登録する（下記）。登録しないと単語が分割されて
  別々の語のように読まれる
- `/audio_query` の `accent_phrases` を書き換えれば、アクセント位置を1語単位で調整できる

#### 読み方・アクセント辞書

辞書の実体は **`~/Library/Application Support/AivisSpeech-Engine/user_dict.json`** にあり、
**dotfilesの管理外**。放置するとPC買い替えで失われるので、`user-dict.json` に
書き出してコミットしておく。

```sh
./aivisspeech-dict.sh list                        # 登録内容の確認
./aivisspeech-dict.sh add みえかた図鑑 ミエカタズカン 5   # 登録（アクセント型は下記）
./aivisspeech-dict.sh export                      # user-dict.json へ書き出す（変更したら必ず）
./aivisspeech-dict.sh import                      # 新しいMacで復元する
```

アクセント型は「何モーラ目の直後で音が下がるか」。0は平板。
例: `ミエカタズカン`（7モーラ）で5なら「ズ」の後で下がる。
耳で確かめて決める。APIは重複チェックをしないが、このスクリプトは
同じ内容が既にあればスキップする。

### 英語・中国語（Qwen3-TTS）

```python
import torch, soundfile as sf
from qwen_tts import Qwen3TTSModel
model = Qwen3TTSModel.from_pretrained(
    "Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice",
    device_map="mps", dtype=torch.bfloat16, attn_implementation="sdpa")
wavs, sr = model.generate_custom_voice(
    text="Hello.", language="English", speaker="Vivian",
    instruct="Speak gently and warmly, like reading a picture book aloud to a small child.")
sf.write("out.wav", wavs[0], sr)
```

- 話者は9種（Vivian / Serena / Uncle_Fu / Dylan / Eric / Ryan / Aiden / Ono_Anna / Sohee）。
  リファレンス音声のクローンではなく、**話者＋自然言語の演技指示**で声を作るモデル
- `language` は `English` / `Chinese` / `Japanese` など。中国語の演技指示は中国語で書く
- macOSでは flash-attn が使えないので `attn_implementation="sdpa"`
- 初回実行時にモデル（約2GB）が `~/.cache/huggingface` へDLされる。M5で1行あたり約3.5秒

### 生成後の整音（動画に載せる場合）

```sh
ffmpeg -i in.wav -af "silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.03,\
areverse,silenceremove=start_periods=1:start_threshold=-50dB:start_silence=0.03,areverse,\
loudnorm=I=-17:TP=-1.5:LRA=9,aformat=sample_rates=44100:channel_layouts=stereo" out.wav
```

前後の無音をカットしてから各行を-17 LUFSに揃える。TTSは前後に0.1秒程度の余白を付けるため、
これをやらないとシーンの尺に収まらない。

## 片付け

不要になったら `rm -rf ~/.venvs/qwen-tts ~/.cache/huggingface/hub/models--Qwen--Qwen3-TTS*` で戻せる。
