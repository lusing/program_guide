# 10 · 集合

> 对应示例：`examples/10_collections/`（`Main.kt` 演示输出，`CollectionsDemo.kt` 承载集合逻辑：wordCount/groupByGrade/indexByName/adultsIn/checksum/allHobbies/zipSums/sortDemo/ageGroup/byAgeGroupThenName）。全部代码经四层验证：`kotlinc -Werror` 零告警 → kotlin.test 单测通过 → 运行 exit 0 → 输出与 `expected.txt` 逐字节一致。环境：Kotlin 2.4.21（K2）+ JDK 21。

Kotlin 集合库 = Java 集合框架的骨架 + 一套函数式操作的皮肉。骨架意思是：运行时的 `List` 底下就是 `ArrayList` 这些 JDK 老面孔，零互操作成本；皮肉意思是：`filter`/`map`/`groupBy`/`fold` 这套管道操作直接长在标准库里，不用再 `stream().collect(...)` 绕一圈。这一章按"接口观 → 创建 → 操作全景 → 排序 → 内幕"走一遍。

---

## 10.1 先立一个总图景

Kotlin 集合接口分两族三档：

- **两族**：`Collection` 一族（`List`/`Set` 往上汇到 `Iterable`）和独立的 `Map` 一族——`Map` **不是** `Collection` 的子接口，这一点后面有实测。
- **三档**：每层接口都有"只读"与"可变"两份声明——`List`/`MutableList`、`Set`/`MutableSet`、`Map`/`MutableMap`。

函数式操作的命名约定也一并记住，后面每节都在用：**不带 `OrNull` 的版本失败就抛异常**（`first`、`max`），**带 `OrNull` 的版本失败给 null**（`firstOrNull`、`maxOrNull`、`reduceOrNull`）。工程代码优先后者。

这里埋着一节**语言演化课**，读老代码会撞上：`max` 的身世很曲折——1.0 的 `max(): T?` 空集合返回 null，1.4 起弃用（warning）、1.5 升级为 error、1.6 直接隐藏，官方指引改用 `maxOrNull()`；**1.7 又 introduced 一个新 `max(): T`**——非空返回、空集合抛 `NoSuchElementException`（JVM 字节码里它的名字叫 `maxOrThrow`）。所以今天你同时看到 `max`（抛）和 `maxOrNull`（给 null）两个 API，选型只看一句：**这个集合可能为空吗**。`min` 家族同理。

---

## 10.2 只读与可变双轨：只读 ≠ 不可变

```kotlin
val ro: List<Int> = listOf(1, 2, 3)              // 只读接口（不是不可变！）
val mu: MutableList<Int> = mutableListOf(1)
mu += 2; mu.add(3)                               // mutable 才有写方法
val view: List<Int> = mu                          // 可变列表可当只读用（向上转型视图）
mu.add(4)
println("只读引用能看到底层变化: view=$view（所以只读 ≠ 不可变）")
val frozen: List<Int> = mu.toList()              // 真正想"快照"就拷贝
mu.add(5)
println("快照 toList 不受影响: frozen=$frozen")
```

`List` 接口里**根本没有 `add`/`remove`**——示例里注释掉的那行 `stuck.add(3)` 是编译错，不是运行错。但这只是"这个引用没有写方法"，不是"内容冻结"。上面代码的输出：

```text
只读引用能看到底层变化: view=[1, 2, 3, 4]（所以只读 ≠ 不可变）
快照 toList 不受影响: frozen=[1, 2, 3, 4]
```

`view` 和 `mu` 指着同一个对象，`mu.add(4)` 从 `view` 里照样看得见。要真正的快照就 [`toList()`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/to-list.html) 拷贝一份——`frozen` 对后来的 `add(5)` 免疫。

**为什么这样设计**：Kotlin 的"只读"是**接口收窄**而非**不变性承诺**，成本是零（不拷贝、不包装），换来的纪律是"函数签名里写 `List` 的，保证不改你的数据"。要硬性的不可变保证，得上 kotlinx-collections-immutable 这类库。实务口诀：**跨模块传参用只读接口，防御性拷贝用 `toList()`，修改只发生在所有者内部**。

---

## 10.3 创建函数全家

```text
listOf(1,2,3) = [1, 2, 3]
mutableListOf = [a]
emptyList<Int>() = []
List(3) { it * it } = [0, 1, 4]      // 工厂：按下标构造
MutableList(3) { 0 } = [0, 0, 0]
buildList { add(1); add(2) } = [1, 2]   // 构建期可变，产物只读
mapOf("a" to 1) = {a=1}
setOf(1, 2, 2, 3) = [1, 2, 3]          // 去重
(1..5).toList() = [1, 2, 3, 4, 5]
```

