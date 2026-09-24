# 05 · 数据类型

> 对应示例：[`examples/05_datatype/05_datatype.sml`](../examples/05_datatype/05_datatype.sml)

`Datatype` 在 HOL4 里不只是一个类型声明：它**一次性证明并存入一组定理**
（区分性、单射性、穷举、归纳原理、case 合同性）。本章把这几件"赠品"
全部列出来，并演示它们在证明里怎么用。

## 05.1 定义一个数据类型

```text
<<HOL message: Defined type: "bt">>
Nd 的类型：:bt -> num -> bt -> bt
Lf 的类型：:bt
```

```sml
val _ = Datatype `bt = Lf | Nd bt num bt`
val _ = out ("Nd 的类型：" ^ (type_of ``Nd`` |> type_to_string))
```

`<<HOL message: Defined type: "bt">>` 这条提示由 `Datatype` 无条件打印，
两条验证入口都会有（它不是"只在一个入口出现"的那种噪声），
所以它留在比对区间里是安全的。

## 05.2 自动生成了哪些定理

```text
bt_ 前缀：bt_nchotomy bt_induction bt_distinct bt_case_eq bt_case_cong bt_Axiom bt_11
datatype 前缀：datatype_bt
```

```sml
fun names pfx =
  String.concatWith " " (List.filter (fn n => String.isPrefix pfx n)
                                     (map #1 (DB.theorems "Tut05")))
```

| 名字 | 内容 | 用途 |
|---|---|---|
| `t_distinct` | 不同构造子造出来的值不等 | 消解矛盾 |
| `t_11` | 构造子是单射的 | 从 `Nd a = Nd b` 推出各分量相等 |
| `t_nchotomy` | 任何值都等于某个构造子的应用 | 穷举分情况 |
| `t_induction` | 结构归纳原理 | `Induct` / `Induct_on` 用它 |
| `t_case_cong` | case 的合同性 | 化简器穿过 `case` |
| `t_case_eq` | case 的求值等式 | `rw` 展开 `case` |
| `t_Axiom` | 原始递归原理 | 定义原始递归函数 |
| `datatype_t` | 上面几条的记录 | 工具内部用 |

> **`Datatype` 只登记定理，不给 ML 绑定。** 想用这些定理必须自己
> `DB.fetch "理论名" "定理名"`（22.3 节）。这是 `Datatype` 和 `Definition`
> 最容易被忽略的一处差别。

## 05.3 三件赠品：distinct / 11 / nchotomy

```text
⊢ ∀a2 a1 a0. Lf ≠ Nd a0 a1 a2
⊢ ∀a0 a1 a2 a0' a1' a2'.
    Nd a0 a1 a2 = Nd a0' a1' a2' ⇔ a0 = a0' ∧ a1 = a1' ∧ a2 = a2'
⊢ ∀bb. bb = Lf ∨ ∃b n b0. bb = Nd b n b0
```

```sml
val _ = out (thm_to_string (DB.fetch "Tut05" "bt_distinct"))
val _ = out (thm_to_string (DB.fetch "Tut05" "bt_11"))
val _ = out (thm_to_string (DB.fetch "Tut05" "bt_nchotomy"))
```

注意 `bt_11` 用的是 `⇔` 不是 `=`：结论是 `bool` 时打印器自动切换（04 章）。
构造子参数在生成的定理里叫 `a0 a1 a2` —— 名字是机器起的，不要依赖。

## 05.4 case 表达式

```text
case t of Lf => 0 | Nd l n r => n
⊢ (case Nd Lf 5 Lf of Lf => 0 | Nd l n r => n) = 5
case 的合同性定理：⊢ ∀M M' v f.
    M = M' ∧ (M' = Lf ⇒ v = v') ∧
    (∀a0 a1 a2. M' = Nd a0 a1 a2 ⇒ f a0 a1 a2 = f' a0 a1 a2) ⇒
    bt_CASE M v f = bt_CASE M' v' f'
```

```sml
val _ = out (term_to_string ``case t of Lf => 0 | Nd l n r => n``)
val _ = out (thm_to_string (EVAL ``case Nd Lf 5 Lf of Lf => 0 | Nd l n r => n``))
```

