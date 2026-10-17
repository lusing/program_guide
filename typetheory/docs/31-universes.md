# 31 全域与类型层级

> 对应读本：Nordström 第 14 章（小集合之集合 U：形式规则、
> Peano 第四公设、独立性、消去子 urec）+ Girard 悖论；
> 《现代类型论的发展与应用》2.4（类型空间）。
> 代码：`examples/31_universes/`——三家宇宙机制对照 + U 编码
> 雏形与 Peano 4 的 Agda 机器件。

## 31.1 为什么要宇宙

「类型的类型」若是一个类型 `Type : Type`，Girard（1972）证明可以
在 System U 里复刻 Russell 悖论——系统不一致。解法是**层级塔**：

```text
Prop = Sort 0     Type 0 = Sort 1     Type 1 = Sort 2     …
Type u : Type (u+1)          ——只许上楼，不许自环
```

Nordström 第 14 章的「第一全域 U」是同一思想的直谓版：把小集合
（Π、Σ、枚举、ℕ…的封闭）收进一个类型 U，U 本身住上层。书里
点明 U 的三个用途：**表达递归/条件式命题的规格说明**、**证明
不等式**（Peano 第四公设）、**定义抽象数据类型**（38 章）。

## 31.2 U 的构造：编码与解码八组

书 14.1 的方案是**塔斯基式**：U 的典则元是集合的**编码**，
解码函数 `Set(x)` 把编码还原成集合。每个成集运算一对规则
（U-引入给编码、Set-引入给解码）：

```text
U-引入 1   {i₁,…,iₙ} ∈ U          Set({i,…}) = {i,…}
U-引入 2   N ∈ U                   Set(N) = N
U-引入 3   A ∈ U ⟹ List(A) ∈ U    Set(List A) = List(Set A)
U-引入 4   A ∈ U, a,b ∈ Set(A) ⟹ îd(A,a,b) ∈ U
U-引入 5   A,B ∈ U ⟹ A+B ∈ U
U-引入 6   A ∈ U, B(x)∈U[x∈Set(A)] ⟹ π(A,B) ∈ U
U-引入 7   … Σ 编码                U-引入 8   … W 编码
```

53 章（UTT）的 `U₀`+解码、Agda 的 `Set ℓ` 内建、Coq/Lean 的
`Type@{i}`/`Sort u` 都是这个方案的后裔。**编码与解码的分层**
不是花招而是命门：书 14.1 末给出一个组合逻辑式自应用的现场
——若允许把「任意集合」当作 U 的元素不加节制，`λx.apply(x,x)`
形的表达式可以在 `{} → N` 里取得居留项而**内部不终止**
（它化归到自身）——Type:Type 病的 U 版预演。分层塔把它挡在
门外。

## 31.3 Peano 第四公设：U 的第一份红利

30 章留下的悬念在这里兑现。要证 `0 ≠ₙ succ(n)`，即构造

```text
peano4 ∈ Id(N, 0, succ(n)) → {}
```

思路：造一个**仅对 0 为真的谓词**，在 0 处解码出 ⊤、在
succ 处解码出 ⊥，然后 subst 搬运 tt：

```text
Is-zero(m) ≜ Set(natrec(m, ⊤̂, (y,z){}))
Is-zero(0)     = Set(⊤̂)     = ⊤      （N-相等 1 + Set-引入）
Is-zero(succ n) = Set({})    = ⊥      （N-相等 2 + Set-引入）
x ∈ Id(N,0,succ n) ⟹ subst(x, tt) ∈ Is-zero(succ n) = ⊥
λ((x)subst(x,tt)) ∈ Id(N,0,succ n) → {}
```

**关键一步用 U 做了什么**：natrec 的动机族 C(y) 必须是一个
**集合族**——从 ℕ 到「集合的世界」的函数。没有 U，集合不是
某个类型的元素，natrec 够不着它们；有 U，`natrec(m,⊤̂,(y,z){})`
就是 U 的元素、经 Set 解码即谓词。Agda 件里这个证明完整
机器化（现代写法用 `ℕ → Set` 的族直接代替编码层）：

