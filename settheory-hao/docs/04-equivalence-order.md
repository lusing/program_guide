# 04 · 等价、划分与序

> "等数"如果也算一种等价关系的话，本章的概念其实从第 00 章
> 就开始了——现在把它精确化。

本章覆盖书第二章后半（2.3 等价与划分、2.4 序、习题 2.5.19-2.5.28；
PDF 37-46 页）：等价关系与划分的字典式对应（这是"商构造"的通用
机制——第 05 章的整数、有理数全部靠它出场），以及偏序、线序、
上下确界的语言（第 09 章良序、第 13 章 Zorn 引理的地基）。

## 4.1 等价关系：三律

> **定义（书 2.3.1）**　R ⊆ X² 是：
> (1) **自反**的：∀x∈X R(x,x)；(2) **对称**的：R(x,y) → R(y,x)；
> (3) **传递**的：R(x,y) ∧ R(y,z) → R(x,z)。三者兼备称**等价
> 关系**，习惯记 ~。

书 2.3.2 的人伦三例是三律的最好体检表：

- **D**（"x 是 y 的后代"）：非自反、非对称、但传递；
- **B**（"x 与 y 至少共享一位祖先"）：自反、对称、**不传递**；
- **S**（"x 与 y 同父母"）：等价关系。

B 的不传递需要具体反例：设 b 的父母 p₁、p₂ 分属两个家族（祖辈
gpA、gpC）。则 B(gpA, b)（共享 p₁ 一线的祖先）、B(b, gpC)（共享
p₂ 一线），但 ¬B(gpA, gpC)（两家没有共同祖先）。Python 单元把
整个家族做成数据并逐条审计（`examples/python/04_equivalence.py`）：

```python
parents = {'gpA': (), 'gpC': (), 'p1': ('gpA',), 'p2': ('gpC',),
           'b': ('p1', 'p2')}

def ancestors(x):                     # 含自身的祖先集（共享祖先按此口径）
    out = {x}
    for p in parents[x]:
        out |= ancestors(p)
    return out

def D(x, y):  return x in ancestors(y) - {y}          # y 是 x 的后代
def B(x, y):  return ancestors(x) & ancestors(y) != set()

assert all(B(x, x) for x in people)                    # 自反
assert all(B(x, y) == B(y, x) for x, y in product(people, repeat=2))   # 对称
assert B('gpA', 'b') and B('b', 'gpC') and not B('gpA', 'gpC')         # 不传递！
```

注意口径约定："共享祖先"把**自身**计入祖先集（否则无祖先的始祖
连自反性都保不住）。原书没有明说这个细节——机器化逼我们把它挑明，
这正是"实现即证明"的教育价值。习题 2.3.3 再添一例：理想 I ⊆ P(X)
上，A ~ B ⟺ A△B ∈ I 是等价关系（对称差的可加性）——第 18 章滤子
与理想的预演。

## 4.2 等价类与划分：一套机制，两个方向

> **定义（书 2.3.4/2.3.6）**　[x]~ = {t∈X | t~x} 是等价类；
> S ⊆ P(X) 是**划分**，若 (1) S 中元素两两不交，(2) ⋃S = X。

**引理（书 2.3.5，两歧性）**　[x]~ = [y]~ 或 [x]~ ∩ [y]~ = ∅。

*证明*。若 z 同时属于两类，则 x~z 且 y~z，于是 x~y（对称+传递）；
进而任取 t∈[x]~，t~x~y 给 t∈[y]~，两类互相包含故相等。∎

于是商集 X/~ = {[x]~ | x∈X} 天然是 X 的划分（书 2.3.8）。反方向
（书 2.3.9）：给定划分 S，定义 x ~_S y ⟺ ∃C∈S (x∈C ∧ y∈C)，
则 ~_S 是等价关系且 X/~_S = S。**两个构造互逆**——"等价关系"与
"划分"是同一件事的两种记载。

Coq 单元（`examples/coq/Ch04Equivalence.v`）把两个方向都做成机器
证明。正向的两歧性拆成两条建设性引理：

```coq
(* 有关系则类相等 *)
Lemma classes_eq : forall x y, R x y ->
  forall z, classOf x z <-> classOf y z.
Proof.
  intros x y H z. unfold classOf. split; intros Hz.
  - apply (Rtrans y x z); [apply Rsym; exact H | exact Hz].
  - apply (Rtrans x y z); [exact H | exact Hz].
Qed.

(* 无关系则类不交 *)
Lemma classes_disjoint : forall x y, ~ R x y ->
  forall z, ~ (classOf x z /\ classOf y z).
Proof.
  intros x y H z [Hz1 Hz2]. apply H.
  apply (Rtrans x z y); [exact Hz1 | apply Rsym; exact Hz2].
Qed.
```

（类以谓词 `classOf x := fun y => R x y` 呈现，绕开商类型的机器
负担；对析取的"两歧"拆成两条引理，避免经典逻辑。）反向：

