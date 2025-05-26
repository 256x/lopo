#!/bin/bash

# Load environment variables from ~/.config/lopo/.env if it exists
ENV_FILE="$HOME/.config/lopo/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
fi

LOPO_DIR="${LOPO_DIR:-$HOME/Documents/lopo}"

if [[ ! -d "$LOPO_DIR" ]]; then
    echo "❌ lopo ディレクトリが見つかりません: $LOPO_DIR"
    notify-send "lopo-search" "ディレクトリが見つかりません"
    exit 1
fi

SEARCH_TERM="$1"

if [[ -z "$SEARCH_TERM" ]]; then
    echo "🔍 検索語が指定されていないため、すべてのファイルから選択します..."

    RESULT=$(find "$LOPO_DIR" -type f -name "*.md" -printf '%T@ %p\n' 2>/dev/null \
        | sort -nr | cut -d' ' -f2- \
        | fzf \
            --header='ファイルを選択してください' \
            --preview "echo '📄 ファイル: {}'; echo '📅 作成日: \$(stat -c %y {})'; echo ''; bat --style=plain --color=always --highlight-line 1 --wrap=never {} 2>/dev/null || head -n 30 {}" \
            --preview-window=up:70%:wrap)
else
    echo "🔍 検索語: '$SEARCH_TERM'"

    SEARCH_RESULTS=$(find "$LOPO_DIR" -type f -name "*.md" 2>/dev/null \
        | xargs grep -l "$SEARCH_TERM" 2>/dev/null)

    if [[ -z "$SEARCH_RESULTS" ]]; then
        echo "❌ 検索結果が見つかりませんでした"
        notify-send "lopo-search" "「$SEARCH_TERM」の検索結果なし"
        exit 1
    fi

    result_count=$(echo "$SEARCH_RESULTS" | wc -l)
    echo "📋 ${result_count}件の検索結果が見つかりました"

    RESULT=$(echo "$SEARCH_RESULTS" | fzf \
        --header="検索結果から選択 (${result_count}件)" \
        --preview "echo '📄 ファイル: {}'; echo '📅 作成日: \$(stat -c %y {})'; echo '🔍 検索語: $SEARCH_TERM'; echo ''; grep -n --color=always '$SEARCH_TERM' {} | head -5; echo ''; bat --style=plain --color=always --highlight-line 1 --wrap=never {} 2>/dev/null || head -n 30 {}" \
        --preview-window=up:70%:wrap)
fi

if [[ -z "$RESULT" ]]; then
    echo "キャンセルしました"
    exit 0
fi

echo "📄 選択されたファイル: $RESULT"

URL=$(grep -oP '(?<=\[リンク\]\().*?(?=\))' "$RESULT" | head -1)

if [[ -z "$URL" ]]; then
    URL=$(grep -oE 'https?://[^\s)]+' "$RESULT" | head -1)
fi

if [[ -z "$URL" ]]; then
    echo "❌ URLが見つかりませんでした"
    notify-send "lopo-search" "URLが見つかりませんでした"

    echo "📄 ファイルの内容:"
    cat "$RESULT"
    exit 1
fi

echo "🌐 URLを開きます: $URL"

if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$URL" &
else
    echo "❌ xdg-openコマンドが見つかりません"
    notify-send "lopo-search" "ブラウザを開けませんでした"
    exit 1
fi

sleep 1.5

activate_browser() {
    if command -v wmctrl >/dev/null 2>&1; then
        BROWSER_WINDOW=$(wmctrl -lx | grep -iE "firefox\.Navigator|chromium|google-chrome|brave" | head -n 1 | awk '{print $1}')

        if [[ -n "$BROWSER_WINDOW" ]]; then
            wmctrl -ia "$BROWSER_WINDOW"
            echo "✅ ブラウザウィンドウをアクティブにしました"
            return 0
        fi
    fi

    if command -v i3-msg >/dev/null 2>&1; then
        i3-msg workspace number 2 >/dev/null 2>&1

        sleep 0.5

        if command -v wmctrl >/dev/null 2>&1; then
            BROWSER_WINDOW=$(wmctrl -lx | grep -iE "firefox\.Navigator|chromium|google-chrome|brave" | head -n 1 | awk '{print $1}')
            if [[ -n "$BROWSER_WINDOW" ]]; then
                wmctrl -ia "$BROWSER_WINDOW"
                echo "✅ ブラウザウィンドウをアクティブにしました (i3)"
                return 0
            fi
        fi
    fi

    echo "⚠  ブラウザウィンドウの自動アクティブ化に失敗しました"
    return 1
}

if activate_browser; then
    notify-send "lopo-search" "URLを開きました: $(basename "$RESULT")"
else
    notify-send "lopo-search" "URLを開きました（手動でブラウザを確認してください）"
fi