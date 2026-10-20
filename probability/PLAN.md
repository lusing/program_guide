# 概率论教程工作计划（The Probability Lifesaver 为纲）

Steven J. Miller, *The Probability Lifesaver*（Princeton UP 2017，
737 页，文字层 + 书签齐全——取材直接 `Read` PDF 页面，免 OCR）。

**教程定位**：本科入门向的概率论完全教程——从计数与公理到分布族、
极限定理、检验与最小二乘；与 `measuretheory/`（研究生向，测度论
语言）互补，全书无测度论前置，代码通道以"教学演示 + 精确小账"
为主。

**纪律**（同 measuretheory 惯例）：
1. docs ≥200 行、正文多于代码、所有代码在正文引用讲解、页脚
   登记文件清单 + Zig 式导航；
2. 五通道验证 `pwsh -NoProfile -Command '& ./build.ps1 -All'`，
   单元以 `==== NN` / `END ====` 头尾标记对账；Lean 通道对
   `warning:`/`error:` 零容忍；
3. 批次提交 `git add probability/`，尾注 Co-Authored-By；
4. 每批回填本章（✅）、批次行、坑账。

## 章表（28 章：00-27）

| 章 | slug | Miller 源（页） | L | I | J | Py | R | 批 | 状态 |
|---|---|---|---|---|---|---|---|---|---|
| 00 | intro | How to use (p16) | · | · | · | · | · | B1 | ✅ |
| 01 | signature-problems | ch1 生日/投篮/对冲 (p22) | ✓ | · | ✓ | ✓ | ✓ | B1 | ✅ |
| 02 | axioms | ch2 公理与定律 (p59) | ✓ | ✓ | ✓ | ✓ | ✓ | B1 | ✅ |
| 03 | counting | ch3.1 阶乘与二项系数 (p98) | ✓ | · | ✓ | ✓ | ✓ | B2 | ✅ |
| 04 | cards | ch3.2-3.4 扑克/接龙/桥牌 (p107) | · | · | ✓ | ✓ | ✓ | B2 | ✅ |
| 05 | conditional | ch4 条件概率与 Bayes (p147) | ✓ | ✓ | ✓ | ✓ | ✓ | B3 | ☐ |
| 06 | inclusion-exclusion | ch5 容斥 (p175) | ✓ | · | ✓ | ✓ | ✓ | B3 | ☐ |
| 07 | combinatorics | ch6 高级组合 (p205) | ✓ | · | ✓ | ✓ | · | B3 | ☐ |
| 08 | discrete-rv | ch7 离散随机变量 (p238) | ✓ | · | ✓ | ✓ | ✓ | B4 | ☐ |
| 09 | continuous-rv | ch8 连续随机变量 (p255) | ✓ | · | ✓ | ✓ | · | B4 | ☐ |
| 10 | expectation | ch9 期望工具 (p271) | ✓ | ✓ | ✓ | ✓ | · | B4 | ☐ |
| 11 | convolutions | ch10 卷积与换元 (p302) | · | · | ✓ | ✓ | · | B5 | ☐ |
| 12 | differentiating | ch11 微分恒等式 (p326) | ✓ | · | ✓ | ✓ | · | B5 | ☐ |
| 13 | discrete-dists | ch12 离散分布族 (p343) | ✓ | ✓ | ✓ | ✓ | ✓ | B6 | ☐ |
| 14 | uniform-exponential | ch13 均匀与指数 (p365) | ✓ | · | ✓ | ✓ | · | B6 | ☐ |
| 15 | normal | ch14 正态分布 (p387) | ✓ | · | ✓ | ✓ | · | B6 | ☐ |
| 16 | gamma | ch15 Γ 函数与分布 (p414) | ✓ | · | ✓ | ✓ | · | B6 | ☐ |
| 17 | chi-square | ch16 卡方 (p443) | ✓ | · | ✓ | ✓ | · | B6 | ☐ |
| 18 | inequalities-lln | ch17 不等式与 LLN (p463) | ✓ | · | ✓ | ✓ | · | B7 | ☐ |
| 19 | stirling | ch18 Stirling 公式 (p483) | · | · | ✓ | ✓ | · | B7 | ☐ |
| 20 | generating-functions | ch19 母函数 (p508) | · | · | ✓ | ✓ | ✓ | B7 | ☐ |
| 21 | clt | ch20 CLT 证明 (p541) | ✓ | ✓ | ✓ | ✓ | · | B7 | ☐ |
| 22 | fourier-clt | ch21 Fourier 与 CLT (p567) | · | · | ✓ | ✓ | · | B7 | ☐ |
| 23 | hypothesis-testing | ch22 假设检验 (p582) | · | · | ✓ | ✓ | ✓ | B8 | ☐ |
| 24 | markov-least-squares | ch23-24 差分方程/Markov/最小二乘 (p620) | · | · | ✓ | ✓ | · | B8 | ☐ |
| 25 | famous-problems | ch25 两著名问题与编码 (p649) | · | · | ✓ | ✓ | ✓ | B8 | ☐ |
| 26 | proof-techniques | 附录 A 证明十一式×概率实例 (p661) | ✓ | · | ✓ | ✓ | ✓ | B8 | ☐ |
| 27 | cheatsheet | 收官（附录 B-D 提炼并入） | · | · | · | · | · | B8 | ☐ |

