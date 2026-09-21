# 01 · Boost 与 C++ 的二十八年：一部"标准库预备队"史

> 本章无例程。它回答一个问题：**为什么 2026 年学 C++ 还要看 Boost？**
> 答案藏在历史里——Boost 不只是一个第三方库集合，它是 C++ 标准库的**预备队**：
> 库在这里酝酿、打磨、证明自己，然后一茬一茬地"毕业"进 ISO 标准。
> 读懂这条时间线，你同时就读懂了现代 C++ 标准库是怎么长成今天这样的。

## 1.1 Boost 是什么

一句话定位：**Boost 是一个由社区评审驱动、跨平台、以头文件为主的 C++ 库集合，自 1998 年由 Beman Dawes 等人发起，坚持免费开源，充当 C++ 标准库的试验场与预备队。**

三个关键机制决定了它的独特地位：

| 机制 | 长相 | 后果 |
|---|---|---|
| **同行评审** | 想进 Boost 的库要经过公开评审（review），由资深维护者把关 | 质量下限高，API 打磨过，敢用 |
| **与 WG21 的旋转门** | 许多 Boost 作者同时是 C++ 委员会成员/提案作者 | 库的设计直接服务"将来进标准" |
| **一条头文件底线** | 绝大多数库 header-only，少量需要编译 | 门槛极低，`#include` 就能用 |

本教程基于 **Boost 1.92.0**（2025 年 8 月发布），`libs/` 下共 160 个模块，刨去伞形与元模块后约 **150 个实际库**——本教程的目标就是把它们**每一个**都讲到：简介 + 可编译运行的自包含例程 + 与 C++ 标准的对照。

## 1.2 时间线：六个时代

### 蛮荒时代（1998–2005）：C++98 的标准库太薄了

C++98 标准定了语言，但标准库只有 STL 容器/算法、iostream、string、locale 这些。写实用程序缺的东西太多了：没有智能指针、没有正则、没有线程、没有日期时间、连 `uint32_t` 都要靠平台宏。Boost 就是在这个空档里长出来的：`smart_ptr`（1999）、`tuple`、`array`、`bind`、`function`、`regex`、`random`、`any`……今天回头 看，这些名字就是后来标准库的名单。

### TR1 时代（2005–2011）：第一次批量输送

2005 年的 **TR1**（Technical Report on C++ Library Extensions，ISO/IEC TR 19768）是委员会第一次正式从 Boost 成建制"收编"：

> `shared_ptr` · `weak_ptr` · `bind` · `function` · `mem_fn` · `ref` · `tuple` · `array` · `type_traits` · `regex` · `random` · `unordered`（hash 容器）· `result_of` · 数学特殊函数

TR1 是"预览版 C++11"——这些库随后在 2011 年正式进入标准。也就是从这时起，"Boost 是标准库预备队"从比喻变成了制度。

### C++11 大收割（2011）

C++11 从 Boost 及其社区收走的远不止 TR1 名单：

| Boost 库 | C++11 里的样子 |
|---|---|
| `boost::thread`（2003 起） | `std::thread` / `mutex` / `condition_variable` / `future` |
| `boost::chrono` | `std::chrono` |
| `boost::ratio` | `std::ratio` |
| `boost::atomic` | `std::atomic` |
| `BOOST_FOREACH` | range-for（`for (auto& x : v)`） |
| `boost::move` | 右值引用与移动语义（提案主力正是 Boost 社区） |
| `boost::typeof`（`BOOST_AUTO`） | `auto` 类型推导 |
| `boost::static_assert` | `static_assert` |
| `boost::integer`（定宽整数） | `<cstdint>` |
| `boost::exception` | `std::exception_ptr` / `rethrow_exception` |
| `boost::unordered` | `std::unordered_map` / `unordered_set` |

**这一波收割直接消灭了整整一代 Boost 库的日常使用**：`foreach`、`typeof`、`static_assert`、`bind` 的简单用法今天都不该再写。本教程第二部会把它们逐一"验明正身"——哪些该被 `std` 替换、哪些还有残余价值。

### 孵化期（2011–2017）：C++14 小步，C++17 大收

C++14 是个小版本，从 Boost 拿走的东西不多但很典型：`std::exchange`（`boost::core::exchange`）、`std::integer_sequence`、泛型 lambda（直接淘汰了 `Boost.Lambda`/`Boost.Phoenix` 的大部分日常场景）。

真正的第二波大收割发生在 **C++17**：

