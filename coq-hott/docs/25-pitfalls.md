# 25 坑位总清单

> 本章不配示例。它是第 01–24 章各章"坑位清单"的**跨章汇总**：
> 各章合计 **291 条**（每章 12 条左右），本章按主题归纳出其中**反复出现、
> 跨章通用**的 30 条。单章特有的坑请回各章查阅。

## 25.1 各章坑位分布

| 章 | 主题 | 坑位数 |
|---|---|---|
| 01 | 类型论原理 | 12 |
| 02 | 工具链 | 12 |
| 03 | 依赖类型 | 12 |
| 04 | 恒等类型与路径归纳 | 12 |
| 05 | Transport | 12 |
| 06 | 路径代数 | 12 |
| 07 | 等价 | 12 |
| 08 | 同伦纤维与可缩性 | 12 |
| 09 | 截断层级 | 12 |
| 10 | 函数外延 | 12 |
| 11 | 泛等公理 | 12 |
| 12 | HIT 区间 | 12 |
| 13 | 圆 S¹ 与编码-解码 | 12 |
| 14 | 类型构造器的路径与等价 | 12 |
| 15 | 截断操作 | 12 |
| 16 | 集合与商类型 | 12 |
| 17 | 截断映射与嵌入 | 12 |
| 18 | 泛等的应用 | 12 |
| 19 | 余极限 | 12 |
| 20 | 范畴论 | 12 |
| 21 | 点化类型与环路空间 | 12 |
| 22 | 自然数与整数 | 14 |
| 23 | 元理论与证明工程 | 13 |
| 24 | 综合实战 | 12 |
| **合计** | | **291** |

## 25.2 通用 30 条（跨章精选）

### A. scope 与记号（出现频率最高的一类）

1. **数字字面量默认不是 `nat`**：`0` 落在 `trunc_scope`（截断层级）、
   `1` 落在 `path_scope`（= `idpath`）。算术表达式必须写 `%nat` / `%int`，
   否则报 `No interpretation for number "3"`。（第 03、22 章）
2. **`1` 被绑定了 9 次**：`idpath`、`equiv_idmap`、`mon_unit`、`sq_id`……
   `Locate "1"` 是分辨它们的唯一可靠方法。（第 23 章）
3. **`+` / `*` 默认是和类型 / 积类型**（`type_scope`），不是算术。
4. **`<~>` 在 `type_scope`**、`->*` / `<~>*` 在 `pointed_scope`、
   `==` 在 `type_scope`（逐点同伦）—— 写目标时想清楚在哪个 scope。
5. **`[X, x]` 点化记号不可用**：与列表记号撞车且 `pointed_scope` 没有
   `Delimit Scope` 键，一律写 `Build_pType X x`。（第 21 章）
6. **`Require Import HoTT.Categories` 触发 `[notation-overridden]` 警告**
   （打在 stderr）：`Set Warnings "-notation-overridden"` 关掉。（第 20 章）

### B. 类型类与实例

7. **typeclass 缺实例时"任意统一"**：`Check hset_path2` 统一到
   `ordinal_carrier ?o`、`Check lt` 统一到 `GenNo ?S`、`Check zero` 统一到
   `?R : CRing`。给具体类型参数即可恢复正常。（第 20、22、23 章）
8. **`pt` 由 `IsPointed` 实例参数化**，`Check pt` 留下未解 evar 是正常的。（第 21 章）
9. **数系的 `IsHSet` / `IsHProp` 实例都在库里**：
   `Definition h : IsHSet nat := _.` 直接可用。（第 22 章）
10. **"Unable to satisfy the following constraints" 的排查顺序**：
    先查截断实例，再查 `Funext` / `Univalence` 是否导入。（第 23 章）
11. **`Univalence_implies_Funext` 会把 `Funext` 带进公理清单**：
    用了泛等的定理自动依赖它，不代表你多用了公理。（第 23 章）

### C. 公理纪律

12. **`HoTT.v` 不导出公理**：`Univalence` 要 `Require Import
    HoTT.Axioms.Univalence`，`Funext` 同理。（第 11、18 章）
13. **路径代数与等价论是零公理的**：`Print Assumptions` 对
    `concat_p1` / `transport_pp` / `isequiv_adjointify` 全部报告
    `Closed under the global context`。（第 23 章）
14. **`path_universe` 不可计算**：`simpl` / `cbn` / `Compute` 都救不了，
    必须用 `_path_universe` 系列引理化开。（第 11、18、24 章）
15. **HIT 的计算规则不是公理**，但 HIT 构造子（如 `gqglue`）会出现在
    `Print Assumptions` 的报告里，属"解释规则"而非公理。（第 23、24 章）
