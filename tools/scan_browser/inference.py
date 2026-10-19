"""Local reference runner for the app's TFLite models; no synthetic detections."""
import io
import math
import threading
import time
from pathlib import Path

import numpy as np
from PIL import Image, ImageOps, UnidentifiedImageError

ROOT = Path(__file__).resolve().parents[2]
Image.MAX_IMAGE_PIXELS = 20_000_000


def suppress(boxes, iou=0.30, containment=0.70):
    kept = []
    for box in sorted(boxes, key=lambda b: b['confidence'], reverse=True):
        def overlaps(other):
            x = max(0, min(box['left'] + box['width'], other['left'] + other['width']) - max(box['left'], other['left']))
            y = max(0, min(box['top'] + box['height'], other['top'] + other['height']) - max(box['top'], other['top']))
            intersection = x * y
            a, b = box['width'] * box['height'], other['width'] * other['height']
            return intersection / (a + b - intersection) >= iou or intersection / min(a, b) >= containment
        if not any(overlaps(other) for other in kept):
            kept.append(box)
    return kept


def plausible(box, width, height):
    w, h = box['width'] / width, box['height'] / height
    x = (box['left'] + box['width'] / 2) / width
    y = (box['top'] + box['height'] / 2) / height
    return (0 < w <= .16 and 0 < h <= .16 and w * h <= .02
            and .40 <= box['width'] / box['height'] <= 2.50 and y >= .06
            and ((x - .5) / .44) ** 2 + ((y - .52) / .50) ** 2 <= 1)


def decode_image(data):
    try:
        with Image.open(io.BytesIO(data)) as source:
            if source.width * source.height > Image.MAX_IMAGE_PIXELS:
                raise ValueError('Ảnh quá lớn. Vui lòng chọn ảnh dưới 20 megapixel.')
            image = ImageOps.exif_transpose(source).convert('RGB')
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as error:
        raise ValueError('Không đọc được ảnh. Hãy chọn ảnh JPEG, PNG hoặc WebP hợp lệ.') from error
    if min(image.size) < 224:
        raise ValueError('Ảnh quá nhỏ. Cần tối thiểu 224 pixel mỗi chiều.')
    return image


class Pipeline:
    def __init__(self):
        import tensorflow as tf
        self.lock = threading.Lock()
        self.detector = tf.lite.Interpreter(model_path=str(ROOT / 'assets/models/acne_detector.tflite'), num_threads=4)
        self.classifier = tf.lite.Interpreter(model_path=str(ROOT / 'assets/models/model_phan_loai_mun.tflite'), num_threads=4)
        for interpreter in (self.detector, self.classifier):
            interpreter.allocate_tensors()
        self.di = self.detector.get_input_details()[0]
        self.do = self.detector.get_output_details()[0]
        self.ci = self.classifier.get_input_details()[0]
        self.co = self.classifier.get_output_details()[0]
        if list(self.ci['shape']) != [1, 3, 224, 224] or list(self.co['shape']) != [1, 2]:
            raise RuntimeError('Unexpected classifier shape')
        if self.di['dtype'] != np.float32 or self.ci['dtype'] != np.float32:
            raise RuntimeError('This runner expects float32 model inputs')
        if list(self.di['shape']) != [1, 3, 640, 640] or list(self.do['shape']) != [1, 5, 8400]:
            raise RuntimeError('Unexpected detector shape')

    def analyze(self, data):
        image = decode_image(data)
        with self.lock:
            return self._analyze(image)

    def _analyze(self, image):
        start = time.perf_counter()
        width, height = image.size
        _, _, ih, iw = self.di['shape']
        iw, ih = int(iw), int(ih)
        gain = min(iw / width, ih / height)
        nw, nh = int(width * gain + .5), int(height * gain + .5)
        px, py = int((iw - nw) / 2), int((ih - nh) / 2)
        resized = image.resize((nw, nh), Image.Resampling.BILINEAR)
        padded = Image.new('RGB', (iw, ih), (114, 114, 114))
        padded.paste(resized, (px, py))
        tensor = (np.asarray(padded, dtype=np.float32) / 255).transpose(2, 0, 1)[None]
        self.detector.set_tensor(self.di['index'], tensor)
        self.detector.invoke()
        output = self.detector.get_tensor(self.do['index'])[0]
        # This model exports [4 + class_count, anchors], normalized xywh.
        if output.ndim != 2:
            raise RuntimeError(f'Unexpected detector output {output.shape}')
        if output.shape[0] < output.shape[1]:
            output = output.T
        if output.shape[1] < 5:
            raise RuntimeError(f'Unexpected detector output {output.shape}')
        boxes = []
        for row in output:
            score = float(np.max(row[4:]))
            if not math.isfinite(score) or score < .08:
                continue
            cx, cy, bw, bh = map(float, row[:4])
            # TFLite export uses coordinates normalized to input dimensions.
            cx, bw, cy, bh = cx * iw, bw * iw, cy * ih, bh * ih
            x1, y1 = max(0., (cx - bw / 2 - px) / gain), max(0., (cy - bh / 2 - py) / gain)
            x2, y2 = min(float(width), (cx + bw / 2 - px) / gain), min(float(height), (cy + bh / 2 - py) / gain)
            box = dict(left=x1, top=y1, width=x2-x1, height=y2-y1, confidence=score)
            if all(math.isfinite(v) for v in box.values()) and box['width'] > 0 and box['height'] > 0:
                boxes.append(box)
        # Native plugin applies detector NMS before the app's classifier.
        candidates = [box for box in suppress(boxes, iou=.7, containment=1.01) if plausible(box, width, height)]
        kept, classified = [], 0
        for box in candidates:
            if box['confidence'] >= .15 and box['width'] / width <= .08 and box['height'] / height <= .08:
                kept.append(box)
                continue
            classified += 1
            cx, cy = box['left'] + box['width']/2, box['top'] + box['height']/2
            left, top = max(0, cx-box['width']), max(0, cy-box['height'])
            right, bottom = min(width, cx+box['width']), min(height, cy+box['height'])
            # Match Dart floor(origin), ceil(expanded size), nearest resize.
            x, y = math.floor(left), math.floor(top)
            crop = image.crop((x, y, x+min(math.ceil(right-left), width-x), y+min(math.ceil(bottom-top), height-y)))
            crop = crop.resize((224, 224), Image.Resampling.NEAREST)
            pixels = np.asarray(crop, dtype=np.float32)/255
            pixels = (pixels - np.array([.485,.456,.406], dtype=np.float32)) / np.array([.229,.224,.225], dtype=np.float32)
            self.classifier.set_tensor(self.ci['index'], pixels.transpose(2,0,1)[None])
            self.classifier.invoke()
            normal, acne = map(float, self.classifier.get_tensor(self.co['index'])[0])
            if not math.isfinite(normal) or not math.isfinite(acne):
                raise RuntimeError('Classifier returned invalid scores')
            total = normal + acne
            probability = acne / total if normal >= 0 and acne >= 0 and .98 <= total <= 1.02 else 1/(1+math.exp(max(-700, min(700, normal-acne))))
            if probability >= (.58 if box['confidence'] >= .15 else .68):
                kept.append(box)
        final = suppress(kept)
        return dict(boxes=final, acne_count=len(final), width=width, height=height,
                    candidates=len(candidates), classified=classified,
                    elapsed_ms=round((time.perf_counter()-start)*1000),
                    engine='YOLO11m + MobileNetV2 (TFLite, local CPU)',
                    note='Kết quả thử nghiệm, không phải chẩn đoán. Chưa kiểm tra ảnh có khuôn mặt hay ánh sáng đạt chuẩn.')
