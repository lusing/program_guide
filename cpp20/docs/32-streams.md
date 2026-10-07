# 32 · 流 I/O：iostream 的输入、状态与文件

> 对应示例：`examples/32_streams/`

## 32.1 流是什么：可以推拉的字符序列

C++20 有了 `std::print`/`std::format`（第 33 章）之后，**输出**这活儿早该换现代工具了；但**输入解析**（`>>`）、**文件读写**、**自定义类型的流行为**这三件事仍是 iostream 的领地。流的心智模型：一个**无限字符序列**，往里推字符叫写（`<<`），从里拉字符叫读（`>>`）。

四个预定义对象（`<iostream>`）：

| 对象 | 对应 C 的 | 指向 | 缓冲 |
|---|---|---|---|
| `std::cin` | stdin | 键盘 | 有 |
| `std::cout` | stdout | 屏幕 | 有 |
| `std::cerr` | stderr | 屏幕 | **无**（错误立刻可见） |
| `std::clog` | stderr | 屏幕 | 有 |

## 32.2 << 与 >>：链式的秘密

`std::cout << "a" << 42` 能链起来，是因为 `operator<<` 返回**流的引用**——左边永远接得上。`>>` 同理，且**预定义了所有内建类型和 string**：

```cpp
int a, b;
std::cin >> a >> b;          // 跳过空白分隔，读两个 int
```

`>>` 读字符串**按空白截断**（`"hello world"` 只拿到 `hello`），要整行用 getline（32.5）。

## 32.3 流状态：while(cin >> x) 的全部原理

每个流带四个状态位，这是一切输入循环的地基：

| 位 | 查询 | 置位的典型原因 |
|---|---|---|
| goodbit | `good()` | 无位设置——正常 |
| eofbit | `eof()` | 读到末尾 |
| failbit | `fail()` | 格式化读失败（该是数字来了字母）、打不开文件 |
| badbit | `bad()` | 流本身坏了（底层 I/O 错误） |

`while (std::cin >> x)` 之所以能当循环条件，是流对象提供了**到 bool 的转换**：fail/bad 位任一设置就转 false。输入循环结束的两种正常姿势：撞到 EOF（Ctrl+Z / 文件尾），或撞到类型不符。

**fail 之后流就"死"了**——后续所有 `>>` 静默失败。还有一条 C++11 规则容易吓到人：**失败的算术抽取会把目标变量写成 0**（不是留着旧值）——读到坏 token 后变量是 0，别拿它当"读到的值"。要继续读必须 `clear()` 复位（常配 `ignore()` 跳过坏 token 或坏行）：

```cpp
if (!(std::cin >> x)) {
    std::cin.clear();                                              // 复位状态位
    std::cin.ignore(std::numeric_limits<std::streamsize>::max(), '\n');   // 跳过这一行
}
```

## 32.4 操纵符：粘性与一次性

| 操纵符 | 作用 | 粘性 |
|---|---|---|
| `std::endl` | 换行 **并 flush** | 一次性 |
| `"\n"` | 只换行 | — |
| `std::hex / dec / oct` | 进制 | **粘** |
| `std::fixed / scientific` | 浮点样式 | 粘 |
| `std::setprecision(n)`（`<iomanip>`） | 精度 | 粘 |
| `std::setw(n)`（`<iomanip>`） | 字段宽 | **只管下一次输出** |
| `std::setfill(c)` | 填充字符 | 粘 |
| `std::left / right` | 对齐 | 粘 |
| `std::boolalpha` | bool 打成 true/false | 粘 |

两条纪律：**默认写 `"\n"`**——`endl` 每次都 flush 缓冲，循环里是性能自杀（需要"立刻可见"的日志例外）；**`setw` 不粘**，两个连续输出只有第一个吃到宽度。粘性操纵符影响后续所有输出，格式完记得换回来。

顺带一提：MSVC 的 `cout` 默认 6 位有效数字（`123.457`），与 format 的默认一致；要更多位用 `setprecision`。

## 32.5 getline 与 >> 混用：经典一坑

```cpp
std::string line;
std::getline(std::cin, line);        // 读整行（含空格），丢弃行尾 '\n'
std::getline(std::cin, line, ';');   // 自定义分隔符
```

`std::getline`（自由函数版，配 std::string 自动管理内存）读整行；流成员版 `cin.getline(buf, n)` 要自己给缓冲区，新代码不用。**坑在这**：`>>` 读数字**不吃行尾换行**——`cin >> n` 之后立刻 `getline`，拿到的是**空行**（残留的 `\n`）。修法就是 32.3 的 `ignore(..., '\n')` 先清场。第 35 章实战逐行读文件，全程只用 getline，从根上绕开此坑。

