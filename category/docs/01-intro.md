# 02 认识范畴论

> 对书：贺伟《范畴论》1.1 /《高级范畴论》1.3（范畴的定义）、1.4（例子）/
> Simmons 1.1–1.4（结构集范畴、箭头不必是函数、预层一瞥）。
> 代码：`examples/01_intro/`（ex01_intro.v / .agda / .lean）。

## 1.1 为什么是范畴

代数研究群、环、域——每个结构内部有运算；范畴论换一个视角：
**只看对象之间怎么映射，不看对象内部是什么**。
一个范畴是如下数据：

- 一堆**对象** `Obj`；
- 每对对象 `a b` 有一堆**态射** `Hom a b`；
- 每个对象有**恒等态射** `idn a : Hom a a`；
- 态射可**复合**：`f : Hom a b`、`g : Hom b c` 拼成 `comp f g : Hom a c`；
- 三条定律：左单位、右单位、结合律。

把它写成类型，就是三份代码共享的同一个 record：

```coq
Record Category@{u v} : Type := mkCat {
  Obj : Type@{u};
  Hom : Obj -> Obj -> Type@{v};
  idn : forall a, Hom a a;
  comp : forall {a b c}, Hom a b -> Hom b c -> Hom a c;
  idL : forall {a b} (f : Hom a b), comp (idn a) f = f;
  idR : forall {a b} (f : Hom a b), comp f (idn b) = f;
  assoc : forall {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
            comp (comp f g) h = comp f (comp g h)
}.
```

Agda 是 `record Category (o ℓ : Level)`，Lean 是
`structure Category`——同一副骨架的三种拼法。**造一个范畴 =
把这八个字段填满，定律无一可逃**：这是「定义即类型」在范畴论上的
第一笔红利。

## 1.2 复合的方向

本书按**图序**（diagrammatic order）书写：`comp f g` = 先 `f` 后 `g`
（Simmons、Mac Lane 部分章节的风格）。函数式的 `f ∘ g` = 先 `g` 后
`f`——它恰好是反范畴视角（03 章）。贺伟本与《高级范畴论》沿用
函数复合习惯；读书时留意每本书的方向约定。

## 1.3 四个首批例子

| 例子 | 对象 | 态射 | 定律 |
|---|---|---|---|
| 终范畴 `catOne` | 1 个 | 恒等 | destruct 后 rfl |
| 幺半群 `catNat` | 1 个 | ℕ | 加法引理（真算术） |
| `FinCat` | 基数 | `fin m → fin n` | βη 折叠全免费 |
| `TyCat` | Type | 函数 | 同上（宇宙多态登场） |

**终范畴 1**：一个对象一条态射。定律里 `f` 是变量，`tt = f` 不能
rfl，要先把 `f` 拆开（Coq 用 `unit_eq`，Lean 用 `Unit.ext`）。

**幺半群 = 单对象范畴**：`(ℕ, +, 0)` 看成只有一个对象 `*` 的范畴，
`Hom * * := ℕ`、恒等 := 0、复合 := 加法。范畴定律逐条变成算术定理：

```coq
idL : 0 + f = f      (* Nat.add_0_l *)
idR : f + 0 = f      (* Nat.add_0_r：要归纳！ *)
assoc : (f + g) + h = f + (g + h)
```

在 `catNat` 里复合两条态射是可计算的：`comp 2 3 = 5`，三家都给出
`rfl`/`refl` 级别的验证。反过来，任何幺半群都是一个单对象范畴，
任何单对象范畴都是一个幺半群——**范畴论统一了「结构」与「作用」**。

**FinCat（有限集范畴的骨架）**：对象 = 自然数（当作基数），
`Hom m n := fin m -> fin n`。本机 coqc 的 stdlib 不含 `Coq.Fin`，
我们自造了四行的 `fin`：

```coq
Fixpoint fin (n : nat) : Set :=
  match n with
  | O => Empty_set
  | S m => option (fin m)   (* None 当 F0，Some 当 FS *)
  end.
```

