# 07 · 字符串深入：std::string 全景

> 对应示例：`examples/07_strings/`

## 7.1 构造与初始化：`()` 与 `{}` 不是一回事

```cpp
std::string literal{"Many a mickle makes a muckle"};
std::string repeated(6, 'z');        // ()：重复 6 次 'z' → "zzzzzz"
std::string head{literal, 0, 4};     // 子串构造：起点 0、长度 4 → "Many"
std::string tail{literal, 20};       // 只给起点：取到末尾 → "muckle"
```

string 的构造重载多得惊人，常用四式如上。头号坑是**圆括号与花括号语义相反**：

```cpp
std::string sleeping(6, 'z');   // "zzzzzz" —— 6 是重复次数
std::string bad{6, 'z'};        // 编译能过！把 6 当字符码 → 乱码两个字符
```

`{}` 走初始化列表路线，两个实参被当成"两个字符"。规则：**重复字符用 `()`，其他初始化一律 `{}`**（vector 的 `v(5, 1)` vs `v{5, 1}` 同病，第 14 章再遇）。

## 7.2 拼接：`+` 的两侧至少要有一个 string

```cpp
std::string full = first + " " + "McCavity";   // ✔ 相邻字面量先粘成一个，再遇 string
// std::string bad = "Phil" + " " + first;     // ✘ 编译错：字面量 + 字面量不行
char comma{','}, space{' '};
int code = comma + space;                       // 44 + 32 = 76，恰好是 'L' 的字符码
```

`+` 的重载要求**至少一侧是 std::string**（字面量只是 `const char[]`，没有运算符）。更隐蔽的是**字符 + 字符**：它不是拼接而是**字符码算术**——`',' + ' '` 得到 76，拼进字符串变成大写 L。这也是 `std::string{"a"} + std::string{"b"}` 与 `'a' + 'b'` 的本质区别。数拼字符串用 `std::to_string(x)`（小数固定 6 位，不可定制）或 `std::format`/`std::print`（第 33 章全家桶）。

## 7.3 查找家族：返回下标或 npos 哨兵

```cpp
std::string sentence{"Manners maketh man"};
sentence.find("man");              // 15 —— 子串 "man" 的起点
sentence.find("an", 3);            // 16 —— 从下标 3 起再找
sentence.rfind("an");              // 16 —— 反向找最后一个
sentence.find_first_of(" ,.;:!?");  // 7 —— 第一个出现在“字符集合里”的位置
sentence.contains("an");           // true (C++23)
sentence.starts_with("Man");       // true (C++20)
sentence.ends_with('.');           // false (C++20)
```

`find`/`rfind`/`find_first_of`（集合中任一字符）/`find_first_not_of`（集合外第一个）都返回**下标**，找不到返回 `std::string::npos`（size_t 最大值——**当布尔用是真不是假**，判失败必须 `== npos`）。三个布尔新秀（`contains`/`starts_with`/`ends_with`）只问在不在、空串上永远安全，能用它们就别数下标。

> `npos` 当 true 的坑：`if (!s.find('x'))` 在 'x' 位于下标 0 时为真——查"没找到"永远写 `== std::string::npos`。

## 7.4 子串与修改：C++ 标记法 = 起点 + 长度

```cpp
std::string word{phrase.substr(4, 6)};    // 从下标 4 起取 6 个字符
std::string to_end{phrase.substr(4, 100)};// 长度越界不抛错：静默截到串尾
text.replace(2, 4, "dandelion");          // 替换下标 2 起的 4 个字符（新旧长度可不同）
text.erase(0, 2);                         // 删下标 0 起的 2 个字符
// text.erase(5);                         // 注意：这是“从 5 删到结尾”，不是删第 5 个！
```

C++ 系 API 的子串标记法是**起点 + 长度**（`substr`/`replace`/`erase`），长度可省略（= 到串尾）；唯一的例外 `string::copy()` 和"字面量 + 长度"的构造走 C 风格的**长度 + 起点**——记不清时想：**C 字符串不知道自己多长，所以长度排第一；C++ string 自知长短，长度可省略靠后**。`erase(i)` 单参 = 删到尾是高频误用；删单个字符写 `erase(i, 1)`。起点越界（如 `substr(100)`）会抛 `out_of_range`，长度越界不抛——不对称，记住。

## 7.5 比较：字典序

```cpp
std::string a{"age"}, b{"beauty"};
a < b                                  // true：逐字符按码点比
std::string{"apple"} < std::string{"applesauce"}   // true：前缀相同，短的小
const auto order{a <=> b};              // 三路比较：is_lt / is_eq / is_gt
```

