# 第 77 章 算术化与哥德尔编码

> 对书：Mendelson §3.4（算术化：哥德尔数）。本章通道：
> C（`examples/77_goedel/ex77_goedel.v`）/
> L（`examples/77_goedel/ex77_goedel.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| 平方配对 | cp(a,b)=(a+b)²+b 与单射性真定理 | C/L |
| 树编码 | 极小一阶语法（项/公式）的 gcf 编码+**单射性定理** | C/L |
| 代入现场 | subt/subf 语法层代入（绑定位保护）三例对账 | C/L |
| β-函数 | b mod (1+(i+1)c) 的序列编码：有界搜索命中/冲突双现场 | C/L |
| 自引骨架 | dsub 模板代入+码值增长+有界无不动点 | C/L |

上一章把「可计算」做成了语法树（prf 构造子）；本章再进一步：把**语法树本身**
编码成自然数——公式变成数、代入变成数上的运算、证明变成数的序列。这就是
哥德尔 1931 年的「算术化」：一旦元数学对象都是数，「谈论自身的系统」就有了
着落点。78 章的不完备性证明以本章的编码为地基。

## 一、哥德尔配对：从两个数到一个数

编码的第一块砖是**配对函数**：把两个自然数无损地压成一个。教科书常用
指数配对 2^a·(2b+1)，但本章机器面选**平方配对**：

```coq
Definition cp (a b : nat) : nat := (a + b) * (a + b) + b.
```

选它的理由是一次**实测教训**：指数配对把编码放进指数位，Coq 的 nat 是
单仁（unary）表示，树深两层的码就到 2^145——Compute 直接内存爆炸。平方
配对的增长是多项式的，单射性证明也只要平方的严格单调：

```coq
Lemma sq_step : forall s, s * s + s < (s + 1) * (s + 1).

Theorem cp_inj : forall a1 b1 a2 b2,
  cp a1 b1 = cp a2 b2 -> a1 = a2 /\ b1 = b2.
```

证明骨架（两侧对称）：若 s₁=a₁+b₁ < s₂=a₂+b₂，则 s₁²+b₁ ≤ s₁²+s₁ <
(s₁+1)² ≤ s₂² ≤ s₂²+b₂——左边被严格夹死，等式不可能。Lean 侧的坑：
omega 不展开非线性乘积，把平方项作为不透明原子喂给纯线性推理的辅助引理
（`key : ∀ p q r X Y Z, X + p < Y → Y ≤ Z → X + q = Z + r → q ≤ p → False`）
才过。三元组态 pr3 a b c := cp a (cp b c) 嵌套两层 cp，单射性连用两次。

## 二、语法树编码与单射性

极小一阶语言（78 章会扩成 mini-S）：项是变元或数字，公式是等式、否定、
蕴含、存在量词。编码给每个构造子一个 tag，子结构码用 cp 嵌套：

```coq
Inductive tm : Type := var (n : nat) | num (n : nat).
Inductive fm : Type :=
| eqt (t1 t2 : tm) | neg (a : fm) | imp (a b : fm) | exq (x : nat) (a : fm).

Definition gct (t : tm) : nat :=
  match t with
  | var n => pr3 0 n 0
  | num n => pr3 0 n 1
  end.

Fixpoint gcf (φ : fm) : nat :=
  match φ with
  | eqt t1 t2 => pr3 1 (gct t1) (gct t2)
  | neg a => pr3 2 (gcf a) 0
  | imp a b => pr3 3 (gcf a) (gcf b)
  | exq x a => pr3 4 x (gcf a)
  end.
```

编码**可解码**的机器化身就是单射性定理：

```coq
Theorem gct_inj : forall t1 t2, gct t1 = gct t2 -> t1 = t2.
Theorem gcf_inj : forall φ1 φ2, gcf φ1 = gcf φ2 -> φ1 = φ2.
```

gcf_inj 对公式结构归纳：两边的 tag（cp 首槽）必须相等——不同构造子的
tag 是不同的小数字，discriminate 即刻分家；同构造子则 cp_inj 拆出子码
等式，递归调用归纳假设。书 §3.4 的编码方案用的是素数幂（2^t·3^a·5^b），
单射性靠素因子分解唯一——数学上等价，机器上我们的 cp 版把「唯一分解」
换成了「平方严格夹逼」，证明负担轻一个量级。样本值给直觉：

```coq
Example gcf_samples :
  (gcf (eqt (var 0) (num 0)), gcf (neg (eqt (var 0) (var 0))),
   gcf (exq 0 (eqt (var 0) (var 0))))
  = (1891, 10, 38).
```

## 三、代入：语法层的现场

算术化的另一半是把**代入**变成数上的运算。语法层的 subt/subf 先行：

```coq
Definition subt (t : tm) (x : nat) (u : tm) : tm :=
  match t with
  | var n => if Nat.eqb n x then u else var n
  | num _ => t
  end.

Fixpoint subf (φ : fm) (x : nat) (u : tm) : fm :=
  match φ with
  | eqt t1 t2 => eqt (subt t1 x u) (subt t2 x u)
  | neg a => neg (subf a x u)
  | imp a b => imp (subf a x u) (subf b x u)
  | exq y a => if Nat.eqb y x then exq y a else exq y (subf a x u)
  end.
```

注意 exq 行：绑定位与被代入位撞名时整体保留——这是**天真代入**；真正的
换名机械（α-变换）是文档线。本章现场里 u 恒取闭项 `num n`，天然避开撞名。
三例对账把行为钉死（自由位替换、绑定位保护、非绑定量词穿透各一）。

书 §3.4 的定理「sub 是原始递归的」——即存在 71 章语言里的 prf 函数在编码
上实现 subf——是文档线：它把「语法操作」拉进「可计算函数」的世界，是
78 章表示性论证的传送带。

## 四、β-函数：中国剩余的序列编码

单个配对不够用——证明是公式的**序列**，需要一个数记住一整列数。哥德尔的
答案是 β-函数（书 §3.4 引理 3.22 的骨架）：

```coq
Definition beta (b c i : nat) : nat := b mod (1 + (i + 1) * c).

