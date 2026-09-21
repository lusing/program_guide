# 02 · 环境与构建：把工具链立起来

> 对应示例：`examples/02_setup/version.cpp`

Boost 的安装形态五花八门（vcpkg / apt 的拆包 / 源码自建 / 官方安装器），本教程锁定本机环境讲**一套能跑通的完整链路**，重点是三个 MSVC + DLL 版 Boost 特有的坑——它们全部来自真实踩雷，不是文档腔的"注意事项"。

## 2.1 本教程的环境

| 组件 | 版本/路径 | 说明 |
|---|---|---|
| Boost | **1.92.0** | scoop 安装：`G:\scoop\apps\boost\current`（符号链接 → `1.92.0`） |
| 预编译库 | vc145 · mt / mt-gd | DLL + 导入库，**没有静态库** |
| 编译器 | MSVC **19.51**（VS 18 Community） | `cl.exe`，`/std:c++latest` = C++26 草案档 |
| GPU | RTX 3060 + CUDA 13.3 | 第 25 章 Boost.Compute 用它的 OpenCL |
| Python | 3.13（scoop） | Boost.Python 的尝试目标 |

scoop 版 Boost 的目录形态值得先看清——它和 vcpkg/官方安装器都不同：

```text
G:\scoop\apps\boost\current\
├── boost\          ← 头文件根（#include <boost/xxx.hpp> 的 xxx 在这）
├── lib\            ← 预编译 DLL + .lib 导入库 + .pdb
│   ├── boost_atomic-vc145-mt-x64-1_92.dll
│   ├── boost_atomic-vc145-mt-x64-1_92.lib
│   └── …（mt = release，mt-gd = debug）
└── libs\           ← 各库的源码、文档、测试（160 个模块）
```

编译时 `-I` 指向**根目录**（不是 `boost\` 子目录），链接靠 Boost 的**自动链接**机制（头文件里的 `#pragma comment(lib, ...)` 会根据编译器版本自动拼出 `boost_xxx-vc145-mt-x64-1_92.lib` 这样的名字）。

## 2.2 头文件库 vs 编译库

Boost 的库分两种，使用方式完全不同：

| | header-only | 需要编译 |
|---|---|---|
| 使用方式 | `#include` 即用 | 链接预编译库（自动链接一般会替你做） |
| 代表 | smart_ptr、optional、variant、hana、mp11、spirit、mpl、range、algorithm | filesystem、regex、thread、serialization、date_time、locale、iostreams、program_options、test、log、context/fiber/coroutine、nowide、system* |
| 注意点 | 编译时间换便利 | 要选对变体（mt/gd、静态/DLL） |

> \* 好玩的是这条线在移动：`boost::system` 从 1.69 起默认 header-only；`atomic`、`charconv`、`json`、`url` 都有 header-only 模式。趋势是"能 header-only 就 header-only"，但 filesystem、context 这些依赖平台实现的核心仍然要链接。

本教程统一走 **DLL + 自动链接** 路线，所以每条编译命令都带三件套（见 2.3）。

## 2.3 三只拦路虎：DLL 版 Boost + MSVC 的真实坑

以下三条每一条都在本教程搭建时实际踩到、并用最小例子复现过。

### 坑 1：不加 `/MD`，直接被自动链接拒绝

`cl` 默认用**静态运行时**（`/MT`），而预编译的 Boost DLL 是按**动态运行时**建的。混用的后果 Boost 直接替你挡下来：

```text
boost/config/auto_link.hpp(440): fatal error C1189:
  "Mixing a dll boost library with a static runtime is a really bad idea..."
```

**修法**：编译永远带 `/MD`（本机没有 Boost 静态库，`/MT` 一律走不通）。

### 坑 2：`/W4` 会被 Boost 头文件的告警淹没——除非用 `/external`

本教程要求例程**零告警**（`/W4`）。但 Boost 是要支持十几种编译器几十个版本的海量模板代码，直接 `/W4` 编译会产生大量来自 Boost 头自身的告警，把例程自己的问题淹没。

MSVC 的正解是外部头机制：

