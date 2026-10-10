# 第十二轮执行计划：Mints 专轮（109→114）

前置：spec 见 specs/2026-10-10-mathlogic-mints-expansion-design.md。
OCR 底稿 `.scratch/mints/ocr/p001-130.txt`（不在库）。

## 批次

- [x] 批〇 侦察：PDF 身份/TOC/按页 OCR/既有覆盖矩阵/spec
- [ ] 批一 重排（第十次）：tools/renumber_l.py 改 MAP={18..25:+4, 26..108:+5},
      GAPS={18,19,20,21,30}, NEW_TITLES 五条；--apply；页脚 \d{2,3} 重生成；
      残留=0；109-wrapup→114-wrapup（标题「第 114 章」）；提交。
- [ ] 批二 新 18 ljpm（C/L）：饱和完备性旗舰；build 两通道绿；docs/18-ljpm.md。
- [ ] 批三 新 19 matrix（C/L）：有限矩阵+锥拓扑+[0,1] 级数；docs/19-matrix.md。
- [ ] 批四 新 20 search（C/L/P）：LJpm* 表列判定+反模型；docs/20-search.md。
- [ ] 批五 新 21 iinterp（C/L）：插值+Beth；docs/21-iinterp.md。
- [ ] 批六 新 30 ipred（C/L）：扩张域+CD+SOA+GG+传递；docs/30-ipred.md。
- [ ] 批七 六深化：04 ADC/替换、13 负翻译+逻辑计算、16 框架条件、
      67 否定式稳定+不可判定、75 直觉 Beth（prose）、15 极性注记（prose）。
- [ ] 批八 收官：README（+5 行+叙事+282）、PLAN（Mints 行+5 行+114 章表）、
      CHEATSheet（Mints 节）、114-wrapup（三点十五对账）、全量回归、记忆、提交。

## 每批 DoD

构建绿（`pwsh build.ps1` 或分通道）+ docs 自含成章 + 无调试残留（dbg/probe/aux）
+ git 提交（中文消息+Co-Authored-By）。
