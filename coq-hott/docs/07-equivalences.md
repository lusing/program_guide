# 07 等价 —— 什么叫"两个类型一样"

> 本章代码：[`examples/07_equivalences.v`](../examples/07_equivalences.v)

集合论里"两个集合一样"有一个清楚的答案：存在双射。类型论里这个问题微妙得多，
因为类型不只是点的集合，还有路径、路径之间的路径……"一样"必须把所有这些层次都对上。
这一章给出 HoTT 的回答——**等价**（equivalence）——并解释为什么它的定义看起来比
"有逆函数"复杂一点，以及这点复杂换来了什么。

## 7.1 第一次尝试：有逆函数

直觉的定义：`f : A -> B` 是等价，如果有 `g : B -> A` 使得 `f ∘ g == id` 且 `g ∘ f == id`。
这个概念叫**拟逆**（quasi-inverse），HoTT 书记作 qinv。

它在"是否存在"的意义上完全正确：`f` 有拟逆当且仅当它是等价。
问题出在**数据**上：类型 `qinv f`（所有拟逆构成的类型）不是命题——同一个 `f` 可以有
"不同"的拟逆证据，因为两个同伦 `f ∘ g == id` 和 `g ∘ f == id` 可以独立选取，
它们之间缺少一个相容条件。这会导致 `{f : A -> B & qinv f}` 和"A 与 B 的等价"
这个概念在高阶上对不齐。

## 7.2 HoTT 的定义：伴随等价

补上那个相容条件，就得到库里的定义：

```coq
Record IsEquiv {A B : Type} (f : A -> B) := Build_IsEquiv
  { equiv_inv : B -> A;
    eisretr   : f o equiv_inv == idmap;                    (* f (g b) = b *)
    eissect   : equiv_inv o f == idmap;                    (* g (f a) = a *)
    eisadj    : forall x, eisretr (f x) = ap f (eissect x) }.
```

四份数据：反函数、右逆同伦、左逆同伦，以及第四条 `eisadj`——它说"用右逆同伦
消掉 `f (g (f x))` 里的外层"与"用左逆同伦消掉内层再让 `f` 作用"这两条从 `f (g (f x))`
到 `f x` 的路径是**相等**的。这就是范畴论里伴随的三角恒等式之一，故名**伴随等价**。

加上这一条之后，`IsEquiv f` 成为一个**命题**（h-prop）：对给定的 `f`，
"它是等价"这件事至多有一种方式成立。于是 `A <~> B`（打包了 `f` 和 `IsEquiv f` 的记录）
里两个元素相等当且仅当底层函数相等——这正是我们想要的"一样"。

```coq
Record Equiv (A B : Type) := Build_Equiv
  { equiv_fun : A -> B;  equiv_isequiv : IsEquiv equiv_fun }.
Notation "A <~> B" := (Equiv A B).
```

`Equiv` 可以强制转换为函数，所以 `e : A <~> B` 时可以直接写 `e a`；反函数用 `e^-1`。

## 7.3 不用手写第四条：`equiv_adjointify`

好消息是你几乎永远不需要手工构造 `eisadj`。给定拟逆（两个同伦），
可以**修正其中一个同伦**使伴随条件成立，这个修正是机械的：

```coq
Check equiv_adjointify.
(* forall (f : A -> B) (g : B -> A), f o g == idmap -> g o f == idmap -> A <~> B *)
```

经典例子，布尔取反是 `Bool` 的自等价：

```coq
Definition equiv_bool_neg : Bool <~> Bool.
Proof.
  refine (equiv_adjointify negb negb _ _).
  - intro b; destruct b; reflexivity.   (* negb (negb b) = b *)
  - intro b; destruct b; reflexivity.
Defined.

Compute equiv_bool_neg true.        (* = false *)
Compute equiv_bool_neg^-1 true.     (* = false *)
```

对简单情形，`make_equiv` 这个 tactic 能自动搜出"反函数 + 两个同伦"：

```coq
Definition my_prod_symm (A B : Type) : A * B <~> B * A.
Proof. make_equiv. Defined.
```

## 7.4 等价构成群胚

和路径一样，等价有单位元、复合、逆：

| | 路径 | 等价 |
|---|---|---|
| 单位 | `1 : x = x` | `equiv_idmap : A <~> A`（`equiv_scope` 里也写 `1`） |
| 复合 | `p @ q` | `g oE f`（注意顺序是数学的 `g ∘ f`） |
| 逆 | `p^` | `e^-1`（`equiv_inverse`） |

```coq
Compute (equiv_bool_neg oE equiv_bool_neg) true.   (* = true *)
```