```agda
IsZero : ℕ → Set
IsZero zero    = ⊤
IsZero (suc _) = ⊥

peano4 : ∀ n → (zero ≡ suc n) → ⊥
peano4 n e = subst IsZero e tt    -- tt : IsZero zero 搬到 IsZero (suc n) = ⊥
```

四行，其中 subst 的搬运与书里的 subst(x,tt) 一字不差。

## 31.4 Smith 独立性定理：没有 U 就没有 Peano 4

更强的事实（书 14.1 末引 [101]）：**无全域的类型论推不出任何
不等式**。证明思路是把无全域理论解释进两元素论域——给每个
集合 A 配真值 p(A)，对推导长度归纳证明：

```text
p(⊤)=⊤   p({i,…})=⊤   p(N)=⊤   p(Id(A,a,b))=p(A)
p(A+B)=p(A)∨p(B)   p((Πx:A)B)=p(A)→p(B)
p((Σx:A)B)=p(A)∧p(B)   p((Wx:A)B)=p(A)∧p(B)   p({x∈A|B})=p(A)∧p(B)
```

于是「可推导 ⟹ p = ⊤」；而 `¬Id(A,a,b)` 的真值是
`p(A)→⊥`，两元素论域里总能选 p(A)=⊤ 使它为 ⊥——故
`¬Id(A,a,b)` 型命题（包括 Peano 4）**无全域不可导**。全域
不只是工程方便，它是**表达力的台阶**：有 U 才能区分 0 与
succ——这是「塔的代价换塔的能力」的最小例证。

## 31.5 urec：全域的消去子与枚举重构

U 的消去有个障碍：`{i₁,…,iₙ}` 的构造子个数不固定，归纳原理
陈述不出来。书 14.2 的解法是**重构成集运算系统**——只留两个
基本枚举 `⊥` 与 `⊤`，其余枚举由 `+` 迭代生成：

```text
N'(x) ≜ natrec(x, ⊥̂, (u,v)(⊤̂+v))     -- n 元枚举的编码函数
Set(N'(0)) = ⊥    Set(N'(1)) = ⊤+⊥    Set(N'(2)) = ⊤+(⊤+⊥) …
```

Martin-Löf 后来给出更直接的算子 `S(A)`（`⊤` 的后继枚举，
附 S-引入 0/s(a) 与 S-消去 scase）——现代 `Fin (suc n)` 的
前身。在重构后的 U 上，消去子 **urec** 有九个分支（⊥/⊤/N/
List/Id/+/Π/Σ/W 各一个），对编码 a 的典则形状分派——它就是
「按类型描述做结构归纳」的原始机器，现代对应物是 Agda 对
`data U` 自动生成的 `U-rec`、以及所有「依类型分派」的解码
函数。附录 A 里 urec 的相关度是全书最长的——九参选取子。

## 31.6 三家宇宙机制对照

现代三家把塔做成语法内建：

| | 宇宙语法 | 事实速览 |
|---|---|---|
| Coq | `Set` / `Type@{i}` / `Prop` | `Set ⊂ Type`（有 Cumulativity） |
| Lean | `Sort u`，`Prop = Sort 0` | **无** Cumulativity，`ULift` 升层 |
| Agda | `Set ℓ` + `Level` 代数 | 无 Cumulativity，`Lift` 升层，`ℓ ⊔ m` 上确界 |

Lean/Agda 没有 Cumulativity 是**实测**出来的（本章文件）：

```lean
#check (Nat : Type 5)
-- Type mismatch: Nat has type Type ... expected Type 5
#check (ULift.{1, 0} Nat : Type 1)   -- 官方升层器才行
```

