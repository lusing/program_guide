# 67 · 不动点与格构造：Bourbaki–Witt、序连续、确界接口、补格

对应示例：`../examples/lib/T67_order_fixpoint.thy`（IsaTutLib 会话，
依赖 `Bourbaki_Witt_Fixpoint`、`Order_Continuity`、`Extended_Nat`、
`Lattice_Constructions`、`Lub_Glb`、`Complemented_Lattices`、
`Complete_Partial_Order2`）

第 51 章讲过 Knaster–Tarski（完备格上单调函数的不动点）。本章是
序理论的工具箱专场：一个更弱前提的不动点定理（Bourbaki–Witt）、
连续性与确界的两个接口层、以及格的「构造子手术」。

## 67.1 Bourbaki_Witt_Fixpoint：无单调性前提的不动点

Knaster–Tarski 要完备格 + 单调函数；Bourbaki–Witt 只要
**链完备**（每条链有 lub）加**递增**算子（`x ≤ f x`，不需要
单调性！）。locale `bourbaki_witt_fixpoint` 收三个参数——`lub`
算子、关系集合 `leq`、算子 `f`——然后：

- `iterates_above a`：从 a 出发，`f` 步进 + 链上取 lub 的归纳
  闭包（注意闭包含**极限步**，不只是有限迭代）；
- `fixp_above a = lub (iterates_above a)`；
- 结论 `fixp_above_unfold`：`a ∈ Field leq ⟹ fixp_above a = f (fixp_above a)`。

实例化到 `enat`（第 61 章：完备线序、`eSuc` 递增）：

```isabelle
interpretation bw: bourbaki_witt_fixpoint Sup "{(x, y::enat). x ≤ y}" eSuc
proof
  show "Partial_order {(x, y::enat). x ≤ y}"
    by (auto simp: partial_order_on_def Field_def preorder_on_def
         intro!: refl_onI transI antisymI intro: order_refl)
next  (* lub_least：链上界的最小性 *)
  fix M :: "enat set" and z
  assume "M ∈ Chains {(x, y). x ≤ y}" "M ≠ {}" "⋀x. x ∈ M ⟹ (x, z) ∈ {(x, y). x ≤ y}"
  then show "(Sup M, z) ∈ {(x, y). x ≤ y}" by (simp add: Sup_least)
next  (* lub_upper：Sup 是上界 *)
  fix M :: "enat set" and x
  assume "M ∈ Chains {(x, y). x ≤ y}" "x ∈ M"
  then show "(x, Sup M) ∈ {(x, y). x ≤ y}" by (simp add: Sup_upper)
next  (* lub_in_Field *)
  fix M :: "enat set"
  assume "M ∈ Chains {(x, y). x ≤ y}" "M ≠ {}"
  show "Sup M ∈ Field {(x, y::enat). x ≤ y}" by (auto simp: Field_def)
next  (* increasing：x ≤ eSuc x *)
  fix x :: enat
  assume "x ∈ Field {(x, y). x ≤ y}"
  show "(x, eSuc x) ∈ {(x, y). x ≤ y}" by (simp add: eSuc_plus_1[symmetric])
qed
```

四条义务恰好是「完备格 + 递增」的逐条展开——写实例化就是
把类实例里的格定律往关系集合语言上搬。结论读出：从 0 出发的
不动点是 ∞——eSuc 的唯一不动点，迭代永远不到头，极限收在无穷：

```isabelle
lemma bw_fixpoint: "bw.fixp_above 0 = ∞"
proof -
  have zero: "0 ∈ Field {(x, y::enat). x ≤ y}" by (auto simp: Field_def)
  have fixeq: "bw.fixp_above 0 = eSuc (bw.fixp_above 0)"
    by (rule bw.fixp_above_unfold[OF zero])
  show ?thesis
  proof (cases "bw.fixp_above 0")
    case (enat n)
    with fixeq show ?thesis by (simp add: eSuc_enat)
  next
    case infinity
    then show ?thesis by simp
  qed
qed
```

证明形状值得记：先用 `fixp_above_unfold` 拿不动点方程，再按
enat 两种形态分情形——有限形态与方程矛盾（`eSuc` 单射），只剩
∞。（顺带一个实测坑：事实名 `fix` 撞 Isar 关键字 `fix`，报的是
外层语法错——起名避开关键词表，这里用 `fixeq`。）

库末尾还有 `fixp_above_conv_while`：这个不动点恰好是
`while` 循环「迭代到不变」的语义——不动点理论与程序语义的
接口就在这里。

## 67.2 Order_Continuity：连续映射保持极限

`Order_Continuity` 定义 `sup_continuous`（`F (SUP i. M i) =
(SUP i. F (M i))`，对单调序列）与对偶的 `inf_continuous`——
斯科特连续性的可数形式。内建 intro 规则集
`order_continuous_intros`（常函数、恒等、复合、sup/inf 保连续）；
61 章 enat 上的 `sup_continuous_eSuc` 是它的用户：

```isabelle
lemma "sup_continuous (eSuc :: enat ⇒ enat)"
  using sup_continuous_eSuc[OF sup_continuous_id] by (simp add: id_def)
```

「连续 + 单调」组合出 Kleene 不动点链的收敛——这是把 67.1 的
抽象不动点算到具体值的通道。

