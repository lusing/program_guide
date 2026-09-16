# 06 · 复合类型：struct、枚举与字符串

> 对应示例：`examples/06_compound/`

## 6.1 struct 与指定初始化器

```cpp
struct Book {
    std::string title;
    double price;
    int pages;
};
// ……
Book b{
    .title = "现代 C++ 实战",
    .price = 89.5,
    .pages = 420,
};
```

struct 把相关数据打包成一个值类型。**指定初始化器**（C++20）让构造自带文档：`.title =` 一眼知道谁是谁，跳过的成员取默认值。两条铁律：**字段顺序必须按声明顺序**（`.pages` 写在 `.price` 前面直接编译错——防"对着成员表打乱序"的隐患），以及它只对"聚合"（无构造函数的简单 struct）生效。

成员访问 `.`（对象）/`->`（指针）——智能指针也用 `->`（第 09 章）。struct 与 class 在 C++ 里几乎是一回事（默认访问权限不同），本章用 struct 表达"纯数据包"，第 08 章用 class 表达"有行为的类型"。

## 6.2 结构化绑定：一把拆出成员

```cpp
auto [title, price, pages] = b;
std::println("{} / {:.1f} 元 / {} 页", title, price, pages);
// 现代 C++ 实战 / 89.5 元 / 420 页
```

**结构化绑定**（C++17）把 struct/pair/tuple 的成员一次拆成独立变量，省掉 `b.title`、`b.price` 的复读。拆的是**副本**（`auto`）；要引用原成员写 `auto& [t, p, n] = b;`。map 遍历的 `for (const auto& [key, value] : m)` 是它的最高频舞台（第 10 章）。

## 6.3 enum class：带作用域的枚举

```cpp
enum class Format { paperback, hardcover, ebook };
// ……
Format f = Format::hardcover;
std::println("格式编号 = {}", static_cast<int>(f));  // 1
```

**`enum class`（强类型枚举，C++11）是枚举的唯一正确写法**，对比老式 `enum` 的三宗罪：名字泄漏进外层作用域（`paperback` 裸奔）、隐式转 int（`if (f == 1)` 编译能过）、底层类型不可控。`enum class` 全部修掉：必须 `Format::` 限定、必须显式 `static_cast` 才能当整数用、可指定底层类型（`enum class Flag : unsigned char`）。

枚举 + switch 是天作之合：switch 一个 enum class 时，/W4 会对**没列全的枚举值报警**（C4062），漏分支当场现形。

## 6.4 std::string：可变字符串

```cpp
std::string s = "C++";
s += "20";
s.push_back('!');
std::println("{}（长度 {}）", s, s.size());      // C++20!（长度 6）
std::println("包含 '20'？{}", s.contains("20")); // true（C++23）
```

`std::string` 是日常字符串的唯一选择：可增长、按值拷贝、自己管内存。常用操作速查：

| 操作 | 效果 | 备注 |
|---|---|---|
| `s += t` / `s.push_back(c)` | 追加 | 复杂度摊还 O(1)~O(n) |
| `s.size()` / `s.length()` | 字节数 | **不是字符数**（UTF-8 中文一字 3 字节，见坑位） |
| `s.find("20")` | 位置或 `npos` | 判存在直接用 `contains`（C++23） |
| `s.substr(0, 4)` | 子串拷贝 | 产生新串；只读场景用 string_view |
| `s[i]` / `s.front()` / `s.back()` | 访问字符 | 越界是 UB（`at()` 会抛但慢） |
| `s.empty()` | 空判断 | 别写 `s.size() == 0` |

与 C 风格 `char*` 的关系：字符串字面量 `"hi"` 的类型是 `const char*`（C 数组），`std::string` 能从它构造；反向用 `s.c_str()`。新代码**收发一律 std::string / string_view**，`char*` 只在 C 接口边界出现。

## 6.5 string_view：不拥有的只读视图

```cpp
std::string_view sv = s;                  // 零拷贝别名
std::println("sv 前 4 个字符：{}", sv.substr(0, 4));  // C++2——零拷贝切片
```

`std::string_view`（C++17）= "指针 + 长度"的只读窗口：**不分配、不拷贝**，substr 只是把窗口挪一挪。函数参数接收只读字符串的首选（字面量、string、别的 view 都能无转换绑定）。代价是它**不拥有数据**——头号坑：

```cpp
std::string_view bad = std::string("临时");  // 临时 string 当场死亡
// bad 从此指向已释放内存——未定义行为（/W4 会警告 C4365 族）
```

规则：**view 的寿命不能超过它看的数据**。函数内局部用很安全；存成员变量、跨线程传、返回 view 都要三思（返回 `sv.substr(...)` 而底层数据是函数参数字符串，同样悬垂）。

## 6.6 span：数组/vector 通吃的视图

```cpp
int sum_of(std::span<const int> values) { /* 求和 */ }
// ……
std::array<int, 5> arr{1, 2, 3, 4, 5};
std::vector<int> vec{10, 20, 30};
std::println("sum(arr) = {}，sum(vec) = {}", sum_of(arr), sum_of(vec));  // 15 60

std::span<int> middle = std::span{arr}.subspan(1, 3);  // 第 2–4 个
middle[0] = 99;  // 非 const span 可写穿
std::println("改写后 arr[1] = {}", arr[1]);  // 99
```

`std::span`（C++20）是 string_view 的"任意元素序列"版：**C 数组、std::array、vector、别的 span** 统统无拷贝适配。函数签名 `std::span<const T>` 比 `const std::vector<T>&` 高一档：调用方数据在哪种容器里都不用转换，还天然支持"只看一段"（`subspan(offset, count)` / `first(n)` / `last(n)`）。

`const` 语义与指针一致：`span<const int>` 只读，`span<int>` 可写穿（`middle[0] = 99` 直接改了底层 arr）。它同样**不拥有数据**——悬垂规则与 string_view 一模一样。

## 6.7 C 数组 vs std::array

```cpp
int weekly[12]{};              // C 数组：长度编译期定，传参即退化成指针
std::array<int, 5> arr{1,2,3,4,5};  // C++ 包装：知道自己的 size()，可拷贝赋值
```

C 数组是历史地层（第 03 章已见过它需要编译期长度）；**新代码用 `std::array<T, N>`**——同样栈上定长、零开销，但带 `size()`、能整体拷贝、能传给 span 而不退化。什么时候还得见 C 数组：接口是 C 的、或字面量表 `const char* names[]` 这类初始化列表场景。

## 6.8 坑位清单

1. **string_view/span 悬垂**：指向临时 string、返回底层是参数的 view、存进成员的 view——全部 UB。口诀"视图不养数据"。
2. **指定初始化器乱序**：`.pages` 写在 `.price` 前编译错，这是特性不是 bug。
3. **`s.size()` 当字符数**：UTF-8 下中文一字占 3 字节，`"你好".size() == 6`。按"字符"处理文本要按字节解码，第 22 章编码节展开。
4. **enum class 直接 print**：`std::println("{}", f)` 编译错——没有对应 formatter；要么 `static_cast<int>`，要么给它写格式化器（进阶，第 22 章）。
5. **string 频繁拼接 O(n²)**：循环里 `s += x` 各次追加本身没问题，但**跨函数反复传值拷贝**才是浪费大户——传 `const string&` / `string_view`。
6. **span 空参数**：`subspan` 的 offset/count 越界是 UB（不是异常），切片前自己核对边界。