通道列：L=Lean4+mathlib4、I=Isabelle2025-2、J=Julia、Py=Python、
R=Prolog（✓=主锚/·=该通道无单元——初判，批次侦察后可调）。

## 批次

- [x] B1 00-02 骨架与公理（**7/7 全绿**——docs 3 篇 108-160 行：导言（书的三特质/四部分地图/五通道/与 measuretheory 关系）、招牌问题三连（生日平方根律/投篮不动点与几何级数/对冲期望线性性）、公理章（三悖论/集合复习/Kolmogorov 三公理/免费午餐八条/σ-代数一瞥）；Lean 2 件：生日 22/23 的 decide 大数判决（22 不等号方向一度写反被 decide 当场抓获）、coin2 两点空间 + measure_mono/compl/union 实弹；Isabelle MT02（emeasure 四锚）；Julia 2/Python 2/Prolog 2：模拟贴理论 3σ 带、Fraction 精确分数（24995/3 对冲账）、3125 全穷举生日玩具、256 对容斥+De Morgan 穷举）
- [x] B2 03-04 计数（**9/9 全绿（本批），终态 -All 16/16**——docs 2 篇 148/157 行：计数基础（乘法/加法原理、排列 vs 组合的 k! 去重、Pascal 双推导（故事+代数）、二项定理、三陷阱、数量级感）；扑克实验室（九型牌型账本逐条结构化（(2,1,1,1) 划分模式→先点数后花色）、分母守恒、接龙 52! 让位模拟、桥牌 void/singleton 容斥伏笔、Yarborough 期望伏笔）；Lean 1 件：Nat.choose 锚（succ_succ 递推/sum_range_choose/eq_zero_of_lt）+ decide 判决 C(52,5)=2598960/C(23,2)=253/10·9·8=6·C(10,3)；Julia 2/Python 2/Prolog 2：Pascal 表逐格、二项定理两侧、九型精确账本+模拟 4σ 带、桥牌 4-4-3-2 谱（21.7% vs 21.6%）、迷你扑克 1140 全穷举（three=20/pair=480/flush=28/straight=180/sflush=12）、4!=24 与 C(4,2)=6 枚举）
- [ ] B3 05-07 条件与组合（Bayes/容斥/Catalan）
- [ ] B4 08-10 随机变量（离散/连续/期望工具）
- [ ] B5 11-12 变换工具（卷积换元/微分恒等式）
- [ ] B6 13-17 分布族（离散五族/均匀指数/正态/Γ/卡方）
- [ ] B7 18-22 极限定理（不等式 LLN/Stirling/母函数/CLT/Fourier）
- [ ] B8 23-27 统计与收官（检验/Markov/最小二乘/著名问题/
  证明十一式/CHEATSheet）

## 取材页码速查（PDF 书签页）