```text
/W4                            ← 自己的代码：四级告警
/external:I"G:\...\boost\current"   ← 把 Boost 头标记为"外部"
/external:W0                   ← 外部头告警级别 0
```

顺序不能乱：`/external:I` 必须出现在使用它定位的头之前（我们的命令行里它排在源文件参数前面，天然满足）。

### 坑 3：DLL 版 Boost 的运行期查找

链接期有自动链接 + `/LIBPATH`，但**运行期**进程要能找到 `boost_*-vc145-mt-x64-1_92.dll`。三种办法：

1. 把 `G:\scoop\apps\boost\current\lib` 加进系统 `PATH`（一劳永逸，但污染全局）；
2. 把需要的 DLL 拷进 exe 旁边（部署友好的笨办法）；
3. **本教程的做法**：`build.ps1` 在启动示例进程时把 Boost lib 目录**前置**进该进程的 `PATH`——不污染全局，仓库开箱即跑。

### 附赠坑（写给改 build.ps1 的人）

PowerShell/.NET 的 `ProcessStartInfo.ArgumentList` 会把参数里的 `"` 转义成 `\"` 再传给子进程。对直接调 `cl` 没事（那些参数不含裸引号），但走 `cmd /c "call vcvars && cl /Fe\"...\""` 这条批处理链时，cmd 收到的引号全废，命令**静默失败**（退出码 1，零输出——连报错都没有，最阴险的一类失败）。`build.ps1` 的 `Invoke-Batch` 因此走 `$psi.Arguments` 原样透传，不碰 `ArgumentList`。改脚本时别"顺手统一"掉这个分支。

## 2.4 编译命令解剖

本教程每个例程的实际编译命令长这样（`build.ps1` 拼装）：

```text
cl /nologo /std:c++latest /EHsc /MD /utf-8 /permissive- /Zc:__cplusplus /W4
   /D BOOST_ALL_DYN_LINK /D _WIN32_WINNT=0x0A00
   /external:I"<boost根>" /external:W0
   /Fo"build\xxx.obj" /Fe"build\xxx.exe" "examples\NN_章\xxx.cpp"
   /link "/LIBPATH:<boost根>\lib" [章节附加系统库]
```

逐项说清为什么：

| 参数 | 作用 |
|---|---|
| `/std:c++latest` | C++26 草案档。**本教程的特色依赖**：讲"Boost vs std 对照"需要 `std::format`/`std::print`/`std::expected`/`std::mdspan` 这些新标准设施都能真编译 |
| `/EHsc` | C++ 异常模型（Boost 几乎所有库都要） |
| `/MD` | 坑 1 的解 |
| `/utf-8` | 源码与执行字符集都是 UTF-8——例程输出中文的根基；不带它 MSVC 按代码页猜，中文输出必乱 |
| `/permissive-` `/Zc:__cplusplus` | 严格标准符合性；后者让 `__cplusplus` 报真值（Boost.Config 靠它探测） |
| `/W4` + `/external:*` | 坑 2 的解 |
| `BOOST_ALL_DYN_LINK` | 所有 Boost 库按 dllimport 生成代码 + 自动链接选 DLL 变体 |
| `_WIN32_WINNT=0x0A00` | 声明目标是 Win10+（asio/winapi 家族需要，否则报"请显式声明目标系统"） |
| `/LIBPATH:...\lib` | 自动链接在这个目录找 `.lib` |
| 章节附加库 | 如 17 章 `dbghelp.lib`（stacktrace）、28 章 `ws2_32.lib`（asio/beast 的 socket 层）、25 章 CUDA 的 `OpenCL.lib` |

## 2.5 build.ps1：一个入口，六条判定

```text
pwsh ./build.ps1 -All                      全量：逐示例编译+运行+判定
pwsh ./build.ps1 -Chapter 03               整章验证（编号或目录名）
pwsh ./build.ps1 -File 03_smartptr/smart_ptr.cpp   单示例
pwsh ./build.ps1 -All -ShowOutput          附带打印运行输出
pwsh ./build.ps1 -Clean                    清理 build 目录
```

