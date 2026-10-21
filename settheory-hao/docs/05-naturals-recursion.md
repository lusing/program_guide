# 05 · 自然数与递归定理

> 数是人类心灵的自由创造。——理查德·戴德金

本章覆盖书第三章前半（3.1 自然数、3.2 递归定理与运算；PDF 47-56
页）：把自然数从集合里造出来，证明归纳原理与良序，然后回答一个
其他教材回避的问题——**递归定义为什么是合法的**。

## 5.1 von Neumann 自然数：从 ∅ 开始的楼梯

0 个元素的集合只有一个：用 ∅ 表示 0 是自然的。1 的表示呢？单元素
集合有许许多多（甚至 {{x | x 是集合}} 这种"全体单元集"是真类），
但最方便的一个是 {∅}：它就是"0 的后继"。于是：

    0 = ∅,  1 = {0} = 0 ∪ {0},  2 = {0,1} = 1 ∪ {1},  3 = {0,1,2}, …

一般地，**后继** S(a) = a ∪ {a}（第 02 章定义 1.3.10），而自然数
就是从 0 开始反复取后继的产物。

> **定义（书 3.1.1）**　集合 X 是**归纳集**，若 ∅ ∈ X 且
> ∀x (x ∈ X → x⁺ ∈ X)。无穷公理恰好说：存在归纳集。

> **定义（书 3.1.2）**　N = {n | 对一切归纳集 X，n ∈ X}。
> 由分离公理（从任一归纳集中分离）与无穷公理，N 是集合且唯一。

> **定理（书 3.1.3）**　N 是归纳集，且包含于任何归纳集——N 是
> **最小归纳集**。

证明只有三行：∅ 属于一切归纳集，故 ∅ ∈ N；若 n ∈ N 则 n 属于
一切归纳集，故 n⁺ 属于一切归纳集，故 n⁺ ∈ N。∎ 最小性的机器
形态很有画面感（`examples/python/05_naturals.py`）——两条推导
规则**逼出**每个数字：

```python
derived = [nat[0]]                                   # 规则一：0 ∈ I
while len(derived) < 6:
    derived.append(succ(derived[-1]))                # 规则二：封闭性
assert derived == nat[:6]                            # 被逼出来的恰是 nat 前段
```

任何归纳集 I 的成员资格检查只有这两条规则可用，于是每个数字都被
"逼进"I——这正是 **N ⊆ 一切归纳集** 的推导式表述。

## 5.2 ∈ 就是 <：自然数上的序

von Neumann 构造的妙处：**隶属关系直接就是大小关系**。定义
m ≤ n ⟺ m ∈ n ∨ m = n，则（书引理 3.1.5，八条）：

1. n ⊆ n+1 且 n ∈ n+1；
2. x ∈ n → x ∈ N（自然数的元素还是自然数）；
3. 0 ∈ n（n≠0）；
4. k ∈ n+1 ⟺ k ∈ n ∨ k = n；
5. m ∈ n → m+1 ∈ n；
6. k ∈ m ∧ m ∈ n → k ∈ n（传递）；
7. m ∉ m（基础公理立得；不用基础公理也可归纳证明——习题 3.7.4）；
8. **m ∈ n ⟺ m ⊊ n**。

第 (8) 条最有味道，书中的证明是三情况分类的归纳（m ⊆ n+1 时 m ⊆ n、
m = n、n ∈ m 三种可能，第三种被 (4)+(1) 排除）。机器侧在 frozenset
实现的数字上全量审计（`examples/python/05_naturals.py`）：

```python
for n in range(1, 6):
    assert nat[n] == frozenset(nat[:n])               # n = {0..n-1}
    for m in range(6):
        assert (nat[m] in nat[n]) == (m < n)          # m ∈ n ⟺ m < n
        assert (nat[m] <= nat[n]) == (m <= n)         # m ⊆ n ⟺ m ≤ n
```

于是（书 3.1.6）**(N, ≤) 是线序**；更强的是：

> **定理（书 3.1.10）**　(N, ≤) 是**良序**——每个非空子集有最小元。

证明用**第二归纳原理**（书 3.1.9）：若对所有 k < n，φ(k) 成立
就能推出 φ(n) 成立，则 ∀n φ(n)。（证明技巧：令 M = {m | ∀k<m
φ(k)}，归纳证 M = N，再用"每个 k 都有更大的 n"把 φ 从 M 中释放
出来。）良序的证明是反证杰作：若非空子集 X 无最小元，则 N−X 满足
第二归纳的前提（∀k<n, k ∈ N−X → n ∈ N−X，否则 n 是 X 的最小
元），故 N−X = N，得 X = ∅——矛盾。良序是第 09 章（一般良序集
与序数）的邀请函。