string 的六个比较运算符 + `<=>` 全部可用，规则是**字典序**（逐字符按字符码，前缀相同短者小，**大小写敏感**——'Z' < 'a'）。`<=>` 的价值在"比较一次、三问全答"（第 11 章 Vec2 的三路比较回扣）。旧代码的 `s1.compare(s2)` 返回 int（负/零/正），**`if (s1.compare(s2))` 判的不是相等**——相等返回 0 即 false，判等用 `==`。

## 7.6 数值 ⇄ 字符串

```cpp
std::to_string(3.14159);       // "3.141590"：固定 6 位小数，不可定制
std::stoi("245");              // 245（家族还有 stol/stod/stoul…）
```

`to_string` 族的格式不可控（小数恒 6 位）——要格式就用 `std::format`/`print`。解析方向的 `stoi` 族失败会抛异常、跳过前导空白、容忍尾随垃圾（`stoi("12abc")` 得 12）；**无异常、无分配、无 locale 的最快解析是 `std::from_chars`**，第 10 章 expected 一节已实战过。钱和精度敏感的场景永远"字符串 → from_chars 校验 → 整数运算"。

## 7.7 string_view：零拷贝只读视图

```cpp
std::string_view sv{literal};          // 不拷贝字符，只是“指针 + 长度”
std::string_view slice{sv.substr(10, 6)};   // 切片同样零拷贝
std::string owned{slice};              // view → string 必须显式（一定伴随拷贝）
```

接收**只读字符串参数**的首选类型（第 09 章词汇类型正式收编）：字面量、string、别的 view 都能无转换绑定，切片只是挪窗口。三条边界记牢：

- **view → string 没有隐式转换**（转换必伴随拷贝，编译器把决定权留给你），拼接 `+` 也不行——先 `std::string{view}`；
- **悬垂规则与 span 一致**（第 08 章）：view 不养数据，别指向临时、别存成成员、别跨线程；
- view 自身**只读**——`sv[0] = 'X'` 编译不过（对比 span 可写穿，那是给数组准备的）。

## 7.8 原始字符串字面量：反斜杠不再转义

```cpp
auto path{R"(C:\ProgramData\guide\file.ext)"};   // 原样保留，无需 \\
auto regex_like{R"(\d{4}-\d{2})"};                // 正则模式串的标配写法
```

普通字面量里 `\\`、`\"`、`\n` 都是转义，Windows 路径和正则被写成"反斜杠面条"。`R"(...)"` 里**所见即所得**，直到配对的 `)"` 才结束（内容含 `)"` 时用 `R"xx(...)xx"` 自定义分隔）。第 33 章正则实战会回来谢它。

## 7.9 逐字符处理：`<cctype>` 的分类与大小写

```cpp
for (unsigned char ch : mixed) {      // <cctype> 函数要求 unsigned char
    if (std::isalpha(ch)) ++letters;
}
for (char& ch : mixed) {
    ch = static_cast<char>(std::toupper(ch));   // toupper 返回 int，收窄要显式
}
```

`isalpha`/`isdigit`/`isspace`/`ispunct` 分类，`tolower`/`toupper` 转大小写——C 时代传下来的一族（入参出参都是 int，所以喂 unsigned char、收回时 static_cast）。**只对 ASCII 安全**：`"你好"` 的 UTF-8 字节传进去分类结果没有意义，中文文本按字节流处理，编解码见第 33 章。

## 7.10 坑位清单

1. **`{6, 'z'}` 想重复字符**：走的是初始化列表，6 变字符码——重复用 `(6, 'z')`。
2. **`'a' + 'b'` 当拼接**：字符相加是码点算术，拼不进 string——两侧至少一侧是 string。
3. **`find` 结果当布尔**：npos 是超大数恒真——判失败写 `== std::string::npos`。
4. **`substr(pos, len)` 的 len 当终点下标**：它是长度！从 JS/Java 过来的第一反应多半是错的。
5. **`erase(i)` 以为删一个**：删到串尾；删单个 `erase(i, 1)`。
6. **string_view 悬垂 / 隐式转 string**：view 不养数据、不自动物化；两个方向都要显式。
7. **`size()` 当字符数**：UTF-8 下中文一字 3 字节（第 03 章老坑，字符串场景高频回归）。
8. **循环里 `s = s + piece` 反复传值**：拼接用 `+=`/`append`，参数用 view/const 引用。

---

上一章：[06 函数](06-functions.md) · 下一章：[08 复合类型](08-compound.md)
