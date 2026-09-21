# 33 · 附录：全库总表

Boost 1.92 的 160 个模块，刨去伞形/元模块后约 150 个实际库，全景如下。**毕业状态**六档：

- ✅ **已毕业**：std 有直系对应，新代码用 std
- 🔁 **半毕业**：std 有对应但覆盖不全（boost 版仍有独有价值）
- ⭐ **独占**：std 无对应，boost 是最佳答案之一
- 🪦 **已淘汰**：被语言特性/新设计取代，只存在于维护场景
- 📖 **简介**：需要外部环境，文档给简介与片段（未纳入六条判定）
- ⬜ **元模块**：不是给人直接用的库

**推荐度**：●（默认考虑）/ ◐（特定场景）/ ○（了解即可）。**验证**：✓ = 本教程例程通过六条判定。

## A. 按毕业状态排列

### ✅ 已毕业（新代码一律 std）——15 库

| 库 | std 对应 | 章 | 验证 |
|---|---|---|---|
| smart_ptr（90%） | `std::smart_ptr` 全家（C++11） | [03](03-smartptr.md) | ✓ |
| function/bind | `std::function`/`std::bind`/lambda | [04](04-function.md) | ✓ |
| tuple/array/static_assert/type_traits/typeof/foreach | C++11 语言与库大波 | [05](05-langbase.md) | ✓ |
| regex | `std::regex`（热路径建议换 Boost.Regex——见 🔁） | [06](06-regex-random.md) | ✓ |
| random | `std::random` | [06](06-regex-random.md) | ✓ |
| chrono/ratio | `std::chrono`/`std::ratio` | [07](07-chrono.md) | ✓ |
| unordered | `std::unordered_*`（flat 系列见 ⭐） | [08](08-unordered.md) | ✓ |
| thread | `std::thread` + C++20 jthread/stop_token | [09](09-thread.md) | ✓ |
| atomic | `std::atomic` | [10](10-atomic.md) | ✓ |
| system | `std::error_code` | [11](11-error.md) | ✓ |
| optional/variant/any/string_view | C++17 四杰 | [12](12-vocabulary.md) | ✓ |
| filesystem | `std::filesystem` | [13](13-filesystem.md) | ✓ |
| range/iterator（大部分） | C++20 ranges/views | [15](15-ranges.md) | ✓ |

### 🔁 半毕业（std 有对应，boost 版有残余价值）——14 库

| 库 | std 对应 | boost 的残余价值 | 章 | 验证 |
|---|---|---|---|---|
| smart_ptr（intrusive_ptr） | 无对应 | ⭐ 计数长在对象里 | [03](03-smartptr.md) | ✓ |
| optional | `std::optional` | `optional<T&>`；单子操作 std 到 C++23 才有 | [12](12-vocabulary.md) | ✓ |
| variant | `std::variant` | 递归变体 | [12](12-vocabulary.md) | ✓ |
| date_time | C++20 chrono 日历 | API 更顺手的老牌 | [07](07-chrono.md) | ✓ |
| regex | `std::regex` | 性能与 Unicode | [06](06-regex-random.md) | ✓ |
| charconv | `std::to_chars` | 全平台补完 + 扩展浮点 | [17](17-cpp23.md) | ✓ |
| lexical_cast | stoi/to_string | 泛型 any-to-string | [19](19-text.md) | ✓ |
| concept_check | C++20 concepts | 老标准支持 | [15](15-ranges.md) | ✓ |
| iterator | C++20 views 覆盖大半 | zip/permutation 迭代器 | [15](15-ranges.md) | ✓ |
| function_types | callable_traits/std | 反向拼装函数类型 | [26](26-modern-tmp.md) | ✓ |
| assign | 初始化列表 | 已死透，历史课 | [21](21-container-core.md) | ✓ |
| align | `std::aligned_alloc`（部分） | align_up/down/is_aligned 无 std 对应 ⭐ | [05](05-langbase.md) | ✓ |
| atomic/thread 的新特性 | C++20 各条 | 老标准支持 | [09](09-thread.md)/[10](10-atomic.md) | ✓ |
| exception | exception_ptr | error_info 行李机制 ⭐ 无 std 对应 | [11](11-error.md) | ✓ |

### ⭐ 独占（std 无对应，boost 是第一候选）——60+ 库

