# 集合论（郝兆宽·杨跃）教程 · 总体规划（PLAN）

以郝兆宽、杨跃《集合论：对无穷概念的探索》（复旦大学出版社 2014，
"逻辑与形而上学教科书系列"第一本，241 页 9 章）为唯一底本的中文
自包含教程，结合机器证明（Lean 4 + mathlib4 主证、Isabelle/ZF
object-logic 第二证明通道——ZF 公理系统在那里是一等公民、Coq 浅嵌入
第三证明通道）与计算/离散实验（Julia、Python/scipy、Prolog）。
全书 9 章全覆盖（含全部习题精选），力迫章（第九章）正文完整讲解，
机器边界如实标注（布尔值路线的完整机器化在 settheory 教程的
Viale 篇 46-55 章，本教程交叉引用不重做）。

**底本定位**：
- `G:\book\计算机\集合论 对无穷概念的探索 (郝兆宽 杨跃) (z-library.sk, 1lib.sk, z-lib.sk).pdf`
  261 页纯扫描零文字层，rapidocr 全书取材于 `build/ocr/hy_000-260.txt`
  （管线 `tools/ocr_haoyang.py`，cudnn 需 `G:\cudnn\9.24\bin\12.9\x64` 前置 PATH）。
- **PDF 页 = 书页 + 14**（书页 1 = PDF 页 15；目录 PDF 12-14；弁言 4-5；
  康托乐园引言 = 书页 i-vi = PDF 6-11）。
- OCR 质量注记：中文正文可靠；数学符号系统性损坏——悖论被识别为
  悸论/撑论/论、∈ 常丢、公式乱码。**公式一律按领域知识重建**，
  只有定理编号与中文叙述可信赖。

**与姊妹教程的关系**：G:\code\guide\settheory（Jech+Viale+Makinson，
69 章研究生向）是高路；本教程是郝/杨跃本科入门向，独立可读，
两教程互不依赖、按需交叉引用。

## 硬性写作纪律

1. **教程而非代码罗列**：所有要讲解的代码必须在 docs 正文中引用并逐段讲解，
   只读 docs 不看 examples 也能学会；每段代码前后必有文字。
2. **自包含提炼原书**：定理给完整证明或完整讲解，不指路"见原书某章"。
   原书编号（如 "1.3.11 定理"）仅作溯源注记，不构成阅读依赖。
3. 每章 ≥200 行、文字多于代码。
4. 章末导航采用 Zig 式（与 mathlogic/probability/settheory 一致）。
5. 机器不可达的元理论（力迫定理全貌、独立性证明的内部细节）正文完整
   讲解，并在文中明说"为什么机器还证不了"（沿 funanalysis 协议）。

## 章表（25 章：00-24）

