# lopo - ウェブページ保存・管理スクリプト

`lopo`は、Pocketのサービス終了をきっかけに、ウェブページを素早く保存・管理するための代替ツールとして開発されたスクリプト群です。Linux環境向けに設計されており、ホットキーを設定可能な環境で、ブラウザのウェブページのURLと内容をMarkdownファイルとして保存します。

## 機能
- **ウェブページ保存**: `lopo-add.py`がクリップボードまたはブラウザから取得したURLのウェブページをフェッチし、`readability`と`BeautifulSoup`でタイトルと本文を抽出し、Markdownファイルとして保存。
- **ホットキー統合**: `lopo-launcher.sh`がアクティブなブラウザ（例：Firefox、Chrome）からURLを取得し、`lopo-add.py`を実行。
- **保存ファイル検索**: `lopo-search.sh`で保存したMarkdownファイルを`fzf`を使って検索し、関連URLをブラウザで開く。
- **ファイル削除**: `lopo-delete.sh`で保存したMarkdownファイルを`fzf`を使って選択・削除。
- **通知**: `notify-send`で成功やエラーのフィードバックを表示。
- **ログ**: デバッグ用に`$LOPO_LAUNCHER_LOG`と`$LOPO_DEBUG_LOG`にログを記録。

## 前提条件
- **OS**: Linux（i3-wmで開発・テスト済みだが、他のウィンドウマネージャやデスクトップ環境でも動作可能）。
- **依存パッケージ**:
  - Python 3（`lopo-add.py`用）
  - Pythonライブラリ: `requests`, `beautifulsoup4`, `readability-lxml`, `charset-normalizer`
  - システムツール: `xclip`, `xdotool`, `wmctrl`, `fzf`, `libnotify`（`notify-send`用）, `xdg-utils`, `bat`（プレビュー用、オプション）
  - Python仮想環境（デフォルト：`~/uv/lopo-env`）
- **ブラウザ**: Firefox、Chrome、Chromium、Brave、Operaに対応。
- **非対応環境**: 現在、Windows環境では動作しません（`xclip`, `xdotool`, `wmctrl`などがLinux依存のため）。Windowsへの移植は大歓迎です！

## インストール
1. **リポジトリをクローン**:
   ```bash
   git clone https://github.com/256x/lopo
   cd lopo
   ```

2. **環境変数の設定（オプション）**:
   環境変数をカスタマイズする場合、`.env`ファイルを`~/.config/lopo/.env`に配置します。サンプル：
   ```bash
   mkdir -p ~/.config/lopo
   cat << EOF > ~/.config/lopo/.env
   # lopo environment variables
   LOPO_DIR=~/Documents/lopo
   LOPO_VENV=~/uv/lopo-env
   LOPO_LAUNCHER_LOG=~/.cache/lopo/lopo-launcher.log
   LOPO_DEBUG_LOG=/tmp/lopo-debug.log
   EOF
   ```
   スクリプトは自動で`~/.config/lopo/.env`を読み込みます。カスタムパスを使用する場合は、このファイルを編集してください。

3. **仮想環境のセットアップ**:
   Python仮想環境を作成し、依存パッケージをインストール:
   ```bash
   mkdir -p ~/uv/lopo-env
   python3 -m venv ~/uv/lopo-env
   source ~/uv/lopo-env/bin/activate
   pip install requests beautifulsoup4 readability-lxml charset-normalizer
   deactivate
   ```

4. **システム依存パッケージのインストール**:
   - **Arch Linux**の場合:
     ```bash
     sudo pacman -S xclip xdotool wmctrl fzf libnotify xdg-utils
     ```
     ファイルプレビューを強化する場合（オプション）:
     ```bash
     sudo pacman -S bat
     ```
   - **Debian系**の場合:
     ```bash
     sudo apt update
     sudo apt install xclip xdotool wmctrl fzf libnotify-bin xdg-utils
     ```
     ファイルプレビューを強化する場合（オプション）:
     ```bash
     sudo apt install bat
     ```

5. **スクリプトの配置**:
   スクリプトを`~/.local/bin`にコピーして実行権限を付与:
   ```bash
   mkdir -p ~/.local/bin
   cp lopo-add.py lopo-launcher.sh lopo-delete.sh lopo-search.sh ~/.local/bin/
   chmod +x ~/.local/bin/lopo-*.{py,sh}
   ```

