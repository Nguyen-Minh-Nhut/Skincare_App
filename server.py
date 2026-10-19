"""Local AI browser tester. Run: .venv-ai/bin/python server.py"""
import argparse
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

from tools.scan_browser.inference import Pipeline, ROOT

MAX_BYTES = 12 * 1024 * 1024


def handler(pipeline, port):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_args):
            pass  # Do not log photos, request bodies or identifiers.

        def allowed(self):
            hosts = {f'127.0.0.1:{port}', f'localhost:{port}'}
            if self.headers.get('Host') not in hosts:
                self.send_error(403)
                return False
            origin = self.headers.get('Origin')
            if origin and origin not in {f'http://{host}' for host in hosts}:
                self.send_error(403)
                return False
            return True

        def respond(self, status, data, content_type='application/json; charset=utf-8'):
            body = json.dumps(data, ensure_ascii=False).encode() if not isinstance(data, bytes) else data
            self.send_response(status)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(body)))
            self.send_header('Cache-Control', 'no-store')
            self.send_header('X-Content-Type-Options', 'nosniff')
            self.end_headers()
            self.wfile.write(body)

        def do_GET(self):
            if not self.allowed():
                return
            path = urlsplit(self.path).path
            if path == '/':
                self.respond(200, (ROOT/'tools/scan_browser/index.html').read_bytes(), 'text/html; charset=utf-8')
            elif path == '/health':
                self.respond(200, {'ready': True, 'engine': 'YOLO11m + MobileNetV2'})
            elif path in ['/sample/acne', '/sample/control']:
                name = 'anh_da_mun.jpg' if path.endswith('acne') else 'anh_2.jpg'
                self.respond(200, (ROOT/'assets/image'/name).read_bytes(), 'image/jpeg')
            else:
                self.respond(404, {'message': 'Not found'})

        def do_POST(self):
            if not self.allowed():
                return
            if self.path != '/analyze_skin':
                self.respond(404, {'message': 'Not found'})
                return
            try:
                size = int(self.headers.get('Content-Length', '0'))
            except ValueError:
                size = 0
            if not 0 < size <= MAX_BYTES:
                self.respond(413, {'message': 'Ảnh phải có dung lượng từ 1 byte đến 12 MB.'})
                return
            self.connection.settimeout(30)
            try:
                data = self.rfile.read(size)
                if len(data) != size:
                    raise ValueError('Ảnh tải lên chưa đầy đủ.')
                self.respond(200, pipeline.analyze(data))
            except ValueError as error:
                self.respond(400, {'message': str(error)})
            except Exception:
                self.respond(500, {'message': 'Model không phân tích được ảnh. Hãy thử lại hoặc chọn ảnh khác.'})
    return Handler


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--port', type=int, default=8765)
    args = parser.parse_args()
    print('Loading real TFLite models...', flush=True)
    pipeline = Pipeline()
    with ThreadingHTTPServer(('127.0.0.1', args.port), handler(pipeline, args.port)) as server:
        print(f'Ready: http://127.0.0.1:{args.port}', flush=True)
        server.serve_forever()