这张表不是巧合。第 11 章的泛等公理会说：**等价就是 `Type` 里的路径**。
那时这两列将真的合为一列。

## 7.5 `ap` 保持等价

若 `f` 是等价，则它在路径上的作用 `ap f : (x = y) -> (f x = f y)` 也是等价：

```coq
Check equiv_ap.   (* forall f, IsEquiv f -> forall x y, (x = y) <~> (f x = f y) *)
```

这是"等价保持所有结构"的第一个例子：它不仅把点一一对应，还把路径一一对应。
第 17 章会把这条性质推广成嵌入的定义。

## 7.6 等价穿过类型构造器

等价是"函子性"的：乘积、Σ、和、函数类型都把等价映到等价：

```coq
Check equiv_functor_prod'.   (* A <~> A' -> B <~> B' -> A * B <~> A' * B' *)
Check equiv_functor_sum.
Check equiv_functor_sigma.
```

第 14 章与第 18 章大量依赖这一点：要证明两个复杂类型等价，把它们拆成构造器，
在每个分量上给等价，再用 `equiv_functor_*` 拼回去。

## 7.7 沿等价做归纳：`equiv_ind`

路径归纳说：要对所有 `y` 和 `p : a = y` 证明某事，只需在 `(a, 1)` 上证明。
等价有一个类似的原则——要对所有 `b : B` 证明 `P b`，只需对所有 `a : A` 证明 `P (f a)`：

```coq
Check equiv_ind.
(* forall (f : A -> B), IsEquiv f -> forall P : B -> Type,
     (forall a, P (f a)) -> forall b, P b *)
```

直觉：`f` 是满的（每个 `b` 都是某个 `f a`），所以沿 `f` 把 `b` 换成 `f a` 不丢失一般性。
配合泛等后，它会升级成真正的"对等价做路径归纳"（`equiv_induction`，第 11 章）。

## 7.8 预告：另一种刻画

还有一种与伴随等价**逻辑等价、并且同样是命题**的刻画：
**`f` 是等价，当且仅当它的每个同伦纤维可缩**。

```coq
Check hfiber.             (* (A -> B) -> B -> Type；hfiber f b := {a : A & f a = b} *)
Check contr_map_isequiv.  (* IsEquiv f -> 所有纤维可缩 *)
```

"纤维可缩"是说对每个 `b`，解集 `{a & f a = b}` 不仅非空、不仅唯一，
而且"唯一性的证明也唯一"……一直到所有层次。这是第 08 章的主题，
也是把等价放进截断层级这把标尺（第 09、17 章）的入口。

## 小结

- "有逆函数"（拟逆）在存在性上够用，但作为数据不是命题；补上伴随条件 `eisadj` 后，
  `IsEquiv f` 成为命题。
- 用 `equiv_adjointify` 从拟逆造等价，用 `make_equiv` 对付简单情形。
- 等价构成群胚（`1`、`oE`、`^-1`），与路径的结构平行——泛等会让它们合一。
- 等价保持路径（`equiv_ap`），穿过类型构造器（`equiv_functor_*`），支持归纳（`equiv_ind`）。
- 等价 ⟺ 所有纤维可缩，下一章展开。

## 常见误区

1. **以为 `IsEquiv` 就是"有左右逆"**。少了 `eisadj` 的版本不是命题，
   不能作为"等价"的定义。但日常构造只需给左右逆，`equiv_adjointify` 会补齐。
2. **把等价当成"同构"的同义词**。HoTT 里没有独立的"同构"概念；对类型而言等价就是
   正确的"一样"。（范畴里对象的同构是另一个层次的事，第 20 章。）
3. **`equiv_adjointify` 的两个同伦顺序**：先 `f o g == idmap`（`B` 上），后 `g o f == idmap`（`A` 上）。
4. **`^-1` 有两个作用域**：函数作用域里是反函数（`B -> A`），等价作用域里是逆等价（`B <~> A`）。

## 练习

1. 用 `equiv_adjointify` 证明 `A + B <~> B + A`，再用 `make_equiv` 做一遍。
2. 证明 `Unit * A <~> A`。
3. 思考：为什么 `qinv f` 不是命题？构造一个 `f` 和它的两个"不同"的拟逆证据
   （提示：取 `f := idmap : Circle -> Circle`，左逆同伦可以选 `fun x => 1`，
   也可以选别的环路——第 13 章之后再回来想这个问题）。

---

**上一章**：[06 路径代数](06-path-algebra.md)
**下一章**：[08 同伦纤维与可缩性](08-fibers.md)
