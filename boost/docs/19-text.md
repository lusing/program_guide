# 19 · 字符串工具：algorithm / tokenizer / lexical_cast / convert / locale

> 对应示例：`examples/19_text/`（5 个例程）

C++ 标准库对字符串的处理长期停留在"能查能截"的水平——修剪、分词、大小写不敏感比较、Unicode 归一化这些**每天都要用的活**一直没有。Boost 的字符串家族把这层补齐了三十年，std 至今只零星收编（`starts_with` C++20、`contains` C++23）。

## 19.1 Boost.Algorithm（字符串算法部，2012）：手术刀全家福

```cpp
boost::to_upper_copy(line);                              // 大小写族
boost::trim_copy(line);                                  // 修剪族
boost::split(parts, line, boost::is_any_of(" ,"));       // 切分
boost::join(parts, "_");                                 // 连接
boost::replace_all(s, "boost::", "std::");               // 替换族
boost::erase_all(s, "std::");
boost::iends_with("Photo.JPG", ".jpg");                  // 大小写不敏感判定
```

运行输出（`algorithm.cpp`）：

```text
大写 = [  THE QUICK, BROWN FOX  ]
修剪 = [The Quick, Brown Fox]
分词数 = 5 连接 = The_Quick__Brown_Fox
替换 = std::algorithm std::string boost
擦除 = algorithm string boost
JPEG? 1
自检通过
```

命名规律：`*_copy` 返回新串，不带 `_copy` 的原地改。std 只收编了 `starts_with/ends_with/contains`（C++20/23）——**split/join/trim/replace_all/i 系列仍是 Boost 独有**。⭐ 每个项目都该有的头文件。

## 19.2 Boost.Tokenizer（2001）：流式分词

与 `split` 的分界：tokenizer 是**迭代器**——逐段产出不建容器，大文件/高频路径的省内存选择：

```cpp
boost::char_separator<char> sep(",;");              // 自定义分隔策略
boost::tokenizer<boost::char_separator<char>> toks(s, sep);

boost::tokenizer<boost::escaped_list_separator<char>> csv(s);   // CSV 语义
boost::offset_separator offs(b, e);                 // 定长切片
```

运行输出（`tokenizer.cpp`）：

```text
分词: [ada] [lovelace] [36] ["计算] [数学"]
CSV: [ada] [lovelace;36] [计算,数学]
定长: [ada] [036] [gra] [ce0] [85]（尾段不足 3 也保留——partial 默认开）
自检通过
```

`escaped_list_separator` 的 CSV 语义实测：引号内的逗号不算分隔符（`计算,数学` 整段保留）。**std 无对应**。⭐

## 19.3 Boost.LexicalCast（2000）与 19.4 Boost.Convert（2014）

```cpp
boost::lexical_cast<int>("42");                       // 失败抛 bad_lexical_cast
boost::lexical_cast<std::string>(3.14);               // any-to-string

boost::convert<int>("not-a-number", cnv).value_or(-1);// 失败不抛，回落
cnv(std::hex); boost::convert<int>("ff", cnv);        // 流操纵符直通
```

运行输出（`lexical_cast.cpp`）：

```text
数值→串 = 3.1415899999999999
串→int = 42
坏转换被抓住: bad_lexical_cast
串→double = 2.71
std 版 = 42（非泛型，仅内置类型）
自检通过
```

运行输出（`convert.cpp`）：

```text
合法 = 2026 非法回落 = -1
hex ff = 255
精度 3 的 pi = 3.14159
255 → 串 = 255
自检通过
```

**毕业档案**：数字场景被瓜分——`stoi/to_string`（C++11）覆盖内置类型，`std::to_chars/from_chars`（C++17）覆盖高性能路径。lexical_cast 的独门是**泛型**：模板参数 T/U 只要能流进出就行，`lexical_cast<std::string>(任意可打印类型)` 仍是最短答案。Convert 是它的可配置版（失败不抛 + 操纵符 + 自定义后端），适合"要 locale/进制/精度控制又不想要异常"的配置解析场景。

## 19.5 Boost.Locale（2010）：Unicode 的地面部队

`std::locale` 只管格式化刻面（数字/日期怎么排）；**大小写转换、归一化、字符集转换、断行**这些真活是 Boost.Locale 的独占领地：

```cpp
std::locale loc = boost::locale::generator().generate("");
boost::locale::to_upper("grüße", loc);               // → GRÜSSE（非 ASCII 也对）
boost::locale::normalize("é", norm_nfd, loc);        // Unicode 归一化
boost::locale::translate("File not found").str();    // gettext 翻译骨架
```

运行输出（`locale.cpp`）：

```text
大写 = GRÜSSE
小写 = grüsse
NFC/NFD 字节数 = 2/3（分解形 e+́ 占更多字节）
归一化后相等? true
翻译键 = File not found（无字典时原样返回）
自检通过
```

> 实测坑（**构建期**，不是平台差异）：Boost.Locale **必须带 ICU 编出来**，否则这一章的语义是残的。本机第一次构建没带 ICU（`otool -L` 里只有 `libiconv`），于是打出来的是
> `大写 = GRÜßE`（`ß` 没变成 `SS`）、`NFC/NFD 字节数 = 2/2`（`normalize(NFD)` **原样返回**，根本没分解）——
> 这不是"macOS 就这样"，是 Boost.Locale 退到了无 ICU 的后端。带 ICU 重建后输出与 Windows 侧一致。
> 判断自己有没有踩到：跑一遍上面的例程，`NFC/NFD` 是 `2/3` 就对了，`2/2` 就是没带 ICU。
>
> 带 ICU 的重建要点（本机）：b2 的 ICU 探测结果**被缓存在 `bin.v2/project-cache.jam`**，改了 `-sICU_PATH` 也不会重探，要先把 `has_icu`/`icu-` 那几行从缓存里删掉；另外 ICU 的 `-L` 会把 `-liconv` 引到 MacPorts 的 GNU libiconv（只导出 `_libiconv`），链接报 `Undefined symbols: _iconv`——解法见 README 的构建段。

**归一化是重点**：视觉相同的字符串可能是不同码点序列（`é` 可以是一个码点或 `e`+重音符两个码点）——**用户输入做键（去重/查找）之前必须归一化**，否则"看起来一样却匹配不上"。四种形式里 NFC（组合）适合存储，NFD（分解）适合比较。⭐ 国际化代码的必需品，std 无对应。

---


> 上一章：[18 · C++26 展望](18-cpp26.md) ｜ 下一章：[20 · 解析器族谱](20-parsers.md) ｜ 返回：[README](../README.md)