逐个点评：

- `listOf`/`mutableListOf`/`setOf`/`mapOf` 是变参直写；`emptyList<Int>()` 共享全局空实例，零分配。
- **`List(3) { it * it }`** 这个工厂函数长得像构造器，其实是 stdlib 函数：给定大小 + 按下标计算的 lambda，一次成型，免去了"建可变、填数据、再包装"三步。
- [`buildList`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/build-list.html) 是"构建期可变、产物只读"的最佳实践：lambda 里随便 `add`，出来后是只读 `List`——比"先 mutableListOf 再 toList"少一次拷贝，也不会把可变引用泄漏出去。这个函数在 2018–2020 年的 Kotlin 书里还见不到（1.6 才转正），现在的代码里应该优先它。
- `mapOf("a" to 1)` 里的 `to` 是中缀函数，造出 `Pair`。
- `setOf(1, 2, 2, 3)` 默默去重，且不保证——实际上保证按插入序（内幕见 10.11）。

---

## 10.4 管道操作：filter / map / 聚合 / 截取

```kotlin
val nums = (1..10).toList()
println("偶数的平方: ${nums.filter { it % 2 == 0 }.map { it * it }}")
println("第一个 >7 的元素: ${nums.first { it > 7 }}")
println("没有匹配时用 firstOrNull: ${nums.firstOrNull { it > 99 }}")
```

```text
偶数的平方: [4, 16, 36, 64, 100]
第一个 >7 的元素: 8
没有匹配时用 firstOrNull: null
count/sum/avg/max: count=10, sum=55, avg=5.5, max=10
take/drop: take(3)=[1, 2, 3], drop(7)=[8, 9, 10]
distinct: [1, 2, 3]
```

[`filter`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/filter.html) 与 [`map`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/map.html) 是管道的两头：一个挑、一个变。**注意它们返回新列表**——链上每一步都物化一份中间集合，这与 Java Stream 的惰性不同（Kotlin 的惰性等价物是 `asSequence()`，超长链或大数据集时才需要）。

第二行输出是一组"带 `OrNull` 版更安全"的对照：`first { it > 99 }` 会抛 `NoSuchElementException`，`firstOrNull` 给 null。聚合一家（`count`/`sum`/`average`/`maxOrNull`）和截取一家（`take`/`drop`/`distinct`）语义直白，看输出即懂。

---

## 10.5 分组与关联：groupBy / groupingBy / associateBy

统计类需求的三件套，示例逻辑在 `CollectionsDemo.kt`：

```kotlin
fun wordCount(text: String): Map<String, Int> =
    text.lowercase().split(Regex("\\W+")).filter { it.isNotBlank() }
        .groupingBy { it }.eachCount()
```

[`groupingBy`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/grouping-by.html) + [`eachCount`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/each-count.html) 是词频统计的定式：`groupingBy { it }` 把流按"元素自身"分组成惰性的 Grouping，`eachCount()` 一次聚合成 `Map<String, Int>`。和 `groupBy` 的区别在于**不物化中间的分组列表**，大文本下省一份内存。

主程序把它接到排序上取 Top3：

```kotlin
val top = wordCount(text).entries.sortedWith(
    compareByDescending<Map.Entry<String, Int>> { it.value }.thenBy { it.key }
).take(3)
```

`compareByDescending { it.value }.thenBy { it.key }` 是"先按词频降序、同频按字典序升序"的组合比较器，输出：

```text
词频 Top3: the×3, brown×1, dog×1
```

测试覆盖了两个边界：`wordCount("A b a")` 得 `{a=2, b=1}`（大小写归一），`wordCount(" !!! ")` 得空 Map（`\\W+` 切完只剩空白，被 `filter { it.isNotBlank() }` 拦光）。

`groupBy` 双 lambda 形态——第一个 lambda 算 key，第二个变换 value：

```kotlin
fun groupByGrade(students: List<Pair<String, Int>>): Map<Char, List<String>> =
    students.groupBy({ if (it.second >= 60) 'P' else 'F' }) { it.first }
```

输出 `按成绩分组: P: [张三, 王五], F: [李四, 赵六]`——没有第二个 lambda 时 value 是整个元素，有了它分组结果直接是名字列表。

`associateBy` 是"以元素的某属性为 key 建索引"：`people.associateBy { it.name }` 得到 `Map<String, Person>`，输出 `indexByName: [Alice, Bob, Carol, Dave]`。同族还有 `associateWith`（元素当 key、lambda 算 value）和全自由的 `associate`。

