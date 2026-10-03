# 19 合一与归结：occurs check 与可靠性

> 对书：Ben-Ari 3e Ch10 / EFT XI / Huth&Ryan 附录

自动定理证明的引擎两件套：**合一**（找代换使两项相等）与
**归结**（从互补文字对消去出新子句）。

## 交付内容（三通道零公理）

**旗舰一：occurs check 的结构健全性**

```
occurs_sound : x ∈ t ⟹ uapply s (ufun f t) ≠ uvar x
```

occurs check 拒绝 `x ↦ f(…x…)` 的语义锚：函数项施任何
代换后**结构上**仍是函数项（ufun ≠ uvar 的构造子差异）——
这正是合一失败判定的结构基础。完整语义（无穷展开无解）
作为文档（深埋在 coinduction/unification 理论中）。

**旗舰二：filter 保成员**

```
filter_member : l ∈ C ∧ latom l ≠ a ⟹
                l ∈ filter (非 a) C
```

**旗舰三：归结可靠性（侧条件版）**

```
resolution_sound : l1 ∈ C1 ∧ latom l1 ≠ a ∧ eval e l1 ⟹
                   lsat e (resolve C1 C2 a) = true
```

侧条件版的含义：**非消去原子的真文字在归结中保留**。
完整版（无侧条件）需要「两前提满足 ⟹ 至少一侧的非 a 文字真」
的经典分情况讨论——这是 Ben-Ari Th 10.8 完整证明的构造性半边，
另一半属于归结完备性理论，文档登记。

## 归结式的定义

```
resolve C1 C2 a = filter (非 a) C1 ++ filter (非 a) C2
```

消去两侧所有 a-原子上的文字（正负都消——教学版统一处理，
经典归结只消互补对，这里简化为消原子）。

## 三家分工

| 通道 | 内容 |
|---|---|
| Coq | 三旗舰全件 + occurs check 现场演示 |
| Lean | 同构（`UTerm.noConfusion` 收结构差异） |
| Isabelle | 侧条件版 + `value` 现场演示归结式计算 |

## 坑位速记（本章实测）

- **Coq**：`subst (latom l)` 对函数应用位置非法（latom 不是
  变量）——改用 `apply Nat.eqb_eq in E; contradiction`；
  `existsb_exists` 的 **proj2** 是「witness → existsb = true」
  （proj1 是反向——方向搞反报 unifies exists with existsb = true）；
  `filter_In` 是 stdlib 的单参数构造（In + 条件）——
  不用手写归纳。
- **Lean**：`mlit (b a : Nat)` 的 b 应为 **Bool**（写成 Nat
  导致 lpos 类型冲突）；单行 `fun l => match l with …` 的箭头
  要提行（方程式编译器不吃单行 match 混合 lambda）；
  `List.mem_filter.mpr ⟨hin, ?_⟩` + `cases hbeq : (latom l == a)`
  建立条件。
- **Isabelle**：`definition` 里引用的函数必须在**定义之前**
  声明（latom 后置报 Extra variables on rhs）。
