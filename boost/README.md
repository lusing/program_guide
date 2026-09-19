# Boost C++ 教程（1.92 全库版）

每个库都有例程和简介，沿 C++ 标准演进时间线讲解。所有例程在本机
编译 + 运行 + 六条判定验证（见 [docs/02-setup.md](docs/02-setup.md)）。

## 目录结构

```text
boost/
├── README.md            ← 本文件（索引）
├── build.ps1            ← 统一构建/验证入口（MSVC + Boost 1.92 DLL）
├── docs/                ← 章节正文（33 章）
└── examples/NN_章名/库.cpp   ← 每库一个自包含例程
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
pwsh ./build.ps1 -Clean        # 清理 build/
```

## 章节目录

### 第一部 · 舞台

| 章 | 主题 |
|---|---|
| [01](docs/01-overview.md) | Boost 与 C++ 的二十八年：一部"标准库预备队"史 |
| [02](docs/02-setup.md) | 环境与构建：把工具链立起来 |

### 第二部 · TR1 与 C++11——黄金毕业潮

| 章 | 主题 | 库 |
|---|---|---|
| 03 | 所有权革命 | smart_ptr |
| 04 | 函数即对象 | function、bind、functional、lambda、lambda2、hof、callable_traits、local_function、phoenix、parameter、compat |
| 05 | 语言基建先行者 | tuple、array、static_assert、type_traits、typeof、integer、utility、core、assert、config、predef、foreach、align、type_index |
| 06 | 正则与随机 | regex、random |
| 07 | 时间与日历 | date_time、chrono、ratio、timer |
| 08 | 无序与哈希 | unordered、container_hash、hash2 |
| 09 | 多线程第一课 | thread |
| 10 | 原子操作 | atomic |
| 11 | 错误处理基石 | exception、system、throw_exception |

### 第三部 · C++17/20/23/26 现代波次

| 章 | 主题 | 库 |
|---|---|---|
| 12 | 词汇类型五虎 | optional、variant、variant2、any、string_view、static_string、uuid、logic |
| 13 | 文件系统与编码 | filesystem、nowide |
| 14 | 格式化 | format |
| 15 | 范围与迭代器 | range、iterator、stl_interfaces、concept_check、sort |
| 16 | 协程时代 | context、coroutine、coroutine2、cobalt、fiber |
| 17 | C++23 波次 | charconv、stacktrace、decimal、outcome、（std::mdspan 对照） |
| 18 | C++26 展望 | describe、pfr、（execution/linalg/hive 展望） |

### 第四部 · 纯 Boost 生态

| 章 | 主题 | 库 |
|---|---|---|
| 19 | 字符串工具 | algorithm、tokenizer、lexical_cast、convert、locale |
| 20 | 解析器族谱 | spirit、xpressive、parser |
| 21 | 容器（上） | container（flat_map/small_vector/static_vector/stable_vector/devector）、circular_buffer、pool、assign |
| 22 | 容器（下） | multi_index、bimap、ptr_container、intrusive、heap、icl、poly_collection、flyweight、dynamic_bitset、bloom、multi_array |
| 23 | 图与几何 | graph、property_map、geometry、polygon |
| 24 | 数值计算 | math、multiprecision、rational、units、qvm、crc、safe_numerics、numeric/conversion |
| 25 | 线代、图像与 GPU | ublas、odeint、interval、accumulators、histogram、gil、compute |
| 26 | 现代元编程 | mp11、hana、fusion、tti、function_types |
| 27 | 古典元编程 | mpl、preprocessor、vmd、metaparse、proto、yap、wave |
| 28 | 网络编程 | asio、beast、url、（mysql/redis/mqtt5 简介） |
| 29 | 进程与系统 | process、dll、interprocess、winapi、endian、iostreams、io、program_options、（python 尝试） |
| 30 | 序列化与配置 | serialization、property_tree、json |
| 31 | 运行时结构与散珠 | signals2、statechart、msm、openmethod、type_erasure、scope、scope_exit、conversion、sort |
| 32 | 工程质量 | test、log、contract、leaf |

### 第五部 · 附录

| 章 | 主题 |
|---|---|
| 33 | 全库总表（毕业状态 / std 对应 / 验证状态 / 推荐度） |

> 状态：教程重写中，章节随批次落地；已落地章节的链接会逐步更新。