6. **ホットキーの設定（例：i3-wm）**:
   ホットキーを設定可能なウィンドウマネージャやデスクトップ環境で、`lopo-launcher.sh`を呼び出すように設定します。以下はi3-wmの設定ファイル（例：`~/.config/i3/config`）に`Shift+Mod+p`（Modは通常Super/Winキー）を割り当てる例:
   ```bash
   bindsym $mod+Shift+p exec --no-startup-id ~/.local/bin/lopo-launcher.sh
   ```
   - `$mod`はi3の修飾キー（通常`Mod1`（Alt）または`Mod4`（Super/Win））です。自分の設定に合わせて調整してください。
   - `--no-startup-id`はi3の起動通知を抑制します。
   - 他のキー（例：`Mod4+s`など）を好みに応じて設定可能。例:
     ```bash
     bindsym $mod+s exec --no-startup-id ~/.local/bin/lopo-launcher.sh
     ```
   - 他の環境（例：GNOME, KDE, Xfce）では、システムのキーボードショートカット設定で同様のコマンドを割り当ててください。

## 使用方法
- **ウェブページの保存**:
  - 対応ブラウザで閲覧中にホットキー（例：`Shift+Mod+p`）を押す。
  - `lopo-launcher.sh`がブラウザからURLを取得し、`lopo-add.py`を実行。
  - ページのタイトルと内容が`$LOPO_DIR/YYYY/MM/YYYY-MM-DD_HHMMSS_タイトル.md`に保存。
  - 成功またはエラーの通知が表示。

- **保存ファイルの検索**:
  ```bash
  ~/.local/bin/lopo-search.sh [検索語]
  ```
  - 検索語なしの場合、`$LOPO_DIR`内の全`.md`ファイルを`fzf`で一覧表示。
  - 検索語指定時は、該当するファイルのみを`fzf`で選択可能。
  - 選択したファイルのURLをデフォルトブラウザで開き、ブラウザウィンドウをアクティブ化（i3-wm最適化済みだが、他の環境でも動作）。

- **保存ファイルの削除**:
  ```bash
  ~/.local/bin/lopo-delete.sh
  ```
  - `$LOPO_DIR`内の`.md`ファイルを`fzf`で複数選択可能。
  - 選択したファイルを削除（確認プロンプトあり）。
  - 成功または失敗の通知を表示。

## 注意事項
- **カスタマイズ**:
  - このスクリプトはLinux環境（開発環境：i3-wm、仮想環境：`~/uv/lopo-env`, 保存先：`~/Documents/lopo`）向けに作られています。以下の環境変数でパスを上書き可能です：
    - `LOPO_DIR`: 保存ディレクトリ（デフォルト：`~/Documents/lopo`）
    - `LOPO_VENV`: 仮想環境ディレクトリ（デフォルト：`~/uv/lopo-env`）
    - `LOPO_LAUNCHER_LOG`: ランチャーログ（デフォルト：`~/.cache/lopo/lopo-launcher.log`）
    - `LOPO_DEBUG_LOG`: デバッグログ（デフォルト：`/tmp/lopo-debug.log`）
    - 例: `~/.bashrc`に以下を追加してカスタマイズ:
      ```bash
      export LOPO_DIR=~/mydocs/lopo
      export LOPO_VENV=~/myvenv/lopo-env
      export LOPO_LAUNCHER_LOG=~/logs/lopo-launcher.log
      export LOPO_DEBUG_LOG=~/logs/lopo-debug.log
      ```
  - 他のカスタマイズ：
    - ブラウザのクラス名（`lopo-launcher.sh`の`get_browser_url`関数）
    - ホットキー（ウィンドウマネージャやデスクトップ環境の設定）
- **文字エンコーディング**:
  - 日本語のウェブページ（例：Shift-JISやEUC-JPを使用するサイト）で保存に失敗する場合、`$LOPO_DEBUG_LOG`を確認してください。検出されたエンコーディングやエラー情報が記録されています。
  - 問題が続く場合、依存パッケージを最新バージョンに更新してください:
    ```bash
    source ~/uv/lopo-env/bin/activate
    pip install --upgrade requests beautifulsoup4 readability-lxml charset-normalizer
    deactivate
    ```
- **依存ツールの確認**: 必要なツール（`xclip`, `xdotool`, `wmctrl`, `fzf`, `libnotify`, `xdg-utils`）がインストールされていることを確認してください。
- **ログファイル**: `$LOPO_DEBUG_LOG`と`$LOPO_LAUNCHER_LOG`にログが記録されます。保存に失敗した場合は`$LOPO_DEBUG_LOG`を確認してください（例：`cat /tmp/lopo-debug.log`）。
- **ブラウザ互換性**: 一部のブラウザや環境ではURL取得が失敗する場合があります。その場合、クリップボードからURLを取得するフォールバックが動作します。
- **Windows環境**: 現在、Windowsでは`xclip`, `xdotool`, `wmctrl`などの依存関係により動作しません。Windows向けの代替実装（例：PowerShellやWSL2での対応）の貢献を歓迎します。
- **セキュリティ**: 保存されるウェブページの内容に機密情報が含まれないよう注意してください。公開リポジトリにアップロードする場合は、保存ディレクトリ（`$LOPO_DIR`）に個人情報が含まれていないことを確認してください。

## ライセンス
MITライセンス
