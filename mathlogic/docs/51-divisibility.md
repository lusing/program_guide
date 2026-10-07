# 第 51 章 整除性与初等数论

> 对书：Jongsma §3.5。本章通道：C（`examples/45_divisibility/ex51_divisibility.v`）/
> L（`examples/45_divisibility/ex51_divisibility.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `divides` 基本律 | 书 Prop 3.5.1（自反/传递/和差/倍数/线性组合） | C/L |
| `dm2` + `div_alg_unique` | 除法算式的存在（fuel 商余对）与唯一 | C/L |
| `egcdf`/`gcdn`/`bezout` | 扩展 Euclid：gcd 的整除刻画（Cor 3.5.3.2）+ Bézout 差形式（Thm 3.5.3） | C/L |
| `euclid_lemma`/`euclid_prime` | 广义 Euclid 引理（Thm 3.5.5）与素数版（VII.30） | C/L |
| `gcd_lcm_product` | gcd·lcm = a·b（Thm 3.5.4，见证式 lcm） | C/L |
| `prime_fac`/`inf_primes` | 素因子存在 + 素数无穷（Euclid 表外再造） | C/L |

Peano 算术立起了加、乘、≤；Jongsma 的 §3.5 在这套机器上开出第一片数学园地：整除。
整除本身只是乘法的一个存在命题（d ∣ n ⟺ ∃k, n = d·k），但围绕它长出的结构——
除法算式、最大公因数、Bézout 系数、Euclid 引理、最小公倍数——构成了初等数论的
骨架，也恰好是「证明助手检查数学」的最佳试金石：每个定理都要求把中学算术
直觉拆成可机械核对的步骤。书自带的整数工具（减法自由、负系数）机器上一概没有，
nat 的世界逼出本章反复出现的两个主题：**减法要加护栏**、**负系数要变形**。

## 一、整除基本律：Prop 3.5.1 的机器版

书 Prop 3.5.1 列了八条（1∣a、a∣0、自反、反对称、传递、和差封闭、倍数封闭、
线性组合封闭），每条都是两行证明。机器版的差异集中在减法：

```coq
Lemma div_sub : forall a b c, divides a b -> divides a c -> c <= b ->
  divides a (b - c).
```

nat 的减法是截断的：b − c 只有在 c ≤ b 时才是「真的减法」，所以这条引理必须
带护栏。证明本体反而是最轻的：设 b = a·k₁、c = a·k₂，见证 k₁ − k₂（此时
k₂ ≤ k₁ 可从 c ≤ b 推出）。Lean 侧同一引理多绕一步：`a * k1 = a * k2 + a * (k1 - k2)`
里的 `a * (k1 - k2)` 是 omega 拒绝的组合项（乘积里含减法），要先把 k₁ 写成
k₂ + (k₁ − k₂)、用 `Nat.mul_add` 展开成纯加法等式，omega 才能在原子层面接手。

## 二、除法算式：书推迟到 §6.4 的定理，机器现在就给

书 Thm 3.5.1（除法算式）：n 除以正数 d，得唯一商 q 与余数 r，n = qd + r 且
0 ≤ r < d。书说「将在 §6.4 证明」（要用整数）；机器用第 7 章以来的 fuel 手艺
现在就把它造出来——商和余数一起算的函数对：

```lean
def dm2 : Nat → Nat → Nat → Nat × Nat
  | 0, a, _ => (0, a)
  | f'+1, a, b =>
    if b ≤ a then ((dm2 f' (a - b) b).1 + 1, (dm2 f' (a - b) b).2)
    else (0, a)
