# 35 · 面向对象进阶：继承、子类型与二元方法

对应示例：`../examples/31_objects_advanced.ml`

OCaml = Objective Caml：对象层是这门语言名字里的 O。它有严肃的
类型理论支撑（行类型、协变注记、类型变量绑定 self），因此能表达
C++/Java 表达不了的东西——也会在二元方法处拒绝 C++/Java 轻易
放行的东西。本章按《OCaml 语言编程基础教程》第 8 章的脉络推进
（8.3–8.14），全部行为在 OCaml 5.4.1 实测；书上的图形案例改成
控制台版本，可无头验证。

第 24 章已经讲了 `object` / `class` 的基础；本章从继承开始。

### 35.1 速览与补遗

值得先钉住的几条边界：

- 字段（`val`）**永远不能**从对象外部直接访问，只能走方法
  （`circle#radiu` 报 `It has no method radiu`）；
- 方法可以**无参**（`method get_radiu`），函数至少要 unit 参数；
- 不写 `class` 也能直接造对象，类型就是方法签名的集合
  `<get_radiu : int; ...>`；带初始化参数的类相当于
  「参数 → 对象」的函数；
- `initializer e` 在 `new` 时执行（校验、打印副作用都放这里）。

### 35.2 继承：`inherit ... as super` 与 `object(self)`

```ocaml
class cl_base (r : int) = object
  val mutable radiu = r
  method get_radiu = radiu
  method set_radiu v = radiu <- v
  method draw = Printf.printf "  [base] circle radius=%d\n" radiu
end

class cl_color (r : int) (c : string) = object(self)
  inherit cl_base r as super            (* 父类别名 *)
  val mutable color = c
  method get_color = color
  method draw =
    Printf.printf "  [color=%s] " self#get_color;
    super#draw                          (* 复用父类 draw *)
end
```

- `object(self)` 给**当前对象**起名，方法里可用 `self#m` 调本类
  （其他静态方法）；不写 self 时直接 `m` 也行；
- `inherit ... as super` 给**被继承实例**起名——覆盖方法里复用
  父类版本的唯一途径；
- 重名的新定义必须与被继承定义**类型一致**，否则类型错。

### 35.3 多重继承

OCaml 允许多重继承。两个父类有同名方法时：

- 同名**同类型**：不重新定义则**后继承的生效**；
- 同名**不同类型**：直接类型错（无法调和）；
- 惯例：在子类里重定义该方法，分别调 `super_a#m`、`super_b#m`
  「合并」两家行为。

另一个反向差异：**OCaml 方法不能重载**。一个类里两个 `method f`
直接 `The method f has multiple definitions`；而 C++ 恰恰允许
父类同名同类型共存、禁止的规则又不同——两家正好相反，C++ 程序员
注意。

### 35.4 延迟绑定

父类方法 `g` 里经 `self#f` 调用 `f`，子类只重定义 `f`：

```ocaml
class d1 = object(self)
  method f i = i + 1
  method g i = self#f i
end

class d2 = object
  inherit d1
  method f i = i + 2              (* 只改 f *)
end

let dd2 = new d2 in
dd2#g 0                            (* 2 —— 调的是 d2 的 f！ *)
```

绑定在**运行期**按接收者决定（C++ 的虚函数同款语义）。

### 35.5 私有方法 ≈ C++ 的 protected

```ocaml
class p1 = object(self)
  method private secret i = i + 100
  method public i = self#secret i
end

class p2 = object
  inherit p1 as super
  method via_super i = super#secret i    (* 子类能调！ *)
end
```

外部 `pp#secret` 报 `It has no method secret`。所以 OCaml 的
`private` 更像 C++/Java 的 **protected**：本类与子类可见、外界
不可见。

### 35.6 虚拟类（抽象类）

```ocaml
class virtual cl_shape = object(self)
  method virtual area : float              (* 无方法体 *)
  method describe = Printf.sprintf "area=%.1f" self#area
end
```

- `new cl_shape` 直接 `Cannot instantiate the virtual class`；
- 用法是继承并在子类里实现全部虚拟方法；
- 虚拟方法**必须**写类型标注。

### 35.7 子类型：上行强制、异构表、开放类型

不同子类的对象不能直接进同一个 list；显式上行到共同父类后可以：

```ocaml
let shapes : cl_shape list =
  [ (new cl_square 2.0 :> cl_shape); (new cl_disk 1.0 :> cl_shape) ]
```

两种「结构化」的宽接口：

```ocaml
let show_any (s : #cl_shape) = ...        (* 开放类型：cl_shape 及其超集 *)
let show_row (s : < area : float; .. >) = ...   (* 行多态：只要有 area *)
```

- `:> ` 是 OCaml 的子类型强制（区别于签名的 `:>`——语境决定含义）；
- **子类型 ≠ 继承**：没有任何继承关系的类，只要方法集是超集，
  就是子类型；
- **坑（实测）**：开放类型 `#cl` 只能用在 `let` 与类初始化参数上；
  写在方法参数 `(a : #cl)` 里直接类型错。方法里用行多态标注代替。

### 35.8 多态类