Fixpoint bcheck (b c : nat) (xs : list nat) (i : nat) : bool :=
  match xs with
  | [] => true
  | v :: rest => Nat.eqb (beta b c i) v && bcheck b c rest (S i)
  end.

Fixpoint findb (xs : list nat) (c b fuel : nat) : option nat :=
  match fuel with
  | O => None
  | S f => if bcheck b c xs 0 then Some b else findb xs c (S b) f
  end.
```

一个 b、一个 c，第 i 位就是 b 对 1+(i+1)c 取余。要编码序列 [x₀,…,x_{k-1}]，
选互素的模族（c 取阶乘倍数即可），中国剩余定理保证存在 b 逐位还原。机器面
双现场：

```coq
Example beta_rt : match findb [2; 5; 1] 6 0 2000 with
                  | Some b => bcheck b 6 [2; 5; 1] 0
                  | None => false
                  end = true.
Example beta_witness : bcheck 590 6 [2; 5; 1] 0 = true.
Example beta_conflict : findb [2; 7] 2 0 500 = None.
```

c=6 时模族 7、13、19 两两互素——搜索在 b=590 命中（590 mod 7=2、mod 13=5、
mod 19=1，逐位精确）；c=2 时模族 3、9 非互素且余数冲突——搜索扑空。
**互素不是装饰，是 CRT 的入场券**——反例现场把这条定理的侧条件演活了。
一般 CRT 的完整证明是文档线（模逆元构造），机器面以「构造性搜索必中」
为存在性证词。

## 五、自引骨架：为什么需要 β

不完备性证明的最深处是**不动点引理**（书 §3.5）：对任何含一个自由变元的
公式 B(x)，存在句子 C 使 S ⊢ C ↔ B(⌜C⌝)——每个性质都能造出「说我具有
这个性质」的句子。机器面给它的素材骨架：

```coq
Definition Tdiag : fm := eqt (var 0) (var 1).
Definition dsub (n : nat) : fm := subf Tdiag 0 (num n).

Example dsub_first : gcf (dsub 0) = 4555.
```

朴素的自指尝试是解 gcf(dsub n) = n——有界搜索无解（Lean 侧 native_decide
跑到 n=200 仍 None）：**直接的编码不动点不存在**，因为代入把码塞进了正在
定义的式子。书 3.5 的构造绕过这一点的手法正是 β-函数：把「对自身编码做
代入」的**中间序列**压进一个数（b, c），代入变成一次算术运算，自指方程
才闭合。这是 β-函数在整个证明里的真正角色——不是省空间的技巧，而是让
自指**可表达**的机关。78 章把这条线走完。

## 六、与前后的接驳

| 章 | 关系 |
|---|---|
| 35 递归函数 | 编码的存在性靠「sub 是 PR」类定理——71 章的 prf 是那类论证的语言 |
| 37 不完备性 | 本章是它的地基：码+β+sub 三件套在那里拼成不动点与真谓词论证 |
| 57 无穷集合 | 2^a·3^b 编码（旧 108 章）是本章配对思想的朴素前身；单仁 nat 的算力预算是两章共同的实测主题 |

## 坑位速记（本章实测）

- **指数配对炸内存**：2^a·(2b+1) 首版让 Compute 对两层深的树 OOM——
  nat 单仁表示下 2^145 不可算。平方配对 (a+b)²+b 多项式增长、单射性
  证明只要 `s²+s < (s+1)²`（Nat.mul_succ_l/r + lia）。**编码的数学等价
  不等于机器等价**。
- **嵌套配对的算力预算**：cp 每嵌套一层再平方一次——dsub 1 的码已破百万
  （1e6 单仁 kernel 转换栈溢出），dsub 2 上亿。Coq 侧样本止步 n=0、
  搜索现场用小 c；Lean 侧 native_decide（GMP 大数）能跑 n=200——
  同构证明、不同算力，账本里各记各的。
- **omega 不碰非线性积**：cp_inj 的 Lean 版把平方项作原子传给全称辅助
  引理（纯线性）——直接 omega 在「两个平方原子+一个和式」上能过，但混入
  未归一的 `(a+b)*(a+b)` 与 `(a+b+1)*(a+b+1)` 变体时失败——原子化要
  手工。
- **Lean 的 if 计算不自动**：`(upd … 2 d) 0` 化简出 `if (0 == 2) = true`
  后 simp only 不动——用 `change x + d = y at h` 让转换检查做闭式 iota。
- **Lean induction 的名字顺序**：`| imp a iha b ihb` 是错的——参数全部
  在前、归纳假设在后：`| imp a b iha ihb`。
- 账本：Coq 全章零公理；Lean cp_inj/gcf_inj 带 [propext, (Classical.choice),
  Quot.sound]（simp/omega 层引入）。

## 小结

算术化把元数学压进算术：配对函数搭桥、树编码命名、β-函数记住序列、
代入变成运算。单射性定理是「编码可解码」的证书，CRT 双现场把互素侧条件
演活，dsub 骨架演示自指为什么非 β 不可。下一章在这块地基上竖起二十世纪
数学最著名的定理。

---

上一章：[76 字问题与重写：Thue 系统与 Tseytin 半群](docs/76-wordproblem.md) · 下一章：[78 哥德尔不完备性：可表示性、算术化与对角化](docs/78-incompleteness.md)
