# 22 · 文本与文件：格式化、正则与文件系统

> 对应示例：`examples/22_textfiles/`

## 22.1 std::format 深入

第 02 章的格式化速查在此扩成完整版（对齐/填充/精度/类型四族）：

```cpp
std::println("{:>10}|", "右对齐");        //        右对齐|
std::println("{:<10}|", "左对齐");        // 左对齐      |
std::println("{:^10}|", "居中");          //    居中    |
std::println("保留两位：{:.2f}，百分比：{:.1f}%", 3.14159, 0.856 * 100);
std::println("十六进制 {:#x}，二进制 {:#b}", 255, 5);  // 0xff 0b101
std::println("填充星号：{:*^14}", "标题");  // *****标题*****
```

说明书的语法骨架 `[[填充]对齐][宽度][.精度][类型]`：填充字符在最前、对齐 `<` `>` `^`、宽度、点精度、类型字符（`f` 定点 / `e` 科学 / `d` 十进制 / `x` 十六进制 / `b` 二进制 / `s` 字符串）。`#` 前缀给进制加 `0x`/`0b` 前导。

**两个实测坑**（都发生在本教程工具链上，写进代码注释的那种）：

1. **浮点 `%` 类型带精度（`{:.1%}`）在 MSVC 编译期格式检查直接报错**（C7595）—— workaround 是 `×100` 后 `{:.1f}%` 手写百分号。标准说合法，实现没跟上；这是"工具链事实优先于标准文本"的活例。
2. **中文宽度按码点计**：`{:>10}` 对"右对齐"三个字按 3 计宽，对齐效果和英文直觉不同——中文表格对齐要么接受近似，要么按字节算。

`std::format` 返回字符串（`auto s = std::format("{:.2f}", pi);`）、`std::format_to(迭代器, ...)` 写进缓冲——print 系只是它们的终端特化。

## 22.2 regex：正则三分工

```cpp
std::string log = "2026-09-17 ERROR 磁盘不足; 2026-09-16 INFO 正常";
std::regex date_re{R"((\d{4})-(\d{2})-(\d{2}))"};  // 原始字符串字面量
for (std::sregex_iterator it{log.begin(), log.end(), date_re}, end; it != end; ++it) {
    std::println("日期 {}-{}-{}", it->str(1), it->str(2), it->str(3));  // str(n) 取捕获组
}
std::println("含 ERROR？{}", std::regex_search(log, std::regex{"ERROR"}));  // true
```

先认识 **`R"(...)"` 原始字符串字面量**：里面反斜杠不是转义符——`R"(\d{4})"` 不用写成 `"\\d{4}"`，写正则/路径/JSON 的标配。三个入口函数分工：

| 函数 | 语义 | 用于 |
|---|---|---|
| `regex_match(s, re)` | **整串**完全匹配 | 严格校验（整个字符串是合法日期吗） |
| `regex_search(s, re)` | **找子串**匹配 | 包含判断 |
| `regex_replace(s, re, fmt)` | 替换全部匹配 | 清洗、模板填充 |

`sregex_iterator` 遍历**全部**匹配（`++` 找下一个），`it->str(n)` 取第 n 个捕获组（`str(0)` 是整体）。

必须知道的性能真相：**std::regex 又慢又重**（解析+回溯引擎，构造一个 regex 对象就是可观开销）——循环里每次重新构造 `std::regex` 是经典性能事故；能用 find/string 操作解决的简单匹配就别上正则；高频热路径换第三方库（RE2、CTRE）。它的地盘是**低频、复杂**的文本处理（配置解析、日志抽取）。

## 22.3 filesystem：目录与文件

```cpp
namespace fs = std::filesystem;
fs::path dir = fs::temp_directory_path() / "cpp_guide_22";
fs::create_directories(dir / "sub");
{
    std::ofstream{dir / "a.txt"} << "hello 文件系统";
    std::ofstream{dir / "sub" / "b.log"} << "日志内容";
}
std::vector<fs::path> entries;  // 收集后排序：目录遍历顺序不保证
for (const auto& e : fs::recursive_directory_iterator{dir}) {
    entries.push_back(e.path());
}
std::sort(entries.begin(), entries.end());
std::println("清理了 {} 个条目", fs::remove_all(dir));
```

