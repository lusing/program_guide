# 实施计划：Prawitz 卷专轮（第十三轮）

依赖 spec：docs/superpowers/specs/2026-10-10-mathlogic-prawitz-expansion-design.md

## 批次

1. **spec/plan 入库**（本批）。
2. **重排 114→123**：tools/renumber_p.py（MAP {34..114}+9、GAPS 34-42、
   ML/Ex 模式 \d{2,3}、NEW_TITLES 九章）→ dry-run → apply → 验证器 →
   全量 build 冒烟（重排后回归应仍 282 全绿）→ 提交。
3. **新 34 章 ge**（C/L）→ 提交。
4. **新 35 章 zucker**（C/L）→ 提交。
5. **新 36 章 lndequality**（C/L）→ 提交。
6. **新 37 章 generally**（C/L）→ 提交。
7. **新 38 章 lcube**（C/L）→ 提交。
8. **新 39 章 linear**（C/L）→ 提交。
9. **新 40 章 roughset**（C/L/P）→ 提交。
10. **新 41 章 ars**（C/L）→ 提交。
11. **新 42 章 ptval**（C/L）→ 提交。
12. **三深化**：27+Hertz 机器件（C/L）、02 注记、123 收官段 → 提交。
13. **收官四文件**：README（+9 行+十三轮叙事+301）、PLAN（书行+9 行）、
    CHEATSheet（Prawitz 节）、123-wrapup（对账表）→ 全量回归
    -All（301/301）→ 提交 → 记忆落盘。

## 每章工序模板（沿用十二轮协议）

- examples/NN_slug/exNN_slug.{v,lean}（40 加 .pl）：章自含、零公理
  或显式公理记账、vm_compute/native、注释讲清对应书页；
- docs/NN-slug.md：教程体（每段代码正文引用+前后文）、≥170 行、
  机器件表、坑位速记（本章实测）；
- 章级 build 验证（-Chapter NN）全绿再进下一章；
- 页脚导航由重排脚本/后续章自然衔接，最后一批统一校对。

## 验收

- 301/301 全绿、0 SKIP、exit 0；
- 九新章 docs 均教程体且代码全在正文引用；
- 十二篇对账矩阵全部有着落（9 新章+3 深化/注记）；
- 重排后无残留旧号（验证器+grep 抽查）。
