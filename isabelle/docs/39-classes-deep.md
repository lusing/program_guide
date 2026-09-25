# 39 · 类型类进阶：overloading 与实例工程

对应示例：`../examples/T39_classes_deep.thy`

## 39.1 一句话概括

classes 手册的后半：`overloading` 块（同名常量按类型分身）、
带证明义务的完整 `instantiation`（本例给 typedef 出的小类型装
`equal` 类）、`subclass` 的正确用法、以及 sort 约束的读法。

## 39.2 overloading：只共享名字，不共享公理

```isabelle
consts shrink :: "'a ⇒ 'a list"

overloading
  shrink_nat \<equiv> "shrink :: nat ⇒ nat list"
  shrink_bool \<equiv> "shrink :: bool ⇒ bool list"
begin
definition "shrink_nat n = [n div 2]"
definition "shrink_bool b = [False]"
end
```

与 class 的区别：class 要求所有实例共享一条公理；overloading
只共享名字。定义分身名要手动起（`shrink_nat_def` 可引用）。
`value "shrink (7::nat)"` 直接按类型选分身。

## 39.3 一个非空义务的完整实例

第 25/30 章的义务用 `standard`+自动化清空。这里补完整版：
typedef 出的 `two`（{0,1::nat}）装 `equal` 类：

```isabelle
typedef two = "{0, 1::nat}" by auto

instantiation two :: equal
begin
definition eq_two: "HOL.equal a b ⟷ Rep_two a = Rep_two b"
instance
proof
  fix x :: two show "HOL.equal x x" by (simp add: eq_two)
qed
end
```

`equal` 驱动 `HOL.equal` 的 code 生成。义务是自反——
`simp add: eq_two` 一行，但**必须显式给**（`instance ..` 在这里
不够，因为 equal 的公理不是定义态）。

## 39.4 subclass 的正确用法

同类强化用**继承**（locale 式 `=`）表达比 subclass 直白；
`subclass` 的真正用途是把**内置类层次**上的包含证出来
（如证新类型落在 `ab_semigroup_add` 下，白拿 `Groups` 树的引理），
义务多时先证辅助引理或上 lifting（第 28 章）。
写不成立的包含硬 `sorry`——构建必拒，别试。

## 39.5 sort 约束阅读法

sort 是**类型的集合**：`'a::{plus,zero}` = 同时是 plus 和 zero
实例的类型。`value` 报 `not of sort {equal,ord}` 系列（第 3/35 章）
时，根源是约束最小的类型变量缺信息——补类型标注解决大半。
`[[show_sorts]]` 打开后排错最快。

## 39.6 坑位清单（实测）

1. `consts` + `overloading` 的定义名要手动起，不然重载块没抓手。
2. `instantiation` 块忘 `instance` 收尾：`Unfinished instantiation`。
3. typedef 后立刻 instance：Rep/Abs 性质不在 simp 里，
   显式 `Abs_two_inverse` / `Rep_two_inject`。
4. `sorry` 构建必拒（quick_and_dirty 关闭时）——写不下去先怀疑设计。
5. `instantiation t :: (c1, c2) c3` 括号里是**类型构造器参数**的约束，
   写错位置类型检查直接爆。

## 39.7 与其他章的接口

- 第 25 章类基础、第 30 章 linorder 实例。
- 第 28 章 lifting：instance 义务的自动化通道。
- 第 40 章 Main 库：类层次的消费侧。
