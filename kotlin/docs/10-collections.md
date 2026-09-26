# 10 · 集合

> 对应示例：`examples/10_collections/`
>
> 只读/可变双轨接口、丰富的管道操作、以及几个专治手滑的陷阱
> （sorted vs sort、只读≠不可变、reduce 空炸）。

## 10.1 双轨接口：List 与 MutableList

```kotlin
val ro: List<Int> = listOf(1, 2, 3)        // 只读接口：没有 add/remove
val mu: MutableList<Int> = mutableListOf(1)
mu.add(2)                                   // 写方法只在这条轨
```

关键认知：**`List` 是"只读视图"，不是"不可变"**：

```kotlin
val view: List<Int> = mu          // 可变列表可当只读用
mu.add(4)
println(view)                     // [1, 2, 4] —— 底层变了视图跟着变
val frozen = mu.toList()          // 真要快照就拷贝
```

设计哲学：API 用 `List` 声明参数 = "我不改它"（但防不了别人改）；真不可变要 `toList()` 拷贝或用 kotlinx-immutable 库。**返回值给 `List`、内部存 `MutableList`** 是日常基线。

## 10.2 创建函数全家

```kotlin
listOf(1, 2, 3); mutableListOf("a"); emptyList<Int>()
List(3) { it * it }                       // [0, 1, 4]：下标工厂
MutableList(3) { 0 }
buildList { add(1); add(2) }              // 构建期可变、产物只读（推荐）
mapOf("a" to 1); setOf(1, 2, 2, 3)        // set 去重
(1..5).toList()
```

`buildList` 是"先用可变 API 组装、拿到只读结果"的正解——替代 `mutableListOf(...)` 然后当 `List` 返回的老套路。

## 10.3 管道操作全景

```kotlin
val nums = (1..10).toList()
nums.filter { it % 2 == 0 }.map { it * it }         // [4, 16, 36, 64, 100]
nums.first { it > 7 }                                // 8（无匹配抛异常）
nums.firstOrNull { it > 99 }                         // null
nums.count(); nums.sum(); nums.average(); nums.maxOrNull()
nums.take(3); nums.drop(7)
listOf(1, 2, 2, 3, 1).distinct()                     // [1, 2, 3]
```

每次链式调用都物化中间集合（急切求值）——大数据量换 `Sequence`（22 章实测对比惰性差异）。

## 10.4 分组与关联

```kotlin
groupingBy { it }.eachCount()                        // 词频
listOf("张三" to 88).groupBy({ 及格? }, { name })     // Map<Char, List<String>>
people.associateBy { it.name }                       // Map<名, 对象>
people.associateWith { it.age }                      // Map<对象, 值>
people.associate { it.name to it.age }               // Map<键, 值>
```

groupingBy + eachCount 是词频统计一行流；`associateBy/With` 三个方向（以谁为键、以谁为值）各有用场。

## 10.5 flatMap / zip / chunked / windowed

```kotlin
people.flatMap { it.hobbies }.toSet()               // 先映射后拍平
a.zip(b).map { it.first + it.second }               // 按位配对（短的截断）
(0..5).chunked(2)                                    // [[0,1],[2,3],[4,5]] 分块
(1..4).windowed(2)                                   // [[1,2],[2,3],[3,4]] 滑窗
(1..4).zipWithNext()                                 // 相邻配对
```

## 10.6 fold / reduce / 前缀和

```kotlin
listOf(1, 2, 3, 4).reduce { a, b -> a + b }          // 10：无初值，空集合抛异常！
listOf(1, 2, 3, 4).fold(10) { a, b -> a + b }        // 20：有初值，空集合安全
listOf(1, 2, 3, 4).runningFold(0) { a, b -> a + b }  // [0,1,3,6,10]：前缀和
```

**reduce 拿空列表调用是运行时炸**——数据可能为空时永远选 fold。

## 10.7 Map 操作

```kotlin
val m = mutableMapOf("a" to 1)
m.getOrPut("c") { 3 }                    // 存在取、不存在算并存入
m.mapValues { it.value * 10 }            // 值变换
m.filterKeys { it != "b" }; m.filterValues { ... }
for ((k, v) in map) {}                   // 解构遍历
```

`getOrPut` 是惰性默认值（lambda 只在缺失时跑）；`map[key]` 对 `Map<K, V?>` 有 null 歧义（04 章）。

## 10.8 Set 运算

```kotlin
a + b                 // 并（union）
a intersect b         // 交
a - b                 // 差（subtract）
```

中缀函数形式比 `a.union(b)` 顺手，两者等价。

## 10.9 排序：sorted* vs sort*

```kotlin
val src = mutableListOf(3, 1, 2)
val copy = src.sorted()          // 新列表 [1,2,3]；src 不动 → [3,1,2]
src.sort()                       // 原地排序 → [1,2,3]（只在 MutableList 上有）
people.sortedWith(compareByDescending<Person> { it.age }.thenBy { it.name })   // 组合比较器
```

**命名规则**：动词原形（sort/filter/map…）= 原地或急切；过去式（sortedBy/filtered…）= 返回新集合。`sortedBy` 返回新列表、`sortBy` 原地——一字母之差，数据丢不丢全看它。

## 10.10 接口层次与实现内幕

Kotlin 集合不是另起炉灶，而是给 `java.util` 贴上双轨接口（只读父 + 可变子）：

```text
Iterable → Collection → List / Set        （MutableIterable → MutableCollection → MutableList / MutableSet）
Map（独立族，不继承 Collection）
```

- `List`/`Set` 都继承 `Collection`（`contains/size/iterator` 的来源），`Map` **不在** Collection 族里——`map !is Collection<*>` 恒成立。
- `listOf(1, 2)` 背后是 `Arrays.asList`（JDK 委托）；`mutableListOf` 才是真 `ArrayList`。
- `sorted()` 委托 `Arrays.sort`、`reversed()` 委托 `Collections.reverse`——Kotlin 标准库大量函数是 JDK 静态调用的**薄糖衣**（源码里一行 `java.util.Arrays.xxx`）。

用 `::class.java.simpleName` 看穿（示例程序打印了每个创建函数的真实实现类）——选型时心中有实现，性能讨论才有地基。

## 10.11 坑位清单

1. **只读 ≠ 不可变**：传出去的 `List` 可能背后是别人的 MutableList。防御性拷贝 `toList()`。
2. **reduce 空集合抛 UnsupportedOperationException**——可能空就用 fold。
3. **`sortedBy` 不改原集合**——"我排序了怎么没反应"九成是调了过去式版本。
4. `first { }` 无匹配抛异常；不确定就用 `firstOrNull`。
5. `zip` 按短的截断——长度不等时静默丢数据，要显式处理用 `zipAll`?（stdlib 无，自己写或先检查长度）。
6. `average()` 空集合返回 NaN（不抛异常）——显示前记得兜底。
7. `Map.forEach` 的 `(k, v)` 是解构——在 lambda 里写 `it` 拿到的是 Entry，两种风格别混。
8. `Map` 不继承 `Collection`——`map as Collection<*>` 编译不过，别在层次图里画错线。
