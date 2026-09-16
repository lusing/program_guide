# 23 · 测试、调试与工具生态

> 对应示例：`examples/23_tooling/`

## 23.1 十行单测框架：assert 的极限用法

```cpp
struct TestCase {
    std::string name;
    std::function<void()> run;
};

int run_tests() {
    std::vector<TestCase> tests{
        {"空串返回空", [] { assert(slugify("") == ""); }},
        {"标点转连字符", [] { assert(slugify("Hello, C++ World!") == "hello-c-world"); }},
        {"首尾不留连字符", [] { assert(slugify("--Hi--") == "hi"); }},
        {"非 ASCII 字节剔除", [] { assert(slugify("你好") == ""); }},
    };
    for (const auto& t : tests) {
        t.run();  // assert 失败会中止（真实框架会捕获并继续，见下）
        std::println("[PASS] {}", t.name);
    }
    return static_cast<int>(tests.size());
}
```

"名字 + 断言 lambda" 的表驱动测试：测试数据成为**声明式清单**，加用例只加一行。被测对象 `slugify`（把标题变 URL 友好串）是**纯函数**——输入定输出、无状态无 IO，这是可测性的第一原理：**把逻辑切出来做成纯函数，测试就免费**。

这个十行框架的短板也要诚实说：assert 失败直接中止（后面的用例不跑了）、没有失败明细（要靠断言表达式自己会打印）、没有分组/过滤。**真实项目三选一**：GoogleTest（事实标准、生态最全）、Catch2（单头文件起步优雅）、doctest（编译最快、本教程气质）。零依赖教学才手造，思想完全平移。

顺带一提"非 ASCII 字节剔除"用例：slugify 对 `"你好"` 返回空——每个 UTF-8 字节都非字母数字（`isalnum` 对 ≥0x80 返回 0），顺带演示了**按字节处理的 ASCII 假设**（第 22 章 22.4 的主题在测试里的样子）。还要注意 `std::isalnum(uc)` 前的 `static_cast<unsigned char>`——char 为负时传给 isalnum 是 UB（22.4 第 2 点的现场）。

## 23.2 assert 的正确姿势

第 07 章立了规矩，测试语境再补三条：**断言不变量，不校验输入**（用户数据错是 expected/异常的事）；**表达式必须纯净**（NDEBUG 下整条消失，副作用跟着消失）；**文案用 `&& "中文说明"` 惯用法**（失败时打印人话）。debug 构建跑全量 assert，release 构建 NDEBUG 静默提速——两副面孔是设计而非缺陷。

## 23.3 调试器：别再 print 了（偶尔可以）

VS 调试 C++ 的最小闭环（其它 IDE 同构）：**断点**（F9，点行号左侧）→ **F10 单步过**（不进函数）/ **F11 单步入**（进函数）→ **监视窗口**（选中变量右键添加监视，实时看值）→ **调用堆栈窗口**（看"怎么到这的"——双击帧跳上去）。条件断点（右键断点设条件）在"循环第 8001 次才炸"时救命。

**print 调试法**的正当场景依然存在：并发时序（断点会停下所有线程、改变节奏——heisenbug）、一次性探针、无调试器的环境。纪律：探针输出带**位置前缀**（`[parse] line=42`），修完就删。第 22 章的 stacktrace 是它的进化版——出错自动打印调用链：

```cpp
auto st = std::stacktrace::current();
std::println("调用栈帧数 = {}", st.size());        // 帧数（确定性，可用于断言）
std::println("{}", std::to_string(st[0]));          // 单帧描述（含符号+地址，因环境而异）
```

## 23.4 并发调试：缩小爆炸半径

数据竞争的恶意在于**不可复现**（加 print 就好、上调试器就消失、CI 上从不崩、客户现场天天崩）。务实策略：

1. **缩小到单线程可测**：把并发结构（队列+锁）与业务逻辑（纯函数）分层——逻辑层单线程测试全覆盖，并发层只验"调度正确性"（第 19/20 章示例的模式）；
2. **确定性复现装置**：固定线程数、注入 sleep 强制交错（`std::this_thread::sleep_for` 手工调度）；
3. **工具**：ThreadSanitizer（TSan）是竞争检测神器——Clang/GCC 有，**MSVC 至今没有**（诚实标注：Windows 上可用 clang-cl 构建 + TSan）；静态分析 `/analyze` 能抓部分锁序问题；
4. **日志加序号与线程 id**：事后拼时序（`[t3][seq 1287] lock acquired`）。

## 23.5 构建生态：CMake 与 vcpkg 一瞥

单文件教程不需要构建系统，真实项目三件套认识骨架：

```cmake
# CMakeLists.txt —— 最小可用的 C++23 工程
cmake_minimum_required(VERSION 3.28)
project(demo CXX)
set(CMAKE_CXX_STANDARD 23)          # 对应 /std:c++latest 与 -std=c++23
add_executable(demo main.cpp)
```

CMake 生成器跨平台（Windows 出 VS 工程/sln，Linux 出 make/ninja），三行把"教 24 章的编译参数"变成各平台正确形态。**依赖管理用 vcpkg**：`vcpkg install fmt` 装库、CMake 一行 `find_package(fmt CONFIG REQUIRED)` 链接——源码树之外的世界（本教程零依赖，故只用标准库）。

跨编译器差异速查（吸收旧指南的编译器支持章）：

| | MSVC | GCC/Clang |
|---|---|---|
| 语言标准 | `/std:c++latest`（还有 c++20 等档位） | `-std=c++23` |
| 源码编码 | `/utf-8`（否则按 GBK/ANSI 猜） | 默认 UTF-8 |
| 模块接口 | `.ixx` + `/interface` | `.cppm` + `-fmodules-ts`/`-std=c++20` |
| 一致性 | `/permissive-` 建议显式 | 默认严格 |

**以本机实测为准、查 cppreference 矩阵**（第 01 章的忠告在生态层同样成立）。

## 23.6 坑位清单

1. **测试依赖执行顺序**：用例 B 依赖用例 A 改过的全局状态——单跑就挂。每个用例自建环境（构造即清理，RAII 测试）。
2. **调 Release 版查逻辑 bug**：优化重排+无 assert，行为和 Debug 对不上。逻辑 bug 先在 Debug 复现；性能问题才用 Release profile。
3. **CMake 忘设 C++ 标准**：默认低标准（14/17），C++20/23 语法直接编译错——`set(CMAKE_CXX_STANDARD 23)` 是新工程第一件事。
4. **只测 happy path**：空输入、非法输入、边界值（0、-1、max）才是 bug 聚居地——示例四个用例三个是边界的。
5. **静态分析当摆设**：`/analyze`（MSVC 内建）和 clang-tidy 能抓空指针/泄漏/锁问题——CI 里跑一次的成本远低于事故。
6. **并发 bug 靠"多跑几次"验证修复**：跑了十遍没崩≠修好（概率事件）。修复要有**机理解释**（哪条竞争被哪把锁/原子消掉了），再跑压测确认。
