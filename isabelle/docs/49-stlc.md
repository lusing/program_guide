# 49 · λ 演算与简单类型 λ 演算

对应示例：`../examples/T49_stlc.thy`

## 49.1 一句话概括

Isabelle 的项语言来自 STLC——implementation 手册第 1 章的推理
规则就是它上面的自然演绎。本章把 STLC 完整形式化（de Bruijn
指标），并证**类型安全**两定理：进展（良型闭项要么是值要么能
前进）与保持（前进一步类型不变）。Wright–Felleisen 经典配方。

## 49.2 语法与类型规则

```isabelle
datatype ty = TNat | TFun ty ty  (infixr "→" 60)
datatype tm = Var nat | Lam ty tm | App tm tm

inductive typing ("_ ⊢ _ : _" 50) where
  T_Var [intro!]: "i < length env ⟹ nth env i = T ⟹ env ⊢ Var i : T"
| T_Lam [intro!]: "T1 # env ⊢ t : T2 ⟹ env ⊢ Lam T1 t : T1 → T2"
| T_App [intro!]: "env ⊢ t1 : T1 → T2 ⟹ env ⊢ t2 : T1 ⟹ env ⊢ App t1 t2 : T2"
```

环境是**内层在前**的表（Var 0 指向最内层抽象）。
`i < length env` 前期不能省——进展定理的空环境情形靠它出矛盾
（实测省掉后 `Ex (⟼ (Var i))` 杀不掉）。

## 49.3 带 cutoff 的移位与带位置的代换

**嵌套数字模式 primrec 不收**（`Nonprimitive pattern`）——
`Var 0` 分派用 `case i of 0 ⇒ ...` 折：

```isabelle
primrec liftn where
  "liftn d k (Var i) = (if i < d then Var i else Var (i + k))"
| "liftn d k (Lam T t) = Lam T (liftn (Suc d) k t)"
| ...
primrec substn where
  "substn d s (Var i) = (if i < d then Var i else if i = d then s else Var (i - 1))"
| "substn d s (Lam T t) = Lam T (substn (Suc d) (liftn 0 1 s) t)"
| ...
```

**移位必须带 cutoff**：不带截止的"全体 +1"进抽象时会把绑定
变量也抬走，weakening 的 Lam 情形对不上 IH（本章最大实测坑）。

## 49.4 两条结构引理（分裂前提式归纳）

weakening 与代换引理都用**"env = Γ1 @ T0 # Γ2 作为前提"**的
归纳形态（对 Γ1/s 同时 arbitrary），这是位置敏感引理的标准式：

```isabelle
lemma lift_ok:
  "env ⊢ t : T ⟹ env = Γ1 @ Γ2 ⟹ Γ1 @ T0 # Γ2 ⊢ liftn (length Γ1) 1 t : T"

lemma subst_ok:
  "env ⊢ t : T ⟹ env = Γ1 @ T0 # Γ2 ⟹ Γ1 @ Γ2 ⊢ s : T0 ⟹
   Γ1 @ Γ2 ⊢ substn (length Γ1) s t : T"
```

Lam 情形里 `s` 要 `liftn 0 1` 抬一层——合法性恰是 weakening，
两条引理互相咬合。

## 49.5 进展与保持

进展用**结构归纳 + 反演**（`blast elim: typing.cases`）而非规则
归纳——canonical forms（值+箭头类型 ⟹ 是 Lam）是必经一步：

```isabelle
theorem progress: "[] ⊢ t : T ⟹ is_value t ∨ (∃t'. t ⟼ t')"
theorem preservation: "Γ ⊢ t : T ⟹ t ⟼ t' ⟹ Γ ⊢ t' : T"
```

保持对 **eval 归纳**（typing 作携带前提），β 情形拆 Lam 反演后
正是代换引理的 Γ1=[] 实例。

## 49.6 坑位清单（实测）

1. `Var 0` 嵌套模式 primrec 不收。
2. 移位必须带 cutoff（绑定变量不能抬）。
3. 代换进壳抬 `s` 一层，合法性=weakening。
4. 进展里 canonical forms 必不可少；归纳泛化 `T`
   （`arbitrary: T`——子项的类型不同）。
5. 保持用 eval 的归纳；β 情形靠反演拆 Lam。
6. 空环境的进展才成立；`Var 0` 良型但卡住——反例本身。
7. **`induct` 与 `induction` 是两个方法**：只有 `induction`
   给 case 的 `.IH`/`.prems` 绑定（实测 `induct` 下
   `T_Lam.IH` Undefined fact——从 List.thy 官方惯用法反推出来的）。

## 49.7 与其他章的接口

- 第 31 章 inductive、第 4 章 datatype：本章的工具箱。
- 第 50 章自然演绎：STLC 类型规则就是 ND 规则。
- 第 42 章 tactic：`blast elim:` 反演的 ML 侧。
