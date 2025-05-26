#!/bin/bash

# 保存ディレクトリ
LOPO_DIR="$HOME/Documents/lopo"

# ディレクトリの存在確認
if [[ ! -d "$LOPO_DIR" ]]; then
    echo "❌ lopo ディレクトリが見つかりません: $LOPO_DIR"
    notify-send "lopo-search" "ディレクトリが見つかりません"
    exit 1
fi

# 検索語
SEARCH_TERM="$1"

# 検索語が指定されていない場合の処理
if [[ -z "$SEARCH_TERM" ]]; then
    echo "🔍 検索語が指定されていないため、すべてのファイルから選択します..."
    
    # 全ファイルから選択（日付順ソート）
    RESULT=$(find "$LOPO_DIR" -type f -name "*.md" -printf '%T@ %p\n' 2>/dev/null \
        | sort -nr | cut -d' ' -f2- \
        | fzf \
            --header='ファイルを選択してください' \
            --preview "echo '📄 ファイル: {}'; echo '📅 作成日: \$(stat -c %y {})'; echo ''; bat --style=plain --color=always --highlight-line 1 --wrap=never {} 2>/dev/null || head -n 30 {}" \
            --preview-window=up:70%:wrap)
else
    echo "🔍 検索語: '$SEARCH_TERM'"
    
    # 検索語で全文検索
    SEARCH_RESULTS=$(find "$LOPO_DIR" -type f -name "*.md" 2>/dev/null \
        | xargs grep -l "$SEARCH_TERM" 2>/dev/null)
    
    if [[ -z "$SEARCH_RESULTS" ]]; then
        echo "❌ 検索結果が見つかりませんでした"
        notify-send "lopo-search" "「$SEARCH_TERM」の検索結果なし"
        exit 1
    fi
    
    # 検索結果の件数表示
    result_count=$(echo "$SEARCH_RESULTS" | wc -l)
    echo "📋 ${result_count}件の検索結果が見つかりました"
    
    # fzfで結果から選択
    RESULT=$(echo "$SEARCH_RESULTS" | fzf \
        --header="検索結果から選択 (${result_count}件)" \
        --preview "echo '📄 ファイル: {}'; echo '📅 作成日: \$(stat -c %y {})'; echo '🔍 検索語: $SEARCH_TERM'; echo ''; grep -n --color=always '$SEARCH_TERM' {} | head -5; echo ''; bat --style=plain --color=always --highlight-line 1 --wrap=never {} 2>/dev/null || head -n 30 {}" \
        --preview-window=up:70%:wrap)
fi

# 選択されなかった場合は終了
if [[ -z "$RESULT" ]]; then
    echo "キャンセルしました"
    exit 0
fi

echo "📄 選択されたファイル: $RESULT"

# URLを抽出（複数の形式に対応）
URL=$(grep -oP '(?<=\[リンク\]\().*?(?=\))' "$RESULT" | head -1)

# URLが見つからない場合は他の形式も試す
if [[ -z "$URL" ]]; then
    URL=$(grep -oE 'https?://[^\s)]+' "$RESULT" | head -1)
fi

# URLが見つからない場合
if [[ -z "$URL" ]]; then
    echo "❌ URLが見つかりませんでした"
    notify-send "lopo-search" "URLが見つかりませんでした"
    
    # ファイルの内容を表示
    echo "📄 ファイルの内容:"
    cat "$RESULT"
    exit 1
fi

echo "🌐 URLを開きます: $URL"

# ブラウザでURLを開く
if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$URL" &
else
    echo "❌ xdg-openコマンドが見つかりません"
    notify-send "lopo-search" "ブラウザを開けませんでした"
    exit 1
fi

# ブラウザが開くまで少し待つ
sleep 1.5

# ブラウザウィンドウをアクティブにする
activate_browser() {
    # wmctrlが利用可能かチェック
    if command -v wmctrl >/dev/null 2>&1; then
        BROWSER_WINDOW=$(wmctrl -lx | grep -iE "firefox\.Navigator|chromium|google-chrome|brave" | head -n 1 | awk '{print $1}')
        
        if [[ -n "$BROWSER_WINDOW" ]]; then
            wmctrl -ia "$BROWSER_WINDOW"
            echo "✅ ブラウザウィンドウをアクティブにしました"
            return 0
        fi
    fi
    
    # i3wmの場合
    if command -v i3-msg >/dev/null 2>&1; then
        # ブラウザが通常あるワークスペースに移動
        i3-msg workspace number 2 >/dev/null 2>&1
        
        sleep 0.5
        
        # 再度ブラウザウィンドウを探す
        if command -v wmctrl >/dev/null 2>&1; then
            BROWSER_WINDOW=$(wmctrl -lx | grep -iE "firefox\.Navigator|chromium|google-chrome|brave" | head -n 1 | awk '{print $1}')
            if [[ -n "$BROWSER_WINDOW" ]]; then
                wmctrl -ia "$BROWSER_WINDOW"
                echo "✅ ブラウザウィンドウをアクティブにしました (i3)"
                return 0
            fi
        fi
    fi
    
    echo "⚠️  ブラウザウィンドウの自動アクティブ化に失敗しました"
    return 1
}

# ブラウザアクティブ化を実行
if activate_browser; then
    notify-send "lopo-search" "URLを開きました: $(basename "$RESULT")"
else  
    notify-send "lopo-search" "URLを開きました（手動でブラウザを確認してください）"
fi
