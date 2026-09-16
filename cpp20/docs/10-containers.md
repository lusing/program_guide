# 10 · 容器与迭代器：数据住哪

> 对应示例：`examples/10_containers/`

## 10.1 容器选型总表

先给全景再逐个深入。STL 容器各司其职，选型看**三个问题**：按什么访问？插入多还是查询多？要不要有序？

| 容器 | 结构 | 查找 | 适用 | 备注 |
|---|---|---|---|---|
| **`vector<T>`** | 动态数组 | 按下标 O(1) | **默认选择**：序列 | 内存连续、缓存友好 |
| `deque<T>` | 分段数组 | O(1) 两端 | 双端队列 | 头部插入也 O(1) |
| `list<T>` | 双向链表 | O(n) | 枑少，要 splice 时 | 不连续、缓存不友好 |
| **`map<K,V>`** | 红黑树 | O(log n) | 有序键值 | 遍历按键排序 |
| `set<K>` | 红黑树 | O(log n) | 有序去重集合 | |
| `unordered_map<K,V>` | 哈希表 | **O(1) 平均** | 无序键值、大数量 | 最坏 O(n)；有 rehash |
| `unordered_set<K>` | 哈希表 | O(1) 平均 | 去重即可 | |
| `flat_map<K,V>` (C++23) | 排序 vector | O(log n) 二分 | 小规模、查询密集 | 缓存最友好，插入 O(n) |

经验法则：**不知道选什么就用 vector**（连续内存的性能红利超乎直觉）；键值查询按"要不要有序遍历"二分 map/unordered_map；flat_map 是 C++23 新宠（小表查询碾压红黑树）。

## 10.2 vector：动态数组

```cpp
std::vector<std::string> tags{"cpp", "modern"};
tags.push_back("tutorial");   // 尾部追加（均摊 O(1)）
tags[1] = "modern-cpp";       // 下标读写（不检查越界）
std::println("{} 个标签，第 2 个是 {}", tags.size(), tags[1]);
```

`push_back` 尾部追加、`pop_back` 尾删、`insert`/`erase` 任意位置（O(n)）、`size()`/`empty()`/`clear()`。容量机制值得知道：vector 按指数扩容（满时申请更大内存、搬移全部元素），所以**中间插入/删除会使指向元素的指针和迭代器全部失效**——坑位清单的头号常客。`reserve(n)` 预留容量避免反复搬（第 15 章会实测搬移成本）。

注意 `size()` 返回**无符号**整数类型（第 03 章的坑在容器时代高频回归）：`tags.size() - 1` 在空 vector 上回绕成天文数字。

## 10.3 map：有序键值对

```cpp
std::map<std::string, int> stock{{"cpp", 3}, {"rust", 5}};
stock["go"] = 2;   // 不存在则插入
++stock["cpp"];    // 存在则修改
if (auto it = stock.find("rust"); it != stock.end()) {  // 初始化语句 + find
    std::println("rust 库存 {}", it->second);
}
for (const auto& [lang, count] : stock) {  // 结构化绑定，按键有序
    std::println("  {}: {}", lang, count);
}
```

map = "键 → 值"的有序表。**`[]` 是双面刃**：读不存在的键会**插入默认值并返回引用**（int 插 0）——想"只查不改"时这是个静默 bug，用 `find`（返回迭代器，找不到等于 `end()`）或 `contains`（C++20，只问在不在）。

遍历天然按键升序（示例输出 cpp → go → rust），结构化绑定 `[lang, count]` 拆开 pair——第 06 章伏笔回收。pair 的两个成员叫 `first`/`second`（迭代器 `it->second` 就是值）。

## 10.4 set 与 unordered_map

```cpp
std::set<int> uniq{5, 3, 3, 1, 5, 9};
// 遍历输出：1 3 5 9——去重 + 排序一步到位

std::unordered_map<std::string, int> votes;
for (const std::string& w : {"cpp", "rust", "cpp", "go", "cpp", "rust"}) {
    ++votes[w];  // 不存在则从 0 起
}
std::println("cpp 得 {} 票", votes["cpp"]);  // 3
```