| 章 | 主题 | 底本 | L | I | Coq | J | Py | R | 批 |
|---|---|---|---|---|---|---|---|---|---|
| 00 | 导引：欢迎来到康托乐园 | 弁言+引言 | · | · | · | ✓ | ✓ | · | B1 |
| 01 | 罗素悖论与一点数理逻辑 | 1.1+1.2 | · | · | ✓ | · | ✓ | ✓ | B1 |
| 02 | ZFC 公理（公理 0-9） | 1.3+1.4 | ✓ | ✓ | · | · | ✓ | · | B1 |
| 03 | 关系与函数 | 2.1+2.2+2.5 | ✓ | · | · | ✓ | ✓ | ✓ | B2 |
| 04 | 等价、划分与序 | 2.3+2.4 | · | · | ✓ | · | ✓ | ✓ | B2 |
| 05 | 自然数与递归定理 | 3.1+3.2 | ✓ | ✓ | · | ✓ | ✓ | · | B3 |
| 06 | 等势与可数 | 3.3 | ✓ | · | · | ✓ | ✓ | ✓ | B3 |
| 07 | 整数、有理数、实数 | 3.4+3.5 | ✓ | · | · | ✓ | ✓ | · | B4 |
| 08 | 不可数集合 | 3.6 | · | · | · | ✓ | ✓ | ✓ | B4 |
| 09 | 良序集 | 4.1 | ✓ | ✓ | · | · | ✓ | ✓ | B5 |
| 10 | 序数与超穷归纳 | 4.2+4.3 | ✓ | ✓ | · | ✓ | ✓ | · | B5 |
| 11 | 超穷递归与序数算术 | 4.3+4.4 | ✓ | · | ✓ | ✓ | ✓ | · | B5 |
| 12 | 古德斯坦定理 | 4.5 | · | · | · | ✓ | ✓ | · | B6 |
| 13 | 选择公理 | 4.6 | ✓ | ✓ | ✓ | · | ✓ | ✓ | B6 |
| 14 | 基数 | 5.1 | ✓ | ✓ | · | · | ✓ | · | B7 |
| 15 | 基数算术 | 5.2 | ✓ | · | · | ✓ | ✓ | · | B7 |
| 16 | 共尾与无穷和积 | 5.3+5.4 | ✓ | · | · | ✓ | ✓ | · | B8 |
| 17 | 基数幂与连续统 | 5.5 | ✓ | · | · | · | ✓ | ✓ | B8 |
| 18 | 滤、理想与无界闭集 | 6.1+6.2 | ✓ | · | · | ✓ | ✓ | ✓ | B8 |
| 19 | 层垒谱系与绝对性 | 7.1-7.4 | ✓ | · | ✓ | ✓ | ✓ | · | B9 |
| 20 | 基础公理与良基归纳 | 7.5-7.7 | ✓ | ✓ | · | · | ✓ | · | B9 |
| 21 | 不可达基数与反映定理 | 7.8+7.9 | · | · | · | ✓ | ✓ | · | B10 |
| 22 | 可构成集 L | 第八章 | · | ✓ | ✓ | · | ✓ | · | B10 |
| 23 | 力迫与 CH 独立性 | 第九章 | · | · | · | ✓ | ✓ | ✓ | B11 |
| 24 | 收官速查表 | 全书 | · | · | · | · | · | · | B11 |

L=Lean I=Isabelle/ZF Coq J=Julia Py=Python R=SWI-Prolog（约 66 单元；按批次微调）

## 批次

- [x] **B0** 骨架 + build.ps1 + Lean 工程空构建 + Isabelle ZF 通道冒烟（2026-10-21）
- [x] **B1**：00-02 导引/悖论语逻/公理——8 单元批内全绿（终态 -All 9/9：
      lean 1 + isa 1 + coq 1 + jl 1 + py 3 + pl 1），docs 239/276/419 行
- [x] **B2**：03-04 关系函数/等价划分序——7 单元批内全绿（终态 -All 16/16：
      lean 1 + jl 1 + py 2 + pl 2 + coq 1），docs 273/261 行
- [x] **B3**：05-06 自然数递归/等势——8 单元批内全绿（终态 -All 24/24：
      lean 2 + isa 1 + jl 2 + py 2 + pl 1），docs 242/204 行
- [x] **B4**：07-08 实数构造/不可数——6 单元批内全绿（终态 -All 30/30：
      lean 1 + jl 2 + py 2 + pl 1），docs 253/202 行
- [x] **B5**：09-11 良序/序数/递归与算术——12 单元批内全绿（终态 -All 42/42：
      lean 3 + isa 2 + coq 1 + jl 2 + py 3 + pl 1），docs 204/200/203 行
- [x] **B6**：12-13 古德斯坦/选择公理——7 单元批内全绿（终态 -All 49/49：
      lean 1 + isa 1 + coq 1 + jl 2 + py 2 + pl 1），docs 204/205 行
- [x] **B7**：14-15 基数/基数算术——6 单元批内全绿（终态 -All 55/55：
      lean 2 + isa 1 + jl 1 + py 2），docs 183/161 行
- [x] **B8**：16-18 共尾/幂/滤与 club——10 单元批内全绿（终态 -All 65/65：
      lean 3 + jl 2 + py 3 + pl 2）
- [x] **B9**：19-20 谱系绝对性/基础良基——7 单元批内全绿（终态 -All 72/72：
      lean 2 + isa 1 + coq 1 + jl 1 + py 2）
- [ ] B10：21-22 不可达反映/L（5 单元）
- [ ] B11：23-24 力迫/速查收官（4 单元）

## 通道分工与判定

