# 25 · 类型类：`class` 与 `instantiation`

对应示例：`../examples/T25_classes.thy`

## 25.1 类型类解决什么问题

第 20 章的 `locale` 是"打包假设"，一次一处；**类型类（`class`）** 是"按类型分派"——写 `x + y` 时，`+` 到底是 nat 的加、int 的加还是 list 的 append，靠 `x` 的类型自动选。它的两条基本纪律：

1. **一个类型对一个类至多一个实例**（区别于 locale 的多实例）；
2. **类里的常量在语法层是"重载"的**，一旦 `instantiation` 完成，普通记号（`x • y`）就直接用。

这带来便利，也带来坑：类型推不出来时报的是"sort constraint"，不是"没定义"。

## 25.2 定义一个最小的半群类

```isabelle
class mg =
  fixes inf2 :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"  (infixl "\<bullet>" 70)
  assumes inf2_assoc: "(x \<bullet> y) \<bullet> z = x \<bullet> (y \<bullet> z)"
```

```text
class mg = type +
  fixes inf2 :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"
  assumes "inf2_assoc": "\<And>x y z. x \<bullet> y \<bullet> z = x \<bullet> (y \<bullet> z)"
```

`class` 命令自动生成三样东西：`mg` 类型约束、`inf2` 投影函数、`mg.inf2_assoc` 泛化引理。注意 `thm` 里那条"类公理"的实际形态：

```isabelle
thm mg.inf2_assoc
```

```text
class.mg ?inf2.0 \<Longrightarrow> ?inf2.0 (?inf2.0 ?x ?y) ?z = ?inf2.0 ?x (?inf2.0 ?y ?z)
```

这里的 `?inf2.0` 就是**类参数字段的显式版本**——类型类内部把 `•` 编译成一个字段，`class.mg` 是"这个类型实例提供了字段"的谓词。日常写 `x • y` 时看不到它；出问题时（尤其是 `simp` 拒绝重写）就要认得。

## 25.3 把 nat 装进去：`instantiation`

```isabelle
instantiation nat :: mg
begin

definition inf2_nat :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "inf2_nat m n = m + n"

instance
  by intro_classes (simp add: inf2_nat_def)

end
```

```text
instantiation
  nat :: mg
  inf2_nat == inf2 :: nat \<Rightarrow> nat \<Rightarrow> nat

consts
  inf2_nat :: "nat \<Rightarrow> nat \<Rightarrow> nat"
```

`instantiation` 像"临时理论"：在里面给运算一个具体定义（命名惯例是 `<op>_<type>`），再补一次证明义务。`intro_classes` 是**类实例专用**的方法（跟 `intro_locales` 对偶），把类公理摊成子目标后交给 simp。

实例建立之后，`•` 记号在 nat 上就是 `inf2_nat`：

```isabelle
value "(3 :: nat) \<bullet> 4"
```

```text
"7"
  :: "nat"
```

## 25.4 再来一个实例：list 的连接

同一个类在**多个类型**上并存，是类型类相对 locale 的关键差别。

```isabelle
instantiation list :: (type) mg
begin

definition inf2_list :: "'a list \<Rightarrow> 'a list \<Rightarrow> 'a list" where
  "inf2_list xs ys = xs @ ys"

instance
  by intro_classes (simp add: inf2_list_def)

end

value "([1,2] :: nat list) \<bullet> [3]"
```

```text
"[1, 2, 3]"
  :: "nat list"
```

**坑**：list 是类型构造子，`instantiation list :: mg` 会报"Bad number of arguments for type constructor"。必须写 `instantiation list :: (type) mg`——`(type)` 是 list 参数的 sort 约束。这是 25 章最容易踩的一条。

## 25.5 类里的引理：靠类型约束触发

`context mg begin ... end` 里写引理，类型变量自动带 `:: mg` 约束。离开 context 后引理名字带 `mg.` 前缀，靠类型约束把假设自动装回去。

```isabelle
context mg
begin

lemma inf2_four: "((a \<bullet> b) \<bullet> c) \<bullet> d = a \<bullet> (b \<bullet> (c \<bullet> d))"
  by (simp add: inf2_assoc)

end

thm mg.inf2_four
```