**set**：扔进去自动去重+排序，"这个词出现过吗"（`contains`）和"TopN 排序"的标配。**unordered_map**：计数器模式的绝配——`++m[key]` 一行完成"没有就建、有就加"。

map vs unordered_map 怎么选：**要按序遍历/范围查询（输出排行榜、找 [a,c] 区间的键）→ map**；纯点查且量大 → unordered_map。unordered 的遍历顺序不可依赖（哈希决定），跨运行甚至可能变。

## 10.5 迭代器：统一的遍历接口

```cpp
std::vector<int> nums{3, 1, 4, 1, 5, 9, 2, 6};
int max_v = nums.front();
for (auto it = nums.begin(); it != nums.end(); ++it) {
    if (*it > max_v) {
        max_v = *it;
    }
}
```

迭代器是"指到容器某位置"的通用把手：`begin()` 指首元素、`end()` 指**尾后**（半开区间 `[begin, end)`——end 不指向任何元素，只是终点标记）。`*it` 取值、`++it` 前进、`it != end()` 判终。

日常遍历被 range-for 覆盖了，但迭代器仍是绕不开的通用货币：**STL 算法（第 11 章）全吃迭代器对**、插入删除返回迭代器、"只处理一段"也要迭代器定位。五大类知道名词即可：

| 类别 | 能力 | 代表 |
|---|---|---|
| 输入/输出 | 单遍读/写 | 流迭代器 |
| 前向 | 多遍 | forward_list |
| 双向 | `--` 后退 | list、map、set |
| **随机访问** | `+n` 跳跃 | vector、deque |

vector 的迭代器是随机访问类（能 `it + 3`），map 是双向类——这就是为什么有些算法（如 std::sort）只收随机访问迭代器、map 不能直接 sort。

## 10.6 删除惯用法：erase_if（C++20）

```cpp
std::erase_if(nums, [](int v) { return v <= 2; });
// 输出：3 4 5 9 6
```

"边遍历边删"是 C++ 史上最著名的雷区：erase 让 it 失效，下一次 ++ 直接 UB。老时代要背 erase-remove 惯用法（`v.erase(std::remove_if(...), v.end())`——一句需要解释三遍的咒语）。**C++20 的 `std::erase_if` 一行说人话**：留下不满足条件的、删掉满足的，返回删除数。新代码没有理由再写旧咒语。

## 10.7 flat_map 一瞥（C++23）

```cpp
std::flat_map<std::string, int> fm{{"b", 2}, {"a", 1}};
fm["c"] = 3;
std::println("flat_map 首键 = {}", fm.begin()->first);  // a：有序
```

`flat_map` 接口与 map 几乎一样，底层换成了**排序 vector**：查询二分（缓存友好，小表快得多），代价是插入 O(n)（要挪）。适用画像：**启动时建好、运行期只查的小字典**（配置表、枚举映射）。C++23 的新工具，MSVC 已实测可用。

## 10.8 坑位清单

1. **遍历中增删元素**：push_back/erase 使当前迭代器失效（vector 扩容全体失效）。要过滤用 erase_if；要"边走边处理新增"重新设计循环。
2. **`[]` 误插入**：`if (m["absent"] > 0)` 一执行就把 absent 插进去了（值为 0）。只读访问用 `find`/`contains`/`at`（at 越界抛异常）。
3. **`size() - 1` 空容器回绕**：无符号算术，空 vector 时得到极大值。先判空，或用迭代器/ranges。
4. **map 的值需要默认构造**：自定义类型没有默认构造函数时 `m[key]` 编译错——用 `emplace`/`insert`。
5. **unordered 容器依赖遍历序**：哈希序不稳定，写进逻辑就是在埋雷；要序用 map。
6. **大对象按值塞容器再改**：`v.push_back(big); v.back().field = x;` 拷贝已发生。原地构造用 `emplace_back(args...)`（在容器里直接构造，省一次搬移）。