```

fuel 每耗一步，被除数减一个 b；燃料 a 恰好够（a ≤ f 是规格条件）。两条规格
引理各是一次归纳：`dm2_ex`（结果满足 a = b·q + r）与 `dm2_lt`（b ≠ 0 时 r < b）。
注意 b = 0 的角落：余数永远是 a 本身（商无意义但无害，b·q = 0），规格只对
b ≠ 0 承诺 r < b——这正是书要求 d 为正的原因。

唯一性是本章第一个「跨原子」推理：若 b·q₁ + r₁ = b·q₂ + r₂ 且两个余数都小于 b，
则 q₁ = q₂。反设 q₁ < q₂：q₂ = q₁ + (q₂ − q₁)，展开 b·q₂ = b·q₁ + b·(q₂ − q₁)，
而 b·(q₂ − q₁) ≥ b（差至少为 1），于是 b·q₂ + r₂ ≥ b·q₁ + b > b·q₁ + r₁，矛盾。
机器上每一步「乘开再比大小」都要显式装配（`Nat.mul_add` 展开、`Nat.add_mul`
按侧展开），lia/omega 只负责最后纯原子的一比。

## 三、扩展 Euclid：把 gcd 算成数据

书 §3.5.3 讲 Euclid 算法（中国更相减损术作引子），核心是阶段引理（Lemma 3.5.1）：
若 n = qd + r，则 (n, d) 与 (d, r) 的公因子集合相同。机器版把这条引理直接织进
递归的归纳证明里，而且一步到位带出 Bézout 系数——返回四元组的 fuel 函数：

```lean
def egcdf : Nat → Nat → Nat → Nat × Nat × Nat × Nat
  | 0, _, _ => (0, 0, 0, 0)
  | f'+1, a, 0 => (a, 1, 0, 0)
  | f'+1, a, b'+1 =>
    match egcdf f' (b'+1) (dmrF a (b'+1)) with
    | (g, x, y, 0) => (g, x + y * dmqF a (b'+1), y, 1)
    | (g, x, y, _) => (g, x, y + x * dmqF a (b'+1), 0)
```

四个分量是 (g, x, y, s)：g 是 gcd，x、y 是 Bézout 系数，s 记等式的**方向**——
s = 0 表示 x·a = y·b + g，s = 1 表示 x·b = y·a + g。这个方向位是 nat 世界的
生存智慧：书例 3.5.5 的 4 = 2·128 − 7·36 有一个负系数，nat 装不下负数，但
「移项」成 2·128 = 7·36 + 4 就全是加法了。两个方向的递推：

- 下层 s = 0（x·b = y·r + g）：代入 r = a − b·q，得 x·b + y·q·b = y·a + g，
  即 (x + y·q)·b = y·a + g——上层方向翻成 s = 1；
- 下层 s = 1（x·r = y·b + g）：同理得 x·a = (y + x·q)·b + g——翻成 s = 0。

全程没有一次真减法出现在结果里。规格引理 `egcdf_spec` 按燃料归纳：每层同时
维护 Gcd 证明与 Bézout 等式，Gcd 部分就是阶段引理（公因子集相同 ⇔ 双向整除
封闭，即 `gcd_step`）。**燃料预算是 S(a + 2b) ≤ f**——不是朴素的 a + b：
当 a < b 时递归对 (b, a) 是一次「换位」，和在 a + 2b 的度量下仍然下降，而
a + b 会原地踏步。这是本章调试时间最长的一处（详见坑位）。

`gcdn` 就是 egcdf 的第一分量，立即得到三件套：

```coq
Theorem gcdn_gcd : forall a b, Gcd (gcdn a b) a b.
Theorem bezout : forall a b,
  exists x y, (x * a = y * b + gcdn a b) \/ (x * b = y * a + gcdn a b).
```

其中 `Gcd d a b` 采用书的整除刻画（Cor 3.5.3.2）：d ∣ a、d ∣ b、且一切公因子
c ∣ d。这个定义比「最大的公因子」更适合机器：不依赖 ≤ 的比较，唯一性
（`gcd_unique`）由互相整除加正性直接推出。冒烟演示对上书例：
gcdn 36 128 = 4、gcdn 15 49 = 1、gcdn 56 472 = 8。

## 四、Euclid 引理：Bézout 的第一次出场

书 Thm 3.5.5（广义 Euclid 引理）：若 d ∣ a·b 且 d 与 a 互素（Gcd 1 d a），
则 d ∣ b。证明是 Bézout 的一步应用：取 x·d = y·a + 1，两侧乘 b 得
x·d·b = y·a·b + b；左边是 d 的倍数，y·a·b 也是（d ∣ a·b 乘 y），于是
b = x·d·b − y·a·b 是 d 的倍数之差——`div_sub` 收尾。素数版（VII.30：
p 素且 p ∣ a·b 且 p ∤ a ⟹ p ∣ b）只多一步：gcd(p, a) 整除 p，素性逼它取 1
或 p，取 p 则 p ∣ a 矛盾。

nat 的另一个别扭：书里的证明一步「两边乘 b」，机器上 omega 做不了这件事
（它不会把假设里的等式乘上变量再匹配目标），要手工 `rw [hf, Nat.add_mul]`
把等式展开到位。两个通道的 Euclid 引理都照这个模子装配。

## 五、gcd·lcm = a·b：见证式 lcm

书 Thm 3.5.4：a, b ≥ 1 时 gcd(a,b)·lcm(a,b) = a·b。机器不定义除法版的
lcm := a·b/g，而是给**见证**：由 a = g·m、b = g·n，取 l := g·m·n，证明
它满足 Lcm 的整除刻画（a ∣ l、b ∣ l、一切公倍数被 l 整除）且 g·l = a·b。
前两条与积等式是初等的；最小性的证明是 Bézout 的第二次出场，也是全章
最重的一段机器装配：

设 q 是公倍数（q = a·s = b·t），Bézout 给 x·a = y·b + g。两边乘 q、代入
两种 q 的表达式，化成 (x·t)·(a·b) = (y·s)·(a·b) + g·q；再用 a·b = g·l
换进去，两侧出现公因子 g，`mul_cancel_l` 约去，得 (x·t)·l = (y·s)·l + q——
l ∣ q 的见证就是 x·t − y·s。Coq 侧这段全是 `ring`（乘法交换半环上的恒等式
变形）加 `lia`（原子线性层）；Lean 没有 ring，每步变形靠 AC-simp
（`simp [Nat.mul_add, Nat.add_mul, Nat.add_comm, Nat.add_assoc, Nat.add_left_comm,
Nat.mul_comm, Nat.mul_assoc, Nat.mul_left_comm]`）做交换半环规范化——
这是 Lean 裸 core 里的「穷人 ring」，本章反复使用。

## 六、素因子存在与素数无穷

素因子存在（每个 ≥2 的数有素因子）在第 49 章已用强归纳+有界排中证过
（`prime_divisor`）；本章以 `properFac`（可判定的「真因子」测试）+ 同一套
有界排中复刻，作为自包含引用。素数无穷则给出 Euclid 的经典构造：

```coq
Theorem inf_primes : forall L, (forall n, In n L -> prime n) ->
  exists p, prime p /\ ~ In p L.
```

任取一张有限素数表，m := 表中元素之积 + 1；m ≥ 2 有素因子 p；若 p 在表里，
则 p 整除表积，又整除表积 + 1，于是 p ∣ 1，素性（2 ≤ p）矛盾。冒烟演示：
[2;3;5;7;11;13] 之积 + 1 = 30031 = 59·509——表外确实还有素数。「唯一分解」
（书练习 3.5.23 假设它）依赖 Euclid 引理与归纳，机器化留给后续章节。

## 坑位速记（本章实测，量大）

> 关于 Bézout 差形式的补充：方向位 s 并非唯一的处理办法——另一种常见方案是把
> 系数取在 ℤ 里（书正是这么做的），但那需要先构造整数（Jongsma 自己也要等到
> §6.4 才正式定义 ℤ）。本章的「移项负系数」方案让扩展 Euclid 在 nat 里自封闭，
> 与第 49 章 Hanoi 的「+1 = 2^n 改写」属于同一族手艺：**nat 没有减法和负数，
> 但等式的两边可以选边站**。

- **Coq：`remember` 是含字母项的安全岛**。`gcdn a b` 里含有 a、b 两个字母，
  任何对 a 或 b 的全局 `rewrite` 都会把 `gcdn a b` 内部的同名字母一起改掉
  （自我指涉爆炸）。解法：`remember (gcdn a b) as g` 把它变成不透明变量，
  或用 `congrArg (fun t => y * t) haq` 这类项式构造替代改写。
- **Lean：同款爆炸更隐蔽**。`rw [hm]`（hm : a = g*m）会改掉 `gcdn a b` 里的 a；
  `conv => lhs; rw [...]` 限定改写区域也常失效。可靠替代：`congrArg` /
  `congrArg2` 风格的项式等式搬运，以及先 `rw [← hm]`（反向改写模式
  g*m → a，模式里没有字母 a 就绝对安全）。
- **Lean：AC-simp 是穷人 ring，但要带全七件**：mul_add、add_mul、
  add_comm、add_assoc、add_left_comm、mul_comm、mul_assoc、mul_left_comm。
  少一件就卡在「只差交换一下」的残局上；残局 goal 里出现 `x * d + b' * (x * d)`
  这类项就是缺 add 侧交换件。此法对纯交换半环恒等式全胜，对含假设的等式
  先 `rw` 后 `simp`。
- **Coq/Lean：fuel 预算用 S(a+2b) ≤ f，不是 S(a+b)**。Euclid 递归 (a,b) →
  (b, a mod b) 在 a < b 时先换位（和不变），下一步才开始真降；a+b 度量会在
  换位步卡死（差一），a+2b 度量在两种步型下都严格降。预算引理提到顶层
  证（无 ∃ 上下文），两分支各一条纯算术引理。
- **Lean：omega 关非算术目标的门会拉 Classical.choice**（49 章坑的完整版）：
  目标是 ∃/∨/抽象 Prop 时用 `absurd ... (by omega)` 或 `exfalso; omega` 替代
  裸 omega；**上下文里有直接 ∃ 假设也会触发**——destruct 之后 `clear` 掉
  原假设（match 不清除）。∀ 包着的 ∃（归纳假设）实测无害。
- **Lean：`Nat.eq_dec`、`set`、`Prod.mk.eta`、`nth_rewrite` 不在裸 core**——
  分别用 `Nat.lt_or_ge + omega`、`match` 概括、`rfl`（结构 eta 定义性成立）、
  `congrArg` 替代。
- **Coq：`apply` 大引理时高阶合一会「聪明反被聪明误」**——`apply div_mul_l`
  按最大模式匹配而非按预期参数；直接给全参数 `(div_mul_l g b q hgb)`，
  或干脆给见证 `exists (x*b); ring`。
- **Coq：`induction n using lt_wf_ind` 在目标为前件式时挂「No product」**——
  自带 `strong_ind`（50 章那六行）配合显式 P 最稳。
- **通用：`rw` 尾部的自动 rfl 只用可约透明度**——`sadd m z ≡ m`、
  `(q,r).2 ≡ r` 这类定义展开收不掉，补一行显式 `reflexivity`/`rfl`。

## 小结

整除、除法算式、gcd/Bézout、Euclid 引理、lcm——初等数论的承重墙在两个
通道上全部立起，且账本干净（Coq 全零公理，Lean 仅基线）。Bézout 的差形式
（方向位 s）是 nat 世界给「负系数」的答案，后面第 54 章（模算术）还会用到
同款手艺。下一章告别算术、进入集合与计数：乘法原理、组合、容斥、鸽笼。

---

上一章：[50 递推、结构归纳与 Peano 算术](docs/50-pa.md) · 下一章：[52 集合、幂集与计数](docs/52-setscount.md)
