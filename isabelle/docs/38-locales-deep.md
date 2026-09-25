# 38 · Locale 进阶：定义、继承与 sublocale

对应示例：`../examples/T38_locales_deep.thy`

## 38.1 一句话概括

locales 手册的后半：locale **内**的定义与 primrec
（interpretation 时自动翻译到载体）、继承与参数合并、
`sublocale` 的带证明包含、局部解释 `interpret`、以及
`print_locale`/`print_interps` 检查工具。

## 38.2 locale 里可以有定义

```isabelle
locale semigroup =
  fixes prod :: "'a ⇒ 'a ⇒ 'a" (infixl "⊗" 70)
  assumes assoc: "(x ⊗ y) ⊗ z = x ⊗ (y ⊗ z)"

context semigroup
begin
primrec power_sg :: "'a ⇒ nat ⇒ 'a" where
  "power_sg x 0 = x"
| "power_sg x (Suc n) = x ⊗ power_sg x n"
end

interpretation list_sg: semigroup append
  by standard (simp add: append_assoc)
```

interpretation 之后 `list_sg.power_sg.simps` 是 append 载体上的
翻译版。**value 里用 locale 定义**要喂全参数：
`value "semigroup.power_sg append [(1::nat)] 3"`——裸写
`power_sg x 3` 报未绑定（实测坑）。

## 38.3 继承与参数合并

```isabelle
locale monoid_l = semigroup +
  fixes one :: 'a ("𝟭")
  assumes left_neutral [simp]: "𝟭 ⊗ x = x"
```

父 locale 的 `prod` 只声明一次，参数自动合并。
`interpretation list_mon: monoid_l append "[]"` 一次过两层的义务。

## 38.4 sublocale：带义务的包含

最有内容的一个——交换半群里"对偶乘法"又是半群：

```isabelle
sublocale comm_semigroup ⊆ dual_sg: semigroup "λx y. y ⊗ x"
  by standard (simp add: assoc)
```

义务（对偶的结合律 `(c⊗b)⊗a = c⊗(b⊗a)`）恰好就是 assoc 本身
——写 `auto simp: assoc [symmetric] comm` 反而磨不动（实测挂死），
义务最小化是 sublocale 的第一纪律。注意 sublocale 的参数映射
写清（`\<lparr>param := expr\<rparr>` 语法在映射非平凡时用）；
写不成立的包含硬 sorry 构建必拒。

## 38.5 局部解释

`interpretation` 全局（写进理论）；`interpret` 只在当前证明里：

```isabelle
lemma nat_sg_local:
  fixes a b :: nat
  shows "(a + b) + b = a + (b + b)"
proof -
  interpret nsg: semigroup "(+) :: nat ⇒ nat ⇒ nat"
    by standard simp
  show ?thesis by (simp add: nsg.assoc)
qed
```

一字之差，作用域天差地别。

## 38.6 检查工具

`print_locale semigroup` / `print_locale comm_semigroup` /
`print_interps semigroup`——忘了解释叫什么名先查它。

## 38.7 坑位清单（实测）

1. locale 定义的引用前缀：`semigroup.power_sg` 或解释前缀
   `list_sg.power_sg`；value 里参数喂全。
2. `interpret`（局部）与 `interpretation`（全局）一字之差。
3. 多继承同名参数映射不同：合并阶段报 `Conflicting`。
4. sublocale 义务证不动 = 包含不成立或映射写错，改设计而非硬顶。
5. locale 里的 primrec 终止性照常检查（右端带 locale 常量没关系）。
6. **locale 内 primrec 的 code 方程不注册**：value 直接报
   `No code equations for semigroup.power_sg`（会话构建实测）——
   观察用 thm，别用 value。
7. **interpret 的多态陷阱**：`interpret nsg: semigroup "(+)"` 不标类型，
   义务变成 ⋀x y z 的多态 assoc，simp 关不掉（实测）；标
   `"(+) :: nat ⇒ nat ⇒ nat"` 单态化后 `by standard simp` 一步过。
8. interpret 在证明里会把后续目标泛化（自由变量变 ⋀）——show 的
   目标形状要跟着调整。

## 38.8 与其他章的接口

- 第 20 章 locale 最小闭环；本章是其工程面。
- 第 25/39 章类型类：locale 与 class 的互相翻译通道。
- 第 31 章 inductive 也可以在 locale 里做（参数 for）。
