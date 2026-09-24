# 17 · 归纳定义

> 对应示例：[`examples/17_inddef/17_inddef.sml`](../examples/17_inddef/17_inddef.sml)

`Datatype` 定义数据，`Definition` 定义函数，而**"由规则生成的谓词"**
用 `Hol_reln`。它一次性给出四样东西：规则、case 分析、规则归纳、强归纳。
操作语义、类型系统、推导关系，全都靠它。

## 17.1 Hol_reln

```text
生成的定理：even_strongind even_rules even_ind even_cases
⊢ even 0 ∧ ∀n. even n ⇒ even (n + 2)
```

```sml
val _ = Hol_reln `even 0 /\ (!n. even n ==> even (n + 2))`
val _ = out ("生成的定理：" ^ tnames "even_")
val _ = out (thm_to_string (DB.fetch "Tut17" "even_rules"))
```

`Hol_reln` 接一个**项的引号**（不是 `Definition` 那样的语法块），
内容是一串用 `/\` 连起来的规则。上面两条规则读作：

```
─────────          even n
even 0             ──────────────
                   even (n + 2)
```

它一次性生成四条定理（名字都带 `<谓词名>_` 前缀）：

| 定理 | 用途 |
|---|---|
| `even_rules` | 规则本身（合取），用来**构造**实例 |
| `even_cases` | case 分析：一个 `even a0` 是怎么来的，用来**倒推** |
| `even_ind` | 规则归纳：证"所有可推导的都满足 P" |
| `even_strongind` | 强归纳版：归纳假设里额外带着 `even n` |

**这些定理只进理论，不产生 ML 绑定** —— 要用得 `DB.fetch "Tut17" "even_rules"`
或者 `DB.fetch "-" "even_rules"`（22 章）。

## 17.2 用规则证实例

```text
⊢ even 2
⊢ even 4
⊢ even 6
一步可及：⊢ even (0 + 2)
```

```sml
val even_rules = DB.fetch "Tut17" "even_rules"
val even0   = CONJUNCT1 even_rules
val evenstep = CONJUNCT2 even_rules
fun step_even th = CONV_RULE (SIMP_CONV arith_ss []) (MATCH_MP evenstep th)
val e2 = step_even even0
val e4 = step_even e2
val e6 = step_even e4
```

`even_rules` 是一个**合取**（`even 0 ∧ ∀n. even n ⇒ even (n+2)`），
所以先用 `CONJUNCT1` / `CONJUNCT2` 把两条规则拆开。

往前推一步的标准做法：

```sml
MATCH_MP evenstep th        (* th : ⊢ even n  ⟹  ⊢ even (n + 2) *)
```

`MATCH_MP` 做"匹配版 MP"（规则里有前件 `even n`，把 `n` 匹配到 `th` 的结论上）。
接着用 `CONV_RULE (SIMP_CONV arith_ss [])` 把 `0 + 2`、`2 + 2` 这些算术化掉，
于是 `e2` `e4` `e6` 一路推出来。

最后一行是重要的边界：

```sml
val _ = out ("一步可及："
             ^ p ``even (0 + 2)`` (metis_tac [even0, evenstep]))
```

`metis_tac [even0, evenstep]` 能证 `even (0 + 2)`（一步匹配），
但**证不了 `even 4`** —— `even 4` 需要先化算术（`4 = 2 + 2`）再两步推导，
而 `metis` 做的是纯一阶匹配，不替你做算术归一化。

> 归纳定义上的"具体实例"通常要**手动 `MATCH_MP` + 算术化简**，
> 或者先把目标改写成跟规则形状对齐的样子。

## 17.3 cases 定理

```text
⊢ ∀a0. even a0 ⇔ a0 = 0 ∨ ∃n. a0 = n + 2 ∧ even n
⊢ even 1 ⇒ F
```

```sml
val _ = out (thm_to_string (DB.fetch "Tut17" "even_cases"))
val _ = out (p ``even 1 ==> F``
               (strip_tac >> imp_res_tac (DB.fetch "Tut17" "even_cases")
                >> rw [] >> DECIDE_TAC))
```

`even_cases` 是"**倒推**"定理：如果 `even a0` 成立，那它必然来自某条规则。
它的形状是 `⇔`（双向），所以既能用来做 case 分析，也能用来"反向构造"。

第二个证明 `even 1 ⇒ F`（1 不是偶数）演示了标准套路：
`strip_tac` 把 `even 1` 放进假设，`imp_res_tac even_cases` 把它拆成
`1 = 0 ∨ ∃n. 1 = n + 2 ∧ even n`，两条分支都是算术矛盾，`rw` + `DECIDE_TAC` 收掉。

> `imp_res_tac` 会自动把 `⇔`/`⇒` 的左端跟假设匹配，把右端加进上下文。
> 处理 `cases` 定理时它比手写 `MP` 方便得多。

## 17.4 规则归纳

```text
⊢ ∀even'. even' 0 ∧ (∀n. even' n ⇒ even' (n + 2)) ⇒ ∀a0. even a0 ⇒ even' a0
偶数的 n 都能被 2 整除：⊢ ∀n. even n ⇒ EVEN n
```

```sml
val _ = out ("偶数的 n 都能被 2 整除：" ^
             p ``!n. even n ==> EVEN n``
               (ho_match_mp_tac (DB.fetch "Tut17" "even_ind") >> rw []
                >> rw [EVEN_ADD]))