ch1 p22 · ch2 p59 · ch3 p97 · ch4 p147 · ch5 p175 · ch6 p205 ·
ch7 p238 · ch8 p255 · ch9 p271 · ch10 p302 · ch11 p326 · ch12 p343 ·
ch13 p365 · ch14 p387 · ch15 p414 · ch16 p443 · ch17 p463 ·
ch18 p483 · ch19 p508 · ch20 p541 · ch21 p567 · ch22 p582 ·
ch23 p620 · ch24 p638 · ch25 p649 · 附录 A p661 / B p687 / C p705。

## 坑账

（逐批追加；格式：编号. （批次）一句话 + 修法）

1. （B1）数学错误被机器连环抓出：投篮账 r = (1−p)(1−q) =
   (1/2)(3/5) = **3/10**（曾凭印象写成 9/25=(3/5)²，A 胜率应为
   5/7 非 25/32——Python/Lean/Prolog 三处同步错，Julia 模拟
   0.7143=5/7 与错误闭式 25/32=0.781 不符暴露）；对冲账 h =
   (V+stake)/6，净得 24995/3（曾手拍 8350）。**教训：闭式先过
   模拟再进精确通道**。
2. （B1）Prolog 两撞：`all_distinct/1` 不存在（sort/2 长度判重，
   且 sort 是谓词不能嵌参）；`PA == 5 rdiv 7` 的 `==` 是项同一性
   ——右侧裸 rdiv 项未求值必假，须 `=:=`（measuretheory 坑账
   同族，跨项目重蹈）。
3. （B1）Julia 几何级数断言的理论余项是 r^100/(1−r) 不是 r^90
   （r=0.9 时 2.65e-4 > 8.7e-5 假阴）；浮点对拍容差要加机器
   epsilon 底（+1e-12）。
4. （B1）Prolog 集合恒等式比较：union/subtract 结果的**元素序**
   不定，`==` 严格序比较假阴——msort 规范化后再比（same_set）。
5. （B1）lake 依赖的 git fetch 被网络中断留下半成品包（batteries
   悬空 HEAD、Cli 空壳）——manifest 与 HEAD 一致也无用，须删
   坏包从兄弟工程（measuretheory）拷完整版；lean 工程复制
   manifest 时 .lake/packages 不会随之复制。
6. （B1）mathlib 4.33 文件名陷阱：`Algebra.BigOperators.Basic`、
   `MeasureTheory.Measure.DiracMeasure`、
   `Analysis.SpecialFunctions.Geometric` 均不存在（重组后的
   真名：Group.Finset.Basic / Measure.Dirac / Field.GeomSum 的
   geom_sum_eq）——import 凭旧印象必炸，先 ls 源目录。
7. （B1）ℚ 上 `decide` 对 Finset.sum 不 reduce（Rat 的
   DecidableEq 卡在 sum 展开）——换 norm_num [Finset.
   sum_range_succ]；孤立 `/-- -/` doc comment 在文件尾非法
   （expected 'lemma'）——改普通注释。measure_union 4.33 只吃
   两个显式参数（h + MeasurableSet s₂）；MeasurableSet 目标
   不能 fun_prop（用 measurability tactic 或显式引理）。
8. （B2）**build.ps1 复制改造的目录名硬编码坑**：lean 发现
   目录写死 'Measuretheory'（源工程名）——新工程 Probability
   的 ChNN 文件全部静默不发现，报告 lean 列空但不报错。
   复制脚本模板时 grep 源工程名逐处替换。
9. （B2）低级算术错被抓：(2+3)^8 写成 8^8 断言（=5^8 才对）；
   迷你扑克公式手推 pair=480（5·C(4,2)·4·4，初写 240 漏了
   第三张花色 4）、flush=28（4·(C(5,3)−3)，初写 32 顺段算
   错）——**穷举（Prolog 1140 手）是公式手推的终审法庭**。
10. （B2）Julia 环境无 Combinatorics 包——组合枚举手写三重
   循环（i<j<k 保序即去重）；mathlib 二项系数求和真名
   Nat.sum_range_choose（非 choose_sum），在 Data.Nat.Choose.
   Sum——#check 失败先 ls Data/Nat/Choose/ 目录。Prolog
   classify 的连续性判定若放在子句体内错误位置会全部分类
   成 straight——多特征分类先算布尔再分派，cut 收尾。
