# 03 反范畴与对偶原理

> 对书：《高级范畴论》1.5（范畴的运算）、2.2 的对偶视角 /
> Simmons 1.5、2.8（Using the opposite category）/ 贺伟 1.4 前置。
> 代码：`examples/02_opposite/`。

## 2.1 反范畴：一行构造，定律互译

`C^op`：同样的对象，箭头全部掉头，复合倒序：

```coq
Definition opposite (C : Category) : Category := {|
  Obj := Obj C;
  Hom := fun a b => Hom C b a;          (* 箭头掉头 *)
  idn := fun a => idn C a;
  comp := fun _ _ _ f g => comp C g f;  (* 复合倒序 *)
  idL := fun _ _ f => idR C f;           (* C 的右单位 = C^op 的左单位 *)
  idR := fun _ _ f => idL C f;           (* 反之亦然 *)
  assoc := fun _ _ _ _ f g h => eq_sym (assoc C h g f)
|}.
```

机器验证了**对偶原理**的微观形态：C^op 的 idL 定律展开后
`comp_op (idn a) f = f` 就是 `comp C f (idn C a) = f`——C 的 idR。
类型检查器逐条核对了定律搬运的方向，写反了它立刻报错。

于是每个范畴论陈述都免费获得一个孪生：mono↔epi（04 章）、
积↔余积（11 章）、极限↔余极限（13 章）、反射↔余反射（18 章）。
**证明一次，对偶免费**——这是范畴论经济性的来源。

## 2.2 预序范畴（瘦范畴）

预序 `(ℕ, ≤)` 看成范畴：对象 = `nat`，`Hom a b := Le a b`，
每两个对象之间**至多一条**态射（《高级范畴论》1.4 的经典例子，
也是「范畴比群更一般」的第一证人：任何预序都是范畴）。

自造 `Le`（放 Set 层，躲开证明无关性讨论）：

```coq
Inductive Le : nat -> nat -> Set :=
| le_refl : forall n, Le n n
| le_step : forall m n, Le m n -> Le m (S n).
```

复合（传递）递归在**第二参数**——这个方向选择直接决定哪条定律
免费（与 typetheory 教程 07 章「加法方向学」同构的现象）：

```text
idR : le_trans f (le_refl b) = f   —— match 分支，定义成立（refl 免费）
idL : le_trans (le_refl a) f = f   —— 要对 f 归纳
```

**Coq 的坑**：`le_trans` 想写成 Fixpoint 会撞索引 match 的墙——
分支里拿不到「b = n」的索引约束。三种语言的三种命运：

| | 写法 | 结果 |
|---|---|---|
| Coq | `Fixpoint + match as/in` | 分支约束缺失，类型对不上 |
| Coq | `revert p; induction q` + `Defined` | 通过（透明性保住 simpl） |
| Agda | 直接双模式 `le-trans p lerefl = p` | Agda 自动处理索引 |
| Lean | 方程式 `| p, .refl _ => p` | 自动处理索引 |

## 2.3 对偶的实感

`geCat := opposite leCat`：Hom a b = Le b a——「≥」范畴。同一棵
证明树 `le_step (le_step le_refl)`：

```coq
Example le35 : Hom leCat 3 5 := le_step 3 4 (le_step 3 3 (le_refl 3)).
Example ge53 : Hom geCat 5 3 := le_step 3 4 (le_step 3 3 (le_refl 3)).
```

一条 3→5 的态射，在 C^op 里就是 5→3。

FinCat 版更反直觉：`catFin^op` 的态射 `3 → 2` 就是 catFin 的函数
`fin 2 -> fin 3`——**「反方向的箭头」在函数世界里是同型函数**，
只是语义换了：

```coq
Check (fun x : fin 2 => Some x) : Hom (opposite catFin) 3 2.
```

## 2.4 op 的 op 不是 C（的重要教训）

`(C^op)^op` 的每个字段都定义地还原成 C 的对应字段，但两个 record
之间**没有相等**可言——类型论里 record 相等是逐字段的，范畴论里
相应的事实是 C ≅ (C^op)^op（且是典范同构）。**「相等」与「典范
同构」的裂缝**从第一章就埋下，直到 08 章（范畴等价）才正面处理。

## 2.5 两个小范畴与主截面（Simmons 1.5）

Simmons 1.5 专门停下来看两个最小的范畴，它们的用处贯穿全书：