判定标准六条，缺一不可（与仓库 cpp20 教程同源，口径一致）：

1. 编译退出码为 0；
2. 编译日志干净——**含告警即失败**（`/W4` 对例程代码，`/external:W0` 保证 Boost 头不背锅）；
3. 运行退出码为 0；
4. stdout 非空、且无控制字符（TAB/LF/CR 除外）——防"进程没跑到业务代码却退出 0"的假阳性；
5. stderr 为空——运行期往 stderr 吐东西也算失败；
6. stdout 里有结束标记 **`自检通过`**——例程自己声明的"我跑完了"。

> 为什么这么严：第 4、6 条专治**假阳性**。DLL 没找到时 Windows 报错走弹窗/退出码 0xXXXX，进程可能"看似启动"；`io.run()` 忘了调、协程没调度、句柄提前析构，这类错误常常**安静地什么都不打印**。六条一起卡，"通过"才有含金量——文档里嵌的每段输出，都是这六条全绿换来的。

目录约定：

```text
examples/NN_章名/库.cpp        每个库一个自包含例程，编成同名 exe
examples/NN_章名/plugin_*.cpp  编成 DLL（/LD），只编译不运行（29 章 dll 的插件）
```

## 2.6 第一个例程：摸清环境

`examples/02_setup/version.cpp` 打印工具链身份，并用 `__has_include` 探测本教程 std 对照侧要用的标准头：

```cpp
// version.cpp —— 摸清环境：Boost 版本 / 编译器 / 标准档位 / 标准头可用性
#include <boost/version.hpp>
#include <print>
#include <string_view>

// 把 _MSVC_LANG 的数值翻译成标准名。
// /std:c++latest 下 MSVC 报 202400（C++26 草案档），比正式值更新。
constexpr std::string_view lang_name(long v) {
    switch (v) {
        case 201103L: return "C++11";
        case 201402L: return "C++14";
        case 201703L: return "C++17";
        case 202002L: return "C++20";
        case 202302L: return "C++23";
        default:      return "C++26 草案（/std:c++latest）";
    }
}

int main() {
    std::print("Boost {}.{}.{}\n", BOOST_VERSION / 100000,
               BOOST_VERSION / 100 % 1000, BOOST_VERSION % 100);
    std::print("MSVC {}.{}\n", _MSC_VER / 100, _MSC_VER % 100);
    std::println("标准档位: {}", lang_name(_MSVC_LANG));

    // __has_include 探一下本教程后面要用到的标准头——
    // Boost 与 std 的"毕业对照"要两边都能跑，先确认 std 侧的弹药充足
#if __has_include(<format>)
    std::println("<format>   有  C++20 std::format");
#endif
#if __has_include(<print>)
    std::println("<print>    有  C++23 std::print");
#endif
#if __has_include(<expected>)
    std::println("<expected> 有  C++23 std::expected");
#endif
#if __has_include(<mdspan>)
    std::println("<mdspan>   有  C++23 std::mdspan");
#endif
    std::println("自检通过");
    return 0;
}
```

实际运行输出（`pwsh ./build.ps1 -Chapter 02 -ShowOutput`）：

```text
Boost 1.92.0
MSVC 19.51
标准档位: C++26 草案（/std:c++latest）
<format>   有  C++20 std::format
<print>    有  C++23 std::print
<expected> 有  C++23 std::expected
<mdspan>   有  C++23 std::mdspan
自检通过
```

四发探照灯全亮：std 侧弹药充足，后面每一章的"Boost vs std 对照"都是两边真编译、真运行出来的，不是文档抄写。

> 小知识：`BOOST_VERSION` 是 `109200`——`/100000` 得主版本、`/100%1000` 得次版本、`%100` 得补丁号。宏在 `<boost/version.hpp>`，也是判断"当前 Boost 够不够新"的标准姿势（条件编译里用它，别在运行期判断）。

---


> 上一章：[01 · 二十八年史](01-overview.md) ｜ 下一章：[03 · 所有权革命](03-smartptr.md) ｜ 返回：[README](../README.md)
