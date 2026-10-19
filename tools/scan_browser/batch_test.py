"""Run unchanged local inference on each image and write an offline report."""
import argparse
import csv
import hashlib
import html
import json
import re
from datetime import datetime, timezone, timedelta
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps
from tools.scan_browser.inference import Pipeline, ROOT, decode_image


def natural(path):
    return [int(v) if v.isdigit() else v.casefold() for v in re.split(r'(\d+)', path.name)]


def checksum(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    source, output = args.source.resolve(), args.output.resolve()
    files = sorted([p for p in source.iterdir() if p.is_file() and p.suffix.lower() in {'.jpg','.jpeg','.png','.webp','.bmp','.tif','.tiff'}], key=natural)
    if not files:
        raise SystemExit('No images found')
    output.mkdir(parents=True, exist_ok=False)
    (output/'images').mkdir()
    pipeline = Pipeline()
    results = []
    for index, path in enumerate(files, 1):
        row = dict(index=index, file=path.name, sha256=checksum(path))
        try:
            data = path.read_bytes()
            if len(data) > 12*1024*1024:
                raise ValueError('Ảnh trên 12 MB, vượt giới hạn của trang thử.')
            result = pipeline.analyze(data)
            original = decode_image(data)
            original.save(output/f'images/{index:02d}-original.jpg', quality=95)
            marked = original.copy()
            draw = ImageDraw.Draw(marked)
            for number, box in enumerate(result['boxes'],1):
                x,y,w,h = [box[k] for k in ('left','top','width','height')]
                draw.rectangle((x,y,x+w,y+h), outline='#ff1744', width=2)
                draw.text((x,max(0,y-12)),str(number),fill='#b00020',stroke_width=1,stroke_fill='white')
            marked.save(output/f'images/{index:02d}-annotated.jpg', quality=95)
            row.update(result, status='ok', original=f'images/{index:02d}-original.jpg', annotated=f'images/{index:02d}-annotated.jpg')
        except Exception as error:
            row.update(status='error', error=str(error))
        results.append(row)
        print(f"{index:02d} {path.name}: {row.get('acne_count','ERROR')} spots; {row.get('elapsed_ms','-')} ms",flush=True)
    metadata = dict(
        created_at=datetime.now(timezone(timedelta(hours=7))).isoformat(),
        source=str(source), images=len(files),
        input='Original file bytes; EXIF orientation applied. No extra resize/re-encode before pipeline; browser JPEG re-encoding can change results slightly.',
        thresholds=dict(detector=.08,trusted=.15,detector_nms=.7,final_nms=.3,containment=.7),
        models={name:checksum(ROOT/'assets/models'/name) for name in ['acne_detector.tflite','model_phan_loai_mun.tflite']},
        limitations='No ground-truth labels: precision/recall/accuracy not measured. One inference per image on local CPU, not mobile benchmark.',
        results=results,
    )
    (output/'results.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2)+'\n')
    with (output/'results.csv').open('w',encoding='utf-8-sig',newline='') as file:
        fields=['index','file','status','width','height','acne_count','candidates','classified','elapsed_ms','error']
        writer=csv.DictWriter(file,fieldnames=fields,extrasaction='ignore');writer.writeheader();writer.writerows(results)
    successful=[r for r in results if r['status']=='ok']
    total=sum(r['acne_count'] for r in successful)
    cards=[]
    for row in results:
        name=html.escape(row['file'])
        if row['status']=='error':
            cards.append(f'<section><h2>{row["index"]:02d}. {name}</h2><p>Lỗi: {html.escape(row["error"])}</p></section>');continue
        cards.append(f'''<section id="image-{row['index']}"><h2>{row['index']:02d}. {name}</h2>
<p><strong>{row['acne_count']} vùng nghi ngờ</strong> · {row['width']} × {row['height']} px · {row['elapsed_ms']} ms</p>
<p>{row['candidates']} ứng viên sau lọc hình học · {row['classified']} vùng qua CNN · giữ cuối {row['acne_count']} vùng. Một số vùng mạnh được giữ trực tiếp.</p>
<div class="pair"><figure><a href="{row['original']}"><img src="{row['original']}" alt="Ảnh gốc {name}"></a><figcaption>Ảnh gốc</figcaption></figure><figure><a href="{row['annotated']}"><img src="{row['annotated']}" alt="Khung dự đoán {name}"></a><figcaption>Khung cuối, đánh số theo confidence giảm dần</figcaption></figure></div></section>''')
    rows=''.join(f'<tr><td><a href="#image-{r["index"]}">{r["index"]:02d}</a></td><td>{html.escape(r["file"])}</td><td>{r.get("acne_count","Lỗi")}</td><td>{r.get("candidates","—")}</td><td>{r.get("classified","—")}</td><td>{r.get("elapsed_ms","—")}</td></tr>' for r in results)
    document=f'''<!doctype html><html lang="vi"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>MeowSkin — Kiểm thử {len(files)} ảnh</title><style>
body{{font:16px/1.6 system-ui;background:#f4f5fc;color:#242338;margin:0}}main{{max-width:1100px;margin:30px auto;padding:20px}}section{{background:white;border:1px solid #dddfea;border-radius:18px;padding:22px;margin:20px 0}}h1{{font-size:30px}}h2{{font-size:20px}}.pair{{display:grid;grid-template-columns:1fr 1fr;gap:18px}}figure{{margin:0}}img{{width:100%;height:auto;border-radius:10px}}figcaption{{color:#666}}table{{border-collapse:collapse;width:100%;background:white}}td,th{{padding:10px;border-bottom:1px solid #ddd;text-align:left}}a{{color:#5253b6}}@media(max-width:600px){{.pair{{grid-template-columns:1fr}}table{{font-size:12px}}td,th{{padding:5px}}}}
</style><main><h1>Kiểm thử {len(files)} ảnh — MeowSkin</h1><p>Ngày 19/10/2026 · YOLO11m + MobileNetV2 · TFLite trên CPU Mac</p><section><strong>{len(successful)}/{len(files)} ảnh phân tích thành công · {total} vùng nghi ngờ được giữ.</strong><p>Đây là đầu ra model, không phải số tổn thương thực tế hoặc chẩn đoán. Chưa có nhãn đối chiếu nên chưa tính precision/recall/accuracy. Không thay ngưỡng và không huấn luyện lại trên tập ảnh này.</p><p>Chạy ảnh gốc với EXIF được chuẩn hóa; trang thử web còn mã hóa lại JPEG nên có thể cho kết quả hơi khác. Mỗi ảnh chạy một lượt, thời gian chỉ tham khảo CPU, không tính tải model.</p><a href="results.csv">Bảng CSV</a> · <a href="results.json">JSON chi tiết, tọa độ và SHA-256 model/ảnh</a></section><table><thead><tr><th>#</th><th>Ảnh</th><th>Giữ lại</th><th>Ứng viên</th><th>Qua CNN</th><th>ms</th></tr></thead><tbody>{rows}</tbody></table>{''.join(cards)}</main></html>'''
    (output/'report.html').write_text(document)
    for offset in range(0,len(results),9):
        page=results[offset:offset+9]
        sheet=Image.new('RGB',(1320,3*390),'#f4f5fc');draw=ImageDraw.Draw(sheet)
        for cell,row in enumerate(page):
            x=(cell%3)*440;y=(cell//3)*390
            if row['status']=='ok':
                with Image.open(output/row['annotated']) as im:
                    tile=ImageOps.contain(im,(416,330));sheet.paste(tile,(x+12+(416-tile.width)//2,y+40+(330-tile.height)//2))
            label=f"{row['index']:02d}  {row['file']}  |  {row.get('acne_count','ERROR')} spots"
            draw.text((x+12,y+10),label,fill='#252338')
        sheet.save(output/f'contact-{offset//9+1}.jpg',quality=95)
    print(f'Report: {output / "report.html"}',flush=True)


if __name__=='__main__':
    main()
