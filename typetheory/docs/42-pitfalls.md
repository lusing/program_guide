# 37 坑位总清单与书目导读

> 本章汇总 01–42 章各章尾的「坑位速记」，按主题重组；
> 末尾是七本读本的阅读建议与四家速查表。

## 31.1 工具链与环境（全章通用）

1. **文件/模块名**：Coq 8.20 与 Agda 都拒绝数字开头（`Invalid
   character '0'` / `InvalidFileName`）——命名一律 `exNN_*`；
   build.ps1 对 Coq 再拷贝 `ex_` 前缀兜底。
2. **Agda 保留字**：`inductive`/`coinductive` 连 `_inductive`
   后缀都不许出现在模块名里（30 章目录被迫改名 30_indfam）。
3. **BOM/行尾**：源码无 BOM UTF-8；`.agda` 钉 LF
   （.gitattributes）。
4. **Agda stdlib（Debian）**：预编译 .agdai 在 `_build/2.8.0/`
   与源码 `src/` 分离——一次性合并（`cp -r`）后秒级加载。
5. **Agda 文件里的 if**：只吃 Bool，`Dec` 要 `⌊_⌋` 降级；
   `≤?`/`≟` 裸塞进 `if` 报类型错。
6. **MAlonzo 编译**：`{-# OPTIONS --guardedness #-}`（IO 的
   infective flag）+ `_>>_` 手动导入 + GHC 在位。

## 31.2 Lean 高频坑

1. `def f (fuel : Nat) : T → U | 0, _ => ...`：**冒号前参数不
   参与模式匹配**——匹配参数全部移到冒号后（04/05/08/12 四章
   连环踩）。
2. 方程式 def 的隐式箭头参数要写成绑定器形式
   （`{x y : α} →` 放冒号前），`: {x y : α} →` 的望远镜写法
   让 pattern 槽位错位（36 章）。
3. `rw` 只看**语法**：iota/δ 折叠之下的子项要 `simp only [f]`
   先暴露（30 章 add_z 四连踩）；`rw` 后残余目标可能要显式
   `rfl`（19 章 progress）。
4. WF 递归（`termination_by`）过了终止检查但 `WellFounded.fix`
   内核难解——要 `by rfl` 断言的函数选结构/燃料递归（05 章）。
5. `variable` **用到才收**：只在 tactic 里用的假设不进泛化
   （27 章 `h.symm` 失踪案）。
6. `opaque` 挡的就是 `rfl`；`native_decide` 是过墙官道
   （22 章）。
7. 核心库占用：`Empty`/`Unit`/`Bool`/`⊕`（Sum）——自定义
   要换名或换符号（22 章 `⊗`）。
8. `⊕`-型自定义记号：`local infixl:65`，裸 `notation x " ⊕ " y`
   会吞掉后面的 `=`（22 章）。
9. `#check (Nat : Type 5)` 揭示 **Lean 无 Cumulativity**——
   升层用 `ULift`（31 章）。
10. 匿名构造器里类型由前字段定时，数字要标注 `(3 : Nat)`
    （OfNat 对投影类型失明，31 章）。
11. doc 注释 `/-- -/` 后必须跟声明；挂文件尾会让整文件
    报 unexpected end of input（08/31/39 章）。
12. 跨行 `|>.length` 在 example 里解析不稳（08 章）。
13. core 没有 `List.maximum?`（Batteries/Mathlib 才有）——自写
    maxOf 三行（07 章）。
14. `Option.get!` 要 `Inhabited`——deriving 行加 Inhabited
    （var 0 当默认值）即可（07 章）。
15. 数据类型前向引用报错形态离谱：Tm 构造子吃 Ty2 而 Ty2
    定义在后，报的是一串 Repr/BEq 无法综合（07 章）。
16. 复制旧代码先数构造子参数：`imp : Fm → Fm → Fm` 少写一段，
    全文报 `Function expected at a.imp`（11 章实测）。
17. `example … := by rfl where …` 非法（where 只挂 def）；
    断言类型里的 `some _` 无法综合——用 `(…).isSome = true`
    （06/07 章）。
18. 归纳证复合律等箭头情形：先 `simp only [applyS]` 展开再 rw
    归纳假设（05 章深化批）。
19. **冒号前参数不参与模式匹配——第五踩**（14 章 axInst）：
    `def axInst (s : Nat) : Fm → Bool | 1, …` 报 OfNat Fm 1；
    全部参数移到冒号后即绿。
20. **deriving BEq 遇嵌套递归字段（List (Val × Val)）内核不
    归约**：#eval 正常而 by rfl/decide 全假，#reduce 停在
    instBEqVal.beq（12 章）——手写 valEq/tabEq 互递归即愈。
21. 公式臂内**多关注点 match on (Option, Option)** 同款卡壳
    ——拆 qcombine/ecombine 辅助函数；`List.lookup` 也要换
    手写查表（14 章）。
