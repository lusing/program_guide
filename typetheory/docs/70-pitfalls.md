# 70 坑位总清单与书目导读

> 本章汇总 1–70 章各章尾的「坑位速记」，按主题重组；
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
   让 pattern 槽位错位（57 章）。
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
    报 unexpected end of input（08/31/63 章）。
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

TTAFP 专轮（21–26 章）追加：文档注释 `/-- -/` 不能挂在
`section`/`variable` 前；`variable` 只在**签名**里被提及时才
自动绑定进定理（四踩：21/22/25 章——古典假设/反对称一律显式
作参数）；core 占名清单添 `Sub`（减法类）与 `Inter`/`Union`
（⋂⋃ 类）——谓词集换名 PSet/Cap/Cup；`∃` 析构用
`Exists.elim h (fun x px => …)`；`List.get?` 不存在用 `l[i]?`；
`do` 块内局部函数用 `let f : T → T := fun …`；core 无
`String.replicate`/`Char.repeat`；嵌套 let+if 的递归函数断言
用 `native_decide` 别硬 `rfl`。

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
7. record 构造子在 seed 位置要 `@MkX A B ...` 全显式（38/61 章
   连环踩）；record 投影带参全应用（`hprop_all (P x) (H x) ...`）。
8. 自造等式类型要 `Unset Automatic Proposition Inductives`
   （否则落 Prop、失去 Type 层消去，57 章）。
9. 记号优先级：`·`(60) 紧于 `!`(65)——`! p · p` 解析成
   `!(p·p)`（57 章）；依赖 match 的 motive 里裸 `idpath` 要
   `@idpath A y'` 注端点（36/61 章）；motive 引用外层 q 必须
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

TTAFP 专轮（26 章）追加：Bézout 在 **Z 模块**（`Z.gcd_bezout`：
`Z.gcd n m = p → ∃a b, a*n+b*m = p`——n/m 与 a/b 配对序相反），
Znumtheory 在 8.20 不存在；`d | m` 中缀在定理声明里解析不稳，
写 `Z.divide d m`；lia 不做非线性——`x*m` 与 `m*x` 是两个原子，
先 `Z.mul_comm` 对齐；`Z.mod_pos_bound` 只对 b>0 给界；
`Open Scope Z_scope` 下 `<=` 默认读 Z，Nat 目标要 `(…)%nat`；
stdlib 析构嵌套合取时 destruct 出的假设可能是「合取里的合取」
——`proj1/proj2` 逐层拆。

## 31.4 Agda 高频坑

1. 自定义中缀**必须声明 fixity**（`infixr 20 _⇒_`），否则
   `ι ⇒ ι ⇒ ι` 解析失败（04 章）。
2. record 多字段用**块形式**（`field` 独占一行）；行内
   `field x : A` + 缩进续行 ParseError（31 章）。
3. `using` 与 `renaming` 不能圈同名；`Level.suc` 与
   `Data.Nat.suc` 冲突要 `renaming (suc to lsuc)`（31 章）。
4. 裸 `where` 块里不能 `open import`（57 章 ap-compose 案）；
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
   两端锚点不一致，63 章）。
2. `transport (fun _ => X) q u == u`（常值族）是 **J-定理**非
   定义——q 不透明时先立引理（42/64 章）。
3. loop-UIP 在自造 paths 上是 destruct 地狱——正路 noconf 或
   投靠 stdlib eq（61 章，三种写法实测全败的记录在案）。
4. 公理**记账制**：每章收尾 `Print Assumptions`；UA 的 β 规则
   要单独公理（59 章 transport_ua）。

## 31.5b cubical Agda 高频坑（HoTT 专轮：58–68 章）

1. 区间运算要 renaming 自 `Agda.Primitive.Cubical`（primINeg
   → ~_ 等）——且 **区间 `_∧_`/`_∨_` 与逻辑记号撞名**（60 章
   起逻辑当道，区间改名 `_∧ᵢ_`/`_∨ᵢ_`）。
2. `primHComp`/`primTransp` 的**别名会触发边界检查**——直接
   在用点调用；J-合成 `_∙_` 用 `J (λ z _ → x ≡ z) p q` 的
   transport 版最稳。
3. **点-free 子句的隐式参不在辖域**（五踩实录：37 的 lUnit、
   39 的 pathOverProp/∃-syntax、41 的 pointed-induction、42
   的 Susp-fun、44 的 transport-fib）——子句模式显式
   `{A = A}` 绑定，或**内联 motive 让 where 块消失**。
4. 巨型 2-维 cong 链：先画**结合树**再写段（Agda 的
   UnequalTerms 十有八九是树形错位）；Coq 版改 **assert
   分段** + 全显式 `@mk…`/`concat`。
5. Glue 手造 ua：`primGlue B (两端 partial 类型) (两端 partial
   等价)`——i0 端放源等价、i1 端放恒等；漏 i1 端 φ 面不全。
6. HIT 的**矛盾路径分支**写 `constructor () i`（absurd 参数
   +区间双占位）——`⊥-elim` 整条路径返回会被端点锚定拒绝
   （60 章 isProp-sum¬ 与 65 章 merid 两案）。
