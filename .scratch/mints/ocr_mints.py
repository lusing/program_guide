import os, sys
import onnxruntime as ort
_orig = ort.InferenceSession
ort.InferenceSession = lambda *a, **k: _orig(*a, **{**k, 'providers': ['CPUExecutionProvider']})
import fitz
from rapidocr_onnxruntime import RapidOCR
ocr = RapidOCR()
doc = fitz.open(r'G:\book\计算机\A short introduction to intuitionistic logic.pdf')
outdir = r'G:\code\guide\.scratch\mints\ocr'
os.makedirs(outdir, exist_ok=True)
for i in range(len(doc)):
    n = i + 1
    dst = os.path.join(outdir, f'p{n:03d}.txt')
    if os.path.exists(dst) and os.path.getsize(dst) > 50:
        continue
    pix = doc[i].get_pixmap(dpi=200)
    res, _ = ocr(pix.tobytes('png'))
    lines = [r[1] for r in res] if res else []
    open(dst, 'w', encoding='utf-8').write('\n'.join(lines))
    if n % 10 == 0:
        print('page', n, 'done', flush=True)
print('ALL DONE')
