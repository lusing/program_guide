# 数学分析读本：七通道交互式教程

以 Raffi Grinberg《The Real Analysis Lifesaver》（《普林斯顿数学分析读本》）
为蓝本的数学分析教程。每一章一篇自包含的中文教程（`docs/`），
讲透原书核心内容；所有正文结论都在**七个独立工具链**里机器验证过。

## 结构

```
docs/           教程正文（00 导言 → 21 收官，共 22 章）
examples/
  lean/         Lean 4.35 + mathlib4 4.35.0（主证明通道）
  isabelle/     Isabelle2026 / HOL-Analysis（每章一个会话 RANN）
  coq/          Rocq 9.1 Stdlib
  agda/         Agda 2.8.0.2 + stdlib
  julia/        Julia 数值实验
  python/       Python 3.13（python -I）
  prolog/       SWI-Prolog 10
build.ps1       七通道一键验证
PLAN.md         章节目录与批次计划
```

## 验证

```powershell
pwsh -NoProfile -Command '& ./build.ps1 -All'        # 全量
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 02' # 单章
pwsh -NoProfile -Command '& ./build.ps1 -Lang lean'  # 单通道
pwsh -NoProfile -Command '& ./build.ps1 -List'       # 章×通道覆盖矩阵
```

输出为“章 × 通道”矩阵；全部 pass 才算该批次完成。

## 阅读顺序

按章号顺序阅读即可。每章教程自包含，不需要翻原书；
正文引用的每一段代码都注明了所在文件，并在正文中逐段讲解。

## 约定

- 数学公式用 `$...$` / `$$...$$`（Forgejo 渲染要求：闭 `$` 后必须跟
  空格或 ASCII 标点）。
- 章号与原书章节有偏移：本教程 00 是导言，01 起对应原书第 2 章
  （NN = 原书章号 − 1，直到 19；20、21 为综合与收官）。
