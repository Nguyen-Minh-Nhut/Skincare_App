#!/bin/zsh
cd -- "${0:A:h}" || exit 1
if [[ ! -x .venv-ai/bin/python ]]; then
  echo 'Chưa có runtime AI. Xem tools/scan_browser/README.md để cài đặt.'
  read '?Nhấn Enter để đóng…'
  exit 1
fi
if .venv-ai/bin/python tools/scan_browser/start.py; then
  open 'http://127.0.0.1:8765'
else
  read '?Nhấn Enter để đóng…'
fi
