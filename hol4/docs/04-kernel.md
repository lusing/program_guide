# 04 · 内核：定理与推导规则

> 对应示例：[`examples/04_kernel/04_kernel.sml`](../examples/04_kernel/04_kernel.sml)

HOL4 的可靠性来自**小内核**：所有定理最终都由少数几条原始规则造出来，
战术只是"自动地按这些规则搭积木"。本章不用任何战术，只用规则手工搭几个
定理，看清 `thm` 到底是什么。

> 理解内核不是为了日常用它 —— 而是为了在战术失败时，能判断"是我不该证明
> 这个"还是"我该换个战术"。

## 04.1 定理的三要素

一条定理是 `(假设的项列表, 结论项)`。它必须是**被造出来的**，不能凭空声明：

```text
 [.] ⊢ p
hyp   长度 = 1
concl      = p
dest_thm   = 1 条假设
```

```sml
val th = ASSUME ``p : bool``
val _ = out ("hyp   长度 = " ^ Int.toString (length (hyp th)))
val _ = out ("concl      = " ^ (concl th |> term_to_string))
```

`ASSUME` 是唯一一条"直接给"的规则：它给出 `p ⊢ p`，代价是 `p` 进了假设集合。
最终定理的假设必须清空（或作为前提保留），否则定理没有意义。

## 04.2 REFL / SYM / TRANS

```text
⊢ 1 = 1
⊢ 1 = 1
 [..] ⊢ a = c
```

```sml
val ab = ASSUME ``(a : num) = b``
val bc = ASSUME ``(b : num) = c``
val _ = out (thm_to_string (TRANS ab bc))
```

`SYM (REFL ``1``)` 打印出来还是 `⊢ 1 = 1` —— 因为对称一条 `1 = 1`
得到的还是 `1 = 1`。看假设标记更准：这一条没有方括号。

## 04.3 合同性

合同性说的是"等式可以穿过函数应用"：

```text
 [.] ⊢ SUC a = SUC b
⊢ f x ⇔ f x
 [.] ⊢ f a ⇔ f b
```

```sml
val _ = out (thm_to_string (AP_TERM ``SUC`` ab))                    (* 穿过函数 *)
val _ = out (thm_to_string (AP_THM (REFL ``(f : num -> bool)``) ``x : num``))
val _ = out (thm_to_string (MK_COMB (REFL ``(f : num -> bool)``, ab)))
```

| 规则 | 作用 | 典型结果 |
|---|---|---|
| `AP_TERM f` | 等式两边同时套上 `f` | `a = b ⊢ SUC a = SUC b` |
| `AP_THM` | 函数等式在参数上实例化 | `f = f ⊢ f x ⇔ f x` |
| `MK_COMB` | 函数等式 + 参数等式 → 应用等式 | `a = b ⊢ f a ⇔ f b` |

注意第二行 `⊢ f x ⇔ f x` 用的是 `⇔` 不是 `=`：当结果是 `bool` 时，
HOL4 的打印器会自动把 `=` 写成 `⇔`。它们是同一个常量。

## 04.4 抽象与 β

```text
⊢ (λx. x + 1) 3 = 3 + 1
⊢ (λx. x) = (λx. x)
```

```sml
val _ = out (thm_to_string (BETA_CONV ``(\x : num. x + 1) 3``))
val _ = out (thm_to_string (ABS ``x : num`` (REFL ``x : num``)))
```

`BETA_CONV` 只做一次 β 归约，不再往里化简 —— 所以右侧还是 `3 + 1` 而不是 `4`。
算到底要 `EVAL`（01.4 节）。

## 04.5 蕴含

```text
⊢ p ⇒ p
 [.] ⊢ p
 [..] ⊢ p ⇒ r
```

```sml
val imp = DISCH ``p : bool`` (ASSUME ``p : bool``)
val _ = out (thm_to_string (MP imp (ASSUME ``p : bool``)))
val _ = out (thm_to_string (IMP_TRANS (ASSUME ``(p : bool) ==> q``)
                                      (ASSUME ``q ==> r``)))
```