22. **类型同义词挡实例**：`def Op2 := List Nat` 之后 `t[i]!`
    报 failed to synthesize GetElem?（15 章）——直接用 List Nat。
23. `interval_cases`/`by_contra` 是 Mathlib 的——standalone 用
    `cases y`/`cases Nat.lt_or_ge` 正向二分（16 章）；∃! 记号
    也不在 core，展开成 ∃ + ∀ 合取（17 章）。
24. `Classical.choose` 的 def 要 `noncomputable`；`choose_spec`
    给整个合取（取 `.1`）；omega 拒非线性假设——先 rw 成常数
    不等式再 omega（17 章）。

## 31.3 Coq 高频坑

1. **注释嵌套**：注释里写 `(*,*,*)` 型规则记号——`(*` 开新层、
   `*)` 提前闭层；规则用空格拆开（20 章两次）。
2. `Theorem ... := term.` **不进语法**——term 式用 `Definition`
  或 `Proof. exact ... Qed.`；且 `forall a, a -> a` 的居留项是
  双层 λ（08 章）。
3. **inversion 名漂移**：生成假设名随版本变——`as` 模式点名或
  `match goal`；`subst` 还会吃掉点名变量（结尾 `eexists` 兜底，
  04 章）。
4. **索引归纳**：对 `has_ty [] t T`（索引是字面量）直接
   induction 丢信息——等式泛化进归纳命题（04 章 progress）。
5. `nth_error` **递归在 n**：`nth_error [] k` 对变量 k 不化简，
   `destruct k` 后再 discriminate（04 章）。
6. `ltac:(lia)` 在**项位置**系统性失灵（"Cannot find witness"）
   ——子集类型证据走 `Proof. exists 1. lia. Defined.`（33 章）。
7. record 构造子在 seed 位置要 `@MkX A B ...` 全显式（37/38 章
   连环踩）；record 投影带参全应用（`hprop_all (P x) (H x) ...`）。
8. 自造等式类型要 `Unset Automatic Proposition Inductives`
   （否则落 Prop、失去 Type 层消去，36 章）。
9. 记号优先级：`·`(60) 紧于 `!`(65)——`! p · p` 解析成
   `!(p·p)`（36 章）；依赖 match 的 motive 里裸 `idpath` 要
   `@idpath A y'` 注端点（36/38 章）；motive 引用外层 q 必须
   retype（q 做成 match 参数，25/29 章）。
10. Coq 的 `+` 递归在第一参数：`2 + n` 折叠、`n + 2` 不折
    （与 Lean 相反，19 章方向学表）。
11. 无构造子归纳默认落 Prop 且**不能消去到 Type**——空类型
    声明 `: Set`（28 章）。
12. 递归子参数 A B 默认显式——`Arguments Wt_rect {A B}` 省心
    （32 章）。
13. `Check f : T` 遇隐式参数用 `@f`；`Fail Check` 演示不可类型
    化（04/29 章）。
14. **`iota` 在 ClassicalDescription 不在 ClassicalEpsilon**；
    签名 `iota [A] (i : A) P`——第二参是**默认元素**（epsilon
    才要 inhabited）（17 章）。
15. `exists!` 析构是**三层** intro 模式 `[x [Hx Huni]]`；且
    `exists! x, P x -> Q` 解析成 `exists! x, (P x -> Q)`——
    前提必须括号（17 章）。
16. 自定义谓词（Definition 出来的 Prop）喂 lia 前要 `unfold`
    ——simpl 不展开 Prop 定义，lia 报 Cannot find witness
    （17 章 square4 实测）。

## 31.4 Agda 高频坑

1. 自定义中缀**必须声明 fixity**（`infixr 20 _⇒_`），否则
   `ι ⇒ ι ⇒ ι` 解析失败（04 章）。
2. record 多字段用**块形式**（`field` 独占一行）；行内
   `field x : A` + 缩进续行 ParseError（31 章）。
3. `using` 与 `renaming` 不能圈同名；`Level.suc` 与
   `Data.Nat.suc` 冲突要 `renaming (suc to lsuc)`（31 章）。
4. 裸 `where` 块里不能 `open import`（36 章 ap-compose 案）；
   类型签名不能带 where。
5. 顶层量词裸写 `∀ a b → ...` 留 meta——带类型
   `∀ (a b : ℕ) → ...`（27 章）。
6. `_++_` 等基础件在 `Data.List.Base`（`Data.List` 的 re-export
   列表不全，34 章）。
7. 非依赖 `if` 两分支必须同型——类型随参数变得走依赖版
   消去子（族先立再填表，28 章）。
8. 字符/字符串字面量需要 BUILTIN 绑定——独立小文件用 ℕ 元素
   （19 章）。
9. `with` 单分支捕获会让定义**卡住归约**（≤? 对变量 stuck）——
   教学实现写普通子句（35 章 sort）。
