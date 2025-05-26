#!/bin/bash

VENV_DIR="${LOPO_VENV:-$HOME/uv/lopo-env}"
LOGFILE="${LOPO_LAUNCHER_LOG:-$HOME/.cache/lopo/lopo-launcher.log}"
mkdir -p "$(dirname "$LOGFILE")"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOGFILE"
}

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

if get_browser_url; then
    URL=$(xclip -o -selection clipboard)
else
    notify-send "lopo" "ブラウザが見つかりません。クリップボードから試行します。"
    log "Falling back to clipboard"
    URL=$(xclip -o -selection clipboard)
    log "Clipboard URL fallback: $URL"
fi

source "$VENV_DIR/bin/activate"

if python ~/.local/bin/lopo-add.py "$URL"; then
    notify-send "lopo" "Saved URL from browser clipboard."
    log "Saved successfully: $URL"
else
    notify-send "lopo" "Failed to save URL. Check log."
    log "Error during saving: $URL"
fi

deactivate