`DISCH` 把一条假设"搬"到结论左边（演绎定理），`MP` 是它的逆（肯定前件）。
这一对就是"假设"在内核层面的全部机制。

## 04.6 量化

```text
 [.] ⊢ P 3
 [.] ⊢ ∀n. P n
 [.] ⊢ ∀n. Q n
```

```sml
val allth = ASSUME ``!(n : num). P n``
val _ = out (thm_to_string (SPEC ``3 : num`` allth))
val _ = out (thm_to_string (GEN ``n : num`` (SPEC ``n : num`` allth)))
val _ = out (thm_to_string (INST [``P : num -> bool`` |-> ``Q : num -> bool``] allth))
```

`SPEC` 把 `∀n.` 去掉并代入；`GEN` 反过来（要求变量不在假设里自由出现）
；`INST` 替换项。

第二行看着像"没变"，其实 `SPEC` 后 `GEN` 回来得到的是 `∀n. P n` 的**新证明** ——
内核不比较内容，只比较构造过程。

## 04.7 手工搭一条定理

从 `f = g` 推出 `f x = g x`，不用战术：

```text
 [.] ⊢ f x ⇔ g x
它和战术版本等价：⊢ f = g ⇒ (f x ⇔ g x)
```

```sml
val fg = ASSUME ``(f : num -> bool) = g``
val manual = MK_COMB (fg, REFL ``x : num``)
val _ = out (thm_to_string (prove(``(f : num -> bool) = g ==> f x = g x``,
                                  DISCH_TAC >> ASM_REWRITE_TAC [])))
```

同一件事的两种写法：手工版 `MK_COMB (fg, REFL x)`，战术版
`DISCH_TAC >> ASM_REWRITE_TAC []`。战术最终会展开成前者那样的一串规则调用。

## 04.8 oracle 会被打标

`mk_thm` 可以凭空造出"定理"。内核不阻止，但会打上 oracle 标记，
而且**任何用到它的下游定理都会继承这个标记**：

```text
真证明的 oracle 标记：NONE? 是
内核只接受规则造出来的定理；mk_thm 能凭空造，但会留下标记。
```

```sml
val real = prove(``1 = 1``, simp [])
val _ = out ("真证明的 oracle 标记：NONE? " ^
             (case Theory.oracle_string_of real of NONE => "是" | SOME s => "否：" ^ s))
```

这是 HOL4 的"诚实指针"设计：你可以撒谎，但谎话会被一路标出来，
任何人拿到你的理论都能查出来哪一条是"信的"。

## 04.9 坑位清单

1. **`ASSUME` 会把命题放进假设集合** → 最终定理带着 `p ⊢ ...` 就没意义了；要用 `DISCH` / `prove` 清掉。
2. **`=` 和 `⇔` 是同一个常量** → 打印器在 `bool` 上自动切换；比对输出时别以为是两条不同的定理。
3. **`BETA_CONV` 只做一步** → `(\x. x+1) 3` 化到 `3 + 1` 就停；要算到底用 `EVAL`。
4. **`GEN` 要求变量不在假设里自由出现** → 否则报 "variable occurs free in hypotheses"。
5. **`AP_TERM` 和 `MK_COMB` 不是一个东西** → `AP_TERM` 只需要等式，`MK_COMB` 要一对（函数等式, 参数等式）。
6. **`SPEC` 出来的项不带简化** → `SPEC ``3`` 之后是 `P 3`，不会帮你算 `P`。
7. **`INST` 的写法是 `[``旧项`` |-> ``新项``]`** → 方向是"旧 → 新"，跟 `inst`（类型层）一样。
8. **oracle 标记会传染** → 一条 `mk_thm` 造的定理会让所有用到它的定理都带标记。
9. **`SYM (REFL t)` 打印出来跟 `REFL t` 一样** → 要看假设标记和构造过程，不能只看打印。
10. **`DISCH` 的参数顺序是 (要搬走的项, 定理)** → 写成 `DISCH th t` 类型错；是 `DISCH ``p`` th`。

---

上一章：[03 · 元语言 Standard ML](03-ml.md) ·
下一章：[05 · 数据类型](05-datatype.md)