「函数当态射」的最小化身，且完全避开宇宙问题。

**TyCat（Set 的化身）**：对象 = Type、态射 = 函数。这里宇宙多态
正式登场：Obj 落在 `Set+1` 层、Hom 落在 `Set` 层（Coq 的
`Record Category@{u v}`；Agda 的 `Category (suc 0ℓ) 0ℓ`；Lean 的
`Category.{1, 0}`）。

## 1.4 「函数范畴的定律免费」

FinCat/TyCat 的 idL/idR/assoc 全是 `eq_refl`——因为 Coq 的定义相等
含 **β 与 η（函数）**：

```text
comp (idn a) f = (fun x => f ((fun y => y) x))  β→ (fun x => f x)  η→ f
```

Agda 与 Lean 同理（η 都是定义性的）。对照幺半群范畴的 `idR` 要
归纳——**定义相等白送什么、不送什么**，是三实现横评的第一课。

## 1.5 三家写法对照

| | Coq 8.20 | Agda 2.8 + stdlib 2.3 | Lean 4.25 |
|---|---|---|---|
| 记录 | `Record ...@{u v}` | `record Category (o ℓ)` | `structure Category` |
| 宇宙 | 显式注解/推断 | Level 参数 + `Set (suc _)` | 自动 `Type u/v` |
| idn 参数 | 显式 `forall a` | 隐式 `{a}`，定律里 `idn {a}` | 显式 `∀ a` |
| 定律证明 | eq_refl / PeanoNat | refl / stdlib 引理 | rfl / Nat.add_zero |
| 字段填充 | 逐 binder 绑定（坑） | `record { field = ... }` | `where` 语法 |

注意 Agda 的 idn 用隐式对象参数（stdlib 惯例），定律里要写
`comp (idn {a}) f ≡ f` 实例化——与 Coq/Lean 的显式风格不同。

## 1.6 结构集范畴：一个配方生成一族范畴

前四个例子各有巧妙，但数学里最常见的范畴来自同一个**配方**：
取一个「携带集」(carrying set)，在上面放结构，箭头 = 保结构的
函数。Simmons 1.2 把这个配方明说了：

| 范畴 | 对象 = 携带集 + 结构 | 箭头 f 要满足 |
|---|---|---|
| `Mon` | 集合 + 结合二元运算 + 单位 | `f(x·y) = f x · f y`、`f ι = ι` |
| `Top` | 集合 + 开集族 | `f⁻¹(开) 开`（原像保开） |
| `Pre` / `Pos` | 集合 + 预序/偏序 | `x ≤ y ⟹ f x ≤ f y`（只进不出） |
| `Pno` | 集合 + 基点 + 自映射 `(A, a, α)` | `f a = b`、`f ∘ α = β ∘ f` |
| `R-Set` / `Set-R` | 集合 + 幺半群左/右作用 | `f(a·r) = f a · r`（26 章） |
| `Pfn` | 集合；箭头 = 部分函数 | 定义域限制后全函数（08 章） |

**复合封闭**是配方的第一道检验（Simmons 1.2.2）：若 f 保
`X→Y` 的结构、g 保 `Y→Z` 的结构，则 `g∘f` 保 `X→Z`——结构
「穿过」中间层。恒等函数永远保结构。于是整套范畴公理里，真正
要验的只有复合封闭这一条；结合律与单位律是**继承**自函数的。

`Pno` 是这个配方的最小完整样本，值得整个机器化。对象是三元组
`(A, a, α)`，箭头是「保点 + 保步」的函数：

```coq
Record PnoAlg : Type := mkPno {
  pcarr : Set;
  pstart : pcarr;
  pstep : pcarr -> pcarr
}.

Record PnoArr (A B : PnoAlg) : Type := mkPnoArr {
  pfun : pcarr A -> pcarr B;
  pkeep1 : pfun (pstart A) = pstart B;
  pkeep2 : forall x, pfun (pstep A x) = pstep B (pfun x)
}.
```