| 通道 | 工具 | 角色 | 判定 |
|---|---|---|---|
| lean | Lean 4.33.1 + mathlib4 钉版 `H:/Lang/lean4/mathlib4-4.33.1` | 主证明（mathlib 的 Set/Ordinal/Cardinal/ZFC 均为一等公民） | `lake build` 退出码 0、无 error/warning |
| isabelle | Isabelle2025-2 的 **ZF object-logic**（ZF/ZF-Constructible 堆已在位） | 二证明（公理名、nat、Ordinal、Cardinal、AC、Constructible 独家锚点） | 每章一会话 `isabelle build`，退出码 0、无 Failed |
| coq | Coq 8.20.1（scoop） | 三证明（浅嵌入：谓词宇宙罗素、公理记账） | `coqc` 退出码 0、无错误 |
| julia | Julia 1.13 | 计算通道一 | 退出码 0、`==== NN` 与 `END ====` 标记 |
| python | Python 3.13 + scipy（G:\scoop\apps\python313） | 计算通道二 | `python -I` 退出码 0、标记齐全 |
| prolog | SWI-Prolog | 有限模型与穷举终审 | 退出码 0、`END ====` 标记 |

机器化边界（正文如实标注）：
- 第 22 章 L 的相对一致性：讲解全文；Isabelle ZF-Constructible 提供锚点件。
- 第 23 章力迫：思想与定理完整讲解；机器只做有限偏序/脱殊滤子玩具
  （布尔值全路线在 settheory 教程 Viale 篇已机器化，交叉引用）。
- 第 12 章古德斯坦：序列计算全机器化；"PA 不可证"如实标注为元定理叙述。

## 坑账（随批次追加）

1. **B0·rapidocr cudnn 路径**：cudnn DLL 在 `G:\cudnn\9.24\bin\12.9\x64`
   （bin 下还有一层 12.9/x64），PATH 须指到最里层否则 `cudnn_graph64_9.dll
   找不到`。
2. **B0·lake 空工程网络拉包**：新工程无 `.lake/packages` 时 lake 试图
   从 GitHub 拉 batteries 等（网络被重置失败）——**直接拷贝 settheory 的
   `.lake/packages`（383M，8 个包）**，manifest 逐字节相同即不再触网。
3. **B0·lake glob 空目录**：`globs := #[.submodules `Sethao]` 在 `Sethao/`
   目录不存在时报 `no such file or directory`——常驻 `Sethao/Prelude.lean`
   占位。
4. **B1·Lean doc 注释 + #check**：`/-- … -/` 后跟 `#check` 报
   "unexpected token '#check'; expected 'lemma'"（doc 注释只能挂声明）——
   #check/#print 前一律用普通块注释 `/- … -/`。probability B2 轮同坑复现。
5. **B1·python -I 忽略 PYTHONIOENCODING**：隔离模式连环境变量一起忽略，
   stdout 走 GBK——print 字符串必须 GBK 安全（`↦`² 不行，`->`^2 行）。
   代码注释不受影响（文件本身 UTF-8）。
6. **B1·zigzag 起点**：有理数对角线枚举须从 d=1 起步（0/1 在第一条
   对角线 p+q=1 上）；从 d=2 起会漏掉 0，断言 [0,1,1/2,2] 才暴露。
7. **B1·两层哥德尔编码爆炸**：真实公式码 ~10^87 做第二层指数超任何
   bigint——第二层演示用玩具码（2^8·3^32），正文注明。
8. **B1·Prolog findall 命名纪律**：多 findall 各用独立变量名（_X1、
   Hits1/Hits2），预防 settheory 轮的变量泄漏坑（本批未触发，写入规范）。
9. **B2·Lean 关系 API**：mathlib 4.33 无 `Rel.dom/range/image`（Lean3
   旧账）；关系代数在 `Relation` 命名空间（`flip_comp`、`comp_assoc`），
   且 `∘r` 是 Relation.lean 的 **local** 记号不外传——自建
   `local infixr:80 " ∘r " => Relation.Comp`，dom/ran/rimage 自定义落在明处。
10. **B2·Lean warning 纪律**：`intro x y` 后 x/y 只出现在假设类型里也触发
    unusedVariables（用 `show` 让变量现身）；simp 未用引理出 unused 警告。
11. **B2·python 优先级+见证手算**：`A & B - C` 解析为 `A & (B-C)`；
    像律单向包含的见证两版算错第三版才对（R 把 0、2 同映 c 时差集 {c}）。
12. **B2·Julia values 广播恒等**：`values.(Xs)` 对 Pair 向量返回原向量
    （values(::AbstractArray)=self）——取第二分量用 `last.(Xs)`。