## 5.3 递归定理：递归定义的合法性证明

数学里到处是"递归定义"，例如加法：

    m + 0 = m,　　m + (n+1) = (m+n) + 1。　　(3.7)

**问题：为什么这样的定义是合理的？**——它真的唯一确定一个函数
吗？一般教材把这一点诉诸直观。但原书的态度一以贯之：既然集合论
要作数学的基础，就只有 ZFC 的公理允许不证自明，其余一切都要证
明。于是：

> **递归定理（书 3.2.1）**　对任意集合 A、a ∈ A、函数
> g : A×N → A，存在唯一函数 f : N → A 满足：
> (1) f(0) = a；(2) ∀n, f(n+1) = g(f(n), n)。

**证明（存在性）**是全书的样板证明，值得逐字读懂。称序列
t : (m+1) → A 为 **m-近似**，若 t₀ = a 且 ∀k<m, t_{k+1} =
g(t_k, k)。令 F = {t ∈ P(N×A) | t 是某个 m-近似}，f = ⋃F。三件
事实：

- **f 是函数**：F 中任意两个近似 t（n-近似）、u（m-近似）相容——
  对 k < min(n,m) 归纳证明 t_k = u_k（都从 a 出发、都按 g 步进）。
  相容函数系统的并是函数（第 03 章 2.2.10）；
- **dom f = N**：对 n 归纳证明存在 n-近似（{(0,a)} 是 0-近似；
  n-近似延长一步得 (n+1)-近似——延长的构造 (3.9)）；
- **f 满足方程**：每个近似的前段一致，f(0) = a 与 f(n+1) =
  g(f(n), n) 从定义直接读出。

**唯一性**：若 h 也满足两方程，f(0) = h(0) 且 f(n) = h(n) →
f(n+1) = g(f(n),n) = g(h(n),n) = h(n+1)，归纳即得 f = h。∎

**带参数的递归定理（书 3.2.3）**：参数 p 的情形归结为无参数版——
把 A 换成函数空间 A^P，步进函数 G(t)(p) = g(p, t(p), n)。这个
"提升类型"的技巧是构造加法（P = N）等二元运算的标准路径。

> **定理（书 3.2.4/3.2.5）**　存在唯一的 + : N×N → N 满足
> m+0 = m、m+(n+1) = (m+n)+1；存在唯一的 · 满足 m·0 = 0、
> m·(n+1) = m·n + m。

交换律、结合律、分配律（书 3.2.7）都是双重归纳的练习——书完整
演示了加法交换律的证明（对 n 外层归纳、对 m 里层归纳，七行等式
链全部只许用定义与归纳假设，不许"显然"）。

## 5.4 机器侧：递归定理的四副面孔

**Lean：递归定理是语言原语**（`examples/lean/Sethao/Ch05Naturals.lean`）。
Lean 的 `Nat.rec` 就是递归定理——它不是库里的定理，而是类型论的
构造规则。于是书的定义可以逐字落地：

```lean
/-- 加法（书 3.2.6）：m + 0 = m；m + (n+1) = (m+n)+1。
递归变量是第二个参数——`Nat.rec m Nat.succ` 逐字翻译。 -/
def add' (m : ℕ) : ℕ → ℕ :=
  Nat.rec (motive := fun _ => ℕ) m (fun _ acc => Nat.succ acc)

theorem add'_zero (m : ℕ) : add' m 0 = m := rfl

theorem add'_succ (m n : ℕ) : add' m (n + 1) = (add' m n) + 1 := rfl

/-- 乘法（书 3.2.6）：m · 0 = 0；m·(n+1) = m·n + m。 -/
def mul' (m : ℕ) : ℕ → ℕ :=
  Nat.rec (motive := fun _ => ℕ) 0 (fun _ acc => add' acc m)
```

两条 `rfl` 就是"定义即方程"的机器证书。然后按书 3.2.7 的结构
重演交换律——先证左单位（书证明的第一步），再证"递归变量换侧"
的账（书证明的里层归纳），最后外层归纳合龙：

```lean
theorem add'_zero_left (n : ℕ) : add' 0 n = n := by
  induction n with
  | zero => rfl
  | succ n ih => rw [add'_succ, ih]

theorem add'_succ_left (m n : ℕ) : add' (m + 1) n = (add' m n) + 1 := by
  induction n with
  | zero => rfl
  | succ n ih => rw [add'_succ, add'_succ, ih]

theorem add'_comm (m n : ℕ) : add' m n = add' n m := by
  induction m with
  | zero => rw [add'_zero, add'_zero_left]
  | succ m ih => rw [add'_succ_left, add'_succ, ih]
```