| Boost 库 | C++17 里的样子 | 血缘 |
|---|---|---|
| `boost::filesystem`（Beman Dawes） | `std::filesystem` | 直系 |
| `boost::optional` | `std::optional` | 直系 |
| `boost::variant` | `std::variant` + `std::visit` | 直系 |
| `boost::any` | `std::any` | 直系 |
| `boost::string_view` | `std::string_view` | 直系 |
| `boost::thread`（读写锁部分） | `std::shared_mutex` | 直系 |
| `boost::math`（gcd/lcm） | `std::gcd` / `std::lcm` | 直系 |
| `boost::functional`（`not_fn`） | `std::not_fn` | 直系 |
| `boost::container`（pmr） | `std::pmr` 内存资源 | 血缘 |

### C++20：ranges 与协程（2020）

C++20 有两件大事与 Boost 有直接血缘，还有一批平行进化的：

| 特性 | 与 Boost 的关系 |
|---|---|
| `std::ranges` | **直系**：`boost::range` 的作者 Eric Niebler 亲手把 range_ex 写成了标准提案，二十年的长跑 |
| 协程（`co_await`） | **血缘**：语言级协程建立在 `Boost.Context` 二十年打磨的栈切换技术上；`Boost.Coroutine2` 是最好的对照物 |
| `std::format` | **平行进化**：来自第三方 fmt 库（Victor Zverovich），**不是** Boost.Format——但毕业效果一样：日常格式化该用 `std::format` 了 |
| `std::span` | 平行进化（GSL 谱系），淘汰 `boost::core::span` 的使用场景 |
| `std::endian` | 直系（`boost::endian` 的探测部分） |
| `std::jthread` / `stop_token` | 血缘（`boost::thread` 的中断机制） |
| `std::atomic::wait/notify`、`semaphore`、`latch`、`barrier` | 直系/血缘（`boost::atomic`、`boost::thread` 早就有） |

> **教学点**："毕业"有三种血缘。**直系**（std API 就是照着 Boost 长的，如 `filesystem`/`optional`）；**血缘影响**（设计思想进入标准但 API 重写，如协程）；**平行进化**（std 特性来自第三方或全新设计，但客观上让某个 Boost 库失去日常价值，如 `std::format` vs `Boost.Format`）。本教程的"毕业档案"会逐库标注这三种关系——分不清这个，选型就会犯"还在用已被替代的旧库"或"误以为新标准能替代它其实不能"两种错。

### C++23/26：仍在进行的输送

| 特性 | 与 Boost 的关系 |
|---|---|
| `std::stacktrace`（C++23） | **直系**：Antony Polukhin 的 Boost.Stacktrace 几乎原样进标准 |
| `std::optional` 单子操作（C++23） | 直系：`and_then`/`or_else`/`transform`，`boost::optional` 2014 年就有 |
| `std::flat_map`/`flat_set`（C++23） | 直系：`boost::container::flat_map` 是祖先 |
| `std::generator`（C++23） | 血缘：`Boost.Coroutine2` 的同步生成器语义 |
| `std::to_underlying`（C++23） | 直系（`boost::utility`） |
| `std::expected`（C++23） | 平行进化：提案参考了 `tl::expected`；**Boost.Outcome** 是同题的另一种答案（更重、更显式） |
| `std::mdspan`（C++23） | 平行进化（Kokkos 谱系），Boost 反而没有——本教程用 `std::mdspan` 对照 `boost::multi_array` |
| 反射（P2996，C++26） | `Boost.Describe` 与 `Boost.PFR` 是"穷人反射"，反射落地后它们的价值重估 |
| `std::execution`（C++26） | 血缘：asio 作者 Chris Kohlhoff 深度参与 P2300，asio 的执行模型是其精神源头 |
| `std::linalg`（C++26） | 血缘：`boost::ublas` 是 C++ 线代库的祖父辈 |
| `std::inplace_vector`（C++26） | 直系：`boost::container::static_vector` |
| `std::hive`（提案中） | 直系：`boost::container::hive`（作者 Matt Bentley 同时是提案人） |

还有一条容易忽略的**反向通道**：**Boost.Compat** 把新标准特性（`function_ref`、`move_only_function`、`latch`、`to_array`……）回移植到老标准——对需要支持 C++11/14 老代码库的团队，这是 Boost 在"毕业"体系之外的独立价值。

## 1.3 毕业波次总表

把上面的时间线压缩成一张速查表（**本教程的地图，建议收藏**）：

