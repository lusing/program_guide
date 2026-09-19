# Boost C++ 教程（1.92 全库版）

每个库都有例程和简介，沿 C++ 标准演进时间线讲解。全部 **149 个例程**在本机
编译 + 运行 + 六条判定验证（297/297 全绿），GPU 例程在 RTX 3060 上实测。

## 目录结构

```text
boost/
├── README.md            ← 本文件（索引）
├── build.ps1            ← 统一构建/验证入口（MSVC + Boost 1.92 DLL）
├── docs/                ← 章节正文（33 章）
└── examples/NN_章名/    ← 每库一个自包含例程（149 个 .cpp，含 1 个插件 DLL）
```

## 工具链

- Boost 1.92.0（scoop：`G:\scoop\apps\boost\current`，vc145 DLL 预编译库）
- MSVC 19.51（VS 18 Community，`/std:c++latest` = C++26 草案档）
- CUDA 13.3 OpenCL（25 章 Boost.Compute 用，RTX 3060）

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