`std::filesystem`（C++17）把路径、目录、文件信息做成跨平台标准：

- **path 的 `/` 运算符**拼接路径（`dir / "sub" / "b.log"`），天然跨平台分隔符；`.string()` 拿系统原生字符串；
- `create_directories` 递归建目录、`remove_all` 递归删（返回删除数）、`exists`/`file_size`/`is_regular_file` 查询；
- `directory_iterator` 单层遍历、**`recursive_directory_iterator` 递归遍历**（本示例与第 24 章实战的主力）；
- **遍历顺序标准不做保证**——要稳定输出先收集进 vector 再 sort（示例注释点明的坑）；
- 错误处理双轨：抛 `fs::filesystem_error` 的默认版 vs 接 `std::error_code` 的 noexcept 版（`remove_all(p, ec)`）——批量遍历跳过坏文件用后者。

文件读写：`std::ofstream/ifstream`（`<fstream>`）——`ofstream{path} << 内容` 一行落盘（临时对象语句结束即 flush，本示例用法）；整读用 `buffer << in.rdbuf()`（第 24 章实战采用了这个惯用法）。

## 22.4 UTF-8 与编码

C++ 的 `char` 字符串是**字节序列**，编码是约定不是类型——本教程全线 UTF-8：源码 `/utf-8` 编译、程序按 UTF-8 字节处理、终端 `chcp 65001` 显示。三个常见认知点：

- `"你好".size() == 6`（每汉字 3 字节）；`s.substr(0, 4)` 切在汉字中间会得到乱码字节——**按"字符"处理 UTF-8 需要解码**（多字节判断），简单场景按"字节串"处理反而安全（搜索/透传）；
- `char` 在 MSVC 是有符号的，字节数值可能为负——与 0x80~0xFF 比较/索引前 `static_cast<unsigned char>`（第 23 章示例的 slugify 就在守这条线）；
- `char8_t`（C++20）是 u8 字符串的新类型，与 char 不隐式互通（历史争议产物）——教程避开 u8 前缀，统一窄字符串 + UTF-8 约定。

## 22.5 stacktrace 与 mdspan：两个一瞥

**`std::stacktrace`（C++23，`<stacktrace>`）**：`std::stacktrace::current()` 抓当前调用栈——出错时打印"从哪来"，比裸日志强一档（第 23 章组合 assert 讲）。

**`std::mdspan`（C++23，`<mdspan>`）**：多维数组视图——一段一维内存按 2×3 网格看：

```cpp
std::array<int, 6> data{1, 2, 3, 4, 5, 6};
std::mdspan grid{data.data(), 2, 3};   // 2 行 3 列
grid[1, 2];                             // 第 2 行第 3 列 = 6（注意：下标语法）
```

**访问语法是 `grid[r, c]`（多维下标）**——不是 `grid(r, c)`（那是 Kokkos 参考实现的旧接口，本机 MSVC 实测无括号版）。行主序映射，`grid.extent(0)`/`extent(1)` 查维度。数值/图像代码的好朋友，教程点到为止。

## 22.6 坑位清单

1. **循环里反复构造 regex**：每次 `std::regex re{pattern}` 都是全量解析——循环外构造一次复用，性能差数量级。
2. **路径手拼分隔符**：`dir + "\\sub"` 在别的平台/口味下翻车——用 `path` 的 `/`。
3. **遍历时改目录**：迭代器还没走完你就 create/remove → UB 或漏文件。先收集、后操作（示例模式）。
4. **ofstream 忘检查 / 依赖缓冲**：`ofstream f{p}; if (!f) …` 建议检查；临时对象写法（`ofstream{p} << x`）语句结束自动 flush，长期对象记得 close 或靠析构。
5. **substr 切进多字节字符中间**：按字节切 UTF-8 产生半个汉字——切点要么对齐边界，要么按解码后的码点操作。
6. **mdspan 写成括号访问**：`grid(r, c)` 编译不过（MSVC 实测）——多维下标是 `grid[r, c]`。