13. **B2·Julia 空求和复现**：`sum(1:0)` 报错（probability 轮同坑）→ init=0。
14. **B2·Prolog setof 自由变元**：`setof(C, X^(class_of(P,X,C)), Q)` 的 X
    不先绑定则以自由身进入 findall、收集全宇宙——`member(X,Es)` 先绑。
15. **B2·Prolog 划分生成器**：按块序+块内倒序产生重复（有序 Bell 数），
    计数前 canonical（maplist sort + sort 块序）去重。
16. **B2·Prolog 序方向三连翻车**：sub_le 写反、整除上界方向反、把最大元
    当最小元断言——有限序分析先手推再写码，机器逐条暴露。
17. **B2·Coq 等价类双表示**：类用谓词（A→Prop）、块用 list（list A），
    避开商类型与函数外延性；两歧性拆两条引理避开经典析取。
18. **B2·OCR 勘误**：书 2.5.24 "inf∅=0" 按数学事实应为 inf∅=X（P(X) 顶），
    正文按正确版讲并注明。
19. **B3·Nat.rec 显式 motive**：`Nat.rec m Nat.succ` 类型推断失败——
    `(motive := fun _ => ℕ)` 必须显式。
20. **B3·doc 注释+#check 第四撞**：坑 #4 在 Ch06 复现两处——#check/#print
    前一律普通块注释，写入肌肉记忆。
21. **B3·Finite≠Fintype**：单射⟺满射是 `Finite.injective_iff_surjective`
    （Finite typeclass 版，非 Fintype）。
22. **B3·Nat.find 不展开**：`Nat.find h = 6` 的 rfl/decide 都不闭合
    （WellFounded 定义的 opaqueness）——改证上界 `≤ 6`（find_min'）。
23. **B3·Isabelle 终端组合**：`by (rule X) (rule Y)` 失败——ZF simp 集
    本含 add_0_right/add_succ_right，直接 `by simp`。
24. **B3·Julia 1-基索引**：aps[3] 误当 3-近似（是 2-近似；aps[1] 为 0-近似）。
25. **B3·Python 世界混用**：succ 是 frozenset 运算，集合里混放 int 崩——
    归纳集最小性改为推导式审计（两条规则逼出数字）。
26. **B3·CSB 窗口模型教训**：书引理本质无穷（有限时 A'=A=B 空洞）——
    有限彩排须以 ℤ 窗口建模；交替序列 C 在 log2(窗口) 深度稳定（实测 7）。
27. **B3·Prolog between 不求值**：`between(0, Max-1, H)` 报 compound——
    先 `MaxM is Max-1` 再 between。
28. **B3·zigzag 超额**：末条对角线整段附加使 count 超标——断言 ≥ 且不重。
29. **B4·Lean nlinarith 需要显式乘积提示**：r ≥ 2 ⟹ r² ≥ 4 对
    nlinarith 不自动——`mul_nonneg h1 h1` 手喂 (r−2)² 再 nlinarith；
    结论端 absurd 配 not_lt.mpr 显式转换。
30. **B4·截断恒等式**：无穷三进级数 0.0222…₃ 的 d 项前缀是
    1/3 − 3^{-d} 而非 1/3——机器逼出精确陈述（这比含糊的"≈"诚实）。
31. **B4·首差异账的位号**：两地址首异于第 2 位却标 n=1、方向还反了
    ——差 ≥ 3^{-(n+1)} 的断言先手推再写码（B2 序方向坑的复现）。
32. **B4·哨兵自坑 (−10)^8 = +10^8**：负底偶次幂为正——两个哨兵
    相同导致区间空、findfirst 永败；写 -(10^8)。
33. **B4·√2 分割的负半轴**：{q | q² < 2} 在负方向不向下封闭——
    分割是 {q ≤ 0} ∪ {q > 0 且 q² < 2}；有限窗口的无最大元条件
    须降格为边界余量版。
34. **B4·Julia 软作用域三连**：全局 p 复用于循环内（警告）→ 循环
    变量改名 pk/qk；数据结构版本 q 的 (3.17) 收敛率首步 2/9>0.2
    ——阈值按 sup|g'| 与首步实际值定 0.23。
35. **B4·mathlib 锚点**：`Real.exists_isLUB` 在
    Algebra/Order/Archimedean/Real（非 Data/Real）；`irrational_sqrt_two`
    在 NumberTheory/Real/Irrational。