16. **π₁(S¹) = ℤ 与"loop 非平凡"都依赖泛等**：这是 HoTT 里最著名的
    公理依赖事实。（第 13、21、24 章）

### D. 裸 `Check` 的语法陷阱

17. **Notation/Abbreviation 不能裸 `Check`**：`IsHSet` / `IsTrunc` /
    `IsEquiv` / `IsEmbedding` / `Contr` 要写成
    `Check (fun A : Type => IsHSet A).` 等带参形式，否则报
    `Abbreviation is not applied enough`。（第 07、09、17 章）
18. **`inl` / `inr` / `fst` / `snd` 的首参数是隐式的**：要写 `@inl`、`@fst`。
    （第 01 章）
19. **注释紧贴 `.)` 会被当成限定名**：`Check (fun ...).(* 蕴含 *)` 报语法错，
    注释前加空格。（第 01 章）
20. **trunc_index 的后继是 `trunc_S n`**，不是 `n.+1`（那个记号不存在）。
    （第 09 章）

### E. 构造子与参数顺序

21. **`Coeq` 的类型变量顺序是 `(B -> A) -> (B -> A) -> Type`**（源在前、
    点在后），且 `Coeq_rec` 的第一个显式参数是目标类型 `P`；漏给时报
    `has type Type0 while it is expected to have type ?A -> ?P`。（第 19 章）
22. **`Build_HSet` / `Build_HProp` 只接受一个参数**（非函数构造）：
    `Build_HSet Bool : HSet`。（第 09 章）
23. **范畴的 `compose` 参数顺序是 `morphism d d'` 在前**；
    `associativity` 与 `associativity_sym`、`identity_identity` 都必须填，
    用 Record 具名字段语法 `{| object := ... ; ... |}` 避免错位。（第 20 章）
24. **`int_iter` 的参数是 `(f : A -> A)` + `IsEquiv f`**，不是 `<~>`。（第 21 章）
25. **`IsEquiv` 的四份数据**（`equiv_inv` / `eisretr` / `eissect` / `eisadj`）
    是伴随等价；日常构造用 `equiv_adjointify` 给两份即可。（第 07 章）

### F. 引理方向

26. **消去方向与构造方向成对出现**：`path_sum_inl` 是
    `inl x = inl x' -> x = x'`（消去），造路径要用 `ap inl p`；
    `moveR_transport_p` 与 `moveL_transport_p` 是对称孪生，靠 `Check` 区分。
    （第 14、05、23 章）
27. **`transport` 的方向不可交换**：`transport P p : P x -> P y` 恒从路径
    起点搬向终点；HIT 消去子里 `transport P (glue a)` 的两端由构造子决定。
    （第 05、19 章）

### G. 工程与元理论

28. **编译开关一个都不能少**：`-noinit`（否则标准库抢走 `paths` / `sig`）、
    `-indices-matter`、`-R theories HoTT`。（第 02、23 章）
29. **模块名不能以数字开头**：`coqc -o` 报
    `Invalid character '0' at beginning of identifier`，先查文件名。（第 23 章）
30. **`Search` 三板斧**：给具体单态类型缩范围、按形状搜
    （`Search (transport _ _ _ = _ -> _ = _)`）、`Check` 确认参数顺序。
    `About` 的 `Expands to` 给全限定名与源码行号。（第 23 章）

## 25.3 按症状速查

| 症状 | 根因 | 见 |
|---|---|---|
| `No interpretation for number "3"` | 字面量缺 `%nat` | 通用 1 |
| `Abbreviation is not applied enough` | 裸 `Check` 记号 | 通用 17 |
| `Invalid character '0' at beginning of identifier` | 文件名数字开头 | 通用 29 |
| `Unable to satisfy the following constraints` | 实例缺失/公理未导入 | 通用 10 |
| `simpl` 后目标纹丝不动 | `: simpl nomatch` 或 `path_universe` | 通用 14；第 23 章 5 |
| 类型打印成 `ordinal_carrier ?o` 等 | typeclass 任意统一 | 通用 7 |
| `has type Type0 while expected ?A -> ?P` | 漏给 HIT 消去子的 `P` | 通用 21 |
| `Unknown interpretation for notation "[ _, _ ]"` | 点化记号撞车 | 通用 5 |
| stderr 出现 `[notation-overridden]` | 范畴模块覆盖记号 | 通用 6 |
| `The term "n" has type "Int" while ...` | `loopexp` 同名遮蔽 | 第 24 章 |
| `mbstate_t`/`EOF` 未声明（C 工具链） | 裸 clang 缺 `-isysroot` | 第 02 章 |
| 目标里 `+` 报"expected Type" | 算术缺 `%nat` | 通用 3 |

---

**上一章**：[24 综合实战 —— 圆上的螺旋覆叠](docs/24-capstone.md)