`class` 定义里不会自动推出多态方法；类型变量要显式写在类名前：

```ocaml
class ['a] c3 = object
  method f (i : 'a) = i
end
```

- `new c3` 的类型是 `'_a c3`——**弱类型变量**（value restriction
  同样作用于对象！），第一次使用后固化；
- 继承多态类必须带类型参数：`inherit ['a] c3`；也可以直接实例化
  `inherit [int] c3` 得到非多态子类；
- 多态类的继承有著名的深坑（类型变量在两个参数间共享导致互相
  固化），书 8.10 节有完整分析——初学阶段记住「类型参数要么保持、
  要么钉死，别中途嫁接」即可。

### 35.9 二元方法：子类未必是子类型（压轴）

**二元方法**（binary method）是参数类型与当前类相同的方法——
典型是相等判断：

```ocaml
class e3 (x_init : int) = object(self)
  val x = x_init
  method get_x = x
  method eq (a : 'a) = self#get_x = a#get_x
end
```

注意 `object(self : 'a)`——self 显式标注类型变量，`eq` 的参数也
用同一个 `'a`。类型系统由此知道「参数与我同型」。

子类加字段并重定义 `eq`（`method eq (a : 'a)` 会随继承自动指向
子类自己的类型）：

```ocaml
class e4 (x_init : int) (y_init : int) = object(self)
  inherit e3 x_init
  val y = y_init
  method get_y = y
  method eq (a : 'a) = self#get_x = a#get_x && self#get_y = a#get_y
end
```

**然后 surprising 的事情发生了**：

```ocaml
(b1 : e4 :> e3)
(* Error: Type e4 = < eq : e4 -> bool; get_x : int; get_y : int >
          is not a subtype of e3 = < eq : e3 -> bool; get_x : int > *)
```

推理链条（书 8.12 节）：

1. `eq` 在 e3 里是 `e3 -> bool`，在 e4 里是 `e4 -> bool`——
   **二元方法的类型随类走**；
2. 要 `e4 <: e3`，需要 e4 的每个方法是 e3 对应方法的子类型；
3. 函数子类型规则：`A -> B <: C -> D` 当且仅当 `C <: A` 且 `B <: D`；
   于是需要 `e3 <: e4`；
4. 但继承方向又要求 `e4 <: e3`——成环，不成立。

**子类未必是子类型。** 深层原因：若把 e4 对象当 e3 用，就可能拿
一个纯 e3 对象去调它的 `eq`，而 e4 的 `eq` 需要 `get_y`——e3
没有。类型系统在救你，不是在为难你。

（对照：不用 `self : 'a`、直接写 `method eq (a : e3)` 的版本，
子类重定义时同样编译不过——`a#get_y` 找不到方法。两条路都堵，
这是对象语言经典的 binary method problem。）

### 35.10 class type：类的类型

`class type` 描述「一类对象的类型」，可当标注、可继承扩展：

```ocaml
class type counter_t = object
  val mutable count : int
  method bump : unit
  method get : int
end

class counter = object
  val mutable count = 0
  method bump = count <- count + 1
  method get = count
end

let ct : counter_t = new counter
```

与签名的 `module type` 类比：一个是对象的契约，一个是模块的契约。

### 35.11 对象相等是物理相等

```ocaml
(1, 2) = (1, 2)          (* true  —— 元组是结构相等 *)
[1; 2; 3] = [1; 2; 3]    (* true  —— 列表是结构相等 *)

(new blank) = (new blank)   (* false —— 对象是物理相等（同地址）！ *)
let only = new blank in only = only   (* true *)
```

为什么不做结构相等：子类型强制后，同类型的两个对象可能来自字段
数不同的类，「逐字段比较」没有良定义的结果。要内容比较，自己写
`eq` 二元方法（见 35.9）。

### 35.12 本章小结

| 概念 | 一句话 |
|---|---|
| `inherit ... as super` | 覆盖方法里复用父类版本 |
| `object(self)` / `object(self : 'a)` | 给自己起名 / 绑定 self 类型 |
| 多重继承 | 同名同类型后者生效；同名不同类型编译错 |
| 延迟绑定 | `self#m` 运行期按接收者解析 |
| `method private` | 对外不可见、子类可见（≈ protected） |
| `class virtual` | 抽象类，不能 new，子类补全 |
| `:>` | 显式子类型上行强制 |
| `#cl` / `< m : t; .. >` | 开放类型 / 行多态宽接口 |
| `class ['a]` | 多态类；`new` 结果带弱类型变量 |
| `object(self:'a)` 二元方法 | 子类未必是子类型的根源 |
| `class type` | 对象类型的显式契约 |
| `=` on objects | 物理相等（地址），不是结构相等 |

书第 8 章最后的案例（面向对象电机接线程序）依赖 Graphics 图形
库，本教程无法无头验证，改写为控制台版本，结构等价。示例 31 把
本章每个机制都跑了一遍。

---
上一章：[34 · 命令式进阶：弱多态、四向链表与命令式容器](34-imperative-deep.md) ｜ 下一章：[36 · 坑清单与最佳实践](36-pitfalls.md) ｜ 返回：[README](../README.md)
