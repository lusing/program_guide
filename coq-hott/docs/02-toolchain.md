# 02 读懂这个库 —— HoTT 库与标准 Coq 的三点不同

> 本章代码：[`examples/02_toolchain.v`](../examples/02_toolchain.v)

Coq-HoTT 不是装在 Coq 上的一个插件，而是**替换了 Coq 的地基**。
这一章不讲安装和编译（那些在 README 附录里），只讲三件读代码之前必须知道的事：
它为什么要自带一套 prelude、它怎样管理公理、以及同一个记号为什么会有好几种含义。
顺带介绍四条问询命令，后面每一章都靠它们"看清楚"库里的对象。

## 2.1 第一点不同：自带 prelude

标准 Coq 启动时会加载 Stdlib 的 Prelude，里面有 `nat`、`list`、`eq`、`+` 等等。
HoTT 库对这些基础类型有自己的定义——它们**同名但不同义**：

- `paths`（即 `=`）在 HoTT 里是一个要认真对待的类型，不是被 proof irrelevance 压扁的命题；
- `nat`、`Bool`、`prod`、`sum`、`sig` 都是重新定义的，带着 HoTT 自己的宇宙层级和记号；
- 没有 `Prop` 这个 impredicative 的命题层，一切都在 `Type` 里。

所以 HoTT 项目必须用 `-noinit` 把标准库挡在外面，再 `Require Import HoTT` 换上自己的地基。
在示例文件里你看到的开头永远是：

```coq
Require Import HoTT.
Local Open Scope path_scope.
```

试图再去拿标准库的东西会失败：

```coq
Fail Require Import Stdlib.Lists.List.
```

这解释了一个常见困惑：为什么 HoTT 教程里的 `nat` 和你在别处学的 `nat` 行为略有差异
（比如 `Print nat` 显示它在 `Type0`，而且 `+` 不在默认作用域）。它们是不同的定义。

## 2.2 第二点不同：公理是显式假设，不是全局事实

HoTT 有两条著名的公理：**函数外延**（逐点相等的函数相等）和**泛等**（等价的类型相等）。
库对它们的处理方式很值得学习：

- 把每条公理做成一个**空的类型类**：`Funext : Type0`、`Univalence : Type0`，没有构造子；
- 需要公理的定理写成 `Context `{Funext}` 或 `Context `{Univalence}`，也就是把公理当参数；
- 真正断言"公理成立"的实例放在单独的模块 `HoTT.Axioms.Funext` 和 `HoTT.Axioms.Univalence` 里。

这样做的好处是**每一条定理用到了什么公理都可以被机器列出来**：

```coq
Print Assumptions concat_p1.      (* 纯路径代数，不用任何公理 *)
```

```text
Closed under the global context
```

```coq
Print Assumptions path_forall.    (* 函数外延 *)
```

```text
Axioms:
isequiv_apD10 : Funext -> forall (A : Type) (P : A -> Type) (f g : forall x : A, P x), IsEquiv apD10
Funext : Type0
```

"Closed under the global context"的意思是：这条定理是纯构造性的，一个公理都没用。
本教程会一直用这个工具标记哪些结论是零公理的、哪些依赖函数外延、哪些依赖泛等
（README 里有总表）。

一个常见的坑由此而来：**`Require Import HoTT` 不给你公理的实例。**
导入 `HoTT` 只是导入定义和定理。当你看到 `path_universe` 的类型里挂着一个
未解决的 `?H : Univalence`，那是在说"请调用方提供泛等"。两种提供方式：

```coq
Section Demo.
  Context `{Univalence}.          (* 方式一：作为假设，出了 Section 变成参数 *)
  (* ... *)
End Demo.

