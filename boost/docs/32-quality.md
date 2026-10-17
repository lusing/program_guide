# 32 · 工程质量：test / log / contract / leaf

> 对应示例：`examples/32_quality/`（4 个例程）

让代码"可信"的四件套：测试、日志、契约、错误负载。

## 32.1 Boost.Test（2001）：单元测试老牌

```cpp
void slug_basic() { BOOST_TEST(slugify("Hello World") == "hello-world"); }
bool/test_suite* init_unit_test(int, char*[]) { master_test_suite().add(BOOST_TEST_CASE(...)); }
int rc = boost::unit_test::unit_test_main(&init_unit_test, argc, argv);
```

运行输出（`test.cpp`；例程把日志/报告 sink 重定向到 stdout 以满足本教程"stderr 恒空"判定）：

```text
Running 3 test cases...
  [夹具] 安装（构造）
G:/code/guide/boost/examples/32_quality/test.cpp(41): warning: in "assertions_demo": WARN 档故意失败：只留日志，不计数不退出
这是 BOOST_TEST_MESSAGE：默认日志级别下不显示
  [夹具] 清理（析构）

*** No errors detected
自检通过
```

**断言分级三档**（命名的中间层是级别，尾部是断言种类）：

| 级别 | 失败后果 | 用在 |
|---|---|---|
| `BOOST_WARN_*` | 留一条日志，**不计数不退出** | 非关键观察（输出里的故意失败就是它） |
| `BOOST_CHECK_*` | 计入错误数，继续跑后续断言 | 默认选择 |
| `BOOST_REQUIRE_*` | 计错并**中止本用例** | 后续断言依赖此前结果时 |

断言种类是全家桶：`EQUAL/NE/LT/LE/GT/GE`、浮点容差 `CLOSE`/`CLOSE_FRACTION`、`SMALL`（绝对误差）、`THROW`/`NO_THROW`、`MESSAGE`（给任何断言附加说明）、`BOOST_TEST_MESSAGE`（纯通知，默认日志级别下不显示——例程用 `--log_level=message` 把它放出来）。

**测试树的组织**：用例（函数）→ 套件（用例的容器，可任意嵌套）→ 主套件（唯一根）。AUTO 体系三对宏 `BOOST_AUTO_TEST_CASE/SUITE(+_END)` 声明即注册；手动体系 `BOOST_TEST_CASE(&fn)` 造用例、`BOOST_TEST_SUITE("名")` 造套件、`add()` 挂树——例程两种混用（`s_slugify` 子套件 + 主套件直挂一个用例）。

**夹具**（fixture = 测试安装 + 清理）：AUTO 体系三档——`BOOST_FIXTURE_TEST_CASE`（用例级）、`BOOST_FIXTURE_TEST_SUITE`（套件级，成员对套件内所有用例可见）、`BOOST_TEST_GLOBAL_FIXTURE`（全局级，每个测试模块一次）。夹具类就是个 struct：构造函数做安装、析构做清理，测试函数直接访问它的成员（继承实现）。例程走手动路径，夹具就是"用例函数开头声明的 RAII 对象"（输出里的安装/清理两行）。

**运行参数**（`--名=值`，大小写敏感、等号两侧无空格）：`--log_level=message/success/warning/error/nothing`（默认 warning，所以 TEST_MESSAGE 不显示）；`--log_sink=stdout --report_sink=stdout`（本例程的 stderr 归零手段）；`--run_test=s_slugify/*`（只跑某个子树，支持通配符）；`--list_content`（列出测试树不运行）；`--build_info=yes`（编译器/Boost 版本）；`--output_format=XML`（CI 集成）。

**期望失败**：`BOOST_AUTO_TEST_CASE_EXPECTED_FAILURES(用例名, n)` 声明"该用例允许 n 条断言失败"——模块没写完先立测试的过渡手段。**泛型测试**：`BOOST_AUTO_TEST_CASE_TEMPLATE(名, 类型形参, 类型列表)`（mpl::list）对一族类型各生成一个用例。

全家福：自动/手动注册、fixture、参数化、浮点容差（`BOOST_CHECK_CLOSE`）、输出比对（`output_test_stream`）、超时、依赖用例。**竞争格局**：GoogleTest/Catch2 更流行，但 Boost.Test 胜在无外部依赖 + Boost 生态原生。
### 补：lightweight_test——头文件级的"最小测试件"（书 6.3）

比 Boost.Test 再轻一档的是 `<boost/core/lightweight_test.hpp>`：无框架、无注册，断言就是宏（`BOOST_TEST`/`BOOST_TEST_EQ`/`BOOST_TEST_NE`/`BOOST_TEST_THROWS`/`BOOST_ERROR`），main 结尾必须调 `boost::report_errors()`（忘了调会触发 BOOST_ASSERT）。还有编译期变体 `<boost/core/lightweight_test_trait.hpp>` 的 `BOOST_TEST_TRAIT_TRUE/FALSE((元函数))`——注意双括号。它跟 std 的 `assert` 一样属于"给库作者验证一小段代码"的工具，不入本教程例程的原因：`report_errors()` 的报告固定写 **stderr**，与本教程"stderr 恒空"的判定口径冲突（第 5 章 core.cpp 例程里有注释存档）。

