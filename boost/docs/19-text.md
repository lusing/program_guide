# 19 · 字符串工具：algorithm / tokenizer / lexical_cast / convert / locale

> 对应示例：`examples/19_text/`（5 个例程）

C++ 标准库对字符串的处理长期停留在"能查能截"的水平——修剪、分词、大小写不敏感比较、Unicode 归一化这些**每天都要用的活**一直没有。Boost 的字符串家族把这层补齐了三十年，std 至今只零星收编（`starts_with` C++20、`contains` C++23）。

## 19.1 Boost.Algorithm（字符串算法部，2012）：手术刀全家福

string_algo 建立在 boost.range 之上（算法吃"区间"而不是两个迭代器），处理对象不必是 string——任何元素的 range 都行。先背**命名律**，三百多个函数就都读得懂：

- `i` 前缀 = 大小写不敏感（`iequals`、`iends_with`…）；
- `_copy` 后缀 = 不动原串、返回处理结果的拷贝；不带 = 原地改；
- `_if` 后缀 = 接谓词（自己定"什么算空白/该删什么"）。

五大类算法：**大小写**（to_upper/to_lower ×2 版）、**判定**（lexicographical_compare/starts_with/ends_with/contains/equals/all）、**修剪**（trim/trim_left/trim_right ×i×copy×if）、**查找与替换**（find/replace/erase 的 first/last/nth/all/head/tail 组合阵）、**分割与合并**（find_all/split/join/join_if）。

```cpp
boost::trim_copy_if(noisy, boost::is_digit() || boost::is_punct() || boost::is_space());
boost::ifind_all(hits, csv, "zelda");              // 大小写不敏感找全部
boost::split(parts, csv, boost::is_any_of(", .:-+"), boost::token_compress_on);
boost::join_if(names, "**", [](const auto& s){ return boost::contains(s, "a"); });
```

**分类件 13 件**（`is_space/is_alnum/is_alpha/is_cntrl/is_digit/is_graph/is_lower/is_print/is_punct/is_upper/is_xdigit/is_any_of/is_from_range`）都是"函数对象工厂"——`is_digit()` 造出谓词，谓词之间还能 `|| && !` 组合成复合条件（上面第一行就是三合一修剪）。

**查找族返回 `iterator_range`**（一段子区间）而不是迭代器：能当容器用（`empty()`/`begin()`）、能直接流输出、能算位置（`r.begin() - text.begin()`）——找不到给空 range，不抛异常。

运行输出（`algorithm.cpp`）：

```text
大小写: [  THE QUICK, BROWN FOX  ] 原地版一致? 1 原串未动? 1
修剪: [The Quick, Brown Fox] 左 [The Quick, Brown Fox  ] 右 [  The Quick, Brown Fox]
修剪_if（去数字/标点/空白）: [Happy New Year]
判定: iends_with(.jpg)? 1 ends_with? false istarts_with(photo)? true icontains(HOTO)? true
iequals(Samus/samus)? true ilexicographical_compare(a/B)? true
all("power", is_lower)? true
分类: is_digit('7')=true is_any_of(abc)('b')=true is_from_range(0-9)('5')=true 组合(小写|数字)('x')=true
查找: [long] 位5 i 版 [Long] 位0 nth [ng] head [Long] tail [king.] 找不到为空? true
替换: first=[samus beat the monster.] all=[Samus bEat thE monstEr.] tail=[Samus beat theridley.]
擦除: all=[samus beat  monster.] head=[beat the monster.]
find_all 命中 2 次:[Zelda][zelda]
split(默认) 8 段[Samus][][Link][Zelda][][Mario][Luigi][zelda]（连续分隔符产出空段）
split(compress) 6 段[Samus][Link][Zelda][Mario][Luigi][zelda]
join = Samus+Link+Zelda+Mario join_if(含a) = Samus**Zelda**Mario
[Samus][samus][mario][][Link]（按 "||" 分割）
自检通过
```

输出里有三个值得点名的行为：`split` 默认把**连续分隔符**当多段（空段出现），`token_compress_on` 把它们压成一段；`split_iterator` 的独门能力是**任意长度字符串当分隔符**（`"||"`，split 算法只能按单字符切）；`join_if` 只有满足谓词的段才进结果。

std 只收编了 `starts_with/ends_with/contains`（C++20/23）——**split/join/trim/replace_all/i 系列/分类件仍是 Boost 独有**。⭐ 每个项目都该有的头文件。