36. **B5·lakefile globs 自动编译**：`globs := #[.submodules `Sethao]` 编译
    目录下**全部**文件——未 import 的新章文件也会进 lake build（好事：
    不必每章改根模块；坏事：写一半的文件会炸整工程）。
37. **B5·Prod.lex 三层包装**：mathlib 的 `Prod.lex`（WellFoundedRelation
    打包）≠ `Prod.Lex`（关系本体，**首**坐标优先）≠ 书 4.1.8（次坐标
    优先——交换乘积上的同一构造）；`Sum.lex` 不存在、是 `Sum.Lex`。
38. **B5·序数引理断代**：4.33 中 `Ordinal.induction` 已 deprecated
    （→ WellFoundedLT.induction）；`add_lt_add_iff_left` 无 Ordinal 命名
    空间版——Covariant 实例走根命名空间无限定名；ω<ω+1 直接 `by simp`。
39. **B5·序数端点无现成引理**：Ordinal.lt_add_one/add_one/zero_lt_one 全
    缺——simp 是万能钥匙。
40. **B5·Prolog 扁平双射列表**：pairs_of 生成**扁平**配对列表，每个解
    就是一个映射——`member(M, Cand)` 枚举的是单个配对（叠了 40 分钟
    才定位）；解直接当 M 用。
41. **B5·Prolog 方向纪律（第四次）**：related(R,X,Y) 的读序约定（X 在
    Y 后）在段/保序/递增三处全部用反——同一坑在本项目已四连撞，
    有限序分析先写约定注释再动笔。
42. **B5·Julia 哨兵自坑复现**：`(-10)^8 = +10^8`（B4 #32 同款）在
    09 未复现但列入检查单；canon 对 [0] 返回 nothing 的 max(nothing,1)
    MethodError——findlast 判空分支不可省。
43. **B5·CNF 乘法首系数两种命运**：e=0 时首系数放大（α·m = ω^d·cm+尾）、
    e≥1 时首系数归一（α·ω^e = ω^{d+e}）——初版公式漏两者被
    (ω·2+1)(ω+5)=ω²+ω·10+1 样本打回。
44. **B5·吸收的范围**：α+β 只吃掉 β 顶指数**以下**的 α 项、交叉处
    **相加**——(ω²+ω·3+4)+ω = ω²+ω·4（不是 ω·2！）；期望值先手推。
45. **B5·CNF 读序**：向量 (c0,c1,..) 的值 = ω^k·ck + … + ω·c1 + c0
    （高位项在**左**）——ω·2+5 是 (5,2) 不是 (3,2)；写期望值时按
    "低位系数在前"逐位对。
46. **B5·Isabelle lt_def 带 Ord 副词**：i<j ⟷ i∈j ∧ Ord(j)——unfolding
    lt_def 后必须供给 Ord 前提（blast intro 组合）。
47. **B5·Coq nat 截断污染**：`length [] - 1 = 0`（非 -1）使空 β 分支
    产出 [0]——定义处 match b with [] => a 显式分流。
48. **B6·Goodstein 书表自纠**：书载 g₇(13)=134219591 与书载 g₈ 不自洽——
    机器链 134219479 恰好复现书载 g₈、g₉；双通道交叉验证裁决原书笔误。
49. **B6·doc 注释+#check 第六撞**：Ch13 两处复现（B1 #4）——#check/#print
    前用 `/- -/` 已列肌肉记忆清单仍漏；写完 grep 一遍 `/--.*-/` + `#check`。
50. **B6·ZF-AC 显式导入**：session = "ZF-AC" 只建堆——AC1_def 等 fact
    仍需 `imports "ZF-AC.AC_Equiv"` 等会话限定名；AC1_WO2 在 HH.thy。
51. **B6·Lean Zorn 根命名空间**：exists_maximal_of_chains_bounded 无 Zorn
    前缀且需显式传递性参数；(4.33 无 Classical.wellOrderingRel)。
52. **B6·Coq In 非自反**：In (x) (x::xs) 的 reflexivity 不成立——
    destruct 后 `simpl; left; reflexivity`。
53. **B6·Julia 顶层 for 软作用域**：三处循环全部包函数（B4 #34 同坑
    复现）——顶层循环一律 goodstein_steps 式封装。