> 实测坑一串（都值得记）：框架**日志与结果报告默认走 stderr**，要归零需 `--log_sink=stdout --report_sink=stdout` 运行时参数（API 重定向不可靠）；`BOOST_TEST_NO_MAIN` 下 **AUTO 宏用例不自动装配**（手动 `BOOST_TEST_CASE` 注册）；默认 init 签名是 `test_suite*(int, char**)` 不是 `bool()`。

## 32.2 Boost.Log（2010）：工业级日志

```cpp
auto backend = boost::make_shared<sinks::text_ostream_backend>();
backend->add_stream(boost::shared_ptr<std::ostream>(&std::cout, [](void*){}));
sink->set_formatter(expr::stream << "[" << severity << "] " << expr::message);
logging::core::get()->set_filter(logging::trivial::severity >= logging::trivial::info);
BOOST_LOG_TRIVIAL(info) << "服务启动完成";
```

运行输出（`log.cpp`；为确定性输出本例不排时间戳）：

```text
[info] 服务启动完成
[warning] 连接数接近上限
[info] 命名 logger 的一条记录
自检通过
```

三大件：**sink**（目的地：文件/控制台/网络，同步或异步前端）、**filter**（全局/线程级快速开关——重度过滤在格式化之前）、**formatter**（属性集模板）。广度过滤器 + 属性 + 多 sink 广播的吞吐设计是十年以上打磨的工程件。⭐ 服务端日志的 C++ 标准答案（spdlog 是流行的轻量第三方对手）。

> 实测坑：过滤器引用 `Severity` 属性时，**没有该属性的记录会被静默丢掉**。裸 `sources::logger` 不带 Severity，所以 `BOOST_LOG(lg) << …` 那条在设了 `severity >= info` 全局过滤后**根本不输出**（本机实测：这一行一度整个消失）。要它出现就得自己挂属性：
> ```cpp
> lg.add_attribute("Severity", boost::log::attributes::constant<logging::trivial::severity_level>(
>                                  logging::trivial::info));
> ```
> 另：Unix 上动态链接 Boost.Log 必须加 `-DBOOST_LOG_DYN_LINK`（与 Windows 的 `BOOST_ALL_DYN_LINK` 对应）。

## 32.3 Boost.Contract（2018 成库）：按契约设计

前置/后置/不变量三件套 + **旧值捕获**：

```cpp
boost::contract::check c = boost::contract::function()          // 必须 check 类型！
    .precondition([&]{ BOOST_CONTRACT_ASSERT(b != 0.0); })
    .postcondition([&]{ BOOST_CONTRACT_ASSERT(result * b == a); });
boost::contract::old_ptr<int> old_n = BOOST_CONTRACT_OLDOF(n_); // 后置比较旧值
// 类：public_function(this) + invariant() 成员
```

运行输出（`contract.cpp`）：

```text
10/4 = 2.5
计数 = 2
自检通过
```

C++26 contracts（P2900）的语言级方案落地前，它是 DbC 的唯一成熟 C++ 实现。违约的处置可配置（抛异常/终止/忽略）。

> 实测坑两个：契约对象**必须显式 `boost::contract::check` 类型**——写 `auto` 拿到中间 specify 类型，契约不激活，运行期 fail-fast 断言 "missing_check_object_declaration"；`.old()` 不是链式终点之后能随便接的。另：contract 内部头在 MSVC 19.51 有 C4701 固有告警，include 处 pragma 压制。

## 32.4 Boost.LEAF（2019）：轻量错误负载

错误对象不随异常走——**负载在传播路径上按需贴**，捕获端按"要得到多少负载"匹配 handler：

```cpp
auto load = leaf::on_error(e_file{"config.ini"}, e_line{42});   // RAII 守卫挂负载
leaf::try_catch(
    [] { throw std::runtime_error("解析失败"); },
    [](std::runtime_error const& e, e_file const& f, e_line const& l) { ... },   // 全负载命中
    []() { ... });                                               // 兜底
```

运行输出（`leaf.cpp`）：

```text
捕获: 解析失败 文件=config.ini 行=42
全负载 rc = 0
负载不全走兜底（符合预期）
半负载 rc = -1
自检通过
```

第二个场景故意只贴一半负载——handler 要 `e_line` 但没贴，自动落到兜底：**"负载按需匹配"**就是 LEAF 的核心语义。与 Outcome（17 章）的分野：LEAF 走异常路径（对已有异常代码零侵入），Outcome 走返回值路径。⭐ 游戏/实时系统（异常可用但不想要重量级错误对象）与"多层调用栈只想让最外层知道细节"的日志式错误处理。

> 实测坑：异常路径用 `try_catch`（兜底是**无参** handler），`try_handle_all` 面向 error_code 路径。

---


**第四部完**。

> 上一章：[31 · 运行时结构与散珠](31-runtime-structures.md) ｜ 下一章：[33 · 全库总表](33-appendix.md) ｜ 返回：[README](../README.md)
