# 13 · 归纳证明

前十二章我们造好了所有零件：等式 `≡`（11 章）、连接词（12 章）、
模式匹配与结构递归（6/7 章）。本章把它们拧成一股绳：**用递归函数写
归纳证明**。这是全教程的巅峰章——Agda 里没有 `induction` 战术，
「归纳」就是一枚长得像普通函数的东西：基例是 `zero` 分支，步例是
`suc` 分支，**归纳假设就是递归调用的返回值**。Coq 用户要先学战术再
理解原理，Agda 用户反过来：先写出函数，原理自动成立。

对应示例：`../examples/Ex13_induction.agda`

本章报错文本均为 Agda 2.8.0 + stdlib 2.3 实测原样粘贴（复现用的临时
文件已删除，报错路径显示为当时的临时路径）；代码片段与示例一致。

## 13.1 为什么「显然」不够：n + 0 ≡ n 算不动

`3 + 0 ≡ 3` 是「算出来」的——示例里一行 `refl` 收工：

```agda
3+0≡3 : 3 + zero ≡ 3     -- ≡ 是 11 章的命题等式；zero/suc 即 0/s 的 Unicode 写法
3+0≡3 = refl
```

但通版 `n + 0 ≡ n` 立刻碰壁。`_+_` 定义在第一个参数上递归
（`zero + m = m`；`suc n + m = suc (n + m)`）：左边是变量 `n` 时
**没有任何规则可套**，`n + zero` 是卡住的正规式。硬交 `refl`：

```text
/home/xulun/code/programming/agda/examples/TmpProbe.agda:8.12-16: error: [UnequalTerms]
_x_7 ≡ _x_7 !=< (n : ℕ) → n + zero ≡ n
when checking that the expression refl has type
(n : ℕ) → n + zero ≡ n
```

报错翻译：`refl` 只能证「两边算到同形」的等式，而
`(n : ℕ) → n + zero ≡ n` 是个函数类型，连等式都算不上。
「n + 0 = n 显然」依赖的是**算术知识（归纳），不是符号计算**——
所以必须对 n 归纳。

## 13.2 归纳 = 依赖消除：recursor 视角

把「对 n 归纳」说人话，就是下面这枚两行的递归函数：

```agda
ℕ-ind : (P : ℕ → Set) → P zero → (∀ n → P n → P (suc n)) → (n : ℕ) → P n
ℕ-ind P base step zero    = base
ℕ-ind P base step (suc n) = step n (ℕ-ind P base step n)
```

对照教科书归纳法：要证「∀n. P(n)」，只需 ①P(0)；②∀n. P(n)⇒P(suc n)。
**一模一样**。差别在三处：

1. `P` 的类型是 `ℕ → Set`——它吃一个数吐一个命题（类型）。这就是
   「依赖消除」：eliminator 的目标类型随被消除的值而变（10 章 Fin
   的老话题，现在露出獠牙的是证明本身）。
2. 步例参数 `∀ n → P n → P (suc n)` 里那个 `P n` 就是归纳假设（IH）。
   在 `ℕ-ind` 的实现里，它是递归调用 `ℕ-ind P base step n` 的返回值——
   **递归即 IH，终止检查替你担保归纳的良基性**。
3. Agda **不会**像 Coq 那样自动为每个 `data` 生成 `nat_ind` 再交给
   战术用；recursor 要么自己写（如上，2 行），要么干脆不写——
   直接模式匹配，效果相同（见 13.3）。

「证明 ∀n. P n = 给 base 和 step」在这成了字面事实：`ℕ-ind` 就是个
柯里化的构造函数。用匿名 λ 造出命题族 `P`，交换律的引理可以这样交：

```agda
+-idʳ-via-ind : (n : ℕ) → n + zero ≡ n
+-idʳ-via-ind = ℕ-ind (λ n → n + zero ≡ n) refl (λ n ih → cong suc ih)
```

`λ n → n + zero ≡ n` 把「带洞的命题」当值传参——这在 Coq 里对应
`induction n; intros` 之前的那步 `P` 抽象，Agda 里是平凡的函数应用。

## 13.3 归纳剧本的 Agda 真身

实战不写 `ℕ-ind`，直接递归。完整批注版（示例中的 `+-idʳ-annotated`）：

