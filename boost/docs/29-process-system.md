# 29 · 进程与系统：process / dll / interprocess / winapi / endian / iostreams / io / program_options

> 对应示例：`examples/29_process_system/`（9 个文件，含 1 个插件 DLL）

系统编程的 Boost 工具箱：进程（process）、动态库（dll）、共享内存（interprocess）、Win32 薄封装（winapi）、字节序（endian）、流过滤（iostreams）、流工具（io）、命令行（program_options）。

## 29.1 Boost.Process v2（2024）：子进程管理

v2 接口（1.86 起）基于 asio 执行器，同步/异步一体：

```cpp
// exe 路径用 find_executable 按 PATH 找，别写死 C:/Windows/System32/…
const boost::filesystem::path hostname = proc::environment::find_executable("hostname");
proc::process h(io, hostname, {});
int rc = h.wait();                       // 0
proc::process::environment::get("PATH");
```

运行输出（`process.cpp`；首行是子进程直接继承父进程 stdout 写的机器名）：

```text
xulundeMacBook-Pro.local
找到 hostname? 1
hostname 退出码 = 0（预期 0）
自己 --exit-3 退出码 = 3（预期 3）
PATH 非空? 1
自检通过
```

（Windows 侧的同一份例程打的是 `where where 退出码 = 0` 那一行——本机改成
"跑自己 + `--exit-3`" 之后，两平台的输出完全一致，见下面第 4、5 条。）

本章实测的**五条坑**（都写进了例程注释）：

1. **exe 路径要显式 `boost::filesystem::path`**——`const char*` 重载会走"命令行搜索"分支，报"系统找不到文件"（system:2）；
2. **cmd.exe 对参数引号极敏感**（`"/c"` 被引号包裹就"命令语法不正确"）——演示选无参系统工具最稳；
3. **`asio::readable_pipe` + `process_stdio` 捕获组合在本机（MSVC 19.51 + vc145 DLL）fail-fast**（0xC0000409，连 stderr 都来不及吐）——需要捕获输出时考虑重定向到文件或 process v1；
4. **【跨平台】exe 路径不能写死** `C:/Windows/System32/hostname.exe`——换到 macOS/Linux 连文件都没有。用 `environment::find_executable("hostname")` 按 PATH 找，Windows 与 Unix 都有这个同名工具；
5. **【跨平台】"退出码传递"别去撞系统工具的失败分支**：`hostname` 遇到非法参数会往 stderr 打一行，本教程的"stderr 恒空"判定不放过子进程的输出。改成跑自己——带 `--exit-3` 参数时 `main` 直接 `return 3`，安静、可控、跨三平台同输出。

## 29.2 Boost.DLL（2014）：运行期加载共享库

例程包含宿主（`dll.cpp`）与插件（`plugin_greeter.cpp` 编成 DLL）：

```cpp
dll::shared_library lib(path);                     // 加载 + has() 查符号
auto greet = dll::import_symbol<const char*(const char*)>(path, "greet");
auto add = dll::import_symbol<int(int, int)>(path, "add");
```

运行输出（`dll.cpp`；macOS 侧首行是 `.dylib`，Windows 侧是 `.dll`）：

```text
插件文件名 = plugin_greeter.dylib
DLL 已加载? 1
有 greet? 1 有 missing? 0
greet(boost) = 你好, boost!
add(3,4) = 7
自检通过
```

**跨平台两条**（都是"写死 Windows 形态"踩出来的）：

- 文件名后缀不能写 `".dll"`：Windows 是 `.dll`、Linux 是 `.so`、macOS 是 `.dylib`。
  例程用 `boost::dll::shared_library::suffix()` 问库自己（构建脚本 `run-all.sh`
  也用同一个 API 定产物名，两边不可能说不到一块去）；
- 导出符号的写法三家不同：`__declspec(dllexport)`（MSVC/MinGW）对
  `__attribute__((visibility("default")))`（clang/GCC）。用宏统一，别 `#if` 掉一侧
  ——Unix 侧这行看着多余，宿主一旦带 `-fvisibility=hidden` 编库，缺它就 dlsym 失败。

**本章最惊险的实测坑**：`shared_library::get<T>()` 把符号当 **T 类型的数据对象**返回引用——拿它取函数（`get<int(*)(int,int)>`），等于把函数机器码字节当指针解引用，调用即访问违例（0xC0000005）。逐层探针（裸 LoadLibrary 对照 → 打印指针值发现是机器码字节）才定位。**函数导入永远用 `import_symbol<签名>`**。⭐ 插件架构、热加载模块的标准件。

## 29.3 Boost.Interprocess（2005）：跨进程共享

```cpp
bip::managed_shared_memory segment(bip::create_only, "BoostTutorialShm", 65536);
ShmVector* vec = segment.construct<ShmVector>("shared_vec")(alloc);   // 段内构造
segment.find<ShmVector>("shared_vec");                                // 另一进程按名找到
bip::named_mutex mtx(bip::create_only, "BoostTutorialMutex");          // 进程间锁
```

运行输出（`interprocess.cpp`）：

```text
共享 vector 大小 = 3
按名找回 = 1 首元素 = 10
跨进程互斥锁已持有
清理完成
自检通过
```

共享内存段的**命名对象**（vector/map/string 全有段内版本）+ 命名同步原语（mutex/condition/semaphore/sharable_lock）+ 段内分配器。⭐ 高性能 IPC（数据库缓存、多进程渲染）的标准答案，std 无对应。**运维要点**：进程崩溃时段不会自动消失，重启时要先 remove 再 create（例程第一行就是防御性清理）。