**范畴 1** = 终范畴（02 章的 catOne）：一个对象、一条恒等。它是
Cat 的**终对象**。

**范畴 2** = 行走箭头：两个对象 0、1，一条非平凡箭头
`0 → 1`。机器版用三条箭头的索引族（Agda 写来最短，四行复合
就写满）：

```agda
data TwoHom : Bool → Bool → Set where
  two-id0 : TwoHom false false
  two-arr : TwoHom false true
  two-id1 : TwoHom true true

twoComp : ∀ {a b c} → TwoHom a b → TwoHom b c → TwoHom a c
twoComp two-id0 two-id0 = two-id0
twoComp two-id0 two-arr = two-arr
twoComp two-arr two-id1 = two-arr
twoComp two-id1 two-id1 = two-id1
```

它的意义：**任何图里的无名箭头都是它**。给定范畴 C 与 C 中箭头
f : a → b，存在唯一函子 2 → C 把 0↦a、1↦b、arr↦f——「交换图」
= 「从图示形状到 C 的函子」这句纲领的最小实例（05 章展开）。
04 章还会用它给出第一批「mono+epi 却不是 iso」的反例。

**预序的切片**（1.5.2）：把预序 S 当范畴后，切片范畴的长相可以
完全算出来——`(S↓s)` 是 s 上方的主上截面 ↑s、`(s↓S)` 是主下
截面 ↓s、`(s↓S↓t)` 是凸截面 {x | s ≤ x ≤ t}。截面的两条基本
单调性各是传递律的一次应用（零公理）：

```coq
Lemma down_mono : forall a b (hab : Le a b) x (hxa : Le x a), Le x b.
Proof. intros. exact (le_trans hxa hab). Qed.

Lemma up_anti : forall a b (hab : Le a b) x (hbx : Le b x), Le a x.
Proof. intros. exact (le_trans hab hbx). Qed.
```

↓ 随基点**单调**、↑ 随基点**反单调**——这两个相反的方向就是
25 章三个超幂集函子 ∃/I/∀ 的第一批观察。10 章会把
`(S↓s)` 认定为逗号范畴（Id↓K）的特例。

**两个反转**（1.5.3/1.5.4）：预序的 S^op 就是把 S 上下颠倒；
幺半群（单对象范畴）的 R^op 是同一个集合配新运算
`r ⋆ s := s·r`。最后，S 上「元素对 + 相容关系」的范畴
（1.3.3 的对偶版本）就是 `A × S^op`——**乘积 + 反范畴**两个
基本操作拼出预层方向，又一次「旧材料的新组合」。

## 坑位速记

1. opposite 的定律搬运要看清展开：`comp_op (idn) f` 展开是
   `comp C f (idn C)`——是 idR 不是 idL；填反了类型对不上。
2. Coq 索引归纳族的复合定义：Fixpoint match 拿不到分支约束，
   要 `revert + induction + Defined`（Qed 挡 delta，定律证明要
   simpl 就得透明）。
3. Agda 的 `Le` 模式匹配族自动处理索引（隐式 m n 模式）；
   Lean 的 `.refl`/`.step` 点模式同理——索引族的「文化差」。
4. Lean 方程式定义返回「第一参数」要给名字（`| p, .refl _ => p`），
   写 `.refl _` 会留 metavar 卡死 iota。
5. Agda `suc` 双义（Level/ℕ）——`renaming (suc to lsuc)`（typetheory
   17 章老坑在此复现）；Fin 的嵌入是 `Fin.suc` 全名。
6. Coq 里「Hom := if 合法 then unit else Empty」的瘦范畴：复合
   的非法分支在类型层看不见端点细化，术语 match 写不出来——
   `destruct a,b,c` 的 tactic 定义一遍暴露（twoComp）；
   索引族版的依赖 destruct 顺序敏感：先 destruct 让公共索引
   定下来的那条箭头。
7. Agda record 字段的模式 λ 匹配隐式对象要花括号：
   `idn = λ { {false} → two-id0 ; {true} → two-id1 }`。
8. Lean 的 `Le` 住在 Type 时，结论是构造而非命题——`theorem`
   拒收「不是命题的类型」，用 `def`。

---

上一章：[02 认识范畴论](01-intro.md) · 下一章：[04 特殊态射与特殊对象](03-arrows.md)
