# 06 · 正则与随机：TR1 双雄

> 对应示例：`examples/06_regex_random/`（regex.cpp、random.cpp）

这两个库是 2005 年 TR1 收编名单里最"应用层"的两个：一个管文本模式匹配，一个管随机数。它们的 std 对应（`std::regex`、`std::random`）几乎是逐字照抄 Boost 的接口设计——**直系毕业的教科书案例**。

## 6.1 Boost.Regex（1998，Boost 元老）

接口四件套，std 全部同名同义：

| 操作 | Boost | std |
|---|---|---|
| 搜索（部分匹配） | `boost::regex_search(s, m, pat)` | 同名 |
| 整串校验 | `boost::regex_match(s, pat)` | 同名 |
| 替换（反向引用） | `boost::regex_replace(s, pat, "$1-***")` | 同名 |
| 迭代所有命中 | `boost::sregex_iterator` | `std::sregex_iterator` |

```cpp
boost::regex pat(R"((\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2}) (\w+) user=(\w+))");
boost::smatch m;
if (boost::regex_search(log, m, pat)) {
    std::cout << m[1] << '/' << m[2] << '/' << m[3] << ' ' << m[8] << '\n';
}
std::string masked = boost::regex_replace(log, pat, "$1/**/$2/**/$3 $4:$$:$5 $7 user=***");
```

运行输出（`regex.cpp`）：

```text
整段: 2026-09-19 12:30:45 INFO user=ada
年=2026 月=09 日=19
级别=INFO 用户=ada
合法邮箱? true 部分? false
脱敏: 2026/**/09/**/19 12:$:30 INFO user=*** action=login
数字出现 6 处
std 版第一组: user=ada
```

**毕业档案**：`std::regex`（TR1→C++11，直系）。那 2026 年还要看 Boost.Regex 吗？两个场景：

1. **性能**：`std::regex` 是出了名的慢（尤其 MSVC 实现）；Boost.Regex 通常快数倍，再往上是 RE2 时代的 `std::regex::awk`... 不，正解是：热路径正则别用 std，Boost.Regex 是 std 的平替升级，CTRE/PCRE2 是更快的第三方。
2. **Unicode 与更多语法**：Boost.Regex 对 Unicode（`icu` 后端）、Perl/POSIX 扩展语法支持更全。

**/std 之外的选择**：文本解析需求若能用 Spirit（第 20 章）或手写状态机，性能和报错都好于正则。

## 6.2 Boost.Random（2000，随机数工程的教科书）

Boost.Random 确立了**引擎/分布两层架构**——`rand()` 时代"一个函数包打天下"的所有错误（模偏差、无法复现、无分布语义）被它一次性纠正，std 照单全收：

```cpp
boost::random::mt19937 gen(42);                         // 引擎：确定性比特流
boost::random::uniform_int_distribution<> die(1, 6);    // 分布：映射到语义区间
die(gen);                                               // 组合使用
boost::random::random_device rd;                        // 真随机源（播种用）
boost::random::mt19937 gen2(rd());
```

运行输出（`random.cpp`）：

```text
掷骰子 x5: 3 5 6 2 5
1000 次抛硬币正面 = 484（约 500）
身高直方图（每 10cm 一档，取 160-180）：160:451 170:456 180:41
std/boost 同种子序列一致? true
不播种的两个引擎同序列? true（默认构造 = 固定种子，注意！）
```

四个工程要点：

1. **同种子同序列**（上面实测 `true`）：`mt19937` 是数值定义确定的算法——这对**可复现测试**至关重要（本教程所有随机示例都固定种子，输出才能进文档）。
2. **默认构造 = 固定种子**：两个未播种的引擎产生**相同**序列（实测 `true`）——忘了播种不会崩，但全程序的"随机"都一样，这是从 `rand()` 时代继承的最常见 bug。
3. **分布是语义层**：`uniform_int_distribution<>(1,6)` 保证无模偏差；`normal_distribution` 给真实高斯。直接 `% 6` 原始引擎输出是错误的。
4. **random_device 播种引擎**是真随机到伪随机的标准桥接。

**毕业档案**：`std::random`（TR1→C++11，直系，名字空间平移 `boost::random::` → `std::`）。Boost 版的残余价值：更多分布（`boost::random::negative_binomial_distribution` 等冷门件）、`generate_canonical` 细节差异、以及老代码兼容。

> 实测坑：`boost/random.hpp` 伞形头**不包含** `random_device.hpp`，用它得单独 `#include <boost/random/random_device.hpp>`——伞形头不伞，是 Boost 一贯的小陷阱。

---


> 上一章：[05 · 语言基建先行者](05-langbase.md) ｜ 下一章：[07 · 时间与日历](07-chrono.md) ｜ 返回：[README](../README.md)
