# 01 认识范畴论

> 对书：贺伟《范畴论》1.1 /《高级范畴论》1.3（范畴的定义）、1.4（例子）/
> Simmons 1.1（Categories defined）。
> 代码：`examples/01_intro/`（ex01_intro.v / .agda / .lean）。

## 1.1 为什么是范畴

代数研究群、环、域——每个结构内部有运算；范畴论换一个视角：
**只看对象之间怎么映射，不看对象内部是什么**。
一个范畴是如下数据：

- 一堆**对象** `Obj`；
- 每对对象 `a b` 有一堆**态射** `Hom a b`；
- 每个对象有**恒等态射** `idn a : Hom a a`；
- 态射可**复合**：`f : Hom a b`、`g : Hom b c` 拼成 `comp f g : Hom a c`；
- 三条定律：左单位、右单位、结合律。

把它写成类型，就是三份代码共享的同一个 record：

```coq
Record Category@{u v} : Type := mkCat {
  Obj : Type@{u};
  Hom : Obj -> Obj -> Type@{v};
  idn : forall a, Hom a a;
  comp : forall {a b c}, Hom a b -> Hom b c -> Hom a c;
  idL : forall {a b} (f : Hom a b), comp (idn a) f = f;
  idR : forall {a b} (f : Hom a b), comp f (idn b) = f;
  assoc : forall {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d),
            comp (comp f g) h = comp f (comp g h)
}.
```

Agda 是 `record Category (o ℓ : Level)`，Lean 是
`structure Category`——同一副骨架的三种拼法。**造一个范畴 =
把这八个字段填满，定律无一可逃**：这是「定义即类型」在范畴论上的
第一笔红利。

## 1.2 复合的方向

本书按**图序**（diagrammatic order）书写：`comp f g` = 先 `f` 后 `g`
（Simmons、Mac Lane 部分章节的风格）。函数式的 `f ∘ g` = 先 `g` 后
`f`——它恰好是反范畴视角（02 章）。贺伟本与《高级范畴论》沿用
函数复合习惯；读书时留意每本书的方向约定。

## 1.3 四个首批例子

| 例子 | 对象 | 态射 | 定律 |
|---|---|---|---|
| 终范畴 `catOne` | 1 个 | 恒等 | destruct 后 rfl |
| 幺半群 `catNat` | 1 个 | ℕ | 加法引理（真算术） |
| `FinCat` | 基数 | `fin m → fin n` | βη 折叠全免费 |
| `TyCat` | Type | 函数 | 同上（宇宙多态登场） |

**终范畴 1**：一个对象一条态射。定律里 `f` 是变量，`tt = f` 不能
rfl，要先把 `f` 拆开（Coq 用 `unit_eq`，Lean 用 `Unit.ext`）。

**幺半群 = 单对象范畴**：`(ℕ, +, 0)` 看成只有一个对象 `*` 的范畴，
`Hom * * := ℕ`、恒等 := 0、复合 := 加法。范畴定律逐条变成算术定理：

```coq
idL : 0 + f = f      (* Nat.add_0_l *)
idR : f + 0 = f      (* Nat.add_0_r：要归纳！ *)
assoc : (f + g) + h = f + (g + h)
```

在 `catNat` 里复合两条态射是可计算的：`comp 2 3 = 5`，三家都给出
`rfl`/`refl` 级别的验证。反过来，任何幺半群都是一个单对象范畴，
任何单对象范畴都是一个幺半群——**范畴论统一了「结构」与「作用」**。

**FinCat（有限集范畴的骨架）**：对象 = 自然数（当作基数），
`Hom m n := fin m -> fin n`。本机 coqc 的 stdlib 不含 `Coq.Fin`，
我们自造了四行的 `fin`：

```coq
Fixpoint fin (n : nat) : Set :=
  match n with
  | O => Empty_set
  | S m => option (fin m)   (* None 当 F0，Some 当 FS *)
  end.
```

「函数当态射」的最小化身，且完全避开宇宙问题。

**TyCat（Set 的化身）**：对象 = Type、态射 = 函数。这里宇宙多态
正式登场：Obj 落在 `Set+1` 层、Hom 落在 `Set` 层（Coq 的
`Record Category@{u v}`；Agda 的 `Category (suc 0ℓ) 0ℓ`；Lean 的
`Category.{1, 0}`）。

## 1.4 「函数范畴的定律免费」

FinCat/TyCat 的 idL/idR/assoc 全是 `eq_refl`——因为 Coq 的定义相等
含 **β 与 η（函数）**：

```text
comp (idn a) f = (fun x => f ((fun y => y) x))  β→ (fun x => f x)  η→ f
```

Agda 与 Lean 同理（η 都是定义性的）。对照幺半群范畴的 `idR` 要
归纳——**定义相等白送什么、不送什么**，是三实现横评的第一课。

## 1.5 三家写法对照

| | Coq 8.20 | Agda 2.8 + stdlib 2.3 | Lean 4.25 |
|---|---|---|---|
| 记录 | `Record ...@{u v}` | `record Category (o ℓ)` | `structure Category` |
| 宇宙 | 显式注解/推断 | Level 参数 + `Set (suc _)` | 自动 `Type u/v` |
| idn 参数 | 显式 `forall a` | 隐式 `{a}`，定律里 `idn {a}` | 显式 `∀ a` |
| 定律证明 | eq_refl / PeanoNat | refl / stdlib 引理 | rfl / Nat.add_zero |
| 字段填充 | 逐 binder 绑定（坑） | `record { field = ... }` | `where` 语法 |

注意 Agda 的 idn 用隐式对象参数（stdlib 惯例），定律里要写
`comp (idn {a}) f ≡ f` 实例化——与 Coq/Lean 的显式风格不同。

## 坑位速记

1. Coq record 字段值要**连隐式 binder 一起绑定**：`comp` 的提供项
   是 `fun _ _ _ f g => ...`（5 个 binder）、assoc 是 7 个。
2. Coq 宇宙实例注解不支持代数层（`Category@{Set+1, Set}` 报语法
   错）——去掉注解让推断自己选。
3. 本机 coqc 无 `Coq.Fin`——自造 `fin`（4 行）。
4. Lean `/-!` 模块文档注释的**内容不能以 `-` 开头**：4.25 扫描器
   把 `/-! -- x -/` 误判 unterminated comment（`/-.` 无此问题）。
5. Lean 数字字面量在结构投影下推不出 OfNat：
   `NatCat.comp ... 2 3` 要写 `(2 : Nat)`。
6. Agda `record {...}` 字面量不能挂 `where`；多个例子各自
   `open Category X` 会撞名——包 `module XxxDemo` 隔离。

---

下一章：[02 反范畴与对偶原理](02-opposite.md)