```agda
+-idʳ : (n : ℕ) → n + zero ≡ n          -- 要证 ∀ n → P n，P := λ n → n + zero ≡ n
+-idʳ zero    = refl                    -- 基例：0 + 0 → 0，两侧同形，算出来
+-idʳ (suc n) = cong suc (+-idʳ n)      -- 步例：目标 suc n + 0 ≡ suc n
                                        -- 化简后 suc (n+0) ≡ suc n，
                                        -- cong suc 把 IH（递归调用）抬进 suc
```

逐行读法：

* **签名即命题**。`+-idʳ` 的类型 `∀ n → n + zero ≡ n` 就是定理全文；
  函数体就是证明。没有 tactic script，没有 proof term 两层皮——
  「程序即证明」在 Agda 里是同一行代码。
* **分支即情形**。`zero` 分支是基例，`suc n` 分支是步例；
  模式变元 `n` 是步例里「小的那个 n」。
* **递归调用即 IH**。类型检查器对 `suc n` 分支的要求是
  `P (suc n)`；你交回 `cong suc (+-idʳ n)`，它反过来要求
  `P n`——**这个新要求就是归纳假设**，由递归调用应答。
  终止检查保证你只能对**严格变小**的 `n` 用这招，所以 IH 不会循环论证。

`cong`（congruence，同余）：`cong f p : x ≡ y → f x ≡ f y`——
等式可以塞进任何函数上下文。`cong suc ih` 就是「对 IH 两边同加一个 S」。

**归纳假设的类型怎么看**：想知道 IH 长什么样，看递归调用被要求的类型。
`+-idʳ (suc n) = cong suc (HERE)`，类型检查器把 HERE 的期望类型定为
`n + zero ≡ n`——IH 不是玄学，是**函数签名的自我实例化**。
递归调用的参数表里传了什么，IH 就只谈什么；这直接引出本章核心手艺：

## 13.4 generalize 的手艺

### 13.4.1 翻车现场：IH 太弱

热身定理 `∀ n → n + n + 0 ≡ n + n`。照剧本对 n 归纳：

```agda
n+n+0-ind : ∀ n → n + n + zero ≡ n + n
n+n+0-ind zero    = refl
n+n+0-ind (suc n) rewrite +-idʳ (n + suc n) = refl   -- ← 修复版（示例）
```

若按直觉硬套「cong suc 递递归」：`n+n+0 (suc n) = cong suc (n+n+0 n)`，
实测报错：

```text
/home/xulun/code/programming/agda/examples/TmpProbe.agda:9.32-44: error: [UnequalTerms]
n != suc n of type ℕ
when checking that the expression self-stuck n has type
n + suc n + zero ≡ n + suc n
```

账目：`suc n + suc n + zero` 化简后是 `suc (suc (n + n) + zero)`，
`cong suc` 需要的 IH 是 `(n + suc n) + zero ≡ n + suc n`，
而递归调用只能给 `n + n + zero ≡ n + n`——**IH 谈的是 n+n，
目标谈的是 n + suc n，对不上**。这就是 Coq 教程里
「intros 太多、归纳前没 generalize」的同款病，Agda 的病根：
**递归调用的参数表（= IH 的谈话范围）比目标窄**。

### 13.4.2 正解：generalize 在 Agda = 函数应用

`n + suc n + 0 ≡ n + suc n` 眼熟吗？它就是 `∀ k → k + zero ≡ k`
在 `k := n + suc n` 的实例！一旦证过通用引理 `+-idʳ`，
整个定理连归纳都不用：

```agda
n+n+0 : ∀ n → n + n + zero ≡ n + n
n+n+0 n = +-idʳ (n + n)        -- 通用引理直接实例到复合项
```

这是 Agda 相对 Coq 最痛快的一点：Coq 的归纳原理对命题宇宙封闭，
IH 不能随便实例到新项上，所以要 `generalize`/`revert` 手术；
Agda 的「引理」就是一切归一化的函数，**`+-idʳ (n + suc n)` 就是
generalize——把复合项当参数递进去，∀ 自动应答**。修复版步例里的
`rewrite +-idʳ (n + suc n)` 是同一手艺的 rewrite 皮。

三种笔法在示例里并排放着，任选：