## 67.3 Lub_Glb：老式确界接口

`Lub_Glb` 是分析库出现前的确界语言，特色是**不要求整个类型
完备**——确界存在性逐集合证：载集 R 内、S 的上界 `isUb R S x`、
最小上界 `isLub R S x`（对偶 `isLb`/`isGlb`），辅助谓词
`S *<= x`/`x <=* S`（注意：第一个参数是**载集**不是关系）。
闭区间上确界是端点：

```isabelle
lemma isLub_interval: "isLub UNIV {0..(1::real)} 1"
  by (auto simp: isLub_def leastP_def isUb_def setle_def setge_def)
```

（展开后：1 是上界显然；任何上界 x 因 `1 ∈ {0..1}` 而 ≥ 1。）
两条关键引理：`isLub_unique`（线序上唯一）与
`isLub_le_isUb`（最小性）。与现代 `Sup`/`Inf`（完备格类）的分工
由此清楚：类实例在、全类型完备时用后者；逐集合的确界存在性
用前者。

## 67.4 Lattice_Constructions：给类型加顶底与拍平

三个「类型构造子级」的格手术：`'a bot`（加底元素 `Bot`）、
`'a top`（加顶 `Top`）、`'a flat_complete_lattice`（拍平：
底 < 所有值 < 顶，值之间不可比——完全格）。原类型的序经
`Value` 注入继续使用：

```isabelle
lemma "Bot ≤ (x :: nat flat_complete_lattice)"
  by simp

lemma flat_two_values:
  "Value a ≤ (z :: 'a flat_complete_lattice) ⟹ Value b ≤ z ⟹ a ≠ b ⟹ z = Top"
  by (rule greater_than_two_values)
```

第二条是拍平格的标志性事实：两个不同的值若有共同上界，那上界
只能是顶。拍平格是抽象解释里常量传播格的标准件。

## 67.5 Complemented_Lattices：补格

`complemented_lattice` 类（有界格 + 补 `- x` + 补公理
`x ⊓ - x = ⊥` 与对偶），并证 `boolean_algebra` 是它的实例。
补格上补惟一（`compl_unique` 一族）：

```isabelle
lemma compl_meet_bot: "x ⊓ - x = (⊥ :: 'a :: complemented_lattice)"
  by simp

lemma bool_double_compl: "- (- (x::bool)) = x"
  by simp
```

（⊓/⊥ 记号开了 `lattice_syntax` bundle——60 章坑 7 的开关。）

## 67.6 Complete_Partial_Order2：ccpo 的工具箱

`Complete_Partial_Order2` 是 Main 的 `ccpo` 类（第 35 章
`partial_function` 的语义底座）的补充包：定点归纳
`fixp_induct` 的更多形态、容许谓词 `ccpo.admissible` 的构造
规则、迭代逼近 `iterates` 的代数。它没有新的定义性内容，全是
让「函数不动点」证明更好写的工具——partial_function 生成的
`.mono`/`.fixp` 引理的证明都收编在这里。

## 67.7 坑位清单（实测）

1. Bourbaki–Witt 的 locale 参数是**关系集合**加显式 `lub`
   算子，不是类实例——实例化时把 `Sup` 与 `{(x,y). x ≤ y}`
   这样喂进去。
2. `iterates_above` 的闭包含**极限步**（链的 lub），所以
   fixp_above 能一步到 ∞ 这类超限点。
3. `Partial_order`（大写，关系集合上的性质）与 `order` 类不
   同层：`Partial_order r ⟷ partial_order_on (Field r) r`。
4. **fact 名撞 Isar 关键字报外层语法错**（实测 `fix` 撞
   `fix`，错误是「proposition expected, end-of-input」，
   位置还指错行）——起名避开 Isar 关键词表。
5. Lub_Glb 的第一参数是载集：`isLub UNIV S x` 读作「x 是 S
   在全类型上的确界」，别把序关系传进去。
6. `bot`/`top`/`flat_complete_lattice` 三个类型的构造子同名
   （`Value`/`Bot`/`Top`），同堂时写全类型标注。
7. `sup_continuous` 定义里只对**单调序列**交换 SUP，不是任意
   集合——文献里「连续」口径可能更宽，引用时对齐定义。
8. 补格的 `- x` 与数值相反数共享记号（`uminus` 类），看类型
   分辨。
9. `eSuc` 递增性用 `eSuc_plus_1[symmetric]`（反向形态）最顺手。
10. 选工具看前提：有单调性走 ccpo/Complete_Partial_Order2
    （带归纳工具）；只有递增性走 Bourbaki–Witt（没归纳原则但
    前提弱）。

## 67.8 与其他章的接口

- 第 51 章 Knaster–Tarski：本章是它的「弱化前提」对照——
  两个不动点定理的前提-结论对照表值得对着读。
- 第 35 章 partial_function：ccpo 底座，67.6 是它的工具库。
- 第 61 章 enat：Bourbaki–Witt 的实例化宿主。
- 第 30 章序与格类层次：本章所有类实例（补格、拍平格）都是
  那条类链上的新节点。
- 第 60 章：`lattice_syntax` bundle 的开关（⊓/⊥ 记号）。