最后是一条四段管道，把"筛城市+成年 → 按年龄降序 → 拼字符串"连成一句：

```kotlin
fun adultsIn(people: List<Person>, city: String): String =
    people.filter { it.city == city && it.age >= 18 }
        .sortedByDescending { it.age }
        .joinToString("、") { "${it.name}(${it.age})" }
```

```text
北京的成年人: Alice(30)、Carol(25)
```

测试里 `adultsIn(people, "南京")` 返回 `""`——空管道流经 `joinToString` 得空串，这种"空集合自然落到合理默认值"的性质是管道风格最舒服的地方。

---

## 10.6 flatMap / zip / chunked / windowed

```kotlin
fun allHobbies(people: List<Person2>): Set<String> = people.flatMap { it.hobbies }.toSet()
```

[`flatMap`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/flat-map.html) = 每人映射成一个列表、再全部拍平成一个流。接 `toSet()` 去重，输出 `全员爱好去重: [编程, 读书, 跑步]`（`.sorted()` 是为了让输出稳定）。

`zip` 两两配对、`chunked` 定长切块、`windowed` 滑窗：

```text
zipSums([1,2,3],[10,20,30]) = [11, 22, 33]
chunked(2) = [[0, 1], [2, 3], [4, 5]]
windowed(2) = [[1, 2], [2, 3], [3, 4]]
zipWithNext = (1,2), (2,3), (3,4)
```

**`zip` 按短截断**是测试专门钉的边界：`zipSums(listOf(1, 2, 3), listOf(0))` 得 `[1]`——长列表多出来的元素被静默丢弃，两数据源长度不一致时要先想清楚这是不是你想要的。`windowed(2)` 与 `zipWithNext()` 都产出相邻对，前者更通用（窗口任意大小、可设步长），后者是"步长 1、大小 2"的特化。

---

## 10.7 fold / reduce / runningFold：折叠三兄弟

```kotlin
val ns = listOf(1, 2, 3, 4)
println("求和 reduce: ${ns.reduce { a, b -> a + b }}")
println("fold(10): ${ns.fold(10) { a, b -> a + b }}")
println("runningFold: ${ns.runningFold(0) { a, b -> a + b }}    // 前缀和")
```

```text
求和 reduce: 10
fold(10): 20
runningFold: [0, 1, 3, 6, 10]    // 前缀和
```

- [`fold`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/fold.html) 带初值：`fold(10)` 从 10 开始累，得 20。**初值即空集合时的返回值**，所以 `checksum(emptyList())` 安全返回 1。
- `reduce` 无初值、拿第一个元素当种子——空集合无处可取，直接抛 `UnsupportedOperationException`（测试 `assertFailsWith` 钉死了这条）。不确定集合非空时别用 reduce。
- `runningFold`（旧名 `scan`）把每一步的中间累加值都留下来——前缀和一行出。示例用它造 `[0, 1, 3, 6, 10]`。

`CollectionsDemo.kt` 里的 `checksum` 演示了 fold 的实战形态——一个经典的 31 倍哈希：

```kotlin
fun checksum(nums: List<Int>): Int = nums.fold(1) { acc, n -> (acc * 31 + n) % 100_007 }
```

测试里有手算过程注释：`(1*31+1)=32 → (32*31+2)=994 → (994*31+3)=30817`，断言 `checksum(listOf(1, 2, 3)) == 30817`。折叠类操作学起来抽象，落地后就是这种"循环变量 + 累加器"的统一抽象。

---

## 10.8 Map 操作：getOrPut 与视图变换

```kotlin
val m = mutableMapOf("a" to 1)
m["b"] = 2
println("getOrPut: ${m.getOrPut("c") { 3 }}，再取还是同一个值: ${m.getOrPut("c") { 99 }}")
println("mapValues: ${m.mapValues { it.value * 10 }}")
println("filterKeys: ${m.filterKeys { it != "b" }}")
```

```text
getOrPut: 3，再取还是同一个值: 3
mapValues: {a=10, b=20, c=30}
filterKeys: {a=1, c=3}
```

[`getOrPut`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/get-or-put.html) 是"有则取之、无则算一个存进去再取"——第一次 `"c"` 不存在，存入 3 并返回；第二次虽然 lambda 写的是 99，但 key 已存在，**lambda 不执行**，返回的还是 3。它是手写 `if (!containsKey) put(...)` 的终结者，做缓存、建索引、分组累加都用得上。