| 库 | 一句话 | 章 | 验证 |
|---|---|---|---|
| hof | compose/partial/pipable/match | [04](04-function.md) | ✓ |
| lambda2 | STL 一行谓词占位符 | [04](04-function.md) | ✓ |
| phoenix | 函数式 EDSL（运行期组装） | [04](04-function.md) | ✓ |
| parameter | 命名参数（乱序+省略） | [04](04-function.md) | ✓ |
| compat | 新 std 特性回移植（反向毕业） | [04](04-function.md) | ✓ |
| functional | overloaded_function 等 | [04](04-function.md) | ✓ |
| callable_traits | 解剖可调用物签名 | [04](04-function.md) | ✓ |
| integer | 按位宽/值域选整型 | [05](05-langbase.md) | ✓ |
| predef | 版本级编译器/OS 探测 | [05](05-langbase.md) | ✓ |
| type_index | typeid 完全体（跨 DLL/可读名） | [05](05-langbase.md) | ✓ |
| assert | 三档断言（库作者向） | [05](05-langbase.md) | ✓ |
| config | 可移植性探测宏地基 | [05](05-langbase.md) | ✓ |
| container_hash | hash_combine/容器哈希 | [08](08-unordered.md) | ✓ |
| hash2 | 第二代哈希（算法可换/种子/流式） | [08](08-unordered.md) | ✓ |
| throw_exception | noexcept 世界的统一抛出口 | [11](11-error.md) | ✓ |
| static_string | 定容栈上字符串 | [12](12-vocabulary.md) | ✓ |
| uuid | v4/v5 标识符 | [12](12-vocabulary.md) | ✓ |
| logic | 三值逻辑 | [12](12-vocabulary.md) | ✓ |
| variant2 | variant 的 C++11 重制 | [12](12-vocabulary.md) | ✓ |
| nowide | Windows 的 UTF-8 总开关 | [13](13-filesystem.md) | ✓ |
| stl_interfaces | 迭代器/视图骨架填空 | [15](15-ranges.md) | ✓ |
| sort | spreadsort/pdqsort 性能特供 | [15](15-ranges.md) | ✓ |
| context/coroutine/coroutine2 | 栈协程家族 | [16](16-coroutines.md) | ✓ |
| fiber | 用户态线程 | [16](16-coroutines.md) | ✓ |
| cobalt | C++20 协程 × asio | [16](16-coroutines.md) | ✓ |
| stacktrace | 栈回溯（C++23 直系毕业中） | [17](17-cpp23.md) | ✓ |
| decimal | 十进制浮点 | [17](17-cpp23.md) | ✓ |
| outcome | result/ TRY 错误处理 | [17](17-cpp23.md) | ✓ |
| describe | 宏注册元数据（穷人反射） | [18](18-cpp26.md) | ✓ |
| pfr | 零注册聚合透视 | [18](18-cpp26.md) | ✓ |
| algorithm（字符串部） | split/join/trim/i 系 | [19](19-text.md) | ✓ |
| tokenizer | 流式分词 | [19](19-text.md) | ✓ |
| convert | 可配置转换 | [19](19-text.md) | ✓ |
| locale | Unicode 归一化/大小写/翻译 | [19](19-text.md) | ✓ |
| spirit | EBNF 即 C++ | [20](20-parsers.md) | ✓ |
| xpressive | 静态正则 | [20](20-parsers.md) | ✓ |
| parser | Spirit 的 C++20 重制 | [20](20-parsers.md) | ✓ |
| container | flat_map/small_vector/static_vector/devector/stable_vector | [21](21-container-core.md) | ✓ |
| circular_buffer | 环形缓冲 | [21](21-container-core.md) | ✓ |
| pool | 同型小块批发 | [21](21-container-core.md) | ✓ |
| multi_index | 一容器 N 索引 | [22](22-container-zoo.md) | ✓ |
| bimap | 双向映射 | [22](22-container-zoo.md) | ✓ |
| intrusive | 侵入式容器（零分配/一物多器） | [22](22-container-zoo.md) | ✓ |
| heap | 优先队列超市（可迭代/可合并/句柄调整） | [22](22-container-zoo.md) | ✓ |
| icl | 区间容器 | [22](22-container-zoo.md) | ✓ |
| flyweight | 享元库化 | [22](22-container-zoo.md) | ✓ |
| dynamic_bitset | 运行期长度位集 | [22](22-container-zoo.md) | ✓ |
| bloom | 概率集合查询 | [22](22-container-zoo.md) | ✓ |
| multi_array | 拥有数据的多维数组 | [22](22-container-zoo.md) | ✓ |
| poly_collection | 按型分段的多态容器 | [22](22-container-zoo.md) | ✓ |
| graph | 图算法圣经（BGL） | [23](23-graph-geometry.md) | ✓ |
| property_map | 属性的泛型接口 | [23](23-graph-geometry.md) | ✓ |
| geometry | 计算几何（含球面） | [23](23-graph-geometry.md) | ✓ |
| polygon | 曼哈顿几何 | [23](23-graph-geometry.md) | ✓ |
| math | 特殊函数/统计分布/常量 | [24](24-numeric.md) | ✓ |
| multiprecision | 超精度数值 | [24](24-numeric.md) | ✓ |
| rational | 精确分数 | [24](24-numeric.md) | ✓ |
| units | 量纲安全 | [24](24-numeric.md) | ✓ |
| qvm | 3D 数学 | [24](24-numeric.md) | ✓ |
| crc | 校验和 | [24](24-numeric.md) | ✓ |
| safe_numerics | 算术 UB 解毒剂 | [24](24-numeric.md) | ✓ |
| ublas | BLAS 线代（C++26 linalg 血脉） | [25](25-compute.md) | ✓ |
| odeint | 微分方程求解器 | [25](25-compute.md) | ✓ |
| interval | 区间算术 | [25](25-compute.md) | ✓ |
| accumulators | 流式统计 | [25](25-compute.md) | ✓ |
| histogram | 工业级直方图 | [25](25-compute.md) | ✓ |
| gil | 泛型图像 | [25](25-compute.md) | ✓ |
| compute | OpenCL 封装（GPU 实测） | [25](25-compute.md) | ✓ |
| mp11 | 现代 TMP 事实标准 | [26](26-modern-tmp.md) | ✓ |
| hana | 编译期 STL | [26](26-modern-tmp.md) | ✓ |
| fusion | 结构体↔序列桥 | [26](26-modern-tmp.md) | ✓ |
| tti | 类型体检 | [26](26-modern-tmp.md) | ✓ |
| preprocessor | 预处理器元编程（X 宏仍活） | [27](27-classic-tmp.md) | ✓ |
| vmd | 变参宏数据 | [27](27-classic-tmp.md) | ✓ |
| metaparse | 编译期字符串解析 | [27](27-classic-tmp.md) | ✓ |
| yap | Proto 的现代继任 | [27](27-classic-tmp.md) | ✓ |
| wave | 可编程预处理器 | [27](27-classic-tmp.md) | ✓ |
| asio | 异步 IO 事实标准（C++26 execution 血脉） | [28](28-network.md) | ✓ |
| beast | HTTP/WebSocket | [28](28-network.md) | ✓ |
| url | RFC 3986 完整实现 | [28](28-network.md) | ✓ |
| process | 子进程管理（v2） | [29](29-process-system.md) | ✓ |
| dll | 运行期加载共享库 | [29](29-process-system.md) | ✓ |
| interprocess | 共享内存/命名同步 | [29](29-process-system.md) | ✓ |
| winapi | Win32 薄封装 | [29](29-process-system.md) | ✓ |
| endian | 字节序双件套 | [29](29-process-system.md) | ✓ |
| iostreams | 流过滤器（gzip 家族） | [29](29-process-system.md) | ✓ |
| program_options | 命令行/配置解析 | [29](29-process-system.md) | ✓ |
| serialization | 对象持久化（版本化） | [30](30-serialization.md) | ✓ |
| property_tree | 一树四格式 | [30](30-serialization.md) | ✓ |
| json | 专而快的 JSON（DOM/SAX） | [30](30-serialization.md) | ✓ |
| signals2 | 线程安全信号-槽 | [31](31-runtime-structures.md) | ✓ |
| statechart | UML 状态机 | [31](31-runtime-structures.md) | ✓ |
| msm | 极速状态机 | [31](31-runtime-structures.md) | ✓ |
| openmethod | 多动态类型分派 | [31](31-runtime-structures.md) | ✓ |
| type_erasure | 概念级 any（零侵入多态） | [31](31-runtime-structures.md) | ✓ |
| scope | 作用域守卫全家福 | [31](31-runtime-structures.md) | ✓ |
| conversion | 转型三兄弟 | [31](31-runtime-structures.md) | ✓ |
| test | 单元测试 | [32](32-quality.md) | ✓ |
| log | 工业级日志 | [32](32-quality.md) | ✓ |
| contract | DbC 三件套 | [32](32-quality.md) | ✓ |
| leaf | 轻量错误负载 | [32](32-quality.md) | ✓ |
| timer | RAII 计时器 | [07](07-chrono.md) | ✓ |