`case` 在内核里是 `bt_CASE` 的应用；`case … of …` 只是它的语法糖。
合同性定理里那两条带前提的等式（`M' = Lf ⇒ v = v'`）正是化简器能
"带着条件"化简分支的原因（20.5 节）。

## 05.5 用赠品做证明

```text
⊢ ∀t. t ≠ Lf ⇒ ∃l n r. t = Nd l n r
⊢ ∀l n r l' n' r'. Nd l n r = Nd l' n' r' ⇒ n = n'
```

```sml
val _ = out (thm_to_string
               (prove(``!t : bt. ~(t = Lf) ==> ?l n r. t = Nd l n r``,
                      Cases_on `t` >> simp [] >> metis_tac [])))
```

第一条：`Cases_on \`t\`` 用 `bt_nchotomy` 分情况；`Lf` 分支与假设 `t ≠ Lf`
矛盾，`simp` 直接消掉；`Nd` 分支用 `metis_tac` 收尾。
第二条：整个证明就是 `simp []` —— `bt_11` 已经在默认 simpset 里了。

> 第二个证明一行 `simp []` 就完事，不是因为它简单，而是因为
> `bt_11` 这类赠品一旦登记进理论，化简器就会自动拿去用。

## 05.6 多态数据类型

```text
<<HOL message: Defined type: "mytree">>
Node : :α -> α mytree -> α mytree -> α mytree
生成定理：mytree_nchotomy mytree_induction mytree_distinct mytree_case_eq mytree_case_cong mytree_Axiom mytree_11
```

```sml
val _ = Datatype `mytree = Leaf | Node 'a mytree mytree`
```

**类型参数不用显式声明**：构造器参数里出现的 quoted 类型变量（`'a`）会被
自动提升为类型参数。写成 `mytree 'a = ...` 反而会被拒：

<!-- 示意：这段是离线复现的报错文本，不是本示例的输出 -->
```text
Exception raised at Datatype.Datatype:
at Type.mk_type: "string" has not been declared
```

（上面这段是离线复现的报错文本，不是本示例的输出 —— 它用来说明
"把参数写在左边"会得到什么。）

## 05.7 互递归数据类型

```text
<<HOL message: Defined types: "evenlist", "oddlist">>
ECons : :num -> oddlist -> evenlist
OCons : :num -> evenlist -> oddlist
生成定理：evenlist_nchotomy evenlist_induction evenlist_distinct evenlist_case_eq evenlist_case_cong evenlist_Axiom evenlist_11 | oddlist_nchotomy oddlist_induction oddlist_case_eq oddlist_case_cong oddlist_Axiom oddlist_11
```

```sml
val _ = Datatype `
  evenlist = ENil | ECons num oddlist ;
  oddlist  = OCons num evenlist`
```

多个类型用分号隔开，一次定义完。注意 `oddlist_*` 里**没有** `distinct`：
它只有一个构造子，没有"不同构造子"可区分。

## 05.8 坑位清单

1. **`Datatype` 不给 ML 绑定** → 用生成的定理必须 `DB.fetch "理论名" "名字"`。
2. **类型参数不能写在左边** → `Datatype \`tree 'a = ...\`` 报 "Omit arguments to new type"；把 `'a` 写在右边让它自己推断。
3. **生成的定理里变量名是 `a0 a1 a2`** → 机器起的名字，不要依赖；用 `strip_tac` 后自己重命名。
4. **`_11` 定理打印成 `⇔`** → 结论是 bool，打印器自动切换；它不是另一条定理。
5. **`case` 要写全所有构造子** → 漏一个会报 "inexhaustive"；顺序无所谓但必须全。
6. **`Datatype` 会打印 `Defined type: "..."`** → 这条两条入口都有，留在区间里不影响比对。
7. **构造器名字不能和已有常量重复** → 报 "already declared"；换名字或用不同理论。
8. **`_distinct` 只在有两个以上构造子时才有** → 单构造子类型（如 `oddlist`）没有它。
9. **互递归类型用分号分隔，一次定义** → 分成两个 `Datatype` 会互相找不到。
10. **`Nd` 的类型里 `:` 后面是参数类型串** → `:bt -> num -> bt -> bt` 是 curried 的，不是 `(bt, num, bt) -> bt`。

---

上一章：[04 · 内核：定理与推导规则](04-kernel.md) ·
下一章：[06 · 递归定义与终止性](06-recursion.md)