```agda
-- 两参数并列进递归（最常用）
+-0-absorb : (n : ℕ) (m : ℕ) → (n + zero) + m ≡ n + m
+-0-absorb zero    m = refl
+-0-absorb (suc n) m = cong suc (+-0-absorb n m)

-- where 内层函数，m 被外层子句固化（实测：where 左端能引用子句模式变量）
+-0-absorb′ : (n : ℕ) (m : ℕ) → (n + zero) + m ≡ n + m
+-0-absorb′ n m = go n
  where
  go : (k : ℕ) → (k + zero) + m ≡ k + m   -- IH 只对这个 m 说话（够用才这么写）
  go zero    = refl
  go (suc k) = cong suc (go k)

-- 匿名 λ/∀ 把 m 拉回归纳范围——「制造 ∀ 假设」的 Agda 形态
+-0-absorb″ : (n : ℕ) (m : ℕ) → (n + zero) + m ≡ n + m
+-0-absorb″ n = go n
  where
  go : (k : ℕ) → (o : ℕ) → (k + zero) + o ≡ k + o
  go zero    o = refl
  go (suc k) o rewrite go k o = refl
```

口诀与 Coq 版同义：**要被归纳的变量放最后进参数表，
可能被实例化的项保持为 ∀**。区别只在 Agda 里这是免费的——
函数类型谁都会写。

### 13.4.3 with 技巧：复合子项提出来

想把 `n + m` 整体当归纳对象/rewrite 靶子时，`with` 就是 Coq 的
`generalize (n + m)` / `remember`：

```agda
n+n+0-with : ∀ n m → (n + m) + zero ≡ n + m
n+n+0-with n m with n + m
... | k = +-idʳ k
```

`with n + m` 把目标里所有 `n + m` 出现替换成新变量 `k`，随后
`+-idʳ k` 一击致命。不 with 也行（`rewrite +-idʳ (n + m) = refl`），
with 的价值在**报错信息里只谈 k**，目标更干净。

### 13.4.4 方向感：rewrite 吃等式的方向

拿着 `n ≡ n + zero`（方向反的引理）去 rewrite，实测翻车：

```text
/home/xulun/code/programming/agda/examples/TmpProbe.agda:13.32-36: error: [UnequalTerms]
n + 0 != n of type ℕ
when checking that the expression refl has type
suc (n + 0 + 0) ≡ suc (n + 0)
```

rewrite 按等式**从左往右**替换：`n ≡ n + zero` 把目标里所有裸 `n`
膨胀成 `n + zero`——火上浇油，越写越长。正解两条：
先证标准方向（`n + zero ≡ n`）；或现场 `sym` 摆正：

```agda
back-to-right : ∀ n → n + zero ≡ n
back-to-right n = sym (flip-direction n)   -- flip-direction : ∀ n → n ≡ n + zero
```

**判断法：想消灭的模式放等式左边。** 这与 12/11 章反复强调的
「等式是有方向的程序」一脉相承。

## 13.5 交换律：双引理套路

`+-comm : m + n ≡ n + m` 对 m 归纳。基例：`zero + n ≡ n + zero`，
左边算成 `n`，右边卡住的还是 `n + zero`——需要 `+-idʳ` 出马：
`rewrite +-idʳ n` 正方向把 RHS 的 `n + 0` 消掉即 `refl`
（stdlib 项模式写法没有 rewrite，改用 `sym (+-identityʳ n)`，13.8 见源码——
同一个 Coq 教程 `plus_n_O` 的故事）。步例：IH 给 `m + n ≡ n + m`，
目标 `suc m + n ≡ n + suc m` 化简成 `suc (m + n) ≡ n + suc m`——
用 IH 后剩 `suc (n + m) ≡ n + suc m`：**S 卡在 + 左边，要挪到右边**，
一枚新引理伺候：

```agda
+-suc : (m n : ℕ) → m + suc n ≡ suc (m + n)
+-suc zero    n = refl
+-suc (suc m) n rewrite +-suc m n = refl

+-comm : (m n : ℕ) → m + n ≡ n + m
+-comm zero    n rewrite +-idʳ n = refl
+-comm (suc m) n rewrite +-comm m n | +-suc n m = refl
```

