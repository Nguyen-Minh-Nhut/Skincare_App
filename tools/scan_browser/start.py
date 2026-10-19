"""Start the local AI server independently of a temporary command session."""
import json
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
URL = 'http://127.0.0.1:8765'
RUNTIME = ROOT / '.scan-browser'


def ready():
    try:
        with urllib.request.urlopen(URL + '/health', timeout=2) as response:
            data = json.load(response)
            return data.get('ready') is True and data.get('engine') == 'YOLO11m + MobileNetV2'
    except (OSError, ValueError, urllib.error.URLError):
        return False


def main():
    if ready():
        print(f'AI đã sẵn sàng: {URL}', flush=True)
        return 0
    RUNTIME.mkdir(exist_ok=True)
    with (RUNTIME / 'server.log').open('ab') as log:
        process = subprocess.Popen(
            [sys.executable, '-u', str(ROOT / 'server.py')], cwd=ROOT,
            stdin=subprocess.DEVNULL, stdout=log, stderr=log,
            start_new_session=True,
        )
    (RUNTIME / 'server.pid').write_text(str(process.pid))
    print('Đang khởi động hai model AI…', flush=True)
    for _ in range(55):
        if ready():
            print(f'AI đã sẵn sàng: {URL}', flush=True)
            print('Server chạy độc lập; đóng cửa sổ này không dừng AI.', flush=True)
            return 0
        if process.poll() is not None:
            print(f'Không khởi động được. Xem log: {RUNTIME / "server.log"}', file=sys.stderr)
            return 1
        time.sleep(1)
    print(f'Chưa sẵn sàng. Xem log: {RUNTIME / "server.log"}', file=sys.stderr)
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