## 32.6 stringstream：字符串当流用（`<sstream>`）

```cpp
std::istringstream in{"42 3.14"};
int n; double d;
in >> n >> d;                              // 从字符串解析——类型安全且可判错

std::ostringstream out;
out << "值 = " << std::fixed << std::setprecision(1) << d;
std::string s = out.str();                 // 拼好的字符串
```

istringstream 是**解析**利器（比 `stoi` 强在：能连续读、能查 fail 位、不抛异常）；ostringstream 的拼接活儿现在多半让给 `std::format`——但"流式追加、最后统一取"的场景（循环里逐个喂）它仍顺手。示例里它还客串"键盘替身"，让 cin 的行为可以自动验证。

## 32.7 fstream：文件读写（`<fstream>`）

```cpp
std::ofstream out{"data.txt"};             // 构造即打开（默认 out|trunc：覆盖写）
if (!out) { /* 打不开必须查：默认不抛异常 */ }
out << "第一行\n" << 42 << '\n';
// 析构自动关文件——RAII（第 11 章）在文件上的样子

std::ifstream in{"data.txt"};
std::string line;
while (std::getline(in, line)) { /* 逐行处理 */ }
```

| 模式位 | 含义 |
|---|---|
| `in` | 读（ifstream 默认） |
| `out` | 写（ofstream 默认，配合 trunc 覆盖） |
| `app` | 追加写（`out|app`） |
| `trunc` | 先清空 |
| `ate` | 打开即定位到尾 |
| `binary` | **二进制模式**（Windows 必写，见坑位） |

常用件：`is_open()` 查开没开；`in.rdbuf()` 是整个文件缓冲——`out2 << in.rdbuf()` 一行拷贝整个文件；`seekg/tellg` 随机定位一瞥（越界不检查，UB）。**教程立场**：文件操作若只是"遍历目录、拷贝、查询大小"，用 `<filesystem>`（第 33 章）；**读内容、写内容**才是 fstream 的本职。

## 32.8 自定义类型接入流：operator<< / operator>>

让自己的类型像内建类型一样可流，规则四条：

```cpp
class Fraction {
public:
    friend std::istream& operator>>(std::istream& in, Fraction& f);     // ③ 输入收非常量引用
    friend std::ostream& operator<<(std::ostream& out, const Fraction& f);   // ④ 输出收常量引用
private:                                                                  // ① friend 才能摸私有成员
    int num{}, den{1};
};

std::ostream& operator<<(std::ostream& out, const Fraction& f) {         // ② 返回流的引用（链式）
    return out << f.num << '/' << f.den;
}
```

与第 12 章的 `std::formatter` 特化二选一：**新代码输出优先 formatter + print**（类型安全、性能、格式串统一），`operator>>` 解析输入则没有替代品——两套并存是常态。

## 32.9 选型总表

| 需求 | 工具 | 章 |
|---|---|---|
| 格式化**输出** | `std::print` / `format` | 33 |
| 解析**输入**（文本 → 值） | `>>` + 流状态 / istringstream | 本章 |
| 读写**文件** | fstream + getline | 本章 |
| 正则/复杂解析 | `<regex>` | 33 |
| 目录/路径操作 | `<filesystem>` | 33 |

## 32.10 坑位清单

1. **`endl` 滥用**：每行 flush 缓冲——大循环里 I/O 次数翻倍；默认 `"\n"`，"必须立刻可见"才 endl。
2. **`>>` 后直接 `getline` 拿空行**：残留 `'\n'` 被 getline 当整行吃掉——`ignore(numeric_limits<streamsize>::max(), '\n')` 清场。
3. **fail 后不复位**：`cin >> x` 失败后的每次读取都静默失败、变量不动——循环里查 bool 转换、坏输入 `clear()` + `ignore()`。
4. **不查 `is_open`/流状态就用**：文件打不开 failbit 已置，写入全进黑洞——`if (!f)` 先查。
5. **Windows 上写二进制不开 `binary`**：文本模式把 `\n` 翻译成 `\r\n`、`0x1A` 当 EOF——二进制数据损坏且悄悄的。
6. **流对象不可拷贝**：传参一律引用——拷贝在编译期就被删了（设计如此：状态唯一）。
7. **`setw` 以为它粘**：只影响下一次输出，表格对齐每列都要重设。
8. **格式操纵符忘了复原**：`hex`、`fixed`、`setprecision` 全是粘的——一处设置污染后续所有输出。

---

上一章：[31 时间](31-time.md) · 下一章：[33 文本与文件](33-textfiles.md)