```

`even_ind` 是"规则归纳"原理，读法：

```
要证  ∀a0. even a0 ⇒ P a0
只需  ① P 0                          （第一条规则产生的）
     ② ∀n. P n ⇒ P (n + 2)           （第二条规则：假设前件满足）
```

这正好就是**按推导树做结构归纳**。用它证"所有偶数都满足某性质"是标准操作。

第二个证明用的战术：`ho_match_mp_tac even_ind >> rw [] >> rw [EVEN_ADD]`。
`ho_` 前缀表示"高阶匹配"，因为归纳原理里有谓词变量 `even'`；
普通的 `match_mp_tac` 匹配不上这种带谓词变量的定理。

## 17.5 强归纳

```text
⊢ ∀even'.
    even' 0 ∧ (∀n. even n ∧ even' n ⇒ even' (n + 2)) ⇒
    ∀a0. even a0 ⇒ even' a0
```

```sml
val _ = out (thm_to_string (DB.fetch "Tut17" "even_strongind"))
```

`even_strongind` 与 `even_ind` 的唯一差别在第二条前提：
它是 `∀n. even n ∧ even' n ⇒ …`，也就是归纳假设里**额外带着
"这个 n 确实可推导"**这一信息。

普通归纳里你只知道"若 `even' n` 成立则 ……"；强归纳里你还知道 `even n` 成立。
需要"先用 `even_cases` 拆开 `even n`"这类证明时，强归纳能省一次推导。

> 实践上：`even_ind` 够用就用它；发现归纳假设里缺 `even n` 这一条，
> 再换 `_strongind`。

## 17.6 一个关系上的归纳定义

```text
<<HOL message: Treating "R", "x" as schematic variables>>
生成的定理：path_strongind path_rules path_ind path_cases
⊢ ∀R x. path R x x ∧ ∀y z. path R x y ∧ R y z ⇒ path R x z
⊢ ∀R x path'.
    path' x ∧ (∀y z. path' y ∧ R y z ⇒ path' z) ⇒ ∀a0. path R x a0 ⇒ path' a0
path 就是可达（⊆ RTC）：⊢ ∀y. path R x y ⇒ R꙳ x y
RTC_INDUCT        : ⊢ ∀R P. (∀x. P x x) ∧ (∀x y z. R x y ∧ P y z ⇒ P x z) ⇒ ∀x y. R꙳ x y ⇒ P x y
RTC_INDUCT_RIGHT1 : ⊢ ∀R P. (∀x. P x x) ∧ (∀x y z. P x y ∧ R y z ⇒ P x z) ⇒ ∀x y. R꙳ x y ⇒ P x y
path_rules 拆开：
  自反 ⊢ path R x x
  步进 ⊢ ∀y z. path R x y ∧ R y z ⇒ path R x z
反过来 RTC ⊆ path：⊢ ∀x y. R꙳ x y ⇒ path R x y
```

```sml
val _ = Hol_reln `path (R : num -> num -> bool) x x /\
                  (!y z. path R x y /\ R y z ==> path R x z)`
val _ = out ("path 就是可达（⊆ RTC）：" ^
             p ``!y. path (R : num -> num -> bool) x y ==> RTC R x y``
               (ho_match_mp_tac (DB.fetch "Tut17" "path_ind")
                >> rw [RTC_REFL] >> metis_tac [RTC_TRANS, RTC_SINGLE]))
```

`Hol_reln` 里的自由变量（这里的 `R` 和 `x`）会被当成**模式变量**，
HOL4 会打印 `Treating "R", "x" as schematic variables` 说明这件事。
于是 `path` 是个带参数的关系：`path R x y` 表示"从 x 沿 R 走若干步到 y"。

这一节证了两个方向的包含，两个都很讲究：

**方向一：`path ⊆ RTC`**

```sml
p ``!y. path R x y ==> RTC R x y`` (ho_match_mp_tac path_ind >> rw [RTC_REFL]
                                    >> metis_tac [RTC_TRANS, RTC_SINGLE])
```

注意目标写成 `!y. path R x y ==> RTC R x y` —— **`R` 和 `x` 故意留成自由变量**。
如果写成 `!R x y. path R x y ==> RTC R x y`，`ho_match_mp_tac` 会报
`not a comb`：归纳原理的量词里没有 `R` 和 `x`（它们是模式变量，已被特化）。