```coq
Lemma relOf_equiv : forall bl, Partition bl ->
  (forall x, relOf bl x x) /\
  (forall x y, relOf bl x y -> relOf bl y x) /\
  (forall x y z, relOf bl x y -> relOf bl y z -> relOf bl x z).
```

划分条件以"共享元素即同块 + 覆盖"陈述；传递性的证明是教科书式的：
x,y 同在块 B₁，y,z 同在块 B₂，则 y 是两块的公共元素，故 B₁ = B₂，
x,z 同块。回收方向"每个块恰是某个元素的类"（block_eq_class）随后
补全互逆。有限侧，Python 与 Prolog 单元做了**穷举版**的互逆验证：

```python
for p4 in parts4:                      # 4 元素全部 15 个划分
    rel = induced(p4)
    assert is_equivalence(rel, [0, 1, 2, 3])
    assert quotient(rel, [0, 1, 2, 3]) == p4               # 往返复原
rels = {induced(p4) for p4 in parts4}
assert len(rels) == 15                                     # 等价关系数 = Bell 数
```

一个漂亮的机器揭示：**n 元素集上等价关系的个数恰是 Bell 数**
B(n)（B(3)=5、B(4)=15、B(5)=52）——因为每个等价关系就是一个划分。
Prolog 侧的生成器还能倒着用：先算任意关系的等价闭包，再验证闭包
等于目标划分的诱导关系：

```prolog
eq_closure([0,1,2,3,4], [(1,2),(3,4)], C),
P = [[0],[1,2],[3,4]],
findall((X,Y), (member(B, P), member(X, B), member(Y, B)), Rel),
sort(Rel, RelS), C == RelS,
```

**满射的核等价（习题 2.5.20）**。设 f:X→Y 满射，定义 x R y ⟺
f(x)=f(y)。则 R 是等价关系；商映射 g(x)=[x]_R；h([x])=f(x) 良定
（同一类的元素 f 值相同——良定性就是"类不依赖代表元"）且满；
**h∘g = f**。这是"任何满射都分解为 商映射∘双射"的因子分解——
群论第一同构定理的原型，也是第 07 章构造整数/有理数的标准动作
（ℤ→ℚ 商去分母等价类）。机器侧留给读者作为本章综合练习（Coq
单元的 relOf/block_eq_class 两引理正是它的全部零件）。

## 4.3 序：偏序、线序与"极小 ≠ 最小"

> **定义（书 2.4.1）**　X 上的关系 ≤ 是**偏序**，若自反、反对称
> （x≤y ∧ y≤x → x=y）、传递；若还满足**连接性**（∀x,y: x≤y 或
> y≤x），称**线序**（全序）。

例（书 2.4.3）：(ℝ,≤) 是线序；(P(X),⊆) 是偏序非线序（X 至少两个
元素时）；( {2,3,4,…}, | ) 整除是偏序非线序。

**极小元与最小元是两个概念**（书 2.4.4）：

- a 是**极小元**：没有元素严格小于 a（∀x ¬(x < a)）；
- a 是**最小元**：a 小于等于一切元素（∀x a ≤ x）。

最小元必是极小元；反之不然。线序中二者合一（书 2.5.25）。两个
标志性例子（书 2.4.6）：

1. **P({1,2}) − {∅}**（⊆）：{1} 与 {2} 都是极小元，但没有最小元
   ——没有任何元素同时 ≤ {1} 和 ≤ {2}。
2. **{2,3,4,5,…}**（|）：每个素数都是极小元（m≠1 且 m≠p 时
   p∤m），**无穷多个极小元**，且无最小元。

Python/Prolog 单元都审计了这两例（Prolog 版 `examples/prolog/04_partitions.pl`）：

```prolog
Subs = [[1],[2],[1,2]],
findall(M, minimal(Subs, sub_le, M), MinS), sort(MinS, [[1],[2]]),
\+ least(Subs, sub_le, _),                    % 无最小元
Divs = [2,3,4,6,12],
findall(M, minimal(Divs, div_le, M), MinD), sort(MinD, [2,3]),   % 素数为极小
```

**上界与上确界**（书 2.4.4(3)）：X₀ ⊆ X 有上界 a（∀x∈X₀ x≤a）；
上界集中的最小元（若存在）称上确界 sup(X₀)。例 2.4.6(3) 是全书
最深的例题之一：

> A = {q∈ℚ | q>0 ∧ q²<2} 作为 ℚ 的子集有上界，但**没有上确界**；
> 作为 ℝ 的子集有上确界 √2。**一个集合有无上确界，取决于它住在
> 哪个集合里**。

这正是"完备性"（第 07 章实数构造的核心命题）的序论表述：ℚ 缺的
不是上界（2 就是），而是最小上界——任何有理上界 r 都满足 r²>2，
而 r−ε 内总有 A 的元素挤上来，r 的位置永远可以被逼近却达不到。
实数正是把这条缺口**定义为**新对象（Dedekind 分割）的产物。

**对偶与子序**（习题 2.5.21/2.5.23）：R⁻¹ 把序反转，极小↔极大、
最小↔最大、sup↔inf 全部对偶；偏序限制到子集仍是偏序，线序限制到
子集仍是线序，但子集线序不保证全集线序。

