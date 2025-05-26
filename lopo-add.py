#!/usr/bin/env python3
# coding: utf-8

import sys
import os
import datetime
import subprocess
import requests
from bs4 import BeautifulSoup
from readability import Document
from charset_normalizer import detect

LOGFILE = os.getenv("LOPO_DEBUG_LOG", "/tmp/lopo-debug.log")
BASE_DIR = os.getenv("LOPO_DIR", os.path.expanduser("~/Documents/lopo"))

def log(msg):
    timestamp = datetime.datetime.now().isoformat()
    line = f"{timestamp} {msg}"
    try:
        with open(LOGFILE, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception as e:
        print(f"LOG WRITE ERROR: {e}", file=sys.stderr)
    print(line, file=sys.stderr)

def notify(summary, body):
    try:
        subprocess.run(["notify-send", summary, body], check=True)
    except Exception as e:
        log(f"Failed to send notification: {e}")

def get_url_from_clipboard():
    try:
        url = subprocess.check_output(["xclip", "-o"], text=True).strip()
        log(f"Clipboard content: {url}")
        return url
    except Exception as e:
        log(f"Error reading clipboard: {e}")
        return ""

def is_valid_url(url):
    return url.startswith("http://") or url.startswith("https://")

def fetch_page(url):
    log(f"Fetching URL: {url}")
    try:
        headers = {'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36'}
        r = requests.get(url, headers=headers, timeout=10)
        r.raise_for_status()
        # バイナリデータからエンコーディングを検出
        detected = detect(r.content)
        encoding = detected.get('encoding', 'utf-8') or 'utf-8'
        r.encoding = encoding
        log(f"Detected encoding: {encoding}")
        return r.text
    except requests.exceptions.RequestException as e:
        log(f"Error fetching page: {e}")
        notify("lopo", f"ページの取得に失敗しました:\n{e}")
        return None

def extract_content(html):
    try:
        doc = Document(html)
        title = doc.title().strip() or "Untitled"
        summary_html = doc.summary()
        # BeautifulSoupでエンコーディングを処理
        soup = BeautifulSoup(summary_html, "html.parser")
        text = soup.get_text(separator="\n").strip()
        if not text:
            raise ValueError("No content extracted")
        log(f"Extracted title: {title}")
        return title, text
    except Exception as e:
        log(f"Error extracting content: {e}")
        notify("lopo", f"コンテンツの抽出に失敗しました:\n{e}")
        return None, None

def save_text(title, text):
    now = datetime.datetime.now()
    dir_path = os.path.join(BASE_DIR, now.strftime("%Y"), now.strftime("%m"))
    try:
        os.makedirs(dir_path, exist_ok=True)
    except Exception as e:
        log(f"Error creating directory {dir_path}: {e}")
        notify("lopo", f"ディレクトリの作成に失敗しました:\n{e}")
        return False

    # ファイル名をさらにサニタイズ
    safe_title = "".join(c if c.isalnum() or c in " -_." else "_" for c in title).strip("_")[:50]
    if not safe_title:
        safe_title = "untitled"
    filename = now.strftime(f"%Y-%m-%d_%H%M%S_{safe_title}.md")
    filepath = os.path.join(dir_path, filename)
    try:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(f"# {title}\n\n")
            f.write(f"[リンク]({url})\n\n")  # URLをファイルに保存
            f.write(text)
        log(f"Saved file: {filepath}")
        notify("lopo", f"保存しました: {filepath}")
        return True
    except Exception as e:
        log(f"Error saving file: {e}")
        notify("lopo", f"ファイルの保存に失敗しました:\n{e}")
        return False

def main():
    global url  # URLをグローバル変数として保存
    if len(sys.argv) > 1:
        url = sys.argv[1]
        log(f"URL from argument: {url}")
    else:
        url = get_url_from_clipboard()
        log(f"URL from clipboard: {url}")

    if not url or not is_valid_url(url):
        log("No valid URL found.")
        notify("lopo", "引数またはクリップボードに有効なURLが見つかりませんでした。")
        sys.exit(1)

    html = fetch_page(url)
    if html is None:
        sys.exit(1)

    title, text = extract_content(html)
    if not title or not text:
        sys.exit(1)

    if not save_text(title, text):
        sys.exit(1)

if __name__ == "__main__":
    main()