### 🪦 已淘汰（历史课/维护场景）——6 库

| 库 | 死因 | 章 |
|---|---|---|
| lambda | C++11 语言级 lambda | [04](04-function.md)（附对比） |
| local_function | lambda + 自递归惯用法 | [04](04-function.md)（附对比） |
| mpl | mp11/hana（词汇仍活在生态里） | [27](27-classic-tmp.md) |
| proto | 维护模式（→ yap） | [27](27-classic-tmp.md) |
| assign | C++11 初始化列表 | [21](21-container-core.md) |
| format（日常用途） | C++20 std::format（fmt 血统，平行淘汰） | [14](14-format.md) |

### 📖 简介（需外部环境，未纳入验证）——7 库

| 库 | 需要什么 | 章 |
|---|---|---|
| mysql | 活 MySQL 服务器 | [28](28-network.md) |
| redis | 活 Redis | [28](28-network.md) |
| mqtt5 | MQTT broker | [28](28-network.md) |
| mpi / graph_parallel / property_map_parallel | MS-MPI 运行时 | — |
| python | Python 开发库链接（本流水线未覆盖） | [29](29-process-system.md) |

### ⬜ 元模块（基础设施，非直接使用）——6 项

`headers`（安装元数据）、`detail`（内部实现）、`numeric`（伞形：conversion/interval/odeint/ublas 已单列）、`compat`（已作为库列入 🔁 表）、`config`/`predef`（已作为库列入）、`build`/`bcp` 等工具。