Coq 则一路绿灯：`Check (nat : Type).`（Set 自动进 Type）。

宇宙多态让一份代码全层复用：

```lean
def myId.{u} {α : Sort u} (a : α) : α := a        -- Lean：隐式宇宙参数
```
```coq
Definition myId@{u} {A : Type@{u}} (a : A) : A := a.   -- Coq 8.20
```
```agda
myId : ∀ {ℓ} {A : Set ℓ} → A → A                   -- Agda：Level 参数
myId a = a
```

Agda 的 `Level` 是**代数**：双参数类型构造器住在
`Set (ℓ ⊔ m)`（上确界）。`Set₀` 上的东西要进 `Set₁`，用
`Lift`（Agda）/`ULift`（Lean）。「类型 + 居留项」是最小的
宇宙敏感结构（件里 `TyAndTerm` 三家对照）。

**UTT 读法与有界量化（53 章）**：本节的罗素式/塔斯基式
之争在罗朝晖书 2.4 有第三个答案——**塔斯基式 + 强制子
类型**（提升算子作强制转换）= 准确且好用；而「有界量化」
（∀X ≤ H）经**子类型空间 U(H)** 进入现代类型论时保持
可判定性——与 50 章 F<: 因 Top 不可判定恰成对照。

## 31.7 taut：全域定型的第二个用场

书 14.1 的另一个例子是 SASL 的**重言式函数**：判断 n 元布尔
函数是否永真——

```text
taut 0 f ≜ f
taut (n+1) f ≜ taut n (f true) and taut n (f false)
```

「多数带类型的语言里此定义导致类型错误」——taut 的参数 f
的**类型依赖 n**（n=1 时 Bool→Bool、n=2 时 Bool→Bool→Bool…），
固定类型的语言装不下。要给它定型，就要对 n 归纳地构造
类型 `Boolⁿ → Bool`——归纳地造类型需要「类型的集合」：
`(Πn∈N) U` 里定义 `τ(0)=Bool̂`、`τ(suc n)=Bool̂→τ(n)`，然后
`taut : (Πn∈N) τ(n) → Bool`。**类型依赖值、值的归纳产生
类型的归纳**——这正是 30 章归纳族的元层需求，也是 U 在
规格说明语言里的日常（39 章 FSET 的 mem 性质同理）。

本章三个数字值得带走：**八**组编码-解码规则（每个成集运算
一对）；**九**参的 urec（全书最长相关度——八大成集运算的
消去各占一参、加上目标主参）；**两**元素论域（Smith 独立性
定理的反模型——真值函数 p 只需 ⊤/⊥ 两个值就能吞掉全部
无全域推导的不等式）。

> **坑位速记**
> ① Lean 无 Cumulativity：`Nat : Type 5` 直接报错，升层用
>   `ULift`；Agda 同理用 `Lift`——写跨层代码前先想清楚；
> ② Lean 匿名构造器里第二字段类型由第一字段定时，数字要
>   手工标注 `(3 : Nat)`（OfNat 对投影类型 `natEx.A` 失明）；
> ③ Agda `field x : A` 后接**缩进续行**会 ParseError——多字段
>   用块形式（`field` 独占一行）或分号；
> ④ Agda 的 `Level.suc`/`Data.Nat.suc` 同名——import 时
>   `renaming (suc to lsuc)`，且 `using` 与 `renaming` 不能
>   同时圈住同一个名字；
> ⑤ Lean 的 doc 注释 `/-- -/` 挂在文件尾（后面无声明）会
>   让整个文件报 unexpected end of input；
> ⑥ Agda 证 peano4 用 `subst IsZero e tt`——谓词 IsZero 的
>   定义方向（zero→⊤、suc→⊥）与 subst 的搬运方向要配对，
>   写反则 tt 落在 ⊥ 侧直接类型错误。

---

上一章：[30 归纳族](30-indfam.md) · 下一章：[32 W 类型](32-wtypes.md)
