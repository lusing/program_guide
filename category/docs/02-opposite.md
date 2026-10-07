# 02 反范畴与对偶原理

> 对书：《高级范畴论》1.5（范畴的运算）、2.2 的对偶视角 /
> Simmons 2.8（Using the opposite category）/ 贺伟 1.4 前置。
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

于是每个范畴论陈述都免费获得一个孪生：mono↔epi（03 章）、
积↔余积（09 章）、极限↔余极限（11 章）、反射↔余反射（15 章）。
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
同构」的裂缝**从第一章就埋下，直到 07 章（范畴等价）才正面处理。

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
   14 章老坑在此复现）；Fin 的嵌入是 `Fin.suc` 全名。

---

上一章：[01 认识范畴论](01-intro.md) · 下一章：[03 特殊态射与特殊对象](03-arrows.md)