## B. 按 C++ 标准演进速查

| 标准 | 从 Boost 毕业的 | 平行进化淘汰的 |
|---|---|---|
| TR1（2005） | shared_ptr、bind、function、tuple、array、regex、random、type_traits、unordered |
| C++11 | thread、chrono、ratio、atomic、move、typeof→auto、static_assert、foreach→range-for、exception_ptr |
| C++14 | exchange、integer_sequence | 泛型 lambda 淘汰 Lambda/Phoenix 日常用法 |
| C++17 | filesystem、optional、variant、any、string_view、shared_mutex | std::to_chars（lexical_cast 数字场景） |
| C++20 | ranges（直系）、endian、atomic wait | format（fmt 系）、span（GSL 系） |
| C++23 | stacktrace（直系）、optional 单子、flat_map、to_underlying | expected（tl 系）、mdspan（Kokkos 系） |
| C++26 | inplace_vector（static_vector）、（hive 提案中） | 反射将重估 Describe/PFR；execution 血脉在 asio |

## C. 本教程的验证边界

- **149 个例程**全部通过六条判定（编译零告警 / 退出码 0 / stderr 空 / stdout 非空无控制字符 / 含"自检通过"）。
- **未验证**的 7 库（mysql/redis/mqtt5/mpi 系/python）因需要活外部服务——文档给简介与代码片段，不假装跑过。
- **hive 更正**：成文时核实 Boost 1.92 **未收录** hive（std::hive 提案的参考实现尚未入 Boost），相关导览已在 18/21 章更正。
- 工具链：Boost 1.92.0（scoop，vc145 DLL）+ MSVC 19.51（VS 18，`/std:c++latest`）+ CUDA 13.3 OpenCL（RTX 3060 实测）。

## D. 一页选型决策树

```text
要用某个能力？
├─ std 有直系对应（附录 A ✅ 表）→ std，无悬念
├─ 常用横切能力 → algorithm 字符串部 / mp11 / format→std::format
├─ 数据结构特需 → 22 章动物园选型表 / 21 章容器选型表
├─ 并发/异步 → std::jthread + asio（+cobalt 协程糖）
├─ 错误处理 → expected(值) / Outcome(值+码) / LEAF(异常) / error_code(码)
├─ 解析 → 简单 regex；结构化 Spirit/Parser；配置 ptree/json
└─ 老标准支持 → Compat 回移植 + 各库的 C++11/14 模式
```

---


**教程完**。回到 [01 · 二十八年史](01-overview.md) 重看那条时间线——现在每个名字你都有了手感。

> 上一章：[32 · 工程质量](32-quality.md) ｜ 返回：[README](../README.md)
