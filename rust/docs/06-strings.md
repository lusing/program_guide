# 06 · 切片与字符串 ⭐

> 对应示例：`examples/06_strings/`
>
> Rust 的字符串让新手怀疑人生的两大原因：UTF-8 是认真的（没有"宽字符"后门），
> 以及 String/&str 二分。本章把两者一次讲透——从内存布局开始。

## 6.1 内存布局：String 是 Vec<u8> 的包装，&str 是胖指针

理解字符串的第一步是放下"字符串是一个东西"的直觉。Rust 把字符串拆成了**字节序列**（堆上的 `str` / `String` 内容）和**视图**（`&str` 胖指针）两层。

**`&str` 是胖指针（fat pointer）**：`str` 本身是动态大小类型（DST，03 章 3.6 节），编译器不知道一个 `str` 有多长，所以你不能直接拥有它。`&str` 在栈上占 16 字节（64 位机器），由两部分组成：

```rust
let s: &str = "Hello Rust";
let ptr = s.as_ptr(); // 指针：str 字节序列的起始地址（固定大小）
let len = s.len();    // 长度：字节数（固定大小整数）
println!("ptr = {:p}, len = {len}", ptr); // len = 10
```

指针 + 长度，两个固定大小的字段拼在一起，编译器就能为它分配栈空间了。这种"携带了 DST 元信息的指针"就是胖指针——`&[T]` 切片胖指针同理（指针 + 元素个数）。`&str` 里的字节序列本体可以住在任何地方：二进制只读段（字符串字面量）、栈上数组、堆上 `String` 的缓冲——`&str` 一概不管，它只看（起点，长度）。

**`String` 是 `Vec<u8>` 的包装**：标准库里 `String` 内部就是一个 `Vec<u8>`，外加"这些字节必须是合法 UTF-8"的不变式。所以 `String` 的内存布局与 `Vec<T>` 完全一致——栈上 24 字节的（指针，长度，容量）三元组 + 堆上缓冲：

```rust
let mut s = String::with_capacity(10); // 预分配 10 字节堆内存（与 Vec::with_capacity 同机制）
println!("len = {}, capacity = {}", s.len(), s.capacity()); // 0 / 10
s.push_str("hi");
println!("len = {}, capacity = {}", s.len(), s.capacity()); // 2 / 10
```

`with_capacity` 预分配是性能惯用法：避免 push 过程中反复 realloc + 拷贝。`String` 与 `Vec<u8>` 可以零拷贝互转（`s.into_bytes()` / `String::from_utf8(v)`），就是因为前者本来就是后者。

## 6.2 两种字符串：拥有的和借用的

| | `&str`（字符串切片） | `String`（拥有的字符串） |
|---|---|---|
| 是什么 | 胖指针（字节起点+长度），**视图** | (指针, 长度, 容量) + 堆缓冲，**owner** |
| 可增长 | ✘ | ✔（push/push_str/insert…） |
| 字面量 | `"字面量"` 就是 `&'static str` | `"x".to_string()` / `String::from("x")` |
| 存在处 | 栈上 16 字节 | 栈上 24 字节 + 堆内容 |
| API 参数 | **默认选择**（只读） | 只在需要拥有/修改时 |

```rust
let lit: &str = "字面量";               // 指向二进制里的 UTF-8 字节
let owned: String = String::from("堆上");
let view: &str = &owned;                // String → &str：免费（deref 强转）
let back: String = lit.to_string();     // &str → String：分配+拷贝
```

方向不对等是关键洞察：**String 随时能交出 &str（视图），反向需要分配**。所以函数参数收 `&str`，两种调用方都满意：

```rust
fn greet(name: &str) -> String { format!("你好，{name}！") }
greet(&owned);   // &String 自动强转
greet(lit);      // 直接传
```

### 为什么 `&String` 能传给 `&str` 参数：Deref 强转

`greet(&owned)` 能编译过，靠的是 `String` 实现了 `Deref<Target = str>`：

```rust
impl ops::Deref for String {
    type Target = str;
    fn deref(&self) -> &str {
        unsafe { str::from_utf8_unchecked(&self.vec) } // 内部就是 Vec<u8>
    }
}
```

`&String` 出现在需要 `&str` 的位置时，编译器自动插入 `deref` 调用完成隐式转换。标准库里 `Vec<T>`、`Box<T>`、`Rc<T>`、`Arc<T>` 都实现了 `Deref`——这是 Rust 智能指针体系的基石（18 章细讲）。

## 6.3 String 的修改全家

```rust
let mut s = String::from("Rust");
s.push('!');                     // 单字符
s.push_str(" 语言");             // 追加 &str（不夺所有权，比 + 高效）
let louder = s.replace('!', "!!"); // 返回新串（原串不动）
s.insert(0, '【');               // 下标处插入（O(n)，字节边界必须合法）
s.pop();
```

拼接的两个姿势：

```rust
let c = a + &b;            // + 左操作数被 move（签名 fn add(self, s: &str)）！
let d = format!("{a}-{b}");// format! 全员只借用——谁也不动，最省心
```

`+` 为什么吃掉左边？看标准库的实现就明白了：

```rust
impl Add<&str> for String {
    type Output = String;
    fn add(mut self, other: &str) -> String {
        self.push_str(other); // 复用左操作数的缓冲，避免新分配
        self
    }
}
```

