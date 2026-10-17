# 20 · 解析器族谱：spirit / xpressive / parser

> 对应示例：`examples/20_parsers/`（3 个例程）

Boost 的解析家族三代同堂：**Xpressive**（2003，正则的表达式化）、**Spirit**（2001，EBNF 的表达式化——Boost 最重的 TMP 库）、**Parser**（2024，Spirit 的 C++20 推倒重制）。它们共同的野心：**把"语法"从字符串里解放出来，变成 C++ 表达式**——编译期可检查、优化器可见、不依赖运行时。

## 20.1 Boost.Spirit.Qi：语法即代码

EBNF `entry := word '=' int ';'` 直接翻译成 C++：

```cpp
qi::rule<std::string::iterator, KeyVal()> entry;
entry = +ascii::alnum >> '=' >> qi::int_ >> ';';
qi::phrase_parse(input.begin(), input.end(), +entry, ascii::space, kv);
// 语义动作：qi::double_[[](double d){ ... }]
```

运行输出（`spirit.cpp`）：

```text
int 解析: 1 值 = 42
列表解析: 1 个数 = 5
键值解析: 1 条数 = 3
  id=7
  age=36
  level=99
语义动作: 3.5×2 = 7
自检通过
```

**它是工业级解析器**：完整的 C++ JSON 解析器用 Spirit 大约 200 行，速度与手写递归下降同量级。代价是编译时间（重头文件）与学习曲线（属性推导的心智模型）。Karma（生成）与 Lex（词法）是它的两个兄弟。

本章实测的**五个坑**（对写 Spirit 的人都是真金白银）：

1. `qi::parse` **不跳空白**——含空格的输入要用 `qi::phrase_parse` + skipper；
2. 有 skipper 时**语法里不要再写空白分隔符**（skipper 先吃掉，`entry % ' '` 静默失败）；
3. 复合属性用**自定义结构体 + `BOOST_FUSION_ADAPT_STRUCT`**——`std::pair` 属性在本机 c++latest 下会被容器判定误伤；
4. rule 用**先声明后赋值**（`qi::rule<...> r; r = expr;`），声明处拷贝初始化会撞重载歧义；
5. 语法要求收尾的（如 `';'`）**输入数据必须真的收尾**——半匹配时属性可能保留部分条目而返回值骗人（实测保留 2 条返回 true 的灵异现场，根因是数据缺尾分号）。

## 20.2 Boost.Xpressive：静态正则

把正则写成 C++ 表达式——**编译期语法检查**是它对 `std::regex` 的降维打击：

```cpp
xp::sregex date = xp::as_xpr("2026") >> '-' >> +xp::_d >> '-' >> +xp::_d;
xp::sregex level = (xp::s1 = xp::as_xpr("ERROR") | "WARN" | "INFO");   // 捕获组
xp::sregex dyn = xp::sregex::compile("retry (\\d+)");                  // 动态版也可
```

运行输出（`xpressive.cpp`）：

```text
日期命中 = 2026-09-19
级别 = ERROR
重试次数 = 3
动态正则 = 3
静态正则编译期检查 = Xpressive 独有卖点
regex_match 整串校验: 1
regex_replace: readme.txt → readyou.txt（$1 = 第一捕获组）
多组反引用: t#t → tNt
regex_iterator 命中 3 次
token(-1 分隔) :[*Link*][+Mario+][Zelda!!!][Metroid]
token(0 匹配) :[Link][Mario][Zelda][Metroid]
compiler 复用: 命中 1 池内同一对象? 1
坏正则抛 regex_error
格式化器: MARIO WORLD
自检通过
```

动态正则的全套件（与 std::regex 同名同语义，例程 6-10 段逐件验证）：

- **`regex_match`** 全串匹配（身份证形校验：一个表达式断言"整串是 18 位身份证形状"，配 `icase` 忽略校验位大小写）；**`regex_search`** 找子串；**`regex_replace`** 替换——格式串里 `$1..$N` 引用捕获组、`$&` 引用全匹配；
- **`regex_iterator`** 遍历所有匹配（流式，不落容器）；**`regex_token_iterator`** 分词双模式：默认给匹配段（抓单词），传 `-1` 给"分隔符之外"的段（按分隔符切）；
- **`regex_compiler`** 正则对象池：`rc["name"]` 按名缓存编译结果（享元）——同一个正则在递归/重入里只编译一次；
- 坏正则抛 **`regex_error`**（boost::exception 子类，可以再塞行李）；替换串可以是**格式化器**（任意可调用物，拿 `match_results` 现算——例程里把每个命中的单词转大写）。

**选型**：正则固定不变（热路径）→ Xpressive 静态正则（编译期确定 + 通常更快）；正则来自配置/用户 → 动态正则或 `std::regex`/Boost.Regex。语义动作、正则嵌套（sregex 里套 sregex）是它的独门。

> 实测坑（MSVC C4702）：xpressive 的 `match_results.hpp` 会在模板实例化点触发"不可达代码"告警——`/external:W0` 压不住实例化诊断（归属本翻译单元），与仓库里 yap/binomial_heap 先例同款，在 include 点定点 `#pragma warning(disable : 4702)`。

## 20.3 Boost.Parser（2024）：Spirit 的现代重制

Zach Laine（Spirit 维护者之一）用 C++20 重写的"Qi 的第二意见"：concepts 约束接口、错误信息人话化、动作直接绑 lambda：

```cpp
auto ints = bp::int_ % ',';
bp::parse("1, 2, 3", ints, bp::ws, v);
bp::int_[[](auto const& ctx) { sum += boost::parser::_attr(ctx); }] % ',';
auto strict = bp::int_ > ',' > bp::int_;      // > = expect：失败给精确位置诊断
```

运行输出（`parser.cpp`）：

```text
列表: 1 个数 = 3
元组: 1 = (3,4)
动作求和 = 60
严格模式接受 "5,6"? 1
自检通过
```

与 Spirit 的对照：属性组合更可预测（`int_ >> int_` 合成 `tuple<int,int>`）、`>` 运算符的**期望失败诊断**直接给行列位置（实测 `"5 6"` 会报 `1:2: error: Expected ',' here:` 到 stderr——本教程判定要求 stderr 恒空，故例程只走成功路径）、C++20 起步。**新项目解析首选**；要支持 C++11/14 旧标准才回 Spirit。

> 实测坑：lambda 挂动作时 `bp::int_[[&sum](...){...}]` 的 `[[` 会被 MSVC 当属性语法——外面包一层括号 `[(lambda)]` 消歧。

---


> 上一章：[19 · 字符串工具](19-text.md) ｜ 下一章：[21 · 容器（上）](21-container-core.md) ｜ 返回：[README](../README.md)