7. HIT 消去子的 squash/push 分支用 `PathP 分量`——依赖版要
   `pathOverProp`（J 一击把 PathP 降为 isProp）。
8. W 编码 ℕ 的**构造子-分支配向**：零参数构造子配空分支
   （`sup true (λ ())`）——配反则自引用不终止（62 章
   Termination checker 抓获）。
9. builtin `⊤`（Unit）自带导出——自造 record ⊤ 会撞名；
   `if-then-else` 非原生（自造 branch）；ℕ 在裸文件里用
   data 自造。
10. Lean 侧姊妹坑：axiom 不能合并声明；裸文件 ℕ 记号失效
    （用 Nat）；依赖 axiom 的 def 要 `noncomputable`；
    `Quot.lift₂` 无内置（相容性定理是良定义的正式载体）。

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

TTAFP 专轮（21–26 章）追加：**Prolog 无函数记法**三连踩——
谓词糖（t_arrow/and2）出现在项位不会被调用，一律 `ex/2`
展开遍历后喂 db；应用链必须完全嵌套，`a(a(x,b),u,v)` 是
`a/3` 静默失败；**de Bruijn 语境是统一坐标系**——压栈时全体
条目（含新注解）在 cutoff 0 上移，查表免 shift，按位置递增
cutoff 或只移新条目都错（21/23/24 三章各现形一次）；代换
三分支 `==j 换入 / >j 减一 / <j 不动` 且换入项由递归预抬——
**顺序代换会互相腐蚀**（后遍的减一伤及前遍的插入），多参数
实例化必须**同时代换**（subst_many）；`tc` 的 app 规则先把
函数类型 βδ-范式化再匹配 Π 形；手搭语境别把类型表达式放进
类型的类型位；探针查询要截断——form 双条款回溯会把输出搅成
ok/NONE 噪声；`between(0, A, X)` 的 A 先算后用；表驱动检查
给 N 定参闭包（le4）防元数错配。

## 31.6b TAPL 线高频坑（36–46 章：Prolog 装配机 + Coq 元定理）

> 装配型语言的五表纪律：每加一个构造子，shift / subst /
> isvalue / step / typeof 五张表**全部同步**——漏一张就是
> 无声 stuck（38/43 章各三连环实测）。

① `loc(L)`/`unitv` 等值构造子在 shift/subst 里写成**匿名
  变量**（`loc(_)`）会把值偷换成未绑定变量——命名绑定铁律；
② Prolog 关系谓词（seqc/desugar）当**构造子**用不出展开 —
  程序构造直接写展开式（ap(lm(unitt,B),A)）；
③ 嵌套序列/生成器的 de Bruijn 指数**逐层 +1**——计数器
  程序带深度参数生成（38 章坑⑤的通则）；
④ 主检定每个 check 用**全新变量**——复用已绑定变量静默失败；
⑤ 声明式子类型/传递律的无界搜索是 16/21 章**算法化的动机** —
  机器件装直推规则+算法版对照，「事故现场」即教学；
⑥ 记录三律子句要 **nonvar(TF) 模式守卫**——T 侧未定时
  length 造无界列表栈爆；
⑦ 算法版子类型的**结构相等快速通道排在展开子句前** —
  否则 μ=μ 空耗燃料（41 章实测）；
⑧ 合一器的裸元变量要 `var(T)` 守卫 + occurs check 的
  ground 守卫——两个连环崩（42 章实测）；
⑨ unify 失败返回 **fail 哨兵**不是 Prolog 失败——`\+ unify`
  测不出拒绝；
⑩ 空体兜底子句 `r(_,_,_).` 是**永真**——删除时想清楚它
  原来挡什么（41 章实测翻车）；
⑪ Coq `<:`/自定义中缀记号与列表 `;` 相互作用错位——
  关键处直接写全名（sub S T）；
⑫ Coq 构造子元数在 isvalue/step/typeof 各处的**一致性** —
  命名 λ 与匿名 λ 两套记号别混文件（43 章三连环）；
⑬ E-TryError 的结果是**处理器项**（→ t2）不是 err——
  一步写反语义全倒；
⑭ build.ps1 的 Prolog 判定对输出做**大小写不敏感**匹配 —
  检定标签里别出现 error/warning 字样（38 章实测误伤）。

## 31.6c 罗朝晖线高频坑（47–56 章：Coq 语义件 + Prolog 分析器）

> 语义建模三纪律：**谓词的论域先声明**（Parameters 全列）；
> **Fail 见证要求失败真的发生**；**双强制要么目标不同
> （合谐）要么删一条**（48 章定理的工程面）。

① Record 字段引用前面的字段拿到的是**字段值**不是投影 —
  `H_a x (am_of x)` 报「Human 不能应用于 x」（51 章实测）；
② 构造子 destruct 的 intro 模式要**平铺全字段**：三字段
  构造子 `[x y Hp]`，嵌套写 `[x [y Hp]]` 被当析取模式拆
  （52 章实测「Expects a disjunctive pattern」）；
③ exists∧exists∧… 的模式**每层合取都有自己的括号** —
  `[k [Hk [f [Hinj Hall]]]]`（52 章 most_two 实测）；