10. 模式里同级运算符要显式括号：`(x ∷ xs) ++ ys`（19 章）。

## 31.5 HoTT/mini 库特有

1. HIT 的 `ap f loop`-型计算规则要用**依赖版 apD**（非依赖版
   两端锚点不一致，39 章）。
2. `transport (fun _ => X) q u == u`（常值族）是 **J-定理**非
   定义——q 不透明时先立引理（39/40 章）。
3. loop-UIP 在自造 paths 上是 destruct 地狱——正路 noconf 或
   投靠 stdlib eq（38 章，三种写法实测全败的记录在案）。
4. 公理**记账制**：每章收尾 `Print Assumptions`；UA 的 β 规则
   要单独公理（37 章 transport_ua）。

## 31.6 Prolog 高频坑（Hindley/Farmer 两专轮：06/09–12–15 章）

1. SWI-Prolog 在 Windows 按系统 locale 读源文件——中文注释必须
   首行 `:- encoding(utf8).`，否则一串 Illegal multibyte Sequence
   告警直接判 FAIL（06 章）。
2. `-l 文件` 不执行 `initialization/2`；位置参数也不行——构建
   通道用 `-q -g main -t halt -l`（成功 0/fail 1/抛错 2）。
3. **裸合一无 occurs-check 会造循环项**：S = arr(S,…) 的「无穷
   公式」当公理实例放行，伪证明 K∈R_（09 章翻案实录）——凡把
   合一当逻辑用的地方（cd/D-规则/计数）都上
   `unify_with_occurs_check/2`。
4. 子句里单次出现的变量给 Singleton 警告（判 FAIL）——`_` 或
   换 `prove(Sys, T, _)` 头模式。
5. 小写开头的 `m` 是原子不是变量——D-搜索器里静默变成「证出
   任意公理」的假阳性（10 章）。
6. `copy_term` 隔断前提间的实例化传播——D-搜索要「大前提先
   落地、小前提证同一个 P」（10 章）。
7. de Bruijn 表示让 α-等价 = 字面相等，枚举去重就是 sort/2；
   深度枚举对 f-双参型按平方爆炸——逐层加燃料 + 撞到
   深度 > ‖τ‖ 早退（11 章）。
8. **算术先于使用**：`numlist(0, N1, L), N1 is N-1` 顺序一反
   就是 instantiation error（15 章 perm/2）。
9. **目标失败时 format 输出被吞**（不 flush 就退场）——电池写
   成 chk/cond 双谓词 + between 链式检查，失败先 format 再
   halt(1)（12 章起定型）。
10. 手写嵌套项十括号九错——**命名部件法**（`t_c1/1`、逐行组合）
    + 逐行括号平衡扫描是批量电池的救命符（12 章）；公式求值器
    允许「变量已换成值」的半展开态时要给叶子值加直通子句
    （13 章 k3_fml(u,u)）。

## 31.7 七本读本怎么读

| 书 | 定位 | 建议路线 |
|---|---|---|
| Hindley《BSTT》 | Curry 线教科书 | **已全覆盖**（专轮 03/06/07/09/10/11 章）；第 9 章技术细节配合 41 章 |
| TTAFP | 立方体主线 | 06–09 章的骨架；第 12 章元理论配 35 章 |
| TAPL | 工程视角 | 03/04/24 章的对照读物；实现细节最全 |
| Nordström 导论 | MLTT 圣经 | 10–16 章逐章对读；扫描件（无文本层） |
| HoTT 书 | 第五部分 | 25–29 章；第 8 章配合 coq-hott 教程 |
| Farmer《STT》(2023) | Church 式实用逻辑全书 | **12–17 章全覆盖**（双语义/未定义性/证明系统/理论/态射/变体）；01 章动机讨论来源 |
| 《现代类型论的发展与应用》 | 中文综述 | 全程中文底本；2.5 子类型配 27 章、6.2 LF 配 19 章 |

## 31.8 四家速查（一页带走）

| | Coq 8.20 | Agda 2.8 | Lean 4 | (Coq-HoTT) |
|---|---|---|---|---|
| 相等 | `eq`(Prop) | `_≡_`(Set) | `Eq`(Prop) | paths(Type) |
| 函数 | `forall` | `→`/`∀` | `→`/`∀` | Π |
| 依赖对 | `sig`/`sigT` | `Σ` | `Σ`/`Subtype` | Σ |
| 归纳 | `Inductive`+tactic | `data`+模式 | `inductive` | +HIT |
| 宇宙 | Set/Type@{i}/Prop | Set ℓ | Sort u | Type |
| 无关性 | proof_irrelevance | 无（纪律） | 内核 defeq | 截断层 |
| 检查器 | coqc（拷贝改名） | agda（WSL） | lean | coqc |

---

上一章：[41 元理论](41-metatheory.md) · 下一章：（完）