| 标准 | 从 Boost 毕业的代表 | 平行进化淘汰的 | 仍在 Boost 的代表 |
|---|---|---|---|
| C++11 | shared_ptr、thread、chrono、atomic、unordered、tuple、array、function、bind、regex、random、type_traits、foreach→range-for、typeof→auto、static_assert、move | — | MultiIndex、Spirit、Asio、Geometry |
| C++14 | exchange、integer_sequence | 泛型 lambda 淘汰 Lambda/Phoenix 日常用法 | — |
| C++17 | filesystem、optional、variant、any、string_view、shared_mutex、gcd/lcm、not_fn | `std::to_chars`（无 Boost 血缘，淘汰 `lexical_cast` 数字场景） | MultiIndex、Fusion、Hana |
| C++20 | ranges（直系）、endian、atomic wait | format（fmt 系）、span（GSL 系）淘汰对应用法 | Asio、Beast、JSON、URL |
| C++23 | stacktrace、optional 单子、flat_map、to_underlying | expected（tl 系）、mdspan（Kokkos 系） | Outcome、LEAF、Describe、PFR |
| C++26 | inplace_vector（static_vector）、（hive 提案中） | reflection 将重估 Describe/PFR | std::execution 血缘在 asio |

## 1.4 今天的 Boost 还剩什么价值

把 150 个库按"毕业状态"分三类，就得到 2026 年的使用决策树：

```text
                    ┌─ 该库直系毕业且 std 实现成熟（filesystem/optional/variant…）
   已进标准？ ──是──┤
        │           └─ 毕业了但 std 覆盖不全？
        │                （atomic 的 wait、thread 的中断、regex 的性能…）
        │                → 看 18.4 节"毕业后仍值得用 Boost"清单
        │
        └─否──┬─ 领域里没有 std 对应物（MultiIndex、Spirit、Geometry、Hana…）
              │    → Boost 就是最佳选择之一
              └─ 依赖外部服务（MySQL/Redis/MQTT/mpi…）
                   → 用不用 Boost 看生态，本教程给简介与代码片段
```

具体到日常选型，三条铁律：

1. **直系毕业且 std 成熟的，新代码一律 std**。`std::optional`、`std::filesystem`、`std::variant`……没有理由再引入 Boost 版本。
2. **领域空白，Boost 常是第一候选**。多索引容器、表达式模板解析器、几何算法、异构元编程——标准库里没有对应物，Boost 的这些库是 C++ 生态的事实标准。
3. **跨标准代码库，Compat 是桥**。代码库要同时支持 C++11 和 C++20？`boost/compat/function_ref.hpp` 让你在两边用同一套代码。

## 1.5 Boost 1.92 全景地图

本教程覆盖的约 150 个库按领域分成八块（编号是章号）：

| 领域 | 库（示例） | 章号 |
|---|---|---|
| 语言基建 | smart_ptr、function 族、tuple、type_traits、config… | 03–05 |
| 经典毕业生 | regex、random、chrono 族、unordered、thread、atomic、error 族 | 06–11 |
| 现代毕业生 | optional/variant/any/string_view、filesystem、format、range 族、协程族、C++23/26 波次 | 12–18 |
| 文本与解析 | algorithm、tokenizer、lexical_cast、convert、locale、spirit、xpressive、parser | 19–20 |
| 容器 | container 家族、multi_index、bimap、intrusive、icl、graph、geometry… | 21–23 |
| 数值与科学 | math、multiprecision、units、ublas、odeint、histogram、compute（GPU）… | 24–25 |
| 元编程 | mp11、hana、fusion、mpl、preprocessor、proto、describe、pfr… | 26–27 |
| 系统与工程 | asio、beast、url、process、dll、interprocess、serialization、json、signals2、test、log… | 28–32 |

完整清单（含每个库的一句话简介、毕业状态、验证状态）在[第 33 章附录](33-appendix.md)。

## 1.6 如何读本教程

- **每库一节**：简介 → 例程（完整代码）→ 实际运行输出 → **毕业档案**（std 对应 / 血缘 / 引入标准 / 选型建议）。
- **例程可复现**：全部例程通过 `build.ps1` 在本机编译运行，六条判定（编译零告警、退出码 0、stderr 空、stdout 非空无控制字符、含"自检通过"标记）全绿后才写进文档。
- **两个视角**：Boost 用法是"是什么"，毕业档案是"在 2026 年的 C++ 里该怎么摆它的位置"。
- **不验证的库**（要活服务器或 MS-MPI/OpenCL 之外的并行环境）：文档给简介与代码片段，并明确标注，不假装跑过。

---


> 下一章：[02 · 环境与构建](02-setup.md) ｜ 返回：[README](../README.md)
