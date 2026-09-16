# 11 · 算法与 lambda：STL 的武器库

> 对应示例：`examples/11_algorithms/`

## 11.1 心智模型：算法 + 谓词 = 声明式循环

你要在 nums 里找第一个大于 8 的数。手写循环：

```cpp
int found = -1;
for (int v : nums) {
    if (v > 8) { found = v; break; }
}
```

STL 写法：

```cpp
auto it = std::find_if(nums.begin(), nums.end(), [](int v) { return v > 8; });
```

两者的差距不是行数，是**语义层级**：手写版描述"怎么找"（下标、比较、跳出），算法版声明"找什么"（第一个满足条件的）。声明式的三个直接收益：**没有 off-by-one**（范围由迭代器对钉死）、**没有忘记 break**、**读代码的人秒懂意图**。这套哲学与 LINQ/Stream 同源——会那套的读者这里直接平移。

STL 算法上百个，高频的不到二十个。本章按用途分组过一遍主力。

## 11.2 sort：默认与自定义比较器

```cpp
std::vector<int> a = nums;
std::sort(a.begin(), a.end());              // 升序：1 1 2 3 3 4 5 5 6 9

std::vector<std::string> words{"pineapple", "fig", "banana", "kiwi"};
std::sort(words.begin(), words.end(),
          [](const std::string& x, const std::string& y) {
              return x.size() < y.size();   // 短的排前面
          });
// fig kiwi banana pineapple
```

`sort` 收迭代器对 + 可选**比较器**（返回 bool 的 callable，"谁排前面"）。默认 `<` 升序；要降序传 `std::greater{}`（`<functional>` 的现成比较器），要自定义规则写 lambda。**比较器必须严格弱序**（`x < y` 与 `y < x` 不同时为真）——写反或写 `<=` 会导致越界 UB（这不是警告，是爆炸），见坑位。

## 11.3 查找与计数：谓词是核心

```cpp
auto it = std::find_if(nums.begin(), nums.end(), [](int v) { return v > 8; });
std::println("第一个 >8 的数 = {}", *it);  // 9
std::println("偶数 {} 个", std::count_if(nums.begin(), nums.end(),
                                         [](int v) { return v % 2 == 0; }));
std::println("全是正数？{}",
             std::all_of(nums.begin(), nums.end(), [](int v) { return v > 0; }));
```

一族高频算法，全部吃 `[first, last)` + 谓词：

| 算法 | 回答的问题 | 返回 |
|---|---|---|
| `find_if` / `find` | 第一个满足条件的在哪 | 迭代器（找不到 = end） |
| `count_if` / `count` | 有几个满足 | 个数 |
| `all_of` / `any_of` / `none_of` | 全满足/至少一个/都不 | bool |
| `max_element` / `min_element` | 最大/最小的在哪 | 迭代器 |

**find_if 的返回值纪律**：用之前必查 `it != nums.end()`——找不到时解引用 `*it` 是 UB。示例里直接 `*it` 是因为数据已知含 9；防御性代码先判再取。

## 11.4 数值与变换

```cpp
int sum = std::accumulate(nums.begin(), nums.end(), 0);  // <numeric>
std::vector<int> doubled(nums.size());
std::transform(nums.begin(), nums.end(), doubled.begin(),
               [](int v) { return v * 2; });
```

`accumulate`（`<numeric>`）折叠求和（初始值 0 起步）；`transform` 逐元素变形写进目标区间（目标要**先有空间**——示例预先构造了 doubled(nums.size())，写越界是 UB）。 Cousins 一句话认识：`for_each`（逐个执行动作）、`copy_if`（条件拷贝）、`reduce`（并行版 accumulate，第 20 章见 execution 策略）。

**accumulate 初始值类型陷阱**：`accumulate(v.begin(), v.end(), 0)` 对 `vector<double>` 求和会**按 int 累加**（初始值定了累加类型），小数全被截断——初始值写 `0.0`。

## 11.5 捕获：lambda 的记忆

```cpp
int threshold = 4;
auto by_value = [threshold](int v) { return v > threshold; };  // 值捕获：快照
auto by_ref = [&threshold](int v) { return v > threshold; };  // 引用捕获：实时
threshold = 6;  // 改给引用捕获看
std::println("值捕获 >4：{} 个；引用捕获 >6：{} 个",
             std::count_if(nums.begin(), nums.end(), by_value),   // 4
             std::count_if(nums.begin(), nums.end(), by_ref));    // 1
```

第 05 章的伏笔在此兑现。`[x]` **值捕获**：定义时拷走快照，之后外面怎么改都影响不到它（示例里 threshold 改成 6，by_value 仍然比 4）。`[&x]` **引用捕获**：引用活变量本体，看到的是实时值。选型直觉：**小变量默认值捕获（安全、独立）；大对象且 lambda 当场就用，引用捕获**。

进阶捕获语法认识即可：`[=]`/`[&]` 全捕获（历史代码常见，**新代码别用**——隐藏依赖关系，读代码看不出 lambda 碰了什么）；`[x = expr]` 初始化捕获（C++14，可捕获 move-only 对象：`[p = std::move(ptr)]`）；`[this]` 捕获对象成员访问权。

## 11.6 泛型 lambda 与 std::function

```cpp
auto show = [](const auto& x) { std::println("值 = {}", x); };
show(42);
show(3.5);
show(std::string("文本"));

std::function<int(int)> f = [](int v) { return v * v; };
f = [sum](int v) { return v + sum; };  // std::function 可重新绑定
std::println("f(3) = {}", f(3));
```

**泛型 lambda**（`auto` 参数）一个 lambda 服务多种类型——每个调用类型各实例化一份，零运行开销。**`std::function`** 是"能装任何可调用对象"的容器：lambda 可以**换弹**（f 先后绑了两个不同 lambda）——回调注册表、事件处理器这种"函数要当变量管理"的场景才需要它。代价：比裸 lambda 多一层间接调用与可能的堆分配——**能 `auto` 接 lambda 就别包 function**。

## 11.7 坑位清单

1. **find_if 不检查就解引用**：`*it` 前必判 `it != end`。找不到返回 end，解引用即 UB。
2. **accumulate 初始值类型劫持累加类型**：double 求和写 `0` 得 int 语义，写 `0.0`。
3. **lambda 引用捕获悬垂**：lambda 活得比它引用的局部变量久（存进容器/跨线程/被返回）→ 调用时 UB。捕获即快照（值捕获）或保证同生共死。
4. **比较器不严格弱序**：`<=` 或"相等返回 true"的比较器让 sort 越界崩溃。调试断言：`comp(x, x)` 必须为 false。
5. **transform 目标空间不足**：目标容器没预留 size 就被写入→越界 UB。先 resize 或用 `std::back_inserter(dst)`。
6. **谓词带状态**：谓词在拷贝中跑（算法可能内部拷贝 functor），**有状态谓词的行为未定义**。状态放捕获只读值，或用 lambda 外的计数器变量。
