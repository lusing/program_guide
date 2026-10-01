# 07 依赖类型（λP）：类型里出现项

> 对应读本：TTAFP 第 5 章（Types dependent on terms）；
> 《现代类型论的发展与应用》6.2（逻辑框架 LF）。
> 代码：`examples/07_dependent/`——三家原生实现同一组依赖类型
> 件套：索引族 `Vec`、谓词 `Even`、Π 定理 `∀ n, Even (n+n)`。

## 7.1 最后一块拼图：B → Π

λ→ 的箭头 `A → B` 有个隐含限制：`B` 不能提到参数。System F 打开了
「类型依赖类型」的一扇门（∀X）；λP 打开的是更关键的一扇——
**类型可以依赖项**。箭头推广为依赖函数类型：

```text
Π (x : A). B(x)        —— B 里可以出现 x
```

新的形成规则（「弱 Π」）：

```text
(formation)   Γ ⊢ A : s₁      Γ, x:A ⊢ B : s₂
              ────────────────────────────────
              Γ ⊢ Π(x:A). B : s₂
```

当 `B` 不含 `x` 时，`Π(x:A). B` 就是 `A → B`——箭头成了 Π 的糖。
判断形式也随之升级：类型不再只有 `A : *`，还允许 `A : □` 之类的
层阶（8 章 PTS 统一处理）。三家的写法对照：

```lean
def vappend : {n m : _} → Vec α n → Vec α m → Vec α (m + n)
```
```coq
Fixpoint vappend {A} {n m} (xs : Vec A n) (ys : Vec A m) : Vec A (n + m)
```
```agda
_++_ : ∀ {n m}{A : Set} → Vec A n → Vec A m → Vec A (n + m)
```

**`vappend` 的类型就是定理陈述**：拼接结果的长度是两段之和。
这不是注释，是机器检查的事实。

## 7.2 索引族：把不变量写进类型

`Vec α n`（长度为 n 的向量）是「类型依赖项」的标准样张：

```lean
inductive Vec (α : Type) : Nat → Type where
  | nil : Vec α 0
  | cons : {n : _} → α → Vec α n → Vec α (n + 1)
```

`Nat` 是**项的世界**，却坐在类型的参数位上。两个直接后果：

1. **`vhead : Vec α (n+1) → α` 只收非空向量**。空表取头不是
   运行时异常、不是 `Option`、不是 `null`——是**语法上写不出来**
   （`nil : Vec α 0` 与 `Vec α (n+1)` 无法统一）。三家文件都把
   这行「不存在的代码」留在注释里供瞻仰。
2. **拼接的长度算术由类型检查器执行**：
   `vappend (vreplicate 2 x) (vreplicate 3 x) : Vec α 5`——
   `2 + 3` 或 `3 + 2` 在类型检查时被算掉。三家测试全部
   `rfl`/`reflexivity`/`refl` 过关。

这套设计哲学叫 **intrinsic（内在式）**：不变量长在类型里，
非法状态不可表示（03 章的「ω 无法表示」是它的逻辑面，这里是
工程面）。与之相对的 extrinsic 风格（先写 `List α` 再配
`length xs = n` 的证明）在 16 章子集类型处对照。

## 7.3 谓词即类型：一阶逻辑落地

λP 上的 Curry–Howard 从**命题逻辑**升到**一阶谓词逻辑**：

| 一阶逻辑 | λP |
|---|---|
| 论域 `A` 上的谓词 `P(x)` | 函数 `P : A → Prop`（谓词是类型上的函数） |
| 全称 `∀x:A. P(x)` | `Π(x:A). P x` |
| 证据/证明 | `P x` 的居留项 |
| 谓词逻辑规则 | Π 的引入/消去（还是 03 章那两条！） |

```lean
inductive Even : Nat → Prop where
  | z : Even 0
  | ss {n : _} : Even n → Even (n.succ.succ)

theorem even_double : ∀ n : Nat, Even (n + n) := by
  intro n
  induction n with
  | zero => exact .z
  | succ n ih =>
      have key : (n + 1) + (n + 1) = (n + n) + 2 := by omega
      rw [key]
      exact .ss ih
```

