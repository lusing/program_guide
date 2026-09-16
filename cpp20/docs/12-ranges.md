# 12 · Ranges：惰性流水线思维

> 对应示例：`examples/12_ranges/`

## 12.1 从嵌套到管道

"取出 80 分以上、格式化成 姓名:分数"——算法嵌套版：

```cpp
auto passed = std::ranges::to<std::vector>(   // 由内向外读，还得先想清楚顺序
    std::views::transform(
        std::views::filter(students, [](const Student& s) { return s.score >= 80; }),
        [](const Student& s) { return s.name + ":" + std::to_string(s.score); }));
```

Ranges 管道版（C++20 视图 + C++23 收集）：

```cpp
auto passed = students
    | std::views::filter([](const Student& s) { return s.score >= 80; })
    | std::views::transform([](const Student& s) {
          return s.name + ":" + std::to_string(s.score);
      })
    | std::ranges::to<std::vector>();  // (C++23) 一行收集
// alice:92  carol:86  eve:95
```

`|` 让数据**从左到右流过加工站**——和 shell 管道、LINQ、Java Stream 同构，会那套的读者直接平移。filter 留下满足条件的，transform 逐个变形，`ranges::to<T>()`（C++23）把视图物化回容器。物化前的一切都是**视图**——不拷贝数据、不马上计算，这就是下一节的主角。

## 12.2 惰性：视图不工作，直到你消费它

本章最重要的实验。给 filter 谓词装个计数器，数它到底跑了多少次：

```cpp
int visited = 0;
auto passing = students | std::views::filter([&visited](const Student& s) {
    ++visited;  // 打点：谓词每跑一次记一次
    return s.score >= 60;
});
std::vector<std::string> first_two;
for (const Student& s : passing) {
    first_two.push_back(s.name);
    if (first_two.size() == 2) break;  // 拿够 2 个就停：后面 3 个根本不看
}
std::println("手动取 2 个，实际只访问了 {} 个元素", visited);  // 2
```

**5 个元素的序列，只碰了 2 个**——视图是惰性的：`passing` 定义时什么都没算（只是记下了流水线图纸），for 循环每走一步才现算一步。拿够即 break，剩余元素从未被任何谓词看见。对着百万级序列“只取前 K 个”时，这就是 O(K) 与 O(n) 的差距。

同一个"取 2 个"换 ranges::to 物化，本机实测翻车现场：

```cpp
int drained = 0;
auto wasted = students
    | std::views::filter([&drained](const Student& s) { ++drained; return s.score >= 60; })
    | std::views::take(2)
    | std::ranges::to<std::vector>();
std::println("ranges::to 取 2 个（结果 {} 个），却访问了 {} 个元素——工具链实测坑",
             wasted.size(), drained);  // 5：to 先估尺寸，惰性白搭
```

**MSVC 的 `ranges::to` 构造目标容器前会先估算尺寸**，把 take 视图的 size 算出来——而 take 的 size 要数完 filter 才知道，于是 filter 被整个抽干（5 次全跑）。结论：**要"提前停"就手动消费（for + break）；ranges::to 适合"要全部结果"的场景**。这是写进示例代码的真实验证，不是理论推演。

## 12.3 生成与裁剪：iota / take / drop / reverse

```cpp
std::print("平方: ");
for (int v : std::views::iota(1, 6) | std::views::transform([](int i) { return i * i; })) {
    std::print("{} ", v);  // 1 4 9 16 25
}
std::print("后两个倒序: ");
for (const auto& s : students | std::views::drop(3) | std::views::reverse) {
    std::print("{} ", s.name);  // eve dave
}
```

`iota(a, b)` 生成 [a, b) 的整数序列——**只写一个参数就是无限序列**（`iota(1)` 是 1,2,3,…），必须配 take 截断，这是惰性存在的终极理由。裁剪三件套：`take(n)` 取前 n、`drop(n)` 跳过前 n、`reverse` 倒着走。这些视图零拷贝——reverse 不翻转数据，只是反着迭代。

常用视图速查（按出场频率）：

| 视图 | 作用 | 备注 |
|---|---|---|
| `filter(pred)` | 留下满足条件的 | 谓词每元素跑一次 |
| `transform(f)` | 逐个变形 | 输出类型可以变 |
| `take(n)` / `drop(n)` | 取/跳过前 n 个 | take 配无限序列 |
| `reverse` | 反向 | 零拷贝 |
| `iota(a, b)` | 生成整数序列 | 单参 = 无限 |
| `enumerate` (C++23) | 带索引遍历 | `for (auto [i, x] : v | views::enumerate)` |
| `split(v)` / `join` | 拆分 / 拍平 | 字符串切分常用 |

## 12.4 ranges 算法 + 投影

```cpp
std::ranges::sort(students, std::greater{}, &Student::score);  // 按分数降序
std::print("排名: ");
for (const auto& name : students | std::views::transform(&Student::name)) {
    std::print("{} ", name);  // eve alice carol bob dave
}
```

C++20 的算法有 ranges 版（`std::ranges::sort(v, ...)`），两大升级：**直接收容器**（不用再写 v.begin(), v.end()——本来就该这样），以及**投影（projection）**——最后一个参数指定"比较之前先取哪个成员"，`&Student::score` 一参消灭一个比较器 lambda。transform 里 `&Student::name` 同理（成员指针也是投影）。

投影的老中青三代写法对照（同样按分数排序）：

```cpp
std::sort(v.begin(), v.end(), [](auto& a, auto& b){ return a.score > b.score; });  // 老
std::ranges::sort(v, std::greater{}, &Student::score);                             // 新
```

## 12.5 视图与容器的分工

视图（view）与容器（container）的关系一句话：**容器拥有数据，视图借用数据**。这决定了使用纪律：

- 管道的源头必须活得比管道久（见坑位 1 的悬垂）；
- 视图**不缓存**：消费两次就算两次（有副作用的谓词会重复执行——又一个"谓词保持纯净"的理由）；
- 要反复使用结果，物化成容器（ranges::to）再复用。

## 12.6 坑位清单

1. **视图悬垂**：`auto v = get_temp_vector() | views::filter(...)`——临时 vector 语句结束即亡，v 从此指向已释放内存。物化（ranges::to）或先存容器再接管。
2. **无限视图忘了 take**：`for (int v : std::views::iota(1))` 死循环。无限序列必须 take/drop 截断。
3. **MSVC ranges::to 抽干惰性**（12.2 实测）：提前停用手动 for + break；全量收集才用 to。
4. **视图存下来二次使用**：不缓存 + 可能已被动过，行为难料。视图即用即弃，结果要留就物化。
5. **filter 后改底层容器**：视图迭代器绑定底层结构，底层一改动（push_back/erase）即失效——同第 10 章迭代器失效纪律。
6. **对 map 直接 views::sort**：map 迭代器是双向的，sort 要随机访问。要排序先物化成 vector（`map | ranges::to<std::vector>()` 拿 pair 序列）。
