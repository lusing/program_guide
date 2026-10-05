# materials — 取材说明

## 参考书

《Windows PowerShell 实战指南（第 3 版）》
原书：Don Jones、Jeff Hicks，《Learn Windows PowerShell in a Month of Lunches, Third Edition》（Manning）。
epub 原始文件位于本机 `G:\book\计算机\powershell\`，不入库。

## book/ 提取产物

- `ch01.txt` … `ch28.txt` 为原书 28 章正文纯文本，由 `../tools/extract-epub.ps1` 从 epub 提取（可复现：`pwsh -File tools/extract-epub.ps1`）。
- epub 内 **N.xhtml 对应第 N+1 章**（N 从 0 起），提取脚本已按此重命名为 `chNN.txt`。
- 该版本 epub 文本层完好、代码清单存活，无需 OCR。

## 用途与边界

本目录仅供写作时查证原书要点；教程正文（`../docs/`）自包含——所有概念、案例、清单在正文讲清，不要求也不建议读者翻原书。
