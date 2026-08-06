#!/usr/bin/env zsh
set -e

# テキストから読み上げ音声を作る汎用環境（ナレーション・デモ動画の音声など用途は問わない）。
# - 日本語: AivisSpeech（GUIアプリ。Gatekeeper解除が必要なため手動インストール）
# - 英語・中国語ほか: Qwen3-TTS（Python venv）
# 詳細と使い方は README.md。

script_dir="${0:A:h}"
venv_dir="$HOME/.venvs/qwen-tts"

setup_qwen_tts() {
  if ! command -v uv >/dev/null 2>&1; then
    echo "uv が見つかりません（mise/installer.sh を先に実行してください）。Qwen3-TTSの設定をスキップします"
    return
  fi

  if [[ ! -d "$venv_dir" ]]; then
    echo "Qwen3-TTS用のvenvを作成します: $venv_dir"
    uv venv --python 3.12 "$venv_dir"
  fi

  # numba を先に固定する。qwen-tts → librosa → numba の依存解決で
  # Python 3.10未満しかサポートしない古いnumbaを掴んでビルドに失敗するため
  VIRTUAL_ENV="$venv_dir" uv pip install -q "numba>=0.61" librosa
  VIRTUAL_ENV="$venv_dir" uv pip install -q torch soundfile qwen-tts

  echo "Qwen3-TTS: $("$venv_dir/bin/python" -c 'import torch; print("torch", torch.__version__, "MPS", torch.backends.mps.is_available())')"
}

# モデル本体（約2GB）は初回の推論時に ~/.cache/huggingface へ自動DLされる。
# 事前に落としておきたい場合だけ実行する
prefetch_qwen_model() {
  printf "Qwen3-TTSのモデル（約2GB）を今ダウンロードしますか? (y/n) :  "
  IFS= read -r answer
  [[ "$answer" = "y" ]] || return
  "$venv_dir/bin/python" - <<'PY'
from huggingface_hub import snapshot_download
snapshot_download("Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice")
print("downloaded")
PY
}

check_aivisspeech() {
  if [[ -d /Applications/AivisSpeech.app ]]; then
    echo "AivisSpeech: インストール済み"
    if curl -s -m 3 -o /dev/null http://127.0.0.1:10101/version; then
      echo "AivisSpeech: エンジン稼働中（http://127.0.0.1:10101）"
    else
      echo "AivisSpeech: エンジンが停止中。日本語ナレーションを作るときはアプリを起動しておくこと"
    fi
    return
  fi

  cat <<'MSG'
AivisSpeech（日本語ナレーション用）が未インストールです。手動で入れてください:

  1. https://aivis-project.com/speech/ からmacOS版をダウンロードしてインストール
  2. 初回起動はGatekeeperにブロックされる（Apple Developer IDでの署名がないため）。
     「ゴミ箱に入れる」ではなく「完了」を押し、
     システム設定 → プライバシーとセキュリティ → 「このまま開く」→ 認証 → 「開く」
  3. アプリ内の音声合成モデル管理から「まお」を追加
     https://hub.aivis-project.com/aivm-models/a59cb814-0083-4369-8542-f51a29e72af7
  4. 読み方・アクセント辞書を復元する（アプリ起動後）: ./aivisspeech-dict.sh import

MSG
}

setup_qwen_tts
[[ -d "$venv_dir" ]] && prefetch_qwen_model
check_aivisspeech

echo 👍 TTS setting is done!