`mapValues`/`filterKeys` 是"只动 value / 只按 key 筛"的视图变换，返回新 Map。遍历 Map 用解构：`for ((k, v) in pairs)`——data class 那套 `componentN`（06 章）在 `Map.Entry` 上同样适用。

测试还顺手验证了 `getOrPut` 后 key 真的落了盘：`assertEquals(3, m["c"])`。

---

## 10.9 Set 运算：并、交、差

```kotlin
val a = setOf(1, 2, 3); val b = setOf(3, 4)
```

```text
a ∪ b = [1, 2, 3, 4]（或 a.union(b)）
a ∩ b = [3]
a − b = [1, 2]
```

`a + b` 是 `union` 的运算符形式，`a - b` 是差集，`intersect` 是交集。注意输出打出来是 `[1, 2, 3, 4]` 这样的列表样——运算结果实际是 `LinkedHashSet`，但 `toString` 长得像 List；测试用 `assertEquals(setOf(1, 2, 3, 4), a + b)` 按集合相等断言，不看字符串。

---

## 10.10 排序：sorted 新列表 vs sort 原地

本章标题级的陷阱，示例专门写了一个函数：

```kotlin
fun sortDemo(): String {
    val src = mutableListOf(3, 1, 2)
    val copy = src.sorted()                 // 新列表
    return "src=$src, copy=$copy"
}
```

```text
src=[3, 1, 2], copy=[1, 2, 3]
```

**`sorted()` 返回新列表，原列表纹丝不动**；要原地排序得在 `MutableList` 上调 `sort()`。这一对命名是全域规则：`sorted/sortedBy/sortedDescending` 系返回新集合，`sort/sortBy` 系原地修改。测试 `assertEquals("src=[3, 1, 2], copy=[1, 2, 3]", sortDemo())` 钉死了"原列表不变"这件事。忘了这点的代码长这样：`list.sorted()` 然后继续用 `list`——排序结果直接被丢弃，bug 悄无声息。

多键排序用组合比较器：

```kotlin
val byName = people.sortedWith(compareByDescending<Person> { it.age }.thenBy { it.name })
```

```text
按年龄降序: Dave, Alice, Carol, Bob
```

先按年龄降序（41 的 Dave 打头），同岁再按名字字典序——30 的 Alice 排在 25 的 Carol 前是年龄决定的，与名字无关。

`compareByDescending`/`thenBy` 背后的积木在 [kotlin.comparisons](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.comparisons/) 包——API 索引里一个容易被忽略的包，排序相关的公共函数全住在这。两个最基础的（`src/CollectionsDemo.kt` 第 42-51 行）：

```kotlin
/** kotlin.comparisons.compareValues：两值比较返回 -1/0/1，自定义比较器的最小结石 */
fun ageGroup(p: Person): Int = when {
    p.age < 18 -> 0        // 未成年
    p.age < 60 -> 1        // 成年
    else -> 2              // 老年
}

/** compareValuesBy：按抽取的键依次比较——选择器列表的顺序就是优先级顺序 */
fun byAgeGroupThenName(a: Person, b: Person): Int =
    compareValuesBy(a, b, { ageGroup(it) }, { it.name })
```

[compareValues](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.comparisons/compare-values.html) 是"两个可比值 → -1/0/1"的最小积石： Comparable 的值直接比，且两侧都能可空（null 有明确排位）。所有自定义 `Comparator` 的手写逻辑，最终都沉淀成这几行。Main 里的演示与输出：

```kotlin
println("compareValues(1, 2) = ${compareValues(1, 2)}, compareValues(\"b\", \"a\") = ${compareValues("b", "a")}")
println("compareValuesBy(年龄段, 名字): ${people.sortedWith { a, b -> byAgeGroupThenName(a, b) }.joinToString { it.name }}")
```

```
compareValues(1, 2) = -1, compareValues("b", "a") = 1
compareValuesBy(年龄段, 名字): Bob, Alice, Carol, Dave
```

[compareValuesBy](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.comparisons/compare-values-by.html) 接收**一串选择器**：先比 `ageGroup`（0/1/2 三档），相等再比 `name`——**选择器的书写顺序就是优先级顺序**，比手写 if-else 链声明式得多。输出把三档看得清清楚楚：17 岁的 Bob（未成年档）打头，30 的 Alice 与 25 的 Carol 同档按字典序（Alice 前），41 岁的 Dave（老年档）垫底。测试 `testCompareValues` 三层断言：`compareValues` 的 -1/0/1 三态各一条，`byAgeGroupThenName` 的整序结果一条，另补 `assertEquals(-1, byAgeGroupThenName(Bob, Alice))` 直接验比较函数本身。