## 19.2 Boost.Algorithm 一般算法部：minmax / clamp / hex（书 ch8）

string_algo 之外，Boost.Algorithm 还有三组数值向小件（`<boost/algorithm/minmax.hpp>` 等单独头）：

（对应示例：`minmax_clamp.cpp`）

运行输出（`minmax_clamp.cpp`）：

```text
minmax(3,7) = 3,7（返回 tuple：小在前大在后）
std::minmax = 3,7
minmax_element: min=2 max=10
first_min 位 = 2 last_min 位 = 3
first_min_last_max: 位 = 2/6（2 与最后一个 10）
clamp: (5∈[1,10])=5 (5<[1])=10 (5>[4])=4
clamp_range(3..9): 3,4,6,8,9,
hex("123") = 313233  hex_lower = 2b2d2a2f
unhex(414243) = ABC
坏输入抛 boost::exception? 1
自检通过
```

- **`boost::minmax(a,b)`** 一次比较拿两个（返回 tuple，`std::minmax` C++11 毕业且返回 pair、多 initializer_list 形态）；**`minmax_element`** 一趟扫描同时拿最小最大（std 同名毕业）；它的**全家族**处理并列第一的取法——`first_min_element`（第一个最小）/`last_min_element`（最后一个最小）/`first_min_last_max_element` 等四种组合，对"打分表要第一个还是最后一个并列者"这类语义敏感场景有用；
- **`clamp(v, lo, hi)`** 夹进闭区间（`std::clamp` C++17 毕业）；`clamp_range` 是整段夹的 transform 形态；
- **`hex`/`hex_lower`/`unhex`** 十六进制编解码（网络协议、二进制转储常用）；坏输入抛 `not_enough_input`/`non_hex_input`（都是 boost::exception 子类，可塞行李）。

## 19.3 Boost.Tokenizer（2001）：流式分词

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

## 19.4 Boost.LexicalCast（2000）与 19.4 Boost.Convert（2014）

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
try_convert("42")? 1 try_convert("0x100")? 0（0x 前缀不认）
num_valid<int>("65535")? 1 num_valid<double>("3.14")? 1 num_valid<int>("3.14")? 0
自定义类 → demo_class#7（合同就是给个 operator<<）
bool 只认 1/0: lexical_cast<bool>("1") = 1
自检通过
```

lexical_cast 的**合同三条**（内部走流）：源可流输出（`operator<<`）、目标可流输入（`operator>>`）、目标可默认构造+拷贝构造——自定义类给个 `operator<<` 就能转出字符串（上面第 8 行）。**边界两条**：待转字符串只能是纯数字表示（`"0x100"`/`"123L"` 都不认，C++ 字面量语法不等于流语法）；bool 只认 `"1"/"0"` 不认 `"true"/"false"`。**不想捕获异常**就用 `boost::conversion::try_lexical_convert(str, val)`（bool 返回值）——一行就能写出输入合法性校验（书里的 `num_valid`），验证用户输入时比 try/catch 干净得多。

运行输出（`convert.cpp`）：

```text
合法 = 2026 非法回落 = -1
hex ff = 255
精度 3 的 pi = 3.14159
255 → 串 = 255
自检通过
```

**毕业档案**：数字场景被瓜分——`stoi/to_string`（C++11）覆盖内置类型，`std::to_chars/from_chars`（C++17）覆盖高性能路径。lexical_cast 的独门是**泛型**：模板参数 T/U 只要能流进出就行，`lexical_cast<std::string>(任意可打印类型)` 仍是最短答案。Convert 是它的可配置版（失败不抛 + 操纵符 + 自定义后端），适合"要 locale/进制/精度控制又不想要异常"的配置解析场景。

## 19.6 Boost.Locale（2010）：Unicode 的地面部队

`std::locale` 只管格式化刻面（数字/日期怎么排）；**大小写转换、归一化、字符集转换、断行**这些真活是 Boost.Locale 的独占领地：

```cpp
std::locale loc = boost::locale::generator().generate("");
boost::locale::to_upper("grüße", loc);               // → GRÜSSE（非 ASCII 也对）
boost::locale::normalize("é", norm_nfd, loc);        // Unicode 归一化
boost::locale::translate("File not found").str();    // gettext 翻译骨架
```

运行输出（`locale.cpp`）：

```text
大写 = GRÜßE
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
