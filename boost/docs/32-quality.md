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
Running 2 test cases...

*** No errors detected
自检通过
```

全家福：自动/手动注册、fixture、参数化、浮点容差（`BOOST_CHECK_CLOSE`）、输出比对（`output_test_stream`）、超时、依赖用例。**竞争格局**：GoogleTest/Catch2 更流行，但 Boost.Test 胜在无外部依赖 + Boost 生态原生。

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
