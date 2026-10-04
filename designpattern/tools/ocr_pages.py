# 用法: python tools/ocr_pages.py <pdf路径> <起始页> <结束页> <输出名>
# 页号 1-based（与 PDF 书签一致），含两端；输出 materials/ocr/<名>.txt
import os
import sys
import pathlib
import fitz
from rapidocr_onnxruntime import RapidOCR

# onnxruntime 的 CUDA EP 依赖 cudnn。默认配置 use_cuda: true，缺 DLL 会直接
# 报 "Could not locate cudnn_graph64_9.dll" 并退出。自动把 G:\cudnn\9.24 下
# 的 DLL 目录加上（find 的版本子目录随 cudnn 发行版而定）。
_CUDNN_ROOT = pathlib.Path(r"G:\cudnn\9.24\bin")
if _CUDNN_ROOT.exists():
    for _dll_dir in _CUDNN_ROOT.glob("*/x64"):
        os.add_dll_directory(str(_dll_dir))
        os.environ["PATH"] = f"{_dll_dir}{os.pathsep}{os.environ.get('PATH', '')}"

pdf, start, end, name = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
out_dir = pathlib.Path(__file__).resolve().parents[1] / "materials" / "ocr"
out_dir.mkdir(parents=True, exist_ok=True)

# 默认会话即可完成本教程的 OCR 量；如需 CUDA/TensorRT 加速，
# 按 rapidocr_onnxruntime 文档给 RapidOCR 传 det/rec 的 EP 配置，
# 运行库在 G:\cudnn\9.24（加入 PATH）。OCR 文本只作素材，事实须与 Sahni 文本层核对。
engine = RapidOCR()
doc = fitz.open(pdf)
lines: list[str] = []
for pno in range(start, end + 1):
    pix = doc[pno - 1].get_pixmap(dpi=200)
    result, _ = engine(pix.tobytes("png"))
    lines.append(f"\n===== PDF page {pno} =====")
    if result:
        lines.extend(item[1] for item in result)
    print(f"page {pno}: {0 if result is None else len(result)} lines", flush=True)
(out_dir / f"{name}.txt").write_text("\n".join(lines), encoding="utf-8")
