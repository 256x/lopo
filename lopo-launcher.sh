#!/bin/bash

# 仮想環境のディレクトリ（修正済み）
VENV_DIR="$HOME/uv/lopo-env"

# ログファイル
LOGFILE="$HOME/.cache/lopo/lopo-launcher.log"
mkdir -p "$(dirname "$LOGFILE")"

# ログ出力関数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOGFILE"
}

# 一時的にブラウザウィンドウからURLを取得してクリップボードにコピー
get_browser_url() {
    BROWSER_WINDOW=$(xdotool search --onlyvisible --class "firefox|chrome|chromium|brave|opera" | head -1)

    if [ -z "$BROWSER_WINDOW" ]; then
        for browser in Firefox Google-chrome Chromium Brave-browser Opera; do
            BROWSER_WINDOW=$(xdotool search --onlyvisible --class "$browser" | head -1)
            if [ -n "$BROWSER_WINDOW" ]; then
                break
            fi
        done
    fi

    if [ -n "$BROWSER_WINDOW" ]; then
        log "Browser window found: $BROWSER_WINDOW"
        xdotool windowactivate "$BROWSER_WINDOW"
        sleep 0.2
        xdotool key ctrl+l
        sleep 0.1
        xdotool key ctrl+c
        sleep 0.2

        CLIP=$(xclip -o -selection clipboard)
        log "Clipboard URL after browser fetch: $CLIP"
        return 0
    else
        log "No browser window found"
        return 1
    fi
}

# URL取得処理
if get_browser_url; then
    URL=$(xclip -o -selection clipboard)
else
    notify-send "lopo" "ブラウザが見つかりません。クリップボードから試行します。"
    log "Falling back to clipboard"
    URL=$(xclip -o -selection clipboard)
    log "Clipboard URL fallback: $URL"
fi

# 仮想環境を有効化
source "$VENV_DIR/bin/activate"

# lopo-add.py を実行（URLを明示渡し）
if python ~/.local/bin/lopo-add.py "$URL"; then
    notify-send "lopo" "Saved URL from browser clipboard."
    log "Saved successfully: $URL"
else
    notify-send "lopo" "Failed to save URL. Check log."
    log "Error during saving: $URL"
fi

# 仮想環境を無効化
deactivate