54. **B6·Python 家族注释写错**：注释声称两两不交但数据相交
    （{a,b} ∩ {b,c}）——断言先于注释说话。
55. **B7·λ 保留字复现**：funanalysis 坑再现——Lean 4 的 λ 是
    lambda 关键字，基数变量改 μ。
56. **B7·ℵ₀ 记号解析不一致**：`ℵ₀ ≤ κ` 作为 add_eq_self 的参数
    类型不匹配，显式 `Cardinal.aleph0 ≤ κ` 过——记号与常量名不同
    宇宙实例； aleph_lt_aleph 的 iff 形态配 `by norm_num`。
57. **B7·窗口等势计数被截断扭曲**：ω 的窗口元素被砍到 6 个、
    ω+1 有 7 个——两者被判不等势（假）；等势判定必须走结构事实
    （有限=自身 / ≥ω 皆可数）而非截断计数——窗口方法论入清单。
58. **B7·Julia union 无序**：union(a,b) == collect(0:n) 恒假——
    sort(vcat(...)) 核对。
59. **B7·ZF 无 Card_succ 引理**：Card(1) 走 Card_iff_initial 展开
    eqpoll_def/bij_def/surj_def 后 auto 可收（空定义域无满射）。
60. **B8·Lean cf 断代名**：isRegular_aleph0 无 Cardinal 前缀报 Unknown
    constant——正确名 Cardinal.isRegular_aleph0；isRegular_aleph_one
    同；cof_cof → cof_ord_cof（deprecated）。
61. **B8·mathlib 无 Cardinal.pow_add**——幂吸收用 cantor→mul_eq_self
    两级火箭；power_le_power_left 根命名空间需 open Cardinal，
    参数是 two_ne_zero。
62. **B8·UltraFilter 命名空间**：exists_ultrafilter_of_finite_inter
    _nonempty 在 Ultrafilter 命名空间（order/filter/ultrafilter/
    basic.lean），mathlib grep 大小写敏感。
63. **B8·Prolog 子集生成器炸栈（本教程最大坑）**：sub(S,Y) 以
    member 逐位生成会产重复元素无限分支——必须 subselect2（头
    include/exclude 二叉）；与 ch04 同坑重踩，列入肌肉记忆。
64. **B8·Julia Set 相等**：generator 造的 Set == 字面 Set 可能因
    首元素差异失败（18 vs 24）——期望值先实际核对。
65. **B8·Prolog between 未实例化**：between(0, A1, H) 中 A1 若是
    表达式 A-1 须先 is 求值再 between。
66. **B8·窗口'无界'语义**：maximum(S)==N-1 过强（稀疏 club 如
    3 倍数永假）——approaches_top(S) = maximum > N-10 更诚实；
    极限点用"n%5==0 + 下方密度"模拟可数极限。
67. **B8·GCH 三分支实现顺序**：先查 κ≤λ（5.2.10 无条件），再
    κ>λ 时的 cf 分岔——写反会把 ℵ₂^ℵ₁ 吞进 2^ℵ₁。
68. **B9·书 7.2.13(3) 的 ⋃ 是求并**：trcl(x) = x ∪ ⋃{trcl(y)}——
    Python 的 frozenset(list) 收集了集合本身而非元素；
    frozenset().union(*list) 才是 ⋃。两版代码写出后才看清。
69. **B9·trcl 不含 x 自身**：书 7.2.12 的 a_0=x, a_{n+1}=⋃a_n
    给出 trcl = ⋃a_n 只含后裔；含 x 的"最小传递集"= trcl(x)
    本身是传递的这一事实（x⊆trcl(x)）不是 x∈trcl(x)。
70. **B9·Coq In 左支方向**：In y (z::l) = (z=y)∨In y l——
    左支 Heq : z = y，subst y（不是 subst z）。
71. **B9·Coq fold_right S 差**：引理给 rank<S(fold) 而目标要
    rank<fold——结论去掉 S 后直接匹配（fold ≥ rank+1 在
    max 中成立）。
72. **B9·Julia V_4 秩直方图**：rank1 的子集恰 1 个({∅})非 4 个
    ——期望值先手推（V_3 的 4 个元素里只有 ∅ 的秩是 0）。
73. **B9·Isabelle thm 占位符**：草稿中的 ?? 残留会当 fact 名报
    Undefined fact——提交前 grep '??.*no such' 自查。
