# 14 · 算法库：map/filter/reduce 与惰性管道

> 对应示例：`examples/14_algorithms/`

## 14.1 变换三剑客

```d
import std.algorithm, std.range, std.array;

auto nums = [4, 8, 15, 16, 23, 42];

nums.map!(x => x * 2);                     // 惰性：此刻一个都没算
nums.map!(x => x * 2).array;               // .array 才消费成数组

nums.filter!(x => x % 2 == 0).array;       // [4, 8, 16, 42]

nums.reduce!((a, b) => a + b);             // 无种子：前两个元素起步
reduce!((a, b) => a + b)(100, nums);       // 有种子：(seed, range) 参数序——别 UFCS！
nums.fold!((a, b) => a + b);               // fold：种子可选、类型更自由
```

**惰性是默认**：`map/filter/take/chain/zip...` 都返回"适配器区间"，元素在被拉取时才算——无限流能处理、大数据不爆内存、管道中途放弃不浪费。

## 14.2 管道：UFCS 串起一切

```d
auto pipeline = 100.iota                   // 0..99
    .filter!(n => n % 3 == 0)              // 3 的倍数
    .map!(n => n * n)                      // 平方
    .filter!(n => n < 10_000)
    .array;                                // 34 个
```

读法 = 数据流向：**从上往下就是执行序**。这套体验是 05 章 UFCS + 13 章 range 的合体。

## 14.3 搜索与判断

```d
nums.canFind(23);                          // 包含吗
nums.count!(x => x > 15);                  // 计数
nums.countUntil(16);                       // 首次下标（找不到 -1）
[1, 2, 3].all!(x => x > 0);                // 全部满足
[1, 2, 3].any!(x => x > 2);                // 任一满足
```

## 14.4 排序

```d
auto data = [5, 2, 8, 1, 9, 3];
auto sorted = data.sort;                   // 就地排序（不是副本！），返回 SortedRange

[5, 2, 8, 1].sort!"a > b";                 // 字符串比较器：降序
[-5, 2, -8].sort!((a, b) => abs(a) < abs(b));   // lambda 比较器：按绝对值
```

- `sort` **就地改原数组**——要保留原序先 `.dup`。
- 返回的 SortedRange 携带"已排序"信息，后续 `canFind` 等自动走二分。
- 字符串比较器 `"a > b"` 里 a/b 就是元素名——老 D 程序员最爱，lambda 版更通用。

## 14.5 聚合与切分

```d
[1, 1, 2, 2, 2, 3].group.array;            // 相邻分组 [(1,2), (2,3), (3,1)]
[3, 1, 4, 1, 5].uniq.array;                // 相邻去重
[1, 2, 3].sum;  [3, 1, 4].minElement;  [3, 1, 4].maxElement;

10.iota.chunks(4);                         // [0,1,2,3] [4,5,6,7] [8,9]：分块（内存友好）
[1, 2, 3].each!(x => write(x * 10, " "));  // 命令式遍历的函数式姿势
```

`chunks` 的每个 chunk 也是惰性视图——要独立数组得 `.map!(c => c.array)`。

## 14.6 无限流 + 管道 = 生成器风格

```d
import std.range;
sequence!"n"(0)                     // 0, 1, 2, …（无限）
    .filter!(n => n % 2 == 0)
    .map!(n => n * n)
    .take(3).array;                 // [0, 4, 16]：只算了需要的 7 个元素
```

## 14.7 坑位清单

1. **带种子的 reduce 别用 UFCS**：`nums.reduce!(op)(100)` 会把 nums 抢到 seed 位置——正确写法 `reduce!(op)(100, nums)`。fold 随意。
2. **taskPool.reduce 的函数必须是命名函数**：内联 lambda 触发 "dual-context deprecated"（17 章）。
3. **sort 是就地**：`auto b = a.sort;` 之后 a 已经被排——b 只是"带着已排序信息的视图"。
4. **chunks/group 返回的子区间是惰性视图**：引用原数据；转数组 `.array`，转数组的数组 `.map!(c => c.array).array`。
5. `map!(...)` 的 `!` 别丢：`map(x => x * 2)` 是把 lambda 当**运行期参数**传（编译错或行为不对）——算法的函数参数走模板实参。
6. 管道中间忘了 `.array` 直接 `writeln`：会打印出适配器类型名（`MapResult!(...)`）——println 消费不了纯惰性对象，先落袋。
7. `equal` 比较两个区间（元素级）；`==` 对区间类型不可用（除数组外）——判断内容相等用 `.equal`。

---