Coq / Agda 版逐行同构（`even_double`）。注意三家证明里那个
`key`/`rewrite`/`+-suc` 的动作——它缝的是**定义相等的缝隙**，
这正是下一节的主角。

## 7.4 加法递归的方向：三家的 defeq 性格

同一条 `even_double` 定理，三家的「缝」位置不同，因为**加法
定义在哪个参数上递归，哪一侧的折叠就是免费的**：

| | `_+_` 递归侧 | 免费折叠 | 要 rewrite 的式子 |
|---|---|---|---|
| Coq / Agda | 第一参数 | `2 + n ≡ S (S n)`、`0 + n ≡ n` | `n + S n = S (n + n)`（用 `+-suc`/`lia`） |
| Lean 4 | 第二参数 | `n + 2 ≡ n+2 折叠`、`m + 0 ≡ m` | `(n+1) + (n+1) = (n+n) + 2`（用 `omega`） |

本章实测里每家都撞过一次：

- Lean 的 `vappend` 若写成 `Vec α (n + m)`，`nil` 分支的
  `0 + m` 不折叠（m 是变量、递归在另一侧）——换成 `m + n`
  朝向后两个分支全程 `rfl`；
- Coq 的 `ss_even` 写 `n + 2` 时 `apply even_ss` 对不上——
  改 `2 + n` 即刻折叠；
- Agda 的 `even-ss` 同病同药。

这不是三家实现得不好，是**定义相等是算法**（whnf 沿定义展开），
而加法只在一侧定义。写依赖类型程序的第一课就是跟 defeq 的
方向感和睦相处：**能选朝向时选递归侧，选不了就用引理搬运**
（`Nat.zero_add`、`+-suc`、`lia`/`omega` 都是搬运工）。

## 7.5 λP 的两个方向：一阶逻辑与 LF

λP 依用途有两个名字：

1. **作为逻辑**：λP = 一阶（其实是高阶）直觉主义逻辑的证明项
   语言。TTAFP 第 5 章用它推出「谓词逻辑 ↔ λP」的完整对应。
2. **作为框架**：Harper–Huet–Plotkin 的 **LF（逻辑框架）** 用 λP
   的一个受限变体（无 Π 类型的层阶交叉）做「描述其他演绎系统」
   的元语言：对象逻辑的公式、证明都是 LF 的项。《现代类型论的
   发展与应用》6.2 用 LF 反过来定义类型论自身（判断规则作为
   LF 声明）——自举的味道。第 24 章元理论会再遇到它。

## 7.6 还差什么：λC

λP 的类型里能有项，但**类型抽象**（System F 的 ∀）没有；
反过来 F 有类型抽象但类型里不能有项。把两者同时打开——
类型里既有项又有类型变量——就是 Barendregt 立方体的顶点
λC（Calculus of Constructions）。Coq 的内核是 λC + 归纳类型
（CIC），Lean 同宗，Agda 则走 MLTT 一系（不用 λC 的非直谓
宇宙）。下一章把立方体补完整。

> **坑位速记**
> ① Lean 依赖匹配要把**长度索引写进模式**（`| 0, _, nil, ys`），
> 全通配会导致结果类型里的元变量解不开；
> ② Lean 构造子模式要 `open Vec`（或写全 `Vec.cons`），否则
> 解析到别的命名空间；
> ③ **方向学三连**（本章三家各撞一次）：Coq/Agda 加法递归在
> 第一参数（`2+n` 折叠），Lean 在第二参数（`n+2`、`m+0` 折叠）；
> 类型里的算术选错朝向就 rewrite；
> ④ Agda 字符/字符串字面量需要 BUILTIN 绑定——独立小文件里
> 用 ℕ 当元素最省事；
> ⑤ Agda 自定义中缀**模式**里同级运算符要显式括号：
> `(x ∷ xs) ++ ys`，裸写 `x ∷ xs ++ ys` 模式解析直接失败；
> ⑥ Coq `Check f : T` 对带隐式参数的 f 要用 `@f`；
> ⑦ Lean `_++_` 这类 def 里的 `·` 记号要括号包裹。
