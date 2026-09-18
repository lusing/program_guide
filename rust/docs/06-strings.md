# 06 · 切片与字符串 ⭐

> 对应示例：`examples/06_strings/`
>
> Rust 的字符串让新手怀疑人生的两大原因：UTF-8 是认真的（没有"宽字符"后门），
> 以及 String/&str 二分。本章把两者一次讲透。

## 6.1 两种字符串：拥有的和借用的

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

## 6.2 String 的修改全家

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

## 6.3 UTF-8：字节、字符、字素三件事

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

## 6.4 遍历与查找

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

## 6.5 与其它类型互转

```rust
let n: i32 = "42".parse().unwrap();        // &str → 数字（返回 Result，10 章）
let s: String = n.to_string();             // Display 类型 → String
format!("{n:.2}")                          // 任意格式化 → String
let bytes = s.into_bytes();                // String → Vec<u8>（免费 move）
String::from_utf8(bytes)                   // Vec<u8> → Result<String>（校验！）
String::from_utf8_lossy(&bytes)            // 非法字节替换为 U+FFFD
```

**字符串与字节串是两个世界**：`b"..."` 字节串字面量只允许 ASCII（`&[u8; N]`），写中文直接编译错——教学示例实测过；写非 ASCII 用 `"中文".as_bytes()`。

## 6.6 设计速记

- 参数要文本？→ `&str`。
- 要存进结构体、要改、要跨函数长期持有？→ `String`。
- 一段大文本里反复取子串？→ 存 `String`，传 `&str` 视图（零拷贝）。
- 字节协议/文件 IO 原始数据？→ `Vec<u8>` / `&[u8]`，需要人读时再 `from_utf8` 校验。

## 6.7 坑位清单

1. **`len()` 是字节数**：判断"空串"没问题，判断"没有字符"也行（空即空），但"长度 5"的语义要分清是字节还是 char。
2. **`&s[0..1]` 是运行期 panic**，不是编译错——`get` 才安全。切"半个 emoji"（4 字节）同理。
3. **`+` 拼接吃掉左操作数**：`a + &b` 之后 a 不可用；循环里累加用 `s.push_str()` 或 `format!`。
4. **`b"中文"` 编译错**（non-ASCII in byte string literal）：用 `"中文".as_bytes()`。
5. **`chars().nth(n)` 是 O(n)**：随机访问字符没有 O(1) 方案（UTF-8 本性），热点路径改成顺序迭代。
6. **HashMap 键是 String 后别再改**：键 move 进表就别惦记；要改先 remove 再插。
7. **clippy 的 `useless_vec` 会追到字符串**：定长数据（`[T; N]`）别用 `vec![]` 起手。
8. **Windows 控制台输出中文**：代码正确也可能显示方块——`chcp 65001` 之后再判断代码对错（本教程脚本已代设）。

---

上一章：[05 借用与引用](05-borrowing.md) · 下一章：[07 结构体](07-structs.md)
