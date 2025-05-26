# lopo - ウェブページ保存・管理スクリプト

`lopo`は、ブラウザで閲覧中のウェブページをホットキーで素早くMarkdownファイルとして保存し、保存したファイルを検索・削除するためのスクリプト群です。Linuxのi3ウィンドウマネージャ（i3-wm）環境向けに設計されており、ホットキーを押すことで現在のウェブページのURLと内容を保存するワークフローを実現します。

## 機能
- **ウェブページ保存**: `lopo-add.py`がクリップボードまたはブラウザから取得したURLのウェブページをフェッチし、`readability`と`BeautifulSoup`でタイトルと本文を抽出し、Markdownファイルとして保存。
- **ホットキー統合**: `lopo-launcher.sh`がアクティブなブラウザ（例：Firefox、Chrome）からURLを取得し、`lopo-add.py`を実行。
- **保存ファイル検索**: `lopo-search.sh`で保存したMarkdownファイルを`fzf`を使って検索し、関連URLをブラウザで開く。
- **ファイル削除**: `lopo-delete.sh`で保存したMarkdownファイルを`fzf`を使って選択・削除。
- **通知**: `notify-send`で成功やエラーのフィードバックを表示。
- **ログ**: デバッグ用に`~/.cache/lopo/lopo-launcher.log`と`/tmp/lopo-debug.log`にログを記録。

## 前提条件
- **OS**: Linux（i3-wm環境で開発）。
- **依存パッケージ**:
  - Python 3（`lopo-add.py`用）
  - Pythonライブラリ: `requests`, `beautifulsoup4`, `readability-lxml`
  - システムツール: `xclip`, `xdotool`, `wmctrl`, `fzf`, `bat`（プレビュー用、オプション）, `notify-send`, `xdg-open`
  - Python仮想環境（`~/uv/lopo-env`に設定）
- **ブラウザ**: Firefox、Chrome、Chromium、Brave、Operaに対応。
- **ウィンドウマネージャ**: i3-wm向けに設定済みだが、他の環境にも適応可能。

## インストール
1. **リポジトリをクローン**:
   ```bash
   git clone <your-repo-url>
   cd lopo
   ```

2. **仮想環境のセットアップ**:
   Python仮想環境を作成し、依存パッケージをインストール:
   ```bash
   mkdir -p ~/uv/lopo-env
   python3 -m venv ~/uv/lopo-env
   source ~/uv/lopo-env/bin/activate
   pip install requests beautifulsoup4 readability-lxml
   deactivate
   ```

3. **システム依存パッケージのインストール**:
   Debian系システムの場合:
   ```bash
   sudo apt update
   sudo apt install xclip xdotool wmctrl fzf libnotify-bin xdg-utils
   ```
   ファイルプレビューを強化する場合（オプション）:
   ```bash
   sudo apt install bat
   ```

4. **スクリプトの配置**:
   スクリプトを`~/.local/bin`にコピーして実行権限を付与:
   ```bash
   mkdir -p ~/.local/bin
   cp lopo-add.py lopo-launcher.sh lopo-delete.sh lopo-search.sh ~/.local/bin/
   chmod +x ~/.local/bin/lopo-*.{py,sh}
   ```

5. **i3-wmホットキーの設定**:
   i3の設定ファイル（例：`~/.config/i3/config`）にホットキーを追加して`lopo-launcher.sh`を呼び出します。以下は`Shift+Mod+p`（Modは通常Super/Winキー）を割り当てる例:
   ```bash
   bindsym $mod+Shift+p exec --no-startup-id ~/.local/bin/lopo-launcher.sh
   ```
   - `$mod`はi3の修飾キー（通常`Mod1`（Alt）または`Mod4`（Super/Win））です。自分の設定に合わせて調整してください。
   - `--no-startup-id`はi3の起動通知を抑制します。
   - 他のキー（例：`Mod4+s`など）を好みに応じて設定可能。例:
     ```bash
     bindsym $mod+s exec --no-startup-id ~/.local/bin/lopo-launcher.sh
     ```

## 使用方法
- **ウェブページの保存**:
  - 対応ブラウザで閲覧中にホットキー（例：`Shift+Mod+p`）を押す。
  - `lopo-launcher.sh`がブラウザからURLを取得し、`lopo-add.py`を実行。
  - ページのタイトルと内容が`~/Documents/lopo/YYYY/MM/YYYY-MM-DD_HHMMSS_タイトル.md`に保存。
  - 成功またはエラーの通知が表示。

- **保存ファイルの検索**:
  ```bash
  ~/.local/bin/lopo-search.sh [検索語]
  ```
  - 検索語なしの場合、`~/Documents/lopo`内の全`.md`ファイルを`fzf`で一覧表示。
  - 検索語指定時は、該当するファイルのみを`fzf`で選択可能。
  - 選択したファイルのURLをデフォルトブラウザで開き、i3-wmでブラウザウィンドウをアクティブ化。

- **保存ファイルの削除**:
  ```bash
  ~/.local/bin/lopo-delete.sh
  ```
  - `~/Documents/lopo`内の`.md`ファイルを`fzf`で複数選択可能。
  - 選択したファイルを削除（確認プロンプトあり）。
  - 成功または失敗の通知を表示。

## 注意事項
- **カスタマイズ必須**: このスクリプトは私のi3-wm環境（仮想環境: `~/uv/lopo-env`, 保存先: `~/Documents/lopo`）向けに作られています。自分の環境に合わせて以下の設定を調整してください:
  - 仮想環境のパス（`lopo-launcher.sh`の`VENV_DIR`）
  - 保存ディレクトリ（`LOPO_DIR`や`lopo-add.py`の`base_dir`）
  - ブラウザのクラス名（`lopo-launcher.sh`の`get_browser_url`関数）
  - ホットキー（i3設定ファイル）
- **依存ツールの確認**: 必要なツール（`xclip`, `xdotool`, `wmctrl`, `fzf`, `notify-send`, `xdg-open`）がインストールされていることを確認してください。
- **ログファイル**: `/tmp/lopo-debug.log`と`~/.cache/lopo/lopo-launcher.log`にログが記録されます。問題発生時はこれらを確認してください。
- **ブラウザ互換性**: 一部のブラウザや環境ではURL取得が失敗する場合があります。その場合、クリップボードからURLを取得するフォールバックが動作します。
- **セキュリティ**: 保存されるウェブページの内容に機密情報が含まれないよう注意してください。公開リポジトリにアップロードする場合は、保存ディレクトリ（`~/Documents/lopo`）に個人情報が含まれていないことを確認してください。

## ライセンス
MIT

