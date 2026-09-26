# 25 · 依赖类型编程实战

**对标**: *Functional Programming in Lean* 第7章。

## 25.1 索引族：长度精确到类型的向量

`Vect α n` 把长度编进类型——`head` 只对非空向量有定义，空向量根本**无法通过类型检查**：

```lean
inductive Vect (α : Type u) : Nat → Type u where
  | nil : Vect α 0
  | cons : α → Vect α n → Vect α (n + 1)

def Vect.head : Vect α (n + 1) → α
  | .cons x _ => x
-- Vect.nil 上调用 head 直接编译错误，无需运行时检查
```

## 25.2 索引方向陷阱：append 与 Nat.add 的递归参数

> **版本陷阱（重要）**：`Nat.add n m` 递归在**第二个**参数 `m` 上（`m + 1` 处可归约）。
> 因此 append 的结果类型必须写成 `Vect α (m + n)`，且模式匹配的是**左**参数：
> 匹配 `0` 时结果类型是 `0 + m`——`Nat.add 0 m` 不能按定义归约，但此处直接返回 `ys : Vect α m`，
> 与 `Vect α (m + 0)` 的相等性由 `Nat.zero_add` 兜底…实际能通过是因为匹配后构造子分支已经统一起来。
> 若把类型写成 `n + m`（与多数旧教材一致），在 4.34 下**编译失败**，报"无法归约 `0 + m`"。

```lean
def Vect.append : {n m : Nat} → Vect α n → Vect α m → Vect α (m + n)
  | 0, _, .nil, ys => ys
  | _ + 1, _, .cons x xs, ys => .cons x (xs.append ys)
```

```lean
def Vect.replicate : (n : Nat) → α → Vect α n
  | 0, _ => .nil
  | n + 1, a => .cons a (replicate n a)

def Vect.nth? : Vect α n → Nat → Option α
  | .nil, _ => none
  | .cons x _, 0 => some x
  | .cons _ xs, i + 1 => xs.nth? i

#check (Vect.cons 1 (Vect.cons 2 Vect.nil) : Vect Nat 2)
-- Vect.cons 1 (Vect.cons 2 Vect.nil) : Vect Nat 2
```

## 25.3 Subtype：把不变量塞进类型

`{ n : Nat // p n }` 是"满足 p 的 n"的 subtype。构造时必须同时给出值与性质证明：

```lean
def fourEven : { n : Nat // n % 2 = 0 } := ⟨4, by decide⟩
#check fourEven.val        -- fourEven.val : Nat
#check fourEven.property   -- fourEven.property : fourEven.val % 2 = 0
#eval fourEven.val         -- 4
```

## 25.4 空索引类型的消除：Fin 0

`Fin 0` 没有元素。拿到 `n : Fin 0` 就能推出 `False`——用 `elim0`，不需要匹配任何构造子：

```lean
example (n : Fin 0) : False := n.elim0
```

---

> 上一章：[24 · 单子变换器](24-monad-transformers.md) ｜ 下一章：[26 · 公理与计算](26-axioms-computation.md) ｜ 返回：[README](../README.md)