`rewrite a | b` 连割两刀：第一刀用 IH 把 `m + n` 换成 `n + m`，
第二刀用 `+-suc n m` 把右边 `n + suc m` 折回 `suc (n + m)`（刀刀
都是「从左往右」）。双引理套路是归纳证明里最高频的「卡住 →
发现缺引理 → 引理本身又是归纳」的递归：缺的几乎都是
**把构造子/运算符搬运过另一个运算符**的搬运工（对照 Coq 的
`plus_n_Sm`，stdlib 实名 `+-suc`）。

## 13.6 结合律与归纳变元的选择

```agda
+-assoc : (m n o : ℕ) → (m + n) + o ≡ m + (n + o)
+-assoc zero    n o = refl
+-assoc (suc m) n o rewrite +-assoc m n o = refl
```

选错归纳变元立刻卡死。对 `o` 归纳，基例是

```agda
assoc-wrong : (m n o : ℕ) → (m + n) + o ≡ m + (n + o)
assoc-wrong m n zero    = refl        -- ← 这行编译不过
assoc-wrong m n (suc o) = cong suc (assoc-wrong m n o)
```

```text
/home/xulun/code/programming/agda/examples/TmpProbe.agda:8.27-31: error: [UnequalTerms]
m + n != m of type ℕ
when checking that the expression refl has type
m + n + zero ≡ m + (n + zero)
```

两侧都卡在「变量 + 0」上（而且卡的还不止一处），`refl` 无能为力。
**「证明的难度分布由定义的形状决定」**：`_+_` 在第一个参数上递归，
所以归纳要选出现在**最左激活位**的那个变量。拿不准就查定义：
`_+_ zero _ = ...` 动谁，就对谁归纳。

## 13.7 列表归纳：同一剧本换布景

List 的 recursor 与 `ℕ-ind` 只差构造子签名（`[]` 与 `x ∷ _`），
剧本零改动。右单位元（`_++_` 在左参数上递归，`xs ++ []` 卡住）：

```agda
++-nil : ∀ {A : Set} (xs : List A) → xs ++ [] ≡ xs
++-nil []       = refl
++-nil (x ∷ xs) rewrite ++-nil xs = refl
```

`++-assoc′` 逐字同构，不贴了。重头戏是 **rev-rev**——直接归纳证不动，
需要**强化引理**（把「累加器」泛化进命题）：

```agda
rev : ∀ {A : Set} → List A → List A
rev []       = []
rev (x ∷ xs) = rev xs ++ [ x ]

-- 强化引理：rev 是 ++ 的反同态（ys 泛化在参数表——generalize！）
rev-++ : ∀ {A : Set} (xs ys : List A) →
         rev (xs ++ ys) ≡ rev ys ++ rev xs
rev-++ []       ys rewrite ++-nil (rev ys) = refl
rev-++ (x ∷ xs) ys
  rewrite rev-++ xs ys | ++-assoc′ (rev ys) (rev xs) [ x ] = refl

rev-rev : ∀ {A : Set} (xs : List A) → rev (rev xs) ≡ xs
rev-rev []       = refl
rev-rev (x ∷ xs)
  rewrite rev-++ (rev xs) [ x ] | rev-rev xs = refl
```

逐处点评：

* **基例**：`rev ys ≡ rev ys ++ []`——泛化引理 `++-nil` 实例到复合项
  `rev ys`（generalize 又一次以函数应用的身份出现）。
* **步例**：IH `rev-++ xs ys` 把 `rev (xs ++ ys)` 翻面，`++-assoc′`
  把括号挪到位。两刀的顺序不能反（第二刀作用于第一刀的产物）。
* **rev-rev 的步例**是「强化引理」的意义所在：单独对 xs 归纳，
  步例得到 `rev (rev xs ++ [ x ]) ≡ x ∷ xs`，`rev` 里套 `++` 再套
  `rev`——没有反同态引理，这题在归纳假设层面就是死局。
  强化命题的通用招法：**给归纳加一个「累加」参数**（这里是 `ys`），
  证更泛的定理，再实例回目标。stdlib 走得更远：`reverse` 干脆
  用累加器函数 `_ʳ++_` 定义（`Data/List/Base.agda`），反同态引理
  就近水楼台。
* `[ x ]` 是**单元素表记法**，要在 import 的 `using` 里带上 `[_]`，
  否则实测 `Not in scope: [`（列表字面量 `[1,2,3]` 则是 2.8 根本没有，
  08 章老坑）。

