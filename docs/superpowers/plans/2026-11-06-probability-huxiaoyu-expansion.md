# 概率论教程 胡晓予扩充轮（HU 轮）

日期：2026-11-06。目标：参考胡晓予《高等概率论》（科学出版社 2009）扩充
G:\code\guide\probability\（Miller+洪永淼双书 44 章，145/145 全绿）。
OCR 库复用 measuretheory/build/ocr/huxiaoyu/（p007-p178，书页=PDF−6，
tools 已有 ocr_huxiaoyu.py）。

## 缺口分析（grep 全 docs + 章节对照）

胡书 8 章中：
- ch1-4（测度/分解/乘积/概率基础）：本教程 01-11/20 已按 Miller 纲自包含；
  测度侧深水区由姊妹篇 measuretheory（严+袁+胡三书全谱）覆盖，不重复。
- ch5 CLT：5.1 portmanteau/UI → 25 章已覆盖（25.12/25.14）；5.2-5.3 经典
  CLT/特征函数 → 27/28 已覆盖；**缺 Lindeberg–Feller 充要条件（5.3.1-5.3.2）**；
  **缺 5.4 无穷可分分布族（式 5.4.7 Lévy–Khinchin、Cramér 定理）**；
  **缺 5.5 u.a.n. 三角阵列极限定理（5.5.2）与小数律（5.5.5）**。
- ch6 大数定律：6.2 强弱律 → 26 已覆盖（Khinchin/Kolmogorov SLLN/截断）；
  **缺 6.1 级数收敛定理（Kolmogorov 不等式 6.1.1、Σvar 定理 6.1.2、
  三级数定理 6.1.4）**；**缺 6.2.2 Lévy 不等式、6.2.3 Feller 弱律（无一阶矩）**；
  **缺 6.3 Kolmogorov 重对数律（指数界 6.3.1、Hartman–Wintner 6.3.3）**。
- ch7 离散鞅（§7.1-7.4 + 习题）：**全缺**（grep 鞅/停时/上穿 全零）——
  7.1 定义与例、7.2 鞅变换/上穿不等式/Doob 族不等式/收敛定理、
  7.3 一致可积与 Lᵖ 收敛、7.4 停时与选样定理。
- ch8 随机过程选讲：随机游动/布朗运动/GFF 已在姊妹篇 measuretheory 59-61
  展开三章；本教程 24 已有有限马氏链。不重复（引用处自包含陈述结论）。

## 新章计划（6 章，附于 42 综合案例之后；速查表 43→49）

| 章 | slug | 胡书出处 | Lean 主件 |
|---|---|---|---|
| 43 | lindeberg | §5.3 定理 5.3.1-5.3.2 | ProbabilityTheory.tendstoInDistribution_inv_sqrt_mul_sum 锚 + Feller 条件两行精确判 |
| 44 | infinitely-divisible | §5.4-5.5 | 特征函数 n 次根封闭性三例（Poisson/Normal/Cauchy 纯 exp 代数全证） |
| 45 | three-series | §6.1-6.2 | 有限数组截断和精确分数账（Fraction/native_decide） |
| 46 | law-iterated-logarithm | §6.3 | 几何分级 2ⁿ 子列精确二项尾账 + 尾 0-1 律锚（ProbabilityTheory.measure_zero_or_one_of_measurableSet_limsup_atTop） |
| 47 | martingales | §7.1-7.2 | MeasureTheory.Martingale/submartingale 全 API + Centering.Doob 分解锚 |
| 48 | martingale-convergence | §7.3-7.4 | Submartingale.exists_ae_tendsto_of_bdd + Integrable.tendsto_ae_condExp + 选样 stoppedValue_ae_eq_condExp_of_le + 上穿不等式 mul_integral_upcrossingsBefore_le_integral_pos_part |

mathlib 4.33.1 锚点（已 grep 实锤）：
- Mathlib.Probability.CentralLimitTheorem: tendstoInDistribution_inv_sqrt_mul_sum(_sub)
- Mathlib.Probability.Independence.ZeroOne (namespace ProbabilityTheory):
  measure_zero_or_one_of_measurableSet_limsup_atTop 族
- Mathlib.Probability.Martingale.{Basic,Convergence,Upcrossing,OptionalSampling,
  OptionalStopping,Centering,BorelCantelli}（namespace MeasureTheory）：
  Martingale.martingale_condExp（Doob 鞅）、Submartingale.exists_ae_tendsto_of_bdd
  （Doob 收敛定理）、Submartingale.mul_integral_upcrossingsBefore_le_integral_pos_part
  （上穿不等式）、predictablePart/martingalePart（Doob 分解=习题 7.3）、
  IsStoppingTime/stoppedProcess/stoppedValue、
  stoppedValue_ae_eq_condExp_of_le（选样定理）、maximal_ineq、
  Integrable.tendsto_ae_condExp（Lévy 鞅上升=定理 7.3.3）、
  UniformIntegrable、cauchy_add（Cauchy 稳定性）
- 无 Lindeberg/无穷可分/三级数/LIL 定理——自建精确小例。

## 批次

- HU0 清理与结构：删 5 个孤儿 docs（17-chi-square/18-inequalities-lln/
  19-stirling/21-clt/22-fourier-clt——上次重排残留，无外部引用）；
  速查表 43→49 重命名（节号 43.x→49.x、导航、chapters.json、README、
  00-intro 溯源、PLAN 开 HU 轮账）；-Docs --final + -All 回归。
- HU1 43-lindeberg；HU2 44-infinitely-divisible；HU3 45-three-series；
  HU4 46-law-iterated-logarithm；HU5 47-martingales；HU6 48-martingale-convergence。
  每批：docs ≥200 行（讲解为主、代码全引用）+ Lean/Julia/Python/Prolog 四通道
  + chapters.json + 根 import + build.ps1 -Chapter NN + -Docs 全绿 + 提交。
- HU7 收官：README 三书底本/篇目全表、PLAN 坑账回填、memory 更新、-All 终态。

## 取材页码表（PDF = 书+6）

- §5.3: p084-091；§5.4: p092-106；§5.5: p107-118（p103 5.4 起、p107 5.5 起）
- §6.1: p119-123；§6.2: p124-128；§6.3: p129-146
- §7.1-7.4+习题: p147-165（已全读）

## 纪律（沿 PLAN 既有 + H 轮新增）

- Python GBK print 禁 ⟹ − ₁ 等；Julia 有理比较用 //；Prolog rdiv 精确判决；
  Lean warning=失败；mathlib 根/前缀命名空间 #check 实锤再写。
- docs 校验：单行 $$、$ 邻接 Forgejo 规则、示例文件名=NN_slug 下划线形、
  正文必须引用示例相对路径 + ```{lang} 围栏、≥200 行、上一章/下一章导航。
- 每批一提交（尾注 Co-Authored-By: Claude Code）。
