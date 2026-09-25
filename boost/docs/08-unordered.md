# 08 · 无序与哈希：两代哈希的故事

> 对应示例：`examples/08_unordered/`（unordered、container_hash、hash2）

哈希容器 2003 年进 Boost（TR1→C++11 毕业为 `std::unordered_*`），但"怎么给类型算哈希"这件事，std 至今只给了个残缺的 `std::hash`——Boost 用两个库回答了两遍：`ContainerHash`（2008，第一代）和 `Hash2`（2023，第二代，C++26 `std::hash` 修订提案的参考实现）。

## 8.1 Boost.Unordered：哈希容器的重制

```cpp
boost::unordered_map<std::string, int> ages{{"ada", 36}, {"grace", 85}};
boost::unordered_set<Point> points;      // Point 只要提供 hash_value + operator==

std::size_t hash_value(const Point& p) {
    std::size_t seed = 0;
    boost::hash_combine(seed, p.x);
    boost::hash_combine(seed, p.y);
    return seed;
}
```

运行输出（`unordered.cpp`）：

```text
3 位: 3 ada=36
桶数 >= 3? true
点集大小 = 2（{1,2} 只进一次）
multimap 中 k 出现 2 次
std 版大小 = 2
```

**毕业档案**：`std::unordered_map/set/multimap/multiset`（TR1→C++11，直系）。Boost 版 2022 年做了大重制（foa 系列开放寻址实现，`boost::unordered_flat_map` 比多数 `std::unordered_map` 实现快 2-3 倍、省一半内存——flat 系列在 21 章容器里展开）。日常哈希容器用 std；性能敏感查表用 boost 的 flat 系。

## 8.2 Boost.ContainerHash：给"一切"算哈希

`std::hash` 的两大残缺：**内置特化少**（没有 vector/tuple/pair），**没有组合机制**（自定义类型要手写一整套特化）。ContainerHash 两个都补了：

```cpp
boost::hash<std::vector<int>> hv;                     // 容器哈希
boost::hash<std::tuple<int, std::string, double>> ht; // 元组哈希
boost::hash_combine(seed, 42);                        // 组合原子
boost::hash_range(v.begin(), v.end());                // 区间哈希
```

运行输出（`container_hash.cpp`）：

```text
hash(42) = 42
hash(boost) 与 hash(boost) 相等? true
vector 哈希 = 9817560623972631116
list 哈希非零? true
tuple 哈希非零? true
组合哈希非零? true
range 哈希 = 2187638889926216118
std::hash(string) = 11527739985994839142
自检通过
```

**2026 价值**：自定义键类型进哈希容器，`hash_value` + `hash_combine` 仍是三行解决战斗的姿势（std 版手写特化 + 自己拼混合要十行）。C++26 之前它都是最优解。

> 实测坑（跨平台）：`boost::hash` 的结果是**规定的**（跨实现稳定，所以上面 `vector/range` 两行在 MSVC 与 clang 上一致），但最后那行 `std::hash<string>` 是**标准库实现自定义的**——MSVC 给 `6367522192732022988`，Apple libc++ 给 `11527739985994839142`。别把 `std::hash` 的值写进测试断言。

## 8.3 Boost.Hash2（2023）：第二代的设计革命

第一代回答"给什么算"，第二代回答**框架问题**：算法可换、种子可控、流式可续、密码学可选：

```cpp
boost::hash2::fnv1a_64 h1(0);       // 快散列（显式种子 0 → 可复现）
boost::hash2::xxhash_64 h2(0);      // 同一框架，换算法只换类型
h1.update("hello", 5);
auto r1 = h1.result();              // 流式快照——注意会推进状态，先存值再用
```

运行输出（`hash2.cpp`）：

```text
fnv1a_64(hello) = 0xa430d84680aabd0b
xxhash_64(hello) = 0x26c7827d889f6da3
手写组合 = 0xbeaf9e59ad3d9c8e
两次运行一致? true
默认随机种子结果不同? true
```

三个设计要点（都是 `std::hash` 没有的）：

1. **默认随机种子**：默认构造的哈希器之间种子不同（实测 `true`）——针对哈希碰撞 DoS（恶意输入打满一个桶）的工程防线。要跨进程复现就显式给种子。
2. **算法库齐全**：fnv1a/xxhash/xxh3（快）、md5/sha1/sha2/sha3/blake2/ripemd（密码学，配 `hmac.hpp`）、siphash（抗 DoS）——同一套 `update/result` 接口。
3. **`hash_append` 协议**：自定义类型声明"字段依次进哈希"，与算法解耦（第一代 `hash_value` 的升级）。

**毕业档案**：无 std 对应；C++26 的 `std::hash` 大修提案正照着它的分层讨论。⭐ 需要字节级摘要、文件指纹、防 DoS 种子时用它。

> 实测坑两条：伞形头 `boost/hash2.hpp` 不存在，要单引 `fnv1a.hpp`/`xxhash.hpp`；`result()` 是**会推进状态的流式快照**，连续两次调用结果不同——先存进变量再用。

---


> 上一章：[07 · 时间与日历](07-chrono.md) ｜ 下一章：[09 · 多线程第一课](09-thread.md) ｜ 返回：[README](../README.md)