```text
class.mg ?inf2.0 \<Longrightarrow>
?inf2.0 (?inf2.0 (?inf2.0 ?a ?b) ?c) ?d =
?inf2.0 ?a (?inf2.0 ?b (?inf2.0 ?c ?d))
```

在 nat 上直接引用：

```isabelle
lemma nat_four: "((1 :: nat) \<bullet> 2) \<bullet> 3 \<bullet> (4 :: nat) = 1 \<bullet> (2 \<bullet> (3 \<bullet> (4 :: nat)))"
  by (simp add: inf2_nat_def)
```

## 25.6 子类：`class mg_idem = mg + assumes ...`

```isabelle
class mg_idem = mg +
  assumes inf2_idem: "x \<bullet> x = x"

instantiation bool :: mg
begin
definition inf2_bool :: "bool \<Rightarrow> bool \<Rightarrow> bool" where
  "inf2_bool p q = (p \<and> q)"
instance by intro_classes (simp add: inf2_bool_def)
end

instantiation bool :: mg_idem
begin
instance by intro_classes (simp add: inf2_bool_def)
end

value "(True :: bool) \<bullet> True"
```

**"至多一实例"带来的筛选**：nat 上 `•` 是 `+`，不幂等，所以 `nat` **是** `mg` 但**不是** `mg_idem`；bool 上 `•` 是 `∧`，幂等，两条都满足。这就是 `mg_idem` 的类型集合是 `mg` 类型集合的**真子集**的原因。

## 25.7 与 locale 的对比

20 章给了分工表；从**类**的视角补一条：

- `class` 的常量在语法层**隐式限定**——同一个短名 `x • y`，nat 上就是 `inf2_nat`、bool 上就是 `inf2_bool`；
- `locale` 里 `mult` 只有一份，不同实例要靠 `interpretation name: locale ...` 起别名，再引用 `name.assoc`。

## 25.8 常见坑：sort constraint 未满足

如果类型没被实例化，写 `x • y` 时报的是 sort 不匹配、**不是**"未定义"。用 `term` 打印带约束的项最容易看出问题在哪：

```isabelle
term "(\<lambda>x y :: 'a :: mg. x \<bullet> y)"
```

```text
"(\<bullet>)"
  :: "'a \<Rightarrow> 'a \<Rightarrow> 'a"
```

看到 `'a::mg` 就说明类型约束**必须**由使用点提供实例；否则报的是 `Type 'a not of sort mg`。

## 本章坑位清单（实测）

1. **`instantiation list :: mg` 报 `Bad number of arguments for type constructor`**：list 是类型构造子，要写 `instantiation list :: (type) mg`。
2. **`intro_class` 不是方法**：正确名字是 `intro_classes`（复数）。同理 `intro_locale` 应为 `intro_locales`。
3. **类公理的 `thm` 输出带 `?inf2.0` 字段**：这是类参数字段的显式形态，不是错误。日常用 `simp add: inf2_assoc` 就够；`simp` 拒改时把它认出来是排错第一步。
4. **`print_class` 不是命令**： Isabelle2025 里没有，`print_classes`（复数）打印所有类名，查单个类公理用 `thm mg.inf2_assoc`。
5. **同一个类不能给同一类型装两个实例**：`instantiation nat :: mg` 写第二遍就报冲突；要多种结构就用 `locale`（第 20 章）。
6. **类里假设是"事实"，locale 里假设是"假设"**：`mg.inf2_assoc` 一旦建立，`simp` 在任何 `mg` 类型上都能用；`locale mg` 里的 `assoc` 只在 `interpretation` 之后按实例名生效。
7. **`class` 只能出现在 `theory` 顶端**，不能包在 `locale ... begin ... end` 里。
8. **类继承时不写 `assumes`，只补 `fixes` 也可以**：`class foo = bar +` 就足够建立子类关系。
9. **`instantiation` 里 `definition` 的默认名字必须**（约定）是 `<op>_<type>`，`intro_classes` 才知道把定义展开塞到哪里。名字乱取，simp 会失败。
10. **sort 与类型类是两套词汇**：`'a::type` 是内置 sort，`'a::mg` 是自定义类；`print_sorts` 看全部 sort，`print_classes` 看全部类。

---

上一章：[24 · 综合案例：编译器](24-capstone.md) ｜ 下一章：[26 · 共归与 codatatype](26-codatatype.md) ｜ 返回：[README](../README.md)