复合封闭 = 两条钩链（trans + cong），零公理：

```coq
Definition pcomp {A B C} (f : PnoArr A B) (g : PnoArr B C) : PnoArr A C :=
  mkPnoArr (fun x => pfun g (pfun f x))
           (eq_trans (f_equal (pfun g) (pkeep1 f)) (pkeep1 g))
           (fun x => eq_trans (f_equal (pfun g) (pkeep2 f x))
                              (pkeep2 g (pfun f x))).
```

但把 `Pno` 凑成完整的 `Category` 时，定律**不再是免费的**：
`idL` 要证 `(fun x => pfun f x) = pfun f`（η 可关）加上两个
命题字段 `eq_trans eq_refl (pkeep f) = pkeep f`。后者在 Coq
里既不是定义相等也不是命题无关——只能逐字段 destruct，而
`forall x` 型字段还要**依赖版外延公理**：

```coq
Axiom funext_dep : forall (A : Type) (B : A -> Type)
  (f g : forall x, B x), (forall x, f x = g x) -> f = g.
```

三家在这件事上的待遇天差地别，值得记住：**Lean 的证明字段住
在 `Prop` 里，证明无关性是定义性的**，所以同一个实例的
`idL/idR/assoc` 全部 `rfl`；Coq 要公理 + 逐字段拆；Agda 需
funext 与 `≡` 无关性两个假设（本文件保持零假设，只做点式
定理）。这是 07/09 章 record 相等三文化的第一预告。

## 1.7 箭头不必是函数

「态射」比「函数」宽得多。Simmons 1.3 的四个例子按抽象度递增：

1. **矩阵**：`m×n` 实矩阵 = `ℝⁿ → ℝᵐ` 线性映射；复合 = 矩阵
   乘法。矩阵只是线性映射的坐标表示，范畴只认映射。
2. **图态射**：`(N,E)` 间箭头是一对函数 `f₀ : N→N'`、
   `f₁ : E→E'` 且保源汇（两个交换方块）。复合按分量进行。
3. **关系**：`Rel` 的对象是集合，`Hom A B := A → B → Prop`，
   复合走存在量词：`c (H∘G) a ⟺ ∃ b, c H b ∧ b G a`。函数的
   图像 `Γ(f) = {(a, f a)}` 嵌进 Rel 且 `Γ(g∘f) = Γ(g)∘Γ(f)`。
4. **对偶对**：箭头是一对函数 `(f, φ)`，f 顺结构走、φ 逆
   索引走（1.3.3/1.3.4）——这正是**预层**的方向（见 1.9 节）。

幺半群当单对象范畴（1.3 节开头）已经打破了「箭头 = 函数」的
迷信：`Hom * * = ℕ` 里没有函数。反过来，1.2.5 指出任何范畴
的 `C[A,A]`（A 的自态射集）配复合与恒等就是一个幺半群——
**范畴是「许多幺半群共享的骨架」**。

## 1.8 万有起点：Pno 的第一定理

结构集配方造出范畴只是热身；Simmons 1.2.1(c) 给出 Pno 的
第一条真定理：`(ℕ, 0, S)` 是**万有起点**——从它到任何
`(B, b, β)` 的箭头存在且唯一。机器版：

```coq
Definition natPno : PnoAlg := mkPno (0 : nat) S.

Fixpoint piter (B : PnoAlg) (r : nat) : pcarr B :=
  match r with
  | O => pstart B
  | S m => pstep B (piter B m)
  end.

Lemma pno_arr_unique (B : PnoAlg) (f : PnoArr natPno B) :
  forall r, pfun f r = piter B r.
Proof.
  induction r as [|m IH]; simpl.
  - apply (pkeep1 f).
  - simpl. rewrite <- IH. apply (pkeep2 f m).
Qed.
```

