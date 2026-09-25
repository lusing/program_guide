# Coq-HoTT CHEATSheet —— 语法速查 + 实测坑位索引

> 所有条目均来自 24 个编译验证过的示例（`examples/`）与实测输出
> （`build/out/NN.sec1`）。坑位编号「章.条」指向该章坑位清单。

## 0. 一条命令跑起来

```bash
coqc -q -noinit -indices-matter -R /Volumes/mac004/lang/Coq-HoTT/theories HoTT ex_01_type_theory.v
```

四个开关缺一不可：`-q` 安静；`-noinit` 不加载标准库（防 `paths`/`sig` 被抢）；
`-indices-matter` HoTT 要求；`-R ... HoTT` 命名空间映射。

## 1. 每文件最小骨架

```coq
Require Import HoTT.                       (* 总导出；不含公理 *)
Require Import HoTT.Axioms.Univalence.     (* 要 path_universe 时单独加 *)
Local Open Scope path_scope.

Definition sec_01_BEGIN := tt.   Check sec_01_BEGIN.   (* 分节哨兵 *)
(* ... Check / Compute / Definition / Proof ... *)
Definition sec_01_END := tt.     Check sec_01_END.
```

- 哨兵用 **`Check` 常量**：`-noinit` 下没有 string 记号，`idtac "..."` 不可用。
- 文件名/模块名**不能以数字开头** → 用 `ex_` 前缀。

## 2. 记号速查（scope 决定含义）

| 写法 | 含义 | 所在 scope |
|---|---|---|
| `1` | `idpath`（路径） | path_scope（默认解释） |
| `1` | `equiv_idmap`（恒等等价） | equiv_scope |
| `1` | 恒等态射 | morphism_scope |
| `p @ q` | 路径复合 | path_scope |
| `p^` | 逆路径 | path_scope |
| `f o g` | 函数复合 | function_scope |
| `f == g` | 逐点同伦（`pointwise_paths`） | type_scope |
| `A <~> B` | 等价类型 `Equiv A B` | type_scope |
| `X ->* Y` | 保点映射 | pointed_scope |
| `X <~>* Y` | 点化等价 | pointed_scope |
| `+` / `*` | **和类型 / 积类型**（非算术！） | type_scope |
| `+` / `*` / `-` | 算术 | nat_scope / int_scope |
| `x.+1` / `x.-1` | 后继 / 前驱 | nat_scope / int_scope |
| `(-2)%trunc` | 截断层级 -2 | trunc_scope |
| `{x : A & P x}` | Σ 类型 | type_scope |
| `forall x : A, P x` | Π 类型 | — |

**数字字面量默认不是 nat**：`0` 是截断层级、`1` 是 `idpath`。
算术一律写 `(2 + 3)%nat`。〔坑 03、22〕

## 3. 核心类型与记号

```coq
paths : ?A -> ?A -> Type           (* a = b 的真名 *)
transport : forall (P : A -> Type) (x y : A), x = y -> P x -> P y
concat_p1 / concat_1p / concat_p_pp / concat_pp_p / concat_V_pp / inv_pp
ap : (A -> B) -> x = y -> f x = f y        apD : 依赖版
IsEquiv（四份数据）: equiv_inv / eisretr / eissect / eisadj
equiv_adjointify f g eisretr eissect   (* 日常造等价 *)
hfiber f y = {x : A & f x = y}         (* 纤维 *)
IsTrunc n A: -2 可缩 / -1 命题 / 0 集合（IsTrunc_internal 归纳族）
path_forall : f == g -> f = g          (* 需 Funext *)
path_universe : IsEquiv f -> A = B     (* 需 Univalence *)
Tr n A / tr / merely / hexists / hor   (* 截断操作 *)
Circle / Circle.base / Circle.loop / Circle_ind
Pushout / pushl / pushr / pglue  |  Coeq / coeq / cglue
Quotient / class_of / qglue  |  Susp
pType / Build_pType / pt / loops / Build_pMap
nat / Int / nat_add / int_iter ...
```

## 4. 证明套路速查

