# 14 · 格式化：Boost.Format 的谢幕

> 对应示例：`examples/14_format/format.cpp`

Boost.Format（2002，Samuel Krembl 之外最广为引用的 Boost 库之一）解决的是 printf 的两大病：**不类型安全**（`%s` 传 int 是 UB）和**不可本地化**（翻译后的句子语序会变）。它的解法是流式喂参 + 位置占位符：

```cpp
boost::format("学生 %1% 得分 %2%") % name % score
boost::format("%1% %2% %1%") % "回声" % 7            // 占位符可复用
boost::format("[%8.3f] [%-8s]") % 3.14159 % "左"     // printf 规格也认
boost::format tmpl("x=%1%; y=%2%");                  // 格式对象可复用
```

运行输出（`format.cpp`）：

```text
学生 ada 得分 95
回声 7 回声
[   3.142] [左     ]
x=1; y=2
x=10; y=20
多喂参数被抓住: boost::too_m...
学生 ada 得分 95
[   3.142] [左      ]
自检通过
```

与 printf 的关键差异（例程逐条实证）：参数多喂**抛异常**而不是 UB；格式串是对象，可以留空复用；`%1%` 位置占位符天生支持本地化语序。

## 14.1 毕业档案：平行进化，不是直系

这里要澄清一个广泛流传的误会：**`std::format`（C++20）不是从 Boost.Format 毕业的**——它来自 Victor Zverovich 的 fmt 库（`{}` 语法、编译期解析、性能远超流式方案）。fmt 进标准（P0645）客观上终结了 Boost.Format 的历史使命，但这是"平行进化淘汰"，不是"直系毕业"：

| | Boost.Format（2002） | std::format（C++20，fmt 血统） |
|---|---|---|
| 占位符 | `%1%` / printf 规格 | `{}` / `{:8.3f}` |
| 类型安全 | 运行期检查（异常） | **编译期检查** |
| 性能 | 慢（流式拼接） | 快（编译期格式串） |
| 本地化语序 | 位置占位符 | 位置参数 `{0} {1}` |
| C++ 档位要求 | C++03 | C++20 |

```cpp
std::format("学生 {} 得分 {}\n", name, score);          // C++20
std::print("学生 {} 得分 {}\n", name, score);           // C++23 连 << 都省了
```

**2026 选型**：C++20 起一律 `std::format`/`std::print`；C++17 及以下的项目里，Boost.Format 仍是类型安全的正解（fmt 也行，但那是第三方依赖的取舍）。boost 版仅维护老代码时出现。

---


> 上一章：[13 · 文件系统与编码](13-filesystem.md) ｜ 下一章：[15 · 范围与迭代器](15-ranges.md) ｜ 返回：[README](../README.md)