两行归纳：`r = 0` 用保点、`r = S m` 用保步。`Print Assumptions`
报 `Closed under the global context`——**零公理**。演示：
取 `B = (bool, true, not)`，唯一箭头是 `r ↦ not^r(true)`，
`pfun theArr 3 = false` 由 `eq_refl` 直接算出。

这句话翻译成范畴语言就是「`(ℕ,0,S)` 是 Pno 的**初始对象**」
（04 章正式定义），而「存在且唯一」的形状则是 17 章**自由/
万有构造**的雏形：一个由泛性质确定的箭头，结构自动继承。

## 1.9 预层一瞥：把「索引化家族」当对象

Simmons 1.4 展示了更高级的配方：对象不再是单个结构集，而是
**按预序 S 索引的集合族** `A(i)`，配上连接函数
`A(j,i) : A(i) → A(j)`（j ≤ i 时），满足相容性。这正是
**S 上的预层**(presheaf)，即函子 `S^op → Set`。箭头
`(fᵢ)ᵢ` 逐分量保结构；复合也逐分量：

```text
A(i) --f_i--> B(i) --g_i--> C(i)     每个索引一层函数
 |            |            |         三个交换方块追一追
 A(j) --f_j--> B(j) --g_j--> C(j)    就知道 (g∘f) 也相容
```

书里那句俏皮话值得引用：*如果我们总得摊开对象内部的细节，
有些计算会变成灾难；把零件藏起来，图景反而清楚*。同节的
金句观察：**链复形就是把 ℤ 当索引预序的一种特殊预层**
——差分算子是连接函数，`m + 2 ≤ n` 时 `Aₙ → Aₘ` 为零。
拓扑学里满地链复形，范畴论一眼看出它们是同一个配方的
实例。28 章（层）会把这条线走到底：层 = 满足粘合条件的
预层。

## 坑位速记

1. Coq record 字段值要**连隐式 binder 一起绑定**：`comp` 的提供项
   是 `fun _ _ _ f g => ...`（5 个 binder）、assoc 是 7 个。
2. Coq 宇宙实例注解不支持代数层（`Category@{Set+1, Set}` 报语法
   错）——去掉注解让推断自己选。
3. 本机 coqc 无 `Coq.Fin`——自造 `fin`（4 行）。
4. Lean `/-!` 模块文档注释的**内容不能以 `-` 开头**：4.25 扫描器
   把 `/-! -- x -/` 误判 unterminated comment（`/-.` 无此问题）。
5. Lean 数字字面量在结构投影下推不出 OfNat：
   `NatCat.comp ... 2 3` 要写 `(2 : Nat)`。
6. Agda `record {...}` 字面量不能挂 `where`；多个例子各自
   `open Category X` 会撞名——包 `module XxxDemo` 隔离。
7. Coq 带参数 Record 的构造子/投影默认**不隐化参数**——
   `mkPnoArr (fun x => x) eq_refl ...` 会把函数塞进 A 槽。
   Pno 段用 `Set Implicit Arguments` 解决，代价：`mkPno` 的
   首字段也被隐化，`natPno` 要写 `mkPno (0 : nat) S` 让推断
   自定 `pcarr`。
8. `f_equal` 的目标数要看清：函数字段被 η 自动关掉时只剩两个
   bullet，错位一层会把错报在下一个字段上。
9. 依赖函数字段（`forall x, ... = ...`）的外延要 `funext_dep`
   ——普通版 `funext` 的 `A -> B` 模式统一不了依赖 pi。
10. Lean 数字字面量落在「结构投影类型」上（`NatPno.carr`）时
    TC 实例合成不展开投影——写 `(3 : Nat)` 显式钉住再靠统一。
11. Agda 的 `Level.suc` 与 `Data.Nat.suc` 同名相冲：顶层
    `renaming (suc to lsuc)`（03 章同款），或模块内局部开
    `Data.Nat`；where 块看不见子句隐式，证明内联进字段最稳。

---

下一章：[03 反范畴与对偶原理](02-opposite.md)
