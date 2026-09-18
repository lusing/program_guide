# 07 · 结构体

> 对应示例：`examples/07_structs/`
>
> 三种结构体、impl 方法、关联函数、derive——比 C++ 的 class 少一半概念，
> 因为所有权已经把"拷贝/释放"管掉了。

## 7.1 三种形态

```rust
struct Rect { width: f64, height: f64 }   // 具名字段（最常用）
struct Color(u8, u8, u8);                 // 元组结构体：按位置访问（c.0/c.1/c.2）
struct Marker;                            // 单元结构体：零大小，当类型标签用
```

元组结构体的两大用途：**新类型模式**（`struct Meters(f64)`——编译期区分单位）和零成本包装。单元结构体常用于 trait 占位、状态机标签。

## 7.2 实例化与解构

```rust
let r = Rect { width: 3.0, height: 4.0 };
let Rect { width: w, height: _ } = r;     // 模式解构（08 章推广到 match）
let widened = Rect { width: 5.0, ..base }; // 结构体更新语法：未列字段从 base 搬来
```

字段初始化简写：变量名与字段同名时 `Rect { width, height: h }`。

**可变性是绑定级、整体生效**——没有"单个 mut 字段"：

```rust
let mut r = Rect::new(1.0, 2.0);
r.width = 9.0;        // ✔ 整个绑定是 mut
// let r2 = Rect { mut width: 1.0, .. };  // ✘ 不存在这种语法
```

需要"局部可变"时用 `Cell`/`RefCell` 包字段（18 章）。

## 7.3 impl：方法与关联函数

```rust
impl Rect {
    // 关联函数（无 self）：Type::name() 调用 —— 构造器惯例叫 new
    fn new(width: f64, height: f64) -> Self { Self { width, height } }
    fn square(size: f64) -> Self { Self::new(size, size) }

    // 方法：self 形态 = 权限声明
    fn area(&self) -> f64 { self.width * self.height }        // 只读借用
    fn scale(&mut self, k: f64) -> &mut Self { /* 就地改 */ self } // 可变借用，链式
    fn into_parts(self) -> (f64, f64) { (self.width, self.height) } // 拿走所有权
}
```

| 第一参数 | 权限 | 调用后原值 |
|---|---|---|
| `&self` | 只读（90% 的方法） | 可用 |
| `&mut self` | 独占修改 | 可用（前提绑定是 mut） |
| `self` | 消耗 | 不可用（变成转换/分解类方法） |

`Self` 是"当前类型"的类型别名。方法调用自动引用/解引用：`r.area()` ≡ `Rect::area(&r)`——无需 C++ 的 `->`/`.` 之分。

## 7.4 Display 与 Debug：两种打印

```rust
#[derive(Debug)]                     // 让 {:?} 可用（编译器生成开发者格式）
struct Rect { w: f64, h: f64 }

impl std::fmt::Display for Rect {    // 让 {} 可用（面向用户的格式，必须手写）
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:.1}×{:.1}", self.w, self.h)
    }
}
```

`{:?}` 调试用；`{}` 是"给人看的"，标准类型里也只有少数实现了——**为自己的公开类型实现 Display 是礼貌**。`{:#?}` 是多行版 Debug。

## 7.5 derive：编译器替你写 impl

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
struct Point { x: i32, y: i32 }
```

| derive | 得到什么 | 常见用途 |
|---|---|---|
| `Debug` | `{:?}` 打印 | 基本必加 |
| `Clone` | `.clone()` 深拷贝 | 需要复制时 |
| `Copy` | 赋值即复制（需 Clone + 无 Drop） | 小型值类型 |
| `PartialEq`/`Eq` | `==`/`!=` | 断言、查找 |
| `Hash` | 可作 HashMap 键 | 与 Eq 成对出现 |
| `Default` | `Default::default()` | 配置结构体惯例 |
| `PartialOrd`/`Ord` | `<`、排序 | BTreeMap 键 |

省略 derive 的理由同样重要：`Eq` 悖论类型（浮点只 PartialEq）；不希望被随意 clone 的大资源。**derive 是白送的正确实现，手写这些 trait 才是新闻**（12 章手写体验一遍）。

## 7.6 结构体更新语法与部分移动

```rust
let base = Rect::new(1.0, 9.9);
let w = Rect { width: 5.0, ..base };
```

`..base` 把 height 从 base **move** 过来：f64 是 Copy 所以无感；若字段是 String，base 进入"部分移动"状态——base.height 不可用，base.width（Copy 部分）还能用。编译器逐字段分析。

## 7.7 与 C++ class 的对照

| C++ | Rust |
|---|---|
| 构造函数 | 关联函数 `new`（惯例，非语言机制） |
| 析构函数 | `Drop` trait（04 章） |
| 拷贝构造/赋值 | `Clone`（显式调用）/ `Copy`（隐式） |
| this 指针 | `&self` / `&mut self` / `self` |
| 访问控制 public/private | 字段默认私有，`pub` 按需开放（17 章模块） |
| 继承 | 没有类继承——组合 + trait（12 章） |
| 运算符重载 | trait 实现（12 章），不能发明新运算符 |
| 友元 | 不存在；测试走 `#[cfg(test)]` 同模块可见性（21 章） |

## 7.8 坑位清单

1. **整可变**：想只改一个字段，也得让绑定 mut；真要字段级可变用 `Cell<T>`（18 章）。
2. **`..base` 之后 base 可能残废**：含非 Copy 字段时是部分移动，编译器逐字段判定，报错行指向具体字段。
3. **derive(Copy) 失败**：字段含 String/Vec 就不行（它们有堆资源）；Drop 与 Copy 互斥。
4. **未加 `#[derive(Debug)]` 却想 `{:?}`**：报错会建议你加——这是最友好的编译错之一。
5. **`new` 不是关键字**：惯例而已；`Default::default()` + 结构体更新语法是另一种起手式。
6. **空结构体的分号**：`struct Marker;`（单元）vs `struct Marker {}`——都合法，前者常见。
7. **方法定义在 impl 块，impl 块可以有多个**：按主题拆分（构造/计算/序列化）是常见组织法，示例 07 就是两个 impl 块。

---

上一章：[06 切片与字符串](06-strings.md) · 下一章：[08 枚举与模式匹配](08-enums.md)