三个引理与书 3.2.7 证明的三个层次一一对应——机器版甚至更诚实：
里层归纳被命名成 `add'_succ_left`，而不是埋在等式链里。第二归纳
原理在 mathlib 里的名字是 `Nat.strongRecOn`，良序原理的可计算
化身是 `Nat.find`（返回满足可判定谓词的最小数——"每个非空子集
有最小元"的算法形态）。

**Isabelle/ZF：ω 的官方户口**（`examples/isabelle/HS05/Naturals.thy`）。
ZF 库把书 3.1.2 的"最小归纳集"逐字实现——nat 定义为相应算子的
最小不动点 lfp：

```isabelle
thm nat_def          (* nat 的 lfp 定义 *)
thm nat_induct       (* 归纳原理：书 (3.4)/(3.5)，case_names 0 succ *)
thm complete_induct  (* 第二归纳原理：书 3.1.9，case_names less *)
thm Ord_nat          (* nat 是序数——第 10 章的预告 *)
```

ZF 的算术库同样用递归定义加法，但**对第一参数递归**
（succ(m) #+ n = succ(m #+ n)），与书互为镜像——同一运算的两种
合法递归式，正好演示递归定理的自由度。会话里用 `nat_induct` 手工
重演一个小证明：

```isabelle
lemma one_add: "n \<in> nat \<Longrightarrow> succ(0) #+ n = succ(n)"
proof (erule nat_induct)
  show "succ(0) #+ 0 = succ(0)" by simp
next
  fix x assume IH: "succ(0) #+ x = succ(x)"
  show "succ(0) #+ succ(x) = succ(succ(x))" using IH by simp
qed
```

**Julia：近似序列的执行**（`examples/julia/05_naturals.jl`）。书
3.2.1 证明的构造可以**运行**：对固定 m，逐层造 n-近似（前缀序列），
并验证"全体近似的并就是函数"：

```julia
aps = approximations(7, 6)
union_ap = sort(unique(vcat(aps...)))          # ⋃F 的值域形态（函数并：无重复）
@assert union_ap == [add_rec(7, k) for k in 0:5]
@assert aps[4] == [7, 8, 9]                    # 3-近似 = 前三个值（aps[1] 是 0-近似）
@assert length.(aps) == 0:6                    # n-近似的长度是 n
```

同一单元还演示**双重递归的合法性问题**：naive 的
fib(n) = fib(n−1) + fib(n−2) **不是**递归定理的实例——步进函数
需要两个先前值，而定理只给一个。合法的写法是把状态配对：
F(n) = (fib n, fib n+1)，步进 g((a,b)) = (b, a+b)。两条实现都能
算对，但调用次数是证词：naive fib(25) 花 **242785 次调用**，状态
配对版是线性——"定义的合法性"与"定义的效率"在此合流。（一般
的良基递归要到第 20 章才获得完全的定理地位。）

**Python：数字的集合形态**。5.1-5.2 节已展示 frozenset 数字与
3.1.5 引理的全量审计；单元尾部还有第二归纳的可计算影子——一个
`step(k, known)` 审计器，谓词对 k 的成立被要求只依赖"全部更小的
值已知"这一事实。

## 本章要点

1. N = 最小归纳集；von Neumann 数字使 **m ∈ n ⟺ m < n ⟺ m ⊊ n**
   三位一体——隶属、大小、包含在自然数上是同一个关系。
2. (N, ≤) 是良序；良序证明的第二归纳原理（强归纳）从此常驻。
3. 递归定理（3.2.1）给"递归定义"补上了合法性证明：近似序列的
   并 + 唯一性归纳；带参数版靠"提升到函数空间"。
4. 机器四面相：Lean 里递归定理是语言原语（Nat.rec），加法交换律
   按书结构重演；Isabelle/ZF 里 nat 是 lfp 定义的官方对象；
   Julia 把近似序列跑起来（并暴露 naive fib 的不合法性）；
   Python 验证数字的集合形态。

*对应示例：`examples/lean/Sethao/Ch05Naturals.lean`、
`examples/isabelle/HS05/Naturals.thy`、`examples/julia/05_naturals.jl`、
`examples/python/05_naturals.py`。*

---

上一章：[04 等价、划分与序](04-equivalence-order.md) · 下一章：[06 等势与可数](06-equipollence.md)