`metis_tac [RTC_TRANS, RTC_SINGLE]` 里两条定理各有分工：
`RTC_SINGLE` 把一步 `R y z` 变成 `RTC R y z`，`RTC_TRANS` 把它跟归纳假设接上。

**方向二：`RTC ⊆ path`**

```sml
p ``!x y. RTC R x y ==> path R x y``
  (ho_match_mp_tac RTC_INDUCT_RIGHT1 >> rw []
   >> metis_tac [CONJUNCT1 (SPEC_ALL path_rules), CONJUNCT2 (SPEC_ALL path_rules)])
```

这里的关键在**挑对 `RTC` 的归纳定理**。两条对比（输出里都打印了）：

| 定理 | 一步加在哪 |
|---|---|
| `RTC_INDUCT` | `R x y ∧ P y z` —— 加在**左端** |
| `RTC_INDUCT_RIGHT1` | `P x y ∧ R y z` —— 加在**右端** |

`path` 的构造规则是 `path R x y ∧ R y z ⇒ path R x z`（往右加），
所以必须用 `RTC_INDUCT_RIGHT1`。用 `RTC_INDUCT` 方向对不上，证不动。

还有一处细节：`path_rules` 必须先 `SPEC_ALL` 再 `CONJUNCT1`/`CONJUNCT2`。
不做 `SPEC_ALL` 的话，`CONJUNCT1` 会试图拆 `∀R x. …` 这个全称量词的内部结构，
得到的东西不是你想要的。

> **这一节集中了本章最容易踩的三个坑**：
> ① 目标里别把模式变量也 `∀` 掉；
> ② `RTC` 的两个归纳定理方向不同，要挑对；
> ③ `path_rules` 要 `SPEC_ALL` 之后再拆合取。

## 17.7 什么时候用哪个

```text
规则生成的是「最小集合」（归纳的），函数是「确定性计算」（递归的）。
差别：even 4 要用规则推两步；evenf 4 直接算。
⊢ ∀n. evenf n ⇔ n MOD 2 = 0
求值：evenf 7 ⇔ F
把两边的偶数概念接起来：
⊢ ∀n. even n ⇒ evenf n
（反方向要说明「能被 2 整除的数都能推出来」，留给练习。）
```

```sml
Definition evenf_def:
  evenf n = (n MOD 2 = 0)
End
val _ = out ("求值：" ^ (EVAL ``evenf 7`` |> concl |> term_to_string))
val _ = out (p ``!n. even n ==> evenf n``
               (ho_match_mp_tac (DB.fetch "Tut17" "even_ind") >> rw [evenf_def]
                >> rw [EVEN_ADD]))
```

同一个"偶数"概念，两种写法：

| 写法 | 本质 | 优点 | 缺点 |
|---|---|---|---|
| `Hol_reln`（`even`） | **最小**满足规则的集合 | 贴近推导/语义规则；自带归纳原理 | 判断具体值要手动推 |
| `Definition`（`evenf`） | 确定性计算 | `EVAL` 直接算 | 跟"推导规则"的对应要另外证明 |

最后一个证明 `even n ⇒ evenf n` 就是在**把两套说法接起来**：
用 `even_ind` 归纳，`rw [evenf_def]` 展开计算定义，`rw [EVEN_ADD]` 处理
`EVEN (n + 2)`。

> 真实项目里两者都要：规则版本写语义（可读、可归纳），
> 函数版本写实现（可执行、可测），然后证它们一致 ——
> 这就是 24 章 capstone 里"编译器正确性"的雏形。

## 17.8 坑位清单

1. **`Hol_reln` 生成四条定理但**不产生 ML 绑定** → 要 `DB.fetch` 取。
2. **`even_rules` 是合取** → 用前先 `CONJUNCT1` / `CONJUNCT2` 拆开。
3. **带参数的规则要先 `SPEC_ALL` 再拆合取** → 否则 `CONJUNCT1` 拿到的是 `∀` 内部。
4. **`metis_tac` 证不了需要算术归一化的实例** → `even 4` 要手动 `MATCH_MP` + 化简。
5. **`ho_match_mp_tac` 用于带谓词变量的归纳原理** → 普通 `match_mp_tac` 匹配不上。
6. **目标里别把模式变量 `∀` 掉** → 否则 `ho_match_mp_tac` 报 `not a comb`。
7. **`RTC_INDUCT` 加一步在左、`RTC_INDUCT_RIGHT1` 在右** → 跟你的规则方向对齐。
8. **`metis_tac [RTC_TRANS]` 容易不终止** → 它是单向定理，搜索会爆（16.3 节）。
9. **`cases` 定理配 `imp_res_tac` 用** → 比手写 `MP` 省事。
10. **`_ind` 不够时换 `_strongind`** → 后者的归纳假设里额外带 `even n`。

---

上一章：[16 · 关系与闭包](16-relations.md) ·
下一章：[18 · 记录类型](18-records.md)