④ `lia` 不算 `Nat.div`——先 `cbn` 把常量除法算掉再 lia；
⑤ 依赖等式上的 destruct 有「抽象不良类型」暗礁：目标/假设
  含**单态函数**（f : Fin 2 → F3）时 destruct 抛异常且
  **try 不捕获**——改道等价形或换见证构造（52 章 Most
  反向改走 Most3，诚实记录）；
⑥ `apply (lemma _)` 留 evar 时把假设**直接应到具体对象**
  （Hua (mkDo f1 d2 I)）一锤定音——exact 消不掉 evar；
⑦ JMeq 在 8.20 预加载库**不存在**——自造三行且隐式参数
  {A}{B} 别写显式（54 章）；自造件必须声明在**使用前**；
⑧ `contradiction` 不认「对称后矛盾」（E : j = i 对 Hij :
  i <> j）——congruence/lia 才行（49 章）；
⑨ Coq 8.20 对空/单点 Inductive 自动降 Prop 并发**弃用警告**
  ——`Unset Automatic Proposition Inductives.` 压制（56 章）；
  同因避开 Prop 形负位归纳（BadNeg→False 会触发双输出）；
⑩ `nth_error_Some` 8.20 是 iff 形——用 proj1 拆方向；
⑪ 双 nat 字段记录的 `:>` 双投影触发 ambiguous-paths **警告**
  （stderr 非空=build 失败）——`Set Warnings "-ambiguous-paths"`
  屏蔽并在注释保留警告原文当教学证据（48 章）；
⑫ Coq 强制插入**只做原子层**——函数逆变/List 传播/谓词
  传播都要手写 map 版函数（理论有实现无的边界，48 章）；
⑬ 强制查找按**语法形状**找目标——参数位目标 `A→Prop`（A
  待定）与注册的 T1 对不上，用类型归属 `(run_word : T1)`
  点名（50 章书原文写法）；
⑭ 语义负例用 `Fail Definition` 见证时先想清楚**会不会真的
  失败**——is 的 A/B 独立参数让「生成过剩」形式上合法
  （54 章实测 The command has not failed!）；真失败的两个
  位（EQP 错误语义的 x 出辖域、Evt_H 的 Table≠Human）才
  是 Fail 的正当用户；
⑮ Prolog 分析器：`(B/A)` 的 A（论域）是**第一分量**——
  sr(cn,np) 是 NP/CN，写反后分析器「看似工作实则全错」
  （55 章 caught/the/most 三连环）；π 消解要**在轨内**做
  （预实例化反成 bug）；应用规则 cumul 方向=参数⊑论域，
  左应用参数在前照抄有序轨必反；
⑯ mini-LF 检查器的 kind_ok 查**开类别**时绑定名被当全局
  常量查表（kel(c(a)) 的 a 出作用域）——只查外层形状是
  诚实的降级（56 章）；
⑰ Section 内的 Coercion 在 End 后失效——这是「局部强制」
  的机器化身不是 bug，docs 要讲明（53 章）。

## 31.7 七本读本怎么读

| 书 | 定位 | 建议路线 |
|---|---|---|
| Hindley《BSTT》 | Curry 线教科书 | **已全覆盖**（专轮 03/06/07/09/10/11 章）；第 9 章技术细节配合 69 章 |
| TTAFP | 立方体与 λD 主线 | **已全覆盖**（专轮 21/23/24/25/26 章：逻辑编码/λD 系统/旗式与附录 A/等式序 ι/公理化算术 Bézout；06–09 章骨架在 18–20） |
| TAPL | 工程视角 | **已全覆盖**（36–46 章专轮：操作语义→纯函数对象十一讲；附录 A 习题答案未收录、附录 B 记号约定融入各章）；03/04/18/24 章的既有对照升级为交叉引用 |
| Nordström 导论 | MLTT 圣经 | 10–16 章逐章对读；扫描件（无文本层） |
| HoTT 书 | 第五部分 | **已全覆盖**（专轮 37/39/41/44/45/46/47 七新章 + 36/38/40/42/43 五章深化）；ch.1–11 核心内容自包含；机器面 cubical Agda 主力（58 章起）+ Coq mini-HoTT 对照 + Lean set 层（39/46/47）；同伦论大定理（Freudenthal/Hopf/van Kampen 完整机器版）以陈述级呈现、coq-hott 教程续读 |
| Farmer《STT》(2023) | Church 式实用逻辑全书 | **12–17 章全覆盖**（双语义/未定义性/证明系统/理论/态射/变体）；01 章动机讨论来源 |
| 《现代类型论的发展与应用》 | 中文综述 | **已全覆盖**（专轮 47–56 十章：UTT/强制子类型/记录与模块/MTT 语义/形容词/证明无关与驴句/标记与点类型/判断与事件/范畴语法/LF 与元理论）；书内 Coq 代码（5.3 节）全部升级为过检机器件、栈细化定理补全真证明；旧引用（2.5 配 33、6.2 配 19、3.5 配 35）升级为交叉引用 |

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

上一章：[69 元理论](69-metatheory.md) · 下一章：（完）
