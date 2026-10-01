# 09 定义与证明工程：λD 的精神

> 对应读本：TTAFP 第 8–11 章（定义 / λD / 在 λD 里做数学）。
> 代码：`examples/09_definitions/`——三家各展定义管理术：
> Coq 的 Section、Lean 的 variable/opaque、Agda 的参数化模块。

## 9.1 定义是什么：保守扩张 + δ

TTAFP 用三章（8–10）把「带定义的类型论」λD 形式化。核心思想
两条：

1. **定义 = 缩写**：`twice := λf n. f (f n)` 引入新常量 `twice`
   与展开规则 `twice ↝δ λf n. f (f n)`。δ-归约与 β 同居一级，
   定义相等因此是 **βδ** 的合一闭环。
2. **保守性**：定义不产生新定理——把所有定义展开后，可证命题
   集合与原系统一致。定义只缩短证明、不增加力量。

听起来平淡，工程上却全是抉择：**要不要让 δ 一直透明？** 三家
给出了三种答案（这正是本章代码的主角）。

## 9.2 三家的定义管理术对照

| 需求 | Coq | Lean 4 | Agda |
|---|---|---|---|
| 全局定义 | `Definition`（透明） | `def`（透明） | 顶层定义（永远透明） |
| 筑墙 | `Qed`（引理不透明） | `opaque` / `@[irreducible]` | **没有墙** |
| 局部定义 | `let ... in` | `let` / `where` 块 | `let` / `where` 块 |
| 批量前提 | `Section` + `Variable`（全量自动泛化） | `section` + `variable`（**用到才收**） | 参数化 `module` |
| 私有性 | `Section` 外不可见？否——导出 | `private` | `private` / 模块不导出 |
| 记法 | `Notation` | `notation` / `infixl` | 语法声明 + fixity |

### 透明与墙：一次实测

```lean
def twice (f : Nat → Nat) (n : Nat) : Nat := f (f n)
-- def 透明：refl 直接穿透
theorem twice_add_0' : ∀ n, twice (fun _ => 0) n = 0 := fun _ => rfl

opaque twiceConst : Nat → Nat := fun n => twice (fun _ => 7) n
#eval twiceConst 5                        -- 求值照常（有运行时值）
-- example : twiceConst 5 = 7 := by rfl   -- 【失败】opaque 挡的就是 rfl
example : twiceConst 5 = 7 := by native_decide   -- 编译器通道绕过内核 δ
```

Coq 的 `Qed` 同理：`simpl` 不再穿透引理体（要 `unfold` 或引理的
**方程**）。为什么需要墙？两个理由：① 性能——全透明会让
`simpl`/`rw` 满屏展开无关定义，证明脚本失控；② 抽象边界——
引理的「怎么证」不该被下游依赖（改证明不破坏使用者）。
Agda 的立场是彻底透明（`refl` 永远全功率），代价靠抽象导出与
编译器旗标控制。

### Section：假设的批量管理

Coq 的经典艺能——段内引理「裸用」前提，段一关自动泛化：

```coq
Section MonoidLike.
  Variable U : Type. Variable op : U -> U -> U.
  Hypothesis op_assoc : forall x y z, op (op x y) z = op x (op y z).
  Variable e : U. Hypothesis e_left : forall x, op e x = x.
  Lemma op_e_left_twice : forall x, op e (op e x) = x. ...
End MonoidLike.
(* 段外：op_e_left_twice 已泛化成带全部前提的独立引理 *)
Check (op_e_left_twice nat Nat.add ... 0 Nat.add_0_l).
```

Lean 的 `variable` 是**用到才收**：只有语句里出现的变量自动进入
类型，假设类前提要写成定理的显式参数——比 Coq 的全量泛化啰嗦
一点，但引理签名更可控。Agda 对应物是**参数化模块**
`module Sort (A : Set) (_≤_ : A → A → Set) where ...`，开箱
`open Sort ℕ ...` 时例化。

## 9.3 复用时的两个小坑（实测）

1. **引理方向要对上**：段内声明的 `op_assoc` 是
   `(x∘y)∘z = x∘(y∘z)` 方向，而 stdlib 的 `Nat.add_assoc`/
   `app_assoc` 恰好**反向**——例化时要 `eq_sym` 转向
   （Coq）/ 用库的方向重排（Lean 的 `←` 重写）。
2. **隐式参数要显式喂**：Coq 里给多态常量例化（`app`、
   `app_assoc`）记得 `@app nat`。

## 9.4 λD 之后：数学进入类型论

TTAFP 的后半部（ch 11–16）在 λD 里搭数学：等词公理、集合与
子集、序数算术、一个完整的等价推理例子——这正是 Coq 生态里
「标准库 + Mathlib」、Lean 生态里 Mathlib 的史前原型。定义、
记号、Section/模块就是这门「搭数学」的手脚架。本指南第三部分
（10–16 章）改走 Martin-Löf 路线（更接近 Agda/Lean 的世界观），
但 λD 的工程教训贯穿全书：

> **类型论的工程 = 规则（08 章 PTS）+ 定义（本章）+ 归纳（13 章）**。
> 三样凑齐，就能在机器里做数学。

> **坑位速记**
> ① Lean 核心库已占用 `⊕`（Sum 记号）——自定义中缀要换冷门
> 符号（本章用 `⊗`），否则 `2 ⊕ 3` 被解析成 `Sum 2 3`；
> ② Lean `notation` 要写优先级（`infixl:65`），裸 `notation
> x " ⊕ " y` 会吞掉后面的 `= 5`；
> ③ `opaque` 恰恰挡 `rfl`——证明要走 `native_decide`（编译器
> 通道）或 `.eq_def`（版本相关）；
> ④ Lean section 变量「用到才收」：只在 tactic 里用的假设不在
> 泛化列表里，会报 unknown identifier——假设写成显式参数最稳；
> ⑤ Coq 8.20 里 `add` 不在顶层作用域（要 `Nat.add`）；
> 多态常量例化用 `@app nat`；
> ⑥ Agda 无 opaque：透明是哲学选择，refl 永远全功率
> （本章 `twice ... ≡ 7` 的 refl 是活例）。
