#!/bin/bash

LOPO_DIR="${LOPO_DIR:-$HOME/Documents/lopo}"

if [[ ! -d "$LOPO_DIR" ]]; then
    echo "❌ lopo ディレクトリが見つかりません: $LOPO_DIR"
    notify-send "lopo-delete" "ディレクトリが見つかりません"
    exit 1
fi

cd "$LOPO_DIR" || exit 1

if ! find . -type f -name "*.md" -print -quit | grep -q .; then
    echo "削除可能な.mdファイルがありません"
    notify-send "lopo-delete" "削除可能なファイルがありません"
    exit 0
fi

targets=$(find . -type f -name "*.md" -printf '%T@ %p\n' | sort -nr | cut -d' ' -f2- | fzf \
  --multi \
  --bind 'space:toggle' \
  --header='Space: 選択/解除, Enter: 確定, Esc: キャンセル' \
  --preview 'echo "📄 ファイル: {}"; echo "📅 作成日: $(stat -c %y {})"; echo "📏 サイズ: $(stat -c %s {}) bytes"; echo ""; bat --style=plain --color=always --wrap=never {} 2>/dev/null || head -n 30 {}' \
  --preview-window=up:70%:wrap)

if [[ -z "$targets" ]]; then
    echo "キャンセルしました"
    exit 0
fi

file_count=$(echo "$targets" | wc -l)
echo "🗑  以下の${file_count}個のファイルを削除します:"
echo "$targets" | sed 's/^/  - /'

echo ""
read -p "本当に削除しますか？ [y/N]: " confirm

if [[ "$confirm" =~ ^[yY]$ ]]; then
    deleted_count=0
    failed_count=0

    while IFS= read -r file; do
        if rm "$file" 2>/dev/null; then
            echo "✅ 削除: $file"
            ((deleted_count++))
        else
            echo "❌ 失敗: $file"
            ((failed_count++))
        fi
    done <<< "$targets"

    if [[ $failed_count -eq 0 ]]; then
        echo "🎉 ${deleted_count}個のファイルを削除しました"
        notify-send "lopo-delete" "${deleted_count}個のファイルを削除しました"
    else
        echo "⚠  ${deleted_count}個削除、${failed_count}個失敗"
        notify-send "lopo-delete" "${deleted_count}個削除、${failed_count}個失敗"
    fi
else
    echo "キャンセルしました"
    notify-send "lopo-delete" "削除をキャンセルしました"
fi