这个包还有一对常用件：[compareBy](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.comparisons/compare-by.html)（选择器直接造 Comparator，`compareBy<Person> { it.age }` 与示例的 `compareByDescending { it.age }.thenBy { it.name }` 同宗）与 `Comparator` 的扩展（`naturalOrder()`/`reversed()`/`thenComparator {}`）——Java 的 `Comparator.comparing().thenComparing()` 链在 Kotlin 侧的对应物。

---

## 10.11 接口层次与实现内幕

两条先验知识，然后看实测。第一，`List` 继承 `Collection`，而 `Map` 自成一族：

```text
继承检查: List is Collection=true, Map is Collection=false
```

（源码里先 `as Any` 再 `is` 检查：静态类型已知时 K2 会报"检查恒真/恒假"告警，教学演示绕一下；这也是 `-Werror` 下必须处理的小讲究。）

第二，Kotlin 集合**没有自己的实现**，全部委托给 JDK：

```text
  listOf -> java.util.Arrays$ArrayList
  mutableListOf -> java.util.ArrayList
  listOf().toList() -> java.util.ArrayList
  buildList -> kotlin.collections.builders.ListBuilder
  setOf -> java.util.LinkedHashSet
  mapOf -> java.util.Collections$SingletonMap
```

逐条解读：

- `listOf(1, 2)` 底下是 `Arrays$ArrayList`——注意这是 `Arrays.asList` 返回的那个**定长**内部类，不是 `java.util.ArrayList`；名字像，两个类。测试注释专门提醒："simpleName 分不清两者，要看全限定名"。
- `mutableListOf` 才是真 `ArrayList`；`buildList` 的产物是 Kotlin 自己的 `ListBuilder`（少数非 JDK 的实现）。
- `setOf` 是 `LinkedHashSet`——所以 `setOf` 迭代按插入序，这不是错觉。
- `mapOf` 单元素时是 `Collections$SingletonMap`，≥2 元素切换成 `LinkedHashMap`（测试两条断言钉死了这个**大小分派**）：`assertEquals("java.util.Collections\$SingletonMap", mapOf(1 to 2)::class.java.name)`、`assertEquals("java.util.LinkedHashMap", mapOf(1 to 2, 3 to 4)::class.java.name)`。小集合用特化实现省内存，是 stdlib 的常规手法。
- 排序/反转这些操作最终落到 `Arrays.sort`/`Collections.reverse` 的 JDK 静态调用上，kotlin 集合库只是薄糖衣——性能心智模型可以直接搬 Java 的。

这一节的实践意义：**Kotlin 集合与 Java 集合是同一批对象**，互操作零成本，`::class.java.name` 随时能看穿；调试性能问题时，ArrayList 的扩容、LinkedHashMap 的序，全都照常适用。

---

## 10.12 坑位清单

1. **只读 ≠ 不可变**：`List` 引用挡不住底层 `MutableList` 的改动，跨边界要快照用 `toList()`。
2. **`sorted` 不动原列表**：要原地排请 `sort`；`val sortedList = list.sorted()` 里接不住结果就是白排。
3. **`reduce` 空集合抛 `UnsupportedOperationException`**：可能为空时换 `fold` 或 `reduceOrNull`。
4. **不带 `OrNull` 的查找失败就抛**：`first`/`max`（`max` 1.7 起为非空返回版，JVM 名 `maxOrThrow`；空集合抛 `NoSuchElementException`）——不确定有结果就加 `OrNull` 后缀（`firstOrNull`/`maxOrNull`）。
5. **`zip` 按短截断**：两边长度不一致时多余元素静默丢弃，关键数据先对齐长度。
6. **管道每步都物化中间列表**：超长链先 `asSequence()`，结尾 `toList()` 收回来。
7. **Map 不是 Collection**：没有 `filter`/`map` 元素级管道？——其实有，但作用在 `entries` 上；记住 `Map` 的操作多是 `mapValues`/`filterKeys` 这种"指定动哪头"的形态。
8. **`getOrPut` 的 lambda 只在缺 key 时执行**：把有副作用的代码放进去，执行次数是"每个 key 至多一次"，别拿它当计数器用。
9. **`compareValuesBy` 的选择器顺序就是优先级**：写反了排序就反了；比较器还必须满足自反与传递，自相矛盾的比较器在 JDK 的 TimSort 里会抛 `IllegalArgumentException: Comparison method violates its general contract`。

---

上一章：[09 ⭐object与委托](09-delegation.md) · 下一章：[11 ⭐泛型](11-generics.md)
