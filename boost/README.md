# Boost C++ 教程（1.92 全库版）

每个库都有例程和简介，沿 C++ 标准演进时间线讲解。全部 **149 个例程**在本机
编译 + 运行 + 六条判定验证（297/297 全绿），GPU 例程在 RTX 3060 上实测。

**macOS 侧另有一套等价入口** `run-all.sh`：Apple clang 16 + 自建 Boost 1.88，
双通道（动态/静态链接 Boost）跑完 149 例，见 [macOS 验证](#macos--linux-验证run-allsh)。

## 目录结构

```text
boost/
├── README.md            ← 本文件（索引）
├── build.ps1            ← Windows 构建/验证入口（MSVC + Boost 1.92 DLL）
├── run-all.sh           ← macOS/Linux 构建/验证入口（clang + 自建 Boost）
├── tools/check-docs.py  ← 文档与实测输出的对账（三项机器核查之一）
├── docs/                ← 章节正文（33 章）
└── examples/NN_章名/    ← 每库一个自包含例程（149 个 .cpp，含 1 个插件库）
```

## 工具链

| 平台 | 编译器 | Boost | 说明 |
|---|---|---|---|
| Windows | MSVC 19.51（VS 18 Community，`/std:c++latest` = C++26 草案档） | 1.92.0（scoop：`G:\scoop\apps\boost\current`，vc145 DLL 预编译库） | 例程的全部实测输出以此为准 |
| macOS | Apple clang 16.0.0（Xcode 16，`-std=c++2b`） | 1.88（源码树 `/Volumes/mac004/lang/boost` 自建） | 见下节；25 章的 GPU 走系统 OpenCL 框架（Iris Pro） |

Windows 侧另有 CUDA 13.3 OpenCL（25 章 Boost.Compute 用，RTX 3060）。

## 构建

```powershell
cd G:\code\guide\boost
pwsh ./build.ps1 -All          # 全量：编译（零告警）+ 运行 + 六条判定
pwsh ./build.ps1 -Chapter 03   # 整章
pwsh ./build.ps1 -File 03_smartptr/smart_ptr.cpp   # 单示例
pwsh ./build.ps1 -Clean        # 清理 build/
```

判定六条：编译零告警（/W4 + /external:W0）/ 退出码 0 / stderr 空 /
stdout 非空无控制字符 / 含结束标记"自检通过"。

## macOS / Linux 验证（run-all.sh）

`build.ps1` 只能在 Windows 上跑（MSVC + Boost DLL + `G:\` 路径）。macOS/Linux 侧的
等价入口是 `run-all.sh`：同一批 149 个例程、同样六条判定，再加一条本仓库多通道
惯例——**两条通道的 stdout 逐字节一致**。

### 环境准备：Boost 要自己编

MacPorts 的 boost 停在 **1.76**，比教程依赖的 1.92 差了十几个小版本
（`hash2`/`parser`/`cobalt`/`url`/`charconv`/`scope`/`bloom`/`decimal` 全都没有）。
所以 macOS 侧不用包管理器版本，直接用源码树自建（与仓库 `io/` 目录"包管理器
版本太老就从源码编"的惯例一致）：

```bash
cd /Volumes/mac004/lang/boost
bash ./tools/build/src/engine/build.sh      # 先编出 b2（本机 bootstrap.sh 没有 +x 位）
cp tools/build/src/engine/b2 ./b2
./b2 headers --build-dir=/tmp/boost-b2      # 生成统一的 boost/ 头文件树（不能省！）
./b2 --build-dir=/tmp/boost-b2 --stagedir=<本目录>/build/boost-1.88 -j8 \
     variant=release link=static,shared threading=multi cxxstd=20 --layout=tagged \
     --with-atomic --with-charconv --with-chrono --with-cobalt --with-container \
     --with-context --with-contract --with-coroutine --with-date_time --with-exception \
     --with-fiber --with-filesystem --with-graph --with-iostreams --with-json \
     --with-locale --with-log --with-math --with-nowide --with-process \
     --with-program_options --with-random --with-regex --with-serialization \
     --with-stacktrace --with-system --with-test --with-thread --with-timer \
     --with-type_erasure --with-url --with-wave        # 约 17 分钟
```

两条会卡住人的地方：

- **`b2 headers` 不能省**：模块化 Boost 的头文件散在 `libs/*/include/boost/`，
  没有这一步 `#include <boost/version.hpp>` 都找不到（源码树里没有顶层 `boost/`）。
- **`--build-dir` 指到源码树外面**：b2 会删自己的 `.o.tmp`，写在受保护目录里会被拦
  （本机的安全策略就拦了一次，整轮构建被 SIGTERM）。
- **Boost.Locale 要带 ICU**（19 章的 Unicode 语义全靠它）：本机 ICU 在 MacPorts 的
  `/opt/local`，但直接给 `-sICU_PATH=/opt/local` 会踩两件事——
  ① 探测结果**被缓存在 `bin.v2/project-cache.jam`**，改了参数也不重探，
  要先把 `has_icu` / `icu-` 开头的行从缓存里删掉；
  ② ICU 带来的 `-L/opt/local/lib` 会把 `-liconv` 引到 MacPorts 的 GNU libiconv
  （只导出 `_libiconv`，而 Boost 的目标文件按系统 iconv 编出的是 `_iconv`），
  链接直接 `Undefined symbols: _iconv`。
  绕法是给 b2 一个**只含 ICU 的目录**（`include/unicode` 与三个 `libicu*.dylib`
  的软链接），这样既探得到 ICU，又不会让 `-L` 抢走 `-liconv`：

  ```bash
  mkdir -p /tmp/icu-only/include /tmp/icu-only/lib
  ln -s /opt/local/include/unicode /tmp/icu-only/include/unicode
  ln -s /opt/local/lib/libicu{data,i18n,uc}.dylib /tmp/icu-only/lib/
  # 删掉 project-cache.jam 里的 has_icu / icu- 行，再：
  ./b2 --build-dir=/tmp/boost-b2 --stagedir=…  --with-locale -sICU_PATH=/tmp/icu-only
  ```

  不带 ICU 的 Boost.Locale 是**半残**的（`normalize()` 原样返回、`to_upper("ß")`
  不变成 `"SS"`），输出看着像"macOS 的差异"，其实是构建缺依赖——别把那种输出写进教程。

### 用法

```bash
./run-all.sh                                  # 全量：两条通道 × 149
./run-all.sh 03 29                            # 指定章号
./run-all.sh -f 29_process_system/process.cpp # 单示例
./run-all.sh -v                               # 附带打印每个示例的输出
BOOST_INC=/path/to/boost BOOST_LIB=/path/to/lib ./run-all.sh   # 换 Boost 位置
```

### 两条通道

| 通道 | 链接方式 | 检验什么 |
|---|---|---|
| `shared` | `libboost_*-mt-x64.dylib` | 运行期按 rpath 找动态库 |
| `static` | `libboost_*-mt-x64.a`（按**完整路径**给） | 同上；两条同源，输出不一致就是真问题 |

静态通道必须写全路径：macOS 的 ld64 没有 `-Bstatic`，同一个 `-L` 目录里 `.dylib`
永远压过 `.a`，不写全路径就等于再跑一遍动态通道，"跨通道比对"会变成摆设。

### 本机结果

Apple clang 16.0.0（Xcode 16）/ macOS 14 / x86_64，Boost 1.88 源码树自建：
**通过 294，失败 4**（149 个例程 × 2 条通道；4 = 2 个例程 × 2 条通道），
输出差异 0 —— 两条通道的 stdout 全部一致。唯一豁免的是 07 章 `timer.cpp` 里
`auto_cpu_timer` 打的那一行真实耗时（`wall/user/system` 每次都不一样），
而且豁免是**按行**给的，同一例程其余行照常逐字节比。

失败的两项都归属**环境缺口**，不是例程写错：

| 例程 | 原因 | 出路 |
|---|---|---|
| `04_function/compat.cpp` | `#include <boost/compat/move_only_function.hpp>`：本机源码树的 Boost.Compat 还没有这个头（1.92 才有） | 换 Boost ≥ 1.92 |
| `20_parsers/parser.cpp` | Boost.Parser 用到 `std::ranges::range_adaptor_closure`，Apple 自带 libc++ 没有（libc++ 19 才实现） | 换 LLVM ≥ 19 的 libc++；`build/parser-llvm23-libcxx.log` 是用 clang++-mp-23 编过 + 跑通的实测留档 |

### macOS 侧踩到的平台差异（都已写回例程/脚本/正文）

| 差异 | Windows | macOS/Linux | 落在哪 |
|---|---|---|---|
| 压掉 Boost 头的告警 | `/external:I` + `/external:W0` | `-isystem <boost根>` | run-all.sh |
| 库链接 | 自动链接（`#pragma comment(lib)`） | 显式给库名 + `-Wl,-rpath`（没有 PATH 可前置） | run-all.sh 的章节表 |
| 动态库后缀 | `.dll` | `.dylib` / `.so` | 29 章 `dll.cpp`：问 `boost::dll::shared_library::suffix()`，不写死 |
| 导出符号 | `__declspec(dllexport)` | `__attribute__((visibility("default")))` | `plugin_greeter.cpp` |
| Boost.WinAPI | 可用 | 头里直接 `#error "Win32 functions not available"`（编译期就不能用） | `winapi.cpp` 的非 Windows 分支 |
| Boost.Stacktrace | dbghelp 后端 | 要 `-DBOOST_STACKTRACE_GNU_SOURCE_NOT_REQUIRED` | run-all.sh 17 章 |
| Boost.Log / Boost.Test | 在 `BOOST_ALL_DYN_LINK` umbrella 下 | 各自要 `-DBOOST_LOG_DYN_LINK` / `-DBOOST_TEST_DYN_LINK` | run-all.sh 32 章 |
| Boost.Test 报告 | 控制台 API，不打转义字节 | 默认带 ANSI 颜色转义（判"无控制字符"会挂）→ `BOOST_TEST_COLOR_OUTPUT=0` | run-all.sh |
| `std::jthread` | 直接可用 | Apple libc++ 要 `-fexperimental-library` 才给（stop_token 被标为未完成） | run-all.sh |
| 子进程路径 | `C:/Windows/System32/hostname.exe` | `environment::find_executable("hostname")` 按 PATH 找 | `process.cpp` |
| 事件名 `pause` | 无冲突 | POSIX 有同名函数 `pause()`，会把类型名遮住 | `msm.cpp` |
| 编译器专属告警压制 | `#pragma warning(disable: X)` | `#pragma clang diagnostic ignored "-W..."` | 04 章两个宏库例程 |
| GPU | RTX 3060 + CUDA OpenCL | 系统 OpenCL 框架（本机落到 Iris Pro） | 25 章 `compute.cpp` |

### 顺带抓到的确定性问题（不是平台差异，Windows 上同样会漂）

本教程有"同一例程两条通道 stdout 逐字节一致"这条判据，下面这些是被它逼出来的——
不改的话在 Windows 上也是每次跑结果不同：

| 例程 | 原来的问题 | 现在 |
|---|---|---|
| `23_graph_geometry/polygon.cpp` | 并集只累加 `uni[0]`，打出「块数 1 / 面积 28」这种自相矛盾的数 | 遍历累加 `gtl::area`（实测 3 块 / 28） |
| `32_quality/log.cpp` | 命名 logger 不带 `Severity`，被 `severity >= info` 全局过滤**静默丢掉** | 挂 `constant<severity_level>` 属性 |
| `05_langbase/align.cpp` | 打「对齐推进 N 字节」，N 随分配地址漂 | 打两条不变量：推进量 < 32? / 结果 32 对齐? |
| `12_vocabulary/uuid.cpp` | v4 UUID 每次跑都不一样 | 固定种子 `mt19937` + `basic_random_generator<mt19937>` |
| `17_cpp23/stacktrace.cpp` | `-O2` 把中间帧内联掉，帧命中率随优化漂 | 三层都标 `BOOST_NOINLINE` |
| `06_regex_random/random.cpp` | 一句「一致?」同时问了裸引擎和分布两件事 | 拆成「同种子的裸引擎序列一致?」+「std/boost 同种子分布一致?」 |
| `29_process_system/dll.cpp` | 打印完整路径（`build/shared` 与 `build/static` 不同） | 只打 `filename()`；`TMPDIR` 固定成绝对路径 |
| `07_chrono/timer.cpp` | `段2 wall>=1ms?` 的迭代数卡在阈值附近，同一通道连跑 5 次有 2 次 `false`——所谓断言在掷硬币 | 迭代数放大到 2000 万次（离 1ms 阈值两个数量级），实测 5/5 稳定 |
| `20_parsers/xpressive.cpp` | 命名捕获的正则写成 `'(' >> +_d >> ')'`，对 `(retry 3)` 匹配不上，`重试次数` 那行**从来没被打印过**（文档里那条是凭印象写的） | 把 `"retry "` 前缀写进正则 |
| `12_vocabulary/logic.cpp` | 源码里 `"（短 路 吸收）"` 多打了两个空格 | 去掉 |
| `17_cpp23/charconv.cpp` | 三处布尔没开 `boolalpha`，打成 `1`/`0`，跟上一行的"错误码=0?"混在一起 | 显式 `std::boolalpha` |

另：**`run-all.sh` 对 timer 的"已知差异"白名单原来是整例豁免的**，等于把上面那条掷硬币的输出也一起放过了。现在改成**按行豁免**（只删 `auto_cpu_timer` 打的真实耗时那一行），其余行照常逐字节比；并且脚本会校验"豁免模式确实命中了行"——命中 0 行就报警，防止模式过期后判据静默失效。

## 章节目录

### 第一部 · 舞台

| 章 | 主题 |
|---|---|
| [01](docs/01-overview.md) | Boost 与 C++ 的二十八年：一部"标准库预备队"史 |
| [02](docs/02-setup.md) | 环境与构建：把工具链立起来 |

### 第二部 · TR1 与 C++11——黄金毕业潮

| 章 | 主题 | 库 |
|---|---|---|
| [03](docs/03-smartptr.md) | 所有权革命 | smart_ptr |
| [04](docs/04-function.md) | 函数即对象 | function、bind、functional、lambda、lambda2、hof、callable_traits、local_function、phoenix、parameter、compat |
| [05](docs/05-langbase.md) | 语言基建先行者 | tuple、array、static_assert、type_traits、typeof、integer、utility、core、assert、config、predef、foreach、align、type_index |
| [06](docs/06-regex-random.md) | 正则与随机 | regex、random |
| [07](docs/07-chrono.md) | 时间与日历 | date_time、chrono、ratio、timer |
| [08](docs/08-unordered.md) | 无序与哈希 | unordered、container_hash、hash2 |
| [09](docs/09-thread.md) | 多线程第一课 | thread |
| [10](docs/10-atomic.md) | 原子操作 | atomic |
| [11](docs/11-error.md) | 错误处理基石 | exception、system、throw_exception |

### 第三部 · C++17/20/23/26 现代波次

| 章 | 主题 | 库 |
|---|---|---|
| [12](docs/12-vocabulary.md) | 词汇类型 | optional、variant、variant2、any、string_view、static_string、uuid、logic |
| [13](docs/13-filesystem.md) | 文件系统与编码 | filesystem、nowide |
| [14](docs/14-format.md) | 格式化 | format（vs std::format） |
| [15](docs/15-ranges.md) | 范围与迭代器 | range、iterator、stl_interfaces、concept_check、sort |
| [16](docs/16-coroutines.md) | 协程时代 | context、coroutine、coroutine2、cobalt、fiber |
| [17](docs/17-cpp23.md) | C++23 波次 | charconv、stacktrace、decimal、outcome、（std::mdspan 对照） |
| [18](docs/18-cpp26.md) | C++26 展望 | describe、pfr、（execution/linalg/inplace_vector 导览） |

### 第四部 · 纯 Boost 生态

| 章 | 主题 | 库 |
|---|---|---|
| [19](docs/19-text.md) | 字符串工具 | algorithm、tokenizer、lexical_cast、convert、locale |
| [20](docs/20-parsers.md) | 解析器族谱 | spirit、xpressive、parser |
| [21](docs/21-container-core.md) | 容器（上） | container（flat_map/small_vector/static_vector/stable_vector/devector）、circular_buffer、pool、assign |
| [22](docs/22-container-zoo.md) | 容器（下） | multi_index、bimap、ptr_container、intrusive、heap、icl、poly_collection、flyweight、dynamic_bitset、bloom、multi_array |
| [23](docs/23-graph-geometry.md) | 图与几何 | graph、property_map、geometry、polygon |
| [24](docs/24-numeric.md) | 数值计算 | math、multiprecision、rational、units、qvm、crc、safe_numerics、numeric::conversion |
| [25](docs/25-compute.md) | 线代、图像与 GPU | ublas、odeint、interval、accumulators、histogram、gil、compute（GPU 实测） |
| [26](docs/26-modern-tmp.md) | 现代元编程 | mp11、hana、fusion、tti、function_types |
| [27](docs/27-classic-tmp.md) | 古典元编程 | mpl、preprocessor、vmd、metaparse、proto、yap、wave |
| [28](docs/28-network.md) | 网络编程 | asio、beast、url、（mysql/redis/mqtt5 简介） |
| [29](docs/29-process-system.md) | 进程与系统 | process、dll（含插件 DLL 全链路）、interprocess、winapi、endian、iostreams、io、program_options、（python 简介） |
| [30](docs/30-serialization.md) | 序列化与配置 | serialization、property_tree、json |
| [31](docs/31-runtime-structures.md) | 运行时结构 | signals2、statechart、msm、openmethod、type_erasure、scope、conversion |
| [32](docs/32-quality.md) | 工程质量 | test、log、contract、leaf |

### 第五部 · 附录

| 章 | 主题 |
|---|---|
| [33](docs/33-appendix.md) | 全库总表（毕业状态 / std 对应 / 验证状态 / 选型决策树） |

## 未纳入验证的库（需外部环境）

mysql / redis / mqtt5（活服务器）、mpi 系（MS-MPI）、python（解释器链接）——
文档给简介与代码片段。hive：Boost 1.92 未收录（见 18 章更正）。