Require Import HoTT.Axioms.Univalence.   (* 方式二：全局导入公理实例 *)
```

第 10、11 章会分别对两条公理演示这两种方式，并用 `Print Assumptions` 看结果的差别。

## 2.3 第三点不同：记号由作用域决定含义

HoTT 库大量使用重载记号，同一个符号在不同作用域（scope）里指不同的东西。
最重要的几个：

| 作用域 | 记号 | 含义 |
|---|---|---|
| `path_scope` | `1`、`p @ q`、`p^` | 恒等路径、路径复合、逆路径 |
| `equiv_scope` | `1`、`g oE f`、`e^-1` | 恒等等价、等价复合、逆等价 |
| `type_scope` | `A * B`、`A + B`、`A <~> B`、`f == g` | 乘积、和、等价类型、逐点同伦 |
| `nat_scope` / `int_scope` | `+`、`*`、`-`、`n.+1` | 算术 |
| `trunc_scope` | `-2`、`-1`、`0` | 截断层级 |
| `fibration_scope` | `u.1`、`u.2` | Σ 类型的投影 |
| `pointed_scope` | `X ->* Y`、`X <~>* Y` | 保点映射、点化等价 |

`1` 是重载最严重的一个：它在 `path_scope` 里是 `idpath`，在 `equiv_scope` 里是 `equiv_idmap`，
在 `nat_scope` 里才是自然数 1。库默认打开 `path_scope`，所以**裸写的 `1` 是恒等路径**。
想要别的含义就加作用域键：`1%nat`、`1%equiv`、`(-2)%trunc`。

```coq
Check (1 : nat = nat).     (* idpath : nat = nat *)
Check (0%nat : nat).       (* 自然数 0 *)
Check (-2)%trunc.          (* 截断层级 -2 *)
Check (equiv_idmap Bool).  (* 打印成 1%equiv *)
```

`^-1` 也有两个版本：`function_scope` 里是"等价的反函数"（`equiv_inv`，类型 `B -> A`），
`equiv_scope` 里是"逆等价"（`equiv_inverse`，类型 `B <~> A`）。日常使用它们可以互换，
但类型不同。

## 2.4 四条问询命令

读 HoTT 库的代码，最重要的技能是"看清楚一个名字到底是什么"。四条命令各有分工：

| 命令 | 回答的问题 | 什么时候用 |
|---|---|---|
| `Check t` | `t` 的类型是什么 | 最常用；确认一条引理说了什么 |
| `About c` | `c` 的完整信息：隐式参数、作用域、定义在哪个文件哪一行 | 排查"为什么它被解析成了别的东西" |
| `Print c` | `c` 的定义体 | 想知道一个引理是怎么证的、一个类型有哪些构造子 |
| `Locate "sym"` | 记号 `sym` 定义在哪、属于哪个作用域 | 遇到不认识的符号 |

一个典型的用法：`Print paths` 让你看到相等类型的真身：

```text
Inductive paths (A : Type) (a : A) : A -> Type :=  idpath : a = a.
```

`A` 和起点 `a` 是**参数**（在冒号左边），终点是**索引**（在冒号右边）。
这个区分决定了路径归纳的形状（第 04 章）。

另一个典型用法：`Locate "->"` 会告诉你 `->` 在四个作用域里有四种含义
（函数类型、布尔蕴含、可判定命题蕴含、保点映射），这就是作用域机制的根源。

`Search` 在找引理时不可或缺，但要给足约束，否则会刷出几百条。第 23 章专门讲搜索技巧。

## 2.5 `-indices-matter` 是什么意思

编译命令里的 `-indices-matter` 值得说一句。Coq 默认在计算一个归纳类型所在的宇宙时，
只看参数不看索引。对 `paths` 这样的索引族，这会让 `x = y` 落在比 `A` 更低的宇宙里，
进而在某些推理里产生不一致。HoTT 要求索引也参与宇宙计算，所以这个开关必须打开。
作为读者你不需要操心它，只需知道：这不是可选优化，而是语义要求。

## 小结

- HoTT 库替换了 Coq 的 prelude，基础类型同名不同义；一切都在 `Type` 里，没有 `Prop`。
- 公理是显式假设：`Funext`、`Univalence` 是空类型类，用 `Context` 引入或从 `HoTT.Axioms.*` 导入；
  `Print Assumptions` 能列出任意定理的公理依赖。
- 记号由作用域决定；裸写的 `1` 是恒等路径，算术要加 `%nat`。
- 四条问询命令：`Check` 看类型、`About` 看全貌、`Print` 看定义、`Locate` 查记号。

## 常见误区

1. **以为 `Require Import HoTT` 已经包含泛等**。没有；看到 `?H : Univalence` 挂在类型上，
   就是在要你提供它。
2. **以为 `1 + 1` 是算术**。在默认作用域下它根本解析不了；写 `(1 + 1)%nat`。
3. **把 `Closed under the global context` 当成报错**。它是好消息：零公理。
4. **把 `Check` 输出里的 `?A`、`?H` 当成错误**。它们是尚未确定的隐式参数或类型类实例，
   给足参数就会消失。

## 练习

1. 对 `transport`、`equiv_adjointify`、`path_universe` 各做一次 `Print Assumptions`，
   预测哪个会出现公理，再验证。
2. `Locate "1"` 列出了多少个作用域？哪一个标着 `default interpretation`？

---

**上一章**：[01 类型论原理](01-type-theory.md)
**下一章**：[03 依赖类型](03-dependent-types.md)
