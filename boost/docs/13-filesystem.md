# 13 · 文件系统与编码：filesystem + nowide

> 对应示例：`examples/13_filesystem/`（2 个例程）

Boost.Filesystem（2002，作者 Beman Dawes）是"个人作品送进标准"的范本：Beman 写了它、运营 Boost 十几年、然后作为委员会成员亲手把它标准化——C++17 的 `std::filesystem` 就是这个库的直系后代，API 几乎逐字相同。而 nowide 解决的是 Windows 特有的 Unicode 恼火问题，std 至今没有对应物。

## 13.1 Boost.Filesystem：路径即类型

核心设计：**`path` 是一个类型**，不是字符串——拼接用 `/` 运算符、分解用 `filename()/extension()/parent_path()`，跨平台的分隔符处理全部内建：

```cpp
namespace fs = boost::filesystem;
fs::path dir = fs::temp_directory_path() / "boost_tutorial_demo";
fs::create_directories(dir);
fs::path file = dir / "data.txt";
fs::ofstream(file) << "hello fs";               // boost 的 fstream 吃 fs::path
fs::exists(file);  fs::file_size(file);

for (const auto& entry : fs::recursive_directory_iterator(dir)) {
    entry.is_regular_file() && entry.path().extension() == ".log";
}
```

运行输出（`filesystem.cpp`）：

```text
目录 = "F:\temp\boost_tutorial_demo"
文件名 = "data.txt" 扩展名 = ".txt"
存在? 1 大小 = 8
目录下条目数 = 2（data.txt + sub）
递归找到 .log = 2 个
std 版文件名 = "data.txt"
清理后存在? 0
```

**毕业档案**：`std::filesystem`（C++17，直系）。两版并存的注意事项：

1. **`boost::path` 与 `std::path` 不互通**（无隐式转换，要走 `.string()`——例程里有一行注释演示）；
2. std 版的错误处理多了非抛出重载（`fs::exists(p, ec)`），boost 版靠异常；
3. 硬链接/符号链接/权限/空间查询（`space()`）两版都有。

**2026 选型**：新代码 `std::filesystem`。boost 版出现在：老代码、需要支持 C++14 以下的项目。

> 实测坑：`std::ofstream` 不认 `boost::filesystem::path`——用 `<boost/filesystem/fstream.hpp>` 里的 `fs::ofstream`。

## 13.2 Boost.Nowide：Windows 的 UTF-8 总开关

Windows 的编码问题是三个码页的叠加态：`main` 的 argv 是 ANSI 码页、控制台输出是另一码页、文件系统 API 要 UTF-16。中文一路走一路乱。Nowide（Artyom Beilis 作品，2019 进 Boost）一次性把三处都切到 UTF-8：

```cpp
boost::nowide::args a(argc, argv);        // argv → UTF-8
boost::nowide::cout << "中文";             // 控制台 UTF-8
boost::nowide::ofstream f(dir / L"文件名.txt");   // 文件名任意 Unicode
```

运行输出（`nowide.cpp`）：

```text
参数个数 = 1
nowide::cout 输出中文无乱码
读回 = 内容也是 UTF-8（中文路径读写成功）
自检通过
```

**毕业档案**：std 无对应（C++26 有 UTF-8 相关提案但远未覆盖 nowide 的地面）。⭐ **Windows 中文程序的刚需**：本教程所有例程用 `/utf-8` 编译所以源码侧统一了，但只要涉及 argv/控制台/任意路径，nowide 就是标准答案。

本章实测的**三个连环坑**（都修进例程注释了）：

1. **窄字符串路径按 ANSI 码页解释**：`/utf-8` 源码里的 `"中文"` 字面量交给 `fs::path` 会变成乱码目录名——要精确 Unicode 就用 `L""` 宽字面量；
2. **流未关就删除 → fail-fast 崩溃**：文件还开着就 `remove_all`，抛 `filesystem_error`，未捕获的它在 Windows 上不是温柔地 terminate——是 `0xC0000409` 快速失败连 stdout 缓冲都不冲。教训：**删文件前先让流析构**；
3. **链接缺 `Shell32.lib`**：`nowide::args` 用 `CommandLineToArgvW`（在 Shell32 里），不链就是 LNK2019——已在 build.ps1 的章节配置表登记。

---


> 上一章：[12 · 词汇类型五虎](12-vocabulary.md) ｜ 下一章：[14 · 格式化](14-format.md) ｜ 返回：[README](../README.md)
