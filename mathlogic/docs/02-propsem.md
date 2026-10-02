# 02 命题逻辑：语法、语义与蛮力判定器

> 对书：Huth&Ryan §1.3-1.4 / Ben-Ari 3e §2.2-2.7 / EFT II-III / Mendelson §1.1-1.2

公式是一棵**归纳类型**的树；语义是一个布尔函数 `eval`；判定器
= 枚举公式全部变元的所有赋值。本章旗舰是一对可靠性定理：

- `check f = true → ∀e, eval e f = true`（报「有效」时语义有效）
- `check f = false → ∃e, eval e f = false`（报「不可满足」时反赋值存在）

两边的桥是**满足一致性引理**（coincidence lemma，EFT III.5）：
`eval` 只看 `vars f` 里出现的那几个变元。

## 公式与语义（Coq 版）

```coq
Inductive form : Type :=
| FVar : nat -> form | FImp : form -> form -> form
| FAnd : form -> form -> form | FOr : form -> form -> form
| FNeg : form -> form | FFals : form.

Fixpoint eval (e : nat -> bool) (f : form) : bool := ...
Fixpoint vars (f : form) : list nat := ...
```

赋值是函数 `nat → bool`；判定器枚举的「向量」通过
`assignOf vs v := fun n => lookup n (combine vs v)` 变回赋值。
四家同构：Coq `form`、Agda `Form`、Lean `Form`、Isabelle `form`。

## 一致性引理：证什么

```
agree : (∀x ∈ vars f, e₁ x = e₂ x) → eval e₁ f ≡ eval e₂ f
```

对 `f` 归纳，六个构造子六个分支。它就是模型论里「满足关系只依赖
自由变元」的命题版，也是后面 FOL 代入引理（14 章）的前奏。

## 蛮力判定器：怎么知道它没算错

```
allVectors vs = map (false∷) (allVectors xs) ++ map (true∷) (allVectors xs)
check f = forallb (λv → eval (assignOf (vars f) v) f) (allVectors (vars f))
```

三条辅助引理撑起双向可靠：

1. `lookup_zip_map`：`x ∈ vs → lookup x (zip vs (map e vs)) = e x`
   ——「`map e vs` 这个向量恰好代表赋值 `e` 自己」；
2. `map_in_allVectors`：`map e vs ∈ allVectors vs`
   ——「`e` 的向量确实被枚举到」（满射性）；
3. `forallb_false_witness`：`forallb p l = false → ∃v ∈ l, p v = false`
   ——「报告失败必有现场」。

`check_true_valid` 的证明骨架（四家一致）：

```
eval e f
  = eval (assignOf vs (map e vs)) f     ← agree + 引理 1（e 与自己的向量一致）
  = true                                 ← 引理 2 + forallb 全真
```

## 现场：真值表语义天生经典

```coq
Example peirce_sem_valid :
  check (FImp (FImp (FImp (FVar 0) (FVar 1)) (FVar 0)) (FVar 0)) = true.
Proof. reflexivity. Qed.
```

Peirce 律在**语义层**恒真（布尔值只有 true/false，经典二值）；
但在**构造证明**里推不出来（04/11 章正面处理）。语义与证毕的这道缝，
就是可靠性与完备性定理要缝的缝（23 章）。

## 四家写法对照

| | Coq 8.20 | Agda 2.8 | Lean 4.25 | Isabelle |
|---|---|---|---|---|
| 公式 | `Inductive form` | `data Form : Set` | `inductive Form` | `datatype form` |
| 一致性引理 | `rewrite (IH1 e1 e2)` 带前置子目标 | `rewrite agree-a | agree-b` | `rw [iha, ihb]` | `by (induction f) auto` |
| 全真拆解 | `proj1 (forallb_forall _ _) H` | 自造 `all-∈` | `List.all_eq_true` | `list_all_iff` |
| 现场计算 | `reflexivity` | （类型检查即计算） | `by decide` | `by eval` |

Isabelle 的证明密度低一个数量级——`agree_eval` 一行
`by (induction f) auto`，这是经典内核+重写自动化的红利。

## 坑位速记

- **Coq**：`In x (a :: l)` 展开是 `a = x \/ ...`（表头在等号左边）；
  iff 引理用 `proj1 (forallb_forall _ _) H` 取向，`apply ... in H` 对 iff 失灵；
  `apply in_map` 后 `IH` 是全称的，要 `exact (IH e)`。
- **Agda**：布尔 `if` 配 `with` 是死胡同——with 只做语法抽象，钻不进
  `lookup` 的展开；换 Dec 版（`x ≟ y` 的 yes/no 自带证明）；
  `rewrite` 与 `with` 混用会让 where 作用域失效（搬 where 辅助函数）；
  stdlib 的 `≡ᵇ⇒≡` 吃 `T`-谓词不是布尔相等——API 一律自造小引理最稳；
  荒谬分支对最后参数写 `()`（`λ ()` 只用于函数目标）。
- **Lean**：`Form.and` 与 `Bool.and` 在 `open Form` 后撞名——构造子改名
  `conj/disj`；`cases h : e x` 已经把目标里的 `e x` 代换掉，别再 `rw [h]`；
  `rfl` 算不动 `check` 时换 `by decide`（内核归约 vs `Decidable` 求值）。
- **Isabelle**：`lemma[of a b]` 的位置参数按变量**在命题里的出现顺序**，
  实参类型对不上时先查顺序（本章 `lookup_zip_map[of _ "vars f"]` 踩过）。
- **示例自检**：`(p₀ ∨ p₁)` 不是有效式——蛮力判定器报 false 是**对的**，
  是例句错了（Lean 的 `decide` 直接证伪了我最初的示例——判定器没 bug）。