## 13.8 stdlib 对照：证明一次，读库百遍

本章引理在 stdlib 里全部同名正品（位置：`Data.Nat.Properties`、
`Data.List.Properties`）。stdlib 的源码节选（真实文本）：

```agda
+-identityˡ : LeftIdentity 0 _+_
+-identityˡ _ = refl
+-identityʳ : RightIdentity 0 _+_
+-identityʳ zero    = refl
+-identityʳ (suc n) = cong suc (+-identityʳ n)

+-comm : Commutative _+_
+-comm zero    n = sym (+-identityʳ n)
+-comm (suc m) n = begin-equality    -- begin-equality 是 14 章推理链的主角
```

命名规律值得背下来：

| 本章 | stdlib | 读法 |
|---|---|---|
| `+-idʳ` | `+-identityʳ` | 上标 ˡ/ʳ = 「特殊的一侧」：ʳ 说 `x + 0`，ˡ 说 `0 + x` |
| `+-suc` | `+-suc` | 同名；读作「S 可以穿过 + 挪到右边」 |
| `+-assoc` | `+-assoc` | 同 |
| `++-nil` | `++-identityʳ` | 列表右单位元 |
| `rev-++` | `reverse-++` | 反同态 |
| `rev-rev` | `reverse-involutive` | 对合 |

`LeftIdentity 0 _+_` 这类是 `Algebra.Definitions` 里的**记号类型**，
展开就是 `∀ x → 0 + x ≡ x`。示例第 7 节做了双向验真：把 stdlib
引理原样转写成本章签名（`check-ʳ = std-+-identityʳ` 等六条），
类型检查全过——**同型同证**。以后在库里撞见 `sym` 过、`mono` 过、
带 ˡ/ʳ 上标的名字，八成就是你这页笔记的印刷版。

## 13.9 坑位清单（本项目实测）

1. **通式 `n + 0 ≡ n` 不是计算**：`refl` 报 `[_x_7 ≡ _x_7 !=< ...]`
   （见 13.1）——函数类型不是等式；实例化变量归纳才是正道。
2. **归纳变元选错全盘卡住**：对 o 归纳证结合律，基例两侧都卡在
   `… + zero`，报错 `m + n != m of type ℕ`（13.6）——跟着定义的
   递归方向选归纳变元。
3. **IH 太弱是「缺 generalize」**：`cong suc (self-stuck n)` 撞上
   `n != suc n`（13.4.1）。Agda 的解法：把引理证成 ∀ 函数，
   **实例到复合项**（`+-idʳ (n + n)`）；或把参数拉回递归调用的参数表。
4. **rewrite 只按左→右替换**：拿 `n ≡ n + 0` 去 rewrite 会把所有裸
   `n` 膨胀成 `n + 0`（报错 `suc (n + 0 + 0) ≡ suc (n + 0)`）——
   先 `sym` 摆正方向，或证引理时就把「想消灭的模式」放左边。
5. **where 子句名在 `rewrite` 里不可用**：实测 `Not in scope`——
   where 的类型左端**可以**引用子句模式变量 m，但 `rewrite` 属于
   左端部分，先于 where 作用域解析；把引理提到顶层或改在 RHS 用。
6. **`using (reverse) renaming (reverse to x)` 非法**：同名列于
   `using` 又 `renaming` 报 `RepeatedNamesInImportDirective`——
   改名导入时只写 `renaming`。
7. **`[ x ]` 记法要 import `[_]`**：`Data.List` 里它是定义
   （`[ x ] = x ∷ []`），`using` 漏了就是 NotInScope。
8. **`rewrite a | b` 有序**：第二刀作用在第一刀改写后的目标上
   （rev-++ 步例）；顺序反了匹配不到。
9. **stdlib 的 `+-monoˡ-≤` 名字反直觉**：ˡ/ʳ 标的是「**变化的一侧**是
   第几个参数」还是「参数在哪一侧」各家不一，实测
   `+-monoˡ-≤ c p : a + c ≤ b + c`（c 钉在**右侧**）——用前 `:Check`。

---
上一章：[12 · 逻辑连接词](12-logic.md) ｜ 下一章：[14 · 推理框架](14-reasoning.md) ｜ 返回：[README](../README.md)