## 29.4 Boost.WinAPI（2014）：Windows 分支的规范薄封装

```cpp
boost::winapi::GetCurrentProcessId();            // API 同名
boost::winapi::DWORD_ / SYSTEM_INFO_             // 类型/常量加 _ 后缀
```

运行输出（`winapi.cpp`，Windows 侧）：

```text
PID = 16800 TID = 8412
PID/TID 都非零? 1
逻辑处理器 = 20 个
页大小 = 4096 字节
自检通过
```

运行输出（`winapi.cpp`，macOS/Linux 侧）：

```text
本机不是 Windows：Boost.WinAPI 不可用
  boost/winapi/basic_types.hpp 在非 Windows 上直接 #error
  "Win32 functions not available"（连编译都过不去）
自检通过
```

写跨平台库的 `#ifdef _WIN32` 分支时用它代替裸 `windows.h`：不污染全局命名空间、头文件粒度细。库作者工具，应用代码一般轮不到。

> **它是"编译期就不跨平台"的那一类**：`boost/winapi/basic_types.hpp` 在非 Windows
> 上直接 `#error "Win32 functions not available"`（macOS 上实测，第 38 行）——
> 不是链接不上，也不是跑不通，连语法检查都过不去。所以 `#include` 本身就得跟着
> 平台走。例程的非 Windows 分支把这段事实打出来（仍然以"自检通过"收尾），
> macOS 上跑出来是这样：
>
> ```text
> 本机不是 Windows：Boost.WinAPI 不可用
>   boost/winapi/basic_types.hpp 在非 Windows 上直接 #error
>   "Win32 functions not available"（连编译都过不去）
> 自检通过
> ```

## 29.5 Boost.Endian（2013）：字节序双件套

`std::endian`（C++20）毕业了**探测**；**转换与缓冲布局**仍是 boost 独占：

```cpp
be::big_uint32_buf_t net_value(0x12345678);   // 大端缓冲（协议结构体直接 memcpy）
net_value.value();                             // 按字节序读回
be::big_uint32_t net_arith(1);                 // 算术型（能 ++、能加）
```

运行输出（`endian.cpp`）：

```text
本机字节序 = 小端
大端字节 = 12 34 56 78
读回值 = 0x12345678
小端 0xABCD 首 8 位字节 = 0xcd
算术参与: 0x12345678 + 1 = 0x12345679
自检通过
```

**buffer vs arithmetic 的分界**：`*_buf_t` 只管内存布局（零开销，`#pragma pack` 网络结构体的正确成员类型）；`endian_arithmetic`（如 `big_uint32_t`）额外支持算术运算。⭐ 网络协议/文件格式的地基件。

## 29.6 Boost.Iostreams（2005）：流的水管工

```cpp
io::filtering_ostream out;
out.push(io::gzip_compressor());          // 过滤器（可叠加）
out.push(io::back_inserter(compressed));  // 设备（目的地）
out << text;
```

运行输出（`iostreams.cpp`）：

```text
原文 115 字节 → 压缩 118 字节
解压还原一致? 1
自检通过
```

本例的中文文本太短，gzip 头开销让它"越压越大"（118>115）——**真实数据要够长才有压缩收益**的直观一课。过滤器库覆盖 gzip/zlib/bzip2/base64/newline/正则替换。⭐ std 无对应。

## 29.7 Boost.IO（2022 重制）：quoted 与让位

```cpp
oss << boost::io::quoted("含,逗号 \"引号\"");   // CSV 编码
iss >> boost::io::quoted(decoded);              // 解码
```

运行输出（`io.cpp`）：

```text
编码 = "含,逗号 \"引号\""
解码一致? 1
自定义定界 = |含,逗号 "引号"|
join: 1 + 2 + 3
自检通过
```

`quoted` 已基本被 `std::quoted`（C++14）覆盖——本库如今是"传家角"，新代码用 std 版。

## 29.8 Boost.ProgramOptions（2002）：命令行解析

```cpp
desc.add_options()
    ("port,p", po::value<int>()->default_value(8080), "监听端口")
    ("tags,t", po::value<std::vector<std::string>>()->multitoken(), "标签(多个)")
    ("verbose,v", po::bool_switch(), "详细输出");
po::store(po::parse_command_line(...), vm);  po::notify(vm);
```

运行输出（`program_options.cpp`）：

```text
port = 9000
verbose = 1
tags: alpha beta
帮助首行 = help
自检通过
```

短/长选项、默认值、多值、配置文件（`parse_config_file`）、环境变量三合一。**竞争者**：CLI11（第三方但现代）。老牌项目的既定答案。⭐

## 29.9 Boost.Python（简介，未纳入验证）

Boost.Python（2002，老牌 C++↔Python 桥）需要链接本机 Python 开发库，且 scoop Python 3.13 的开发头与本流水线的组合超出了教程的验证边界——按既定策略给代码片段：

```cpp
#include <boost/python.hpp>
BOOST_PYTHON_MODULE(calc) {
    boost::python::def("add", +[](int a, int b) { return a + b; });
}
// 编成 calc.pyd 后：Python 侧 import calc; calc.add(1, 2)
```

2026 视角：新项目更多选 **pybind11**（同为 C++ 模板桥但更轻）；Boost.Python 的生态位是大型遗留绑定与 Boost 内部（Math/UBlas 的 Python 壳）。

---


> 上一章：[28 · 网络编程](28-network.md) ｜ 下一章：[30 · 序列化与配置](30-serialization.md) ｜ 返回：[README](../README.md)