## 4.4 三个格：完备性的三种面孔

**格**（非书的术语，但习题 2.5.24/2.5.27/2.5.28 全是格）是有
sup 与 inf 的偏序集。本章三个例子一个比一个深。

**格一：(P(X),⊆)，一切 sup/inf 都在**（习题 2.5.24）。任意
S ⊆ P(X)：sup S = ⋃S，inf S = ⋂S（S≠∅ 时）；空族另算——

> sup ∅ = ∅（∅ 是所有集合的下界中……准确说：一切元素都是 ∅ 的
> 上界，最小上界是 ∅）；inf ∅ = X（一切元素都是 ∅ 的下界，最大
> 下界是 X）。

**关于 inf ∅ 的口径**：OCR 原文此处显示为"inf∅ = 0"，但按定义
（∅ 的一切下界的最大元）应为 X——P(X) 的底是 ∅、顶是 X，这是
数学事实，本教程按 X 讲。机器审计把空族账目并入一般族：

```python
TOP = frozenset({1, 2, 3})
for fam in (P3, [frozenset({1, 2}), frozenset({2, 3})], []):
    ubs = [u for u in P3 if all(s <= u for s in fam)]
    assert least(ubs, le_sub) == [frozenset().union(*fam)]           # sup = ⋃F
    lbs = [l for l in P3 if all(l <= s for s in fam)]
    assert least(lbs, lambda a, b: b <= a) == [TOP.intersection(*fam)]   # inf = ⋂F
```

（`least` 的实现：筛出"没有严格更小者"的元素；上确界用 ≤、下确界
把序反过来筛。空族时 `union(*())` = ∅、`TOP.intersection(*())` =
TOP，恰是 sup∅ 与 inf∅。）

**格二：整除格**。({1,2,3,6}, |) 上 sup(a,b) = lcm(a,b)、
inf(a,b) = gcd(a,b)——最小公倍数/最大公因子之名原来就是 sup/inf
之名。双通道审计（Python 全对，Prolog 用 `least(UBs, div_le, L),
L =:= lcm(A,B)` 终审）：

```python
for a in D4:
    for b in D4:
        ubs = [u for u in D4 if u % a == 0 and u % b == 0]           # 公倍数
        assert least(ubs, le_div) == [lcm(a, b)]                     # sup = lcm
```

**格三：划分格 Pt(X)**（习题 2.5.28）。S₁ ≤ S₂ ⟺ S₁ 的每块都含于
S₂ 的某块（"S₁ 加细 S₂"）。Pt(X) 是偏序；任意两划分有下确界（公共
加细的"最粗者"），任意划分族 T 有上确界与下确界——划分格是完备
格。等价关系的视角下，"加细"就是"包含"（R₁ ⊆ R₂ 作为关系），
Pt(X) 与"X 上全体等价关系"格同构——4.2 节的字典又添一页。这个格
在第 18 章（滤子的对偶）与第 23 章（力迫的脱殊滤子）还会回来。

**拟序的商（习题 2.5.26）**：传递+自反但不反对称的关系（拟序），
经 x~y ⟺ x≤y∧y≤x 商化后得到偏序——"≤ 同层无差别，层间有序"。
这是格论与计算机科学（偏序集的弱序化）的标准操作，与 4.2 节的
核等价一脉相承。

**Fn(X,Y)（习题 2.5.27）**：{f | f:Z→Y 函数, Z⊆X} 按 ⊆ 是偏序；
子族 F 有上确界 ⟺ F 相容，且 sup F = ⋃F。——3.3 节相容系统理论
的序论表述。第 13 章 Zorn 引理证明"每个偏序集的链都有上界则有
极大元"时，标准应用（Hahn-Banach、基的存在性）的"链"正是相容
函数系统——习题 2.5.27 是那些大定理的零号原型。

## 本章要点

1. 等价关系三律；类两歧（同或离）；等价关系 ↔ 划分互逆，机器在
   有限情形穷举互证（等价关系数 = Bell 数）。
2. 满射的核等价 + 商映射分解 h∘g = f——一切"商构造"（ℤ、ℚ、
   同构定理）的原型。
3. 极小 ≠ 最小；P(X)−{∅} 两极小无最小、素数无穷多极小元；线序中
   二者合一。
4. sup/inf 依赖环境：{q | q²<2} 在 ℚ 无上确界、在 ℝ 有——完备性
   的序论表述，第 07 章实数构造的靶心。
5. 三个格：P(X)（sup=⋃、inf=⋂、sup∅=∅、inf∅=X）、整除格
   （sup=lcm、inf=gcd）、划分格（加细序）——后者通向第 18 章。
6. Fn(X,Y)：相容 ⟺ 有上确界，sup = ⋃——Zorn 应用的零号原型。

*对应示例：`examples/coq/Ch04Equivalence.v`、
`examples/python/04_equivalence.py`、`examples/prolog/04_partitions.pl`。*

---

上一章：[03 关系与函数](03-relations-functions.md) · 下一章：[05 自然数与递归定理](05-naturals-recursion.md)
