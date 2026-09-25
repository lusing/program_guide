# 11 · 错误处理基石：exception / system / throw_exception

> 对应示例：`examples/11_error/`（3 个例程）

错误处理是 Boost 对标准库影响最深远的领域之一：`std::error_code` 的原型是 `boost::system::error_code`，跨线程搬运异常的 `std::exception_ptr` 语义来自 Boost.Exception。而 Boost.Exception 的"错误信息随身携带"设计至今没有 std 对应——它是本章唯一"毕业后仍不可替代"的库。

## 11.1 Boost.Exception（2002）：异常的随身行李

核心思想：**异常类型不用为每种上下文膨胀**——抛出方往异常对象里塞任意键值对（`error_info`），捕获方按需取用：

```cpp
struct parse_error : virtual std::exception, virtual boost::exception {};
typedef boost::error_info<struct tag_line, int> line_info;
typedef boost::error_info<struct tag_src, std::string> src_info;

BOOST_THROW_EXCEPTION(parse_error{} << line_info(42) << src_info("config.ini"));

catch (const boost::exception& e) {
    *boost::get_error_info<line_info>(e);       // 42
}
```

运行输出（`exception.cpp`）：

```text
行号 = 42
来源 = config.ini
重抛后仍能取行号 = 42
exception_ptr 搬运后重抛成功? true
```

三个设计点：

1. **虚继承双根**：异常同时是 `std::exception`（std 世界认）和 `boost::exception`（行李舱）——两种 catch 都能接住。
2. **重抛加行李**：中间层 `catch (boost::exception& e) { e << 上下文; throw; }`——错误信息逐层累积，到顶层日志时已经带完整因果链。这是它真正的杀手级用法。
3. **`std::exception_ptr`**（C++11）：`current_exception`/`rethrow_exception` 把异常**当值传递**——线程池 worker 捕获、主线程重抛的整个模式由此而来（boost 首创语义，例程验证搬运后类型完好）。

**毕业档案**：`exception_ptr` 毕业了；**行李机制（error_info）没有 std 对应**，⭐ 抛异常带上下文的最佳 C++ 实践至今仍属它。

## 11.2 Boost.System（2003）：error_code 的老家

`error_code` 的双层设计（**值** + **类别**）是它的核心贡献：错误值 `2` 在 generic 类别是"文件不存在"，在自定义类别可以是"连接被拒"——比较必须带类别，跨库错误互不串味。

```cpp
// 库作者三件套：枚举 + category 单例 + message
class net_category_impl : public boost::system::error_category { ... };
boost::system::error_code ec(static_cast<int>(net_err::timeout), mylib::net_category());
ec.message();                                    // "网络超时"
```

运行输出（`system.cpp`）：

```text
值=1 域=mylib.net 消息=网络超时
是 timeout? true
默认构造无错? true
捕获 system_error: 连接被拒
std 版: Operation timed out (域 generic)
ENOENT: 有错=true 值=2（generic 类别）
自定义类别: mylib.net
自检通过
```

**毕业档案**：`std::error_code`/`std::error_category`/`std::system_error`（C++11，直系——委员会照着 Boost.System 的设计逐条标准化）。boost 版从 1.69 起甚至默认就是 std 的薄包装。**2026 新代码用 `<system_error>`。**

> 实测坑：自定义 `enum class` 错误码**不能**隐式构造 `error_code`（要显式 `(value, category)`），除非为它特化 `is_error_code_enum`；另外 Windows `system_category().message()` 走 **ACP 编码**，中文系统上打印到 UTF-8 终端是乱码——通用错误用 generic 类别。
>
> 实测坑（跨平台）：`std::error_code::message()` 的**文案是平台给的**，不是标准规定的。同一个 `ETIMEDOUT`，MSVC 的 `generic_category` 给 `timed out`，macOS 的给 `Operation timed out`；`ENOENT` 同理（`No such file or directory` vs MSVC 的 `No such file or directory`……但 errno 值 2 是一致的）。写断言要比**错误码**和**类别**，别比文案。

## 11.3 Boost.ThrowException：统一的抛出出口

```cpp
// 库作者姿势：内部一律
boost::throw_exception(std::out_of_range("checked_at: 下标越界"));
// 而不是直接 throw
```

运行输出（`throw_exception.cpp`）：

```text
捕获: checked_at: 下标越界
诊断信息含异常类型名? 1
统一出口对 noexcept/嵌入式构建的意义见上
自检通过
```

价值在**可配置性**：关掉异常的构建（`BOOST_NO_EXCEPTIONS`，嵌入式/内核）里，它变成 abort 或用户注册的钩子，而直接 `throw` 无处安放。所有 Boost 库内部抛异常都走它——这就是为什么 Boost 能支持无异常构建。

**毕业档案**：无 std 对应（std 的 `std::throw_with_nested` 是另一件事）。⭐ 库作者的卫生习惯，一行为代价换来嵌入式可移植性。

## 11.4 错误处理的现代全景

把本章放进 C++ 错误处理的完整版图（后面的章节会补齐剩下的拼图）：

| 风格 | 工具 | 章节 |
|---|---|---|
| 异常（不可恢复/构造失败） | std::exception + boost::exception 行李 | 本章 |
| 错误码（可恢复/跨 ABI） | std::error_code（原型 boost::system） | 本章 |
| 返回值语义（C++23） | `std::expected` ↔ **Boost.Outcome** | 第 17 章 |
| 无分配错误负载（游戏/实时） | **Boost.LEAF** | 第 32 章 |

---


**第二部完**。接下来第三部：现代波次。

> 上一章：[10 · 原子操作](10-atomic.md) ｜ 下一章：[12 · 词汇类型五虎](12-vocabulary.md) ｜ 返回：[README](../README.md)