`add` 的第一个参数是 `self`（按值接收），所以左操作数被 move 进函数、原地扩展后作为返回值出来。这是刻意的性能设计：拼接 `n` 个字符串用 `+` 链是 O(总长度)，每步都不浪费已有分配。注意泛型参数是 `&str` 而不是 `Self`——所以右操作数必须是 `&str`（`&String` 靠 Deref 强转过关）。

## 6.4 UTF-8：字节、字符、字素三件事

```rust
let zh = "你好";
zh.len()               // 6 —— 字节数！UTF-8 每个汉字 3 字节
zh.chars().count()     // 2 —— Unicode 标量值（char）个数
zh.bytes()             // e4 bd a0 e5 a5 bd —— 原始字节
zh.char_indices()      // (0,'你') (3,'好') —— 字节偏移 + 字符
```

**`s[0]` 不存在，是刻意设计**：UTF-8 变长编码下，"第 0 个字节"多半是半个字符。安全取法：

```rust
zh.get(0..3)     // Some("你")  —— 恰好完整边界
zh.get(0..1)     // None       —— 边界劈开字符，返回 None 而不是 panic
&zh[0..1]        // ← 能编译，运行时 panic（边界不合法）——别用
zh.chars().nth(1)// Some('好') —— "第 n 个字符"的正确写法
```

三个层次的官方立场：**字节**（`bytes()`）、**标量值/char**（`chars()`）是一等公民；**字素簇**（用户感知的"一个字"，如 emoji 组合、重音符号）标准库不管——需要时用 `unicode-segmentation` crate。这与 C++ 的 char/wchar 混杂、Go 的 rune 形成对照：Rust 把最复杂的部分交给生态，把坑明示出来。

`char` 是 4 字节 Unicode 标量值（不是 1 字节！），支持转义和码位构造：

```rust
let star = '\x2A';        // ASCII 转义：'\xHH'，仅限 ASCII 范围
let odbl = '\u{151}';     // Unicode 转义：'\u{HHHH}'，任意标量值
assert_eq!(star, '*');
assert_eq!(odbl, 'ő');
```

## 6.5 遍历与查找

```rust
for ch in "你好a".chars() {}          // 按字符
for b in "你好".bytes() {}            // 按字节 u8
for (i, ch) in s.char_indices() {}    // 偏移+字符

s.find(' ')               // Option<usize>：字节偏移
s.split_whitespace()      // 按空白切（15 章迭代器管道常客）
s.split(',')              // 按分隔符
s.lines()                 // 按行（处理 \n 与 \r\n）
s.starts_with("go") / s.ends_with("!")
s.trim() / s.to_lowercase() / s.to_uppercase()   // 都返回新值
```

`to_lowercase` 处理土耳其 İ 之类大小写变换会**变长**——这就是为什么它返回 String 而不是原地改。

## 6.6 与其它类型互转

```rust
let n: i32 = "42".parse().unwrap();        // &str → 数字（返回 Result，10 章）
let s: String = n.to_string();             // Display 类型 → String
format!("{n:.2}")                          // 任意格式化 → String
let bytes = s.into_bytes();                // String → Vec<u8>（免费 move）
String::from_utf8(bytes)                   // Vec<u8> → Result<String>（校验！）
String::from_utf8_lossy(&bytes)            // 非法字节替换为 U+FFFD
```

**字符串与字节串是两个世界**：`b"..."` 字节串字面量只允许 ASCII（`&[u8; N]`），写中文直接编译错——教学示例实测过；写非 ASCII 用 `"中文".as_bytes()`。

## 6.7 设计速记

- 参数要文本？→ `&str`。
- 要存进结构体、要改、要跨函数长期持有？→ `String`。
- 一段大文本里反复取子串？→ 存 `String`，传 `&str` 视图（零拷贝）。
- 字节协议/文件 IO 原始数据？→ `Vec<u8>` / `&[u8]`，需要人读时再 `from_utf8` 校验。

## 6.8 坑位清单

1. **`len()` 是字节数**：判断"空串"没问题，判断"没有字符"也行（空即空），但"长度 5"的语义要分清是字节还是 char。
2. **`&s[0..1]` 是运行期 panic**，不是编译错——`get` 才安全。切"半个 emoji"（4 字节）同理。
3. **`+` 拼接吃掉左操作数**：`a + &b` 之后 a 不可用；循环里累加用 `s.push_str()` 或 `format!`。
4. **`b"中文"` 编译错**（non-ASCII in byte string literal）：用 `"中文".as_bytes()`。
5. **`chars().nth(n)` 是 O(n)**：随机访问字符没有 O(1) 方案（UTF-8 本性），热点路径改成顺序迭代。
6. **HashMap 键是 String 后别再改**：键 move 进表就别惦记；要改先 remove 再插。
7. **clippy 的 `useless_vec` 会追到字符串**：定长数据（`[T; N]`）别用 `vec![]` 起手。
8. **Windows 控制台输出中文**：代码正确也可能显示方块——`chcp 65001` 之后再判断代码对错（本教程脚本已代设）。macOS / Linux 终端默认 UTF-8，不会遇到这个；若真出现方块，先查 `locale` 是不是 `*.UTF-8`。

---

上一章：[05 借用与引用](05-borrowing.md) · 下一章：[07 结构体](07-structs.md)