| 任务 | 做法 |
|---|---|
| 路径目标 | `destruct p q; reflexivity` 或直接 `exact` 路径代数引理 |
| transport 化简 | `transport_const` / `transport_pp` / `transport_pV` / `transport_compose` |
| 沿泛等路径搬运 | `apply transport_path_universe`（**simpl 化不开**） |
| HIT 消去 | `HIT_ind`：点给值 + 路径给 `transport P glue a = b` |
| h-命题目标免相容条件 | `Quotient_ind_hprop` / 目标 `IsHProp` 时走捷径 |
| 移项 | `moveR_transport_p` / `moveL_transport_p`（对称孪生，`Check` 区分） |
| 公理审计 | `Print Assumptions foo` → `Closed under the global context` = 零公理 |
| 找引理 | `Search (IsEquiv) (@inverse Bool true false).`（带具体类型！） |
| 查记号 | `Locate "@"` / `Locate "1"`（`1` 被绑定 9 次） |
| 查定义 | `Print X`（摊开）；`About X`（含全限定名 + 源码行号） |

## 5. 高频坑位 Top 15（各章坑位清单合计 **291** 条，完整版见 docs/25-pitfalls.md）

1. 数字字面量要 `%nat` / `%int`；`0`/`1` 默认是截断层级/`idpath`〔03.1, 22.1〕
2. 裸 `Check IsHSet` 报 `Abbreviation is not applied enough` → 带参写〔07, 09〕
3. `Check` 出 `ordinal_carrier ?o` 之类怪类型 = typeclass 任意统一 → 给具体类型〔20, 23〕
4. `path_universe` 不可计算，`simpl` 救不了 → 用 `_path_universe` 引理〔11, 18〕
5. `-noinit` 缺了标准库会抢走 `paths` / `sig` / `=`〔02, 23〕
6. 模块名数字开头 → `Invalid character '0'`〔23〕
7. `HoTT.Categories` 触发 stderr 警告 → `Set Warnings "-notation-overridden"`〔20〕
8. `Coeq_rec` 第一个显式参数是目标类型 `P`；`Coeq` 变量顺序是 `(B->A)->(B->A)`〔19〕
9. `Build_HSet` / `Build_HProp` 只吃一个参数〔09〕
10. `[X, x]` 点化记号不可用（撞列表 + 无定界键）→ `Build_pType`〔21〕
11. 消去方向引理（`path_sum_inl` 等）是"从构造子里抽路径"，造路径用 `ap`〔14〕
12. `ap (fun Z => Z * A)` 的 `Z` 要显式标类型，否则宇宙推不出〔18〕
13. `equiv_scope` 打开时 `1` 是恒等等价；`@` 三连可能触发 `level-tolerance` 警告〔11〕
14. `loopexp` 有两份（Int 与 BinInt）同名互相遮蔽 → 自己写 `loopexp_nat`〔24〕
15. 命题是 `Type0` 里的类型不是 Bool；判定归 `Decidable`〔22〕

## 6. 截断层级与映射对照

| 层级 | 名称 | 含义 | `IsTruncMap n f` 的含义 |
|---|---|---|---|
| -2 | `Contr` | 可缩（有中心点） | f 是等价 |
| -1 | `IsHProp` | 命题（任意两点相等） | f 是嵌入 |
| 0 | `IsHSet` | 集合（路径空间是命题） | —（满射用 `IsConnMap (Tr (-1))`） |

`Build_Contr center contr` / `istrunc_S n`：`IsTrunc_internal` 的两个构造子。
抬层级用 `istrunc_leq : (m <= n)%trunc -> IsTrunc m A -> IsTrunc n A`。

## 7. 常用源码位置（`/Volumes/mac004/lang/Coq-HoTT/theories/`）

| 内容 | 文件 |
|---|---|
| `paths` / `transport` / `ap` / `IsEquiv` / `nat` / `hfiber` | `Basics/Overture.v` |
| `Univalence` / `path_universe` | `Types/Universe.v` |
| `interval` | `HIT/Interval.v` |
| `Circle` | `Spaces/Circle.v` |
| `Quotient` | `Colimits/Quotient.v` |
| `Pushout` / `Coeq` | `Colimits/` |
| `Int` / `loopexp` | `Spaces/Int.v`、`Spaces/BinInt/LoopExp.v`（同名遮蔽！） |

`About X` 的 `Expands to` 会直接给出全限定名与源码行号，可 grep。
