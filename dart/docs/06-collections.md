# 06 · 集合：List、Set、Map 与 Iterable

> 对应示例：examples/06_collections.dart

## 6.1 解决什么问题

程序的一半工作是搬运和变换数据，而集合就是数据的容器。Dart 的集合体系有三个主角（List/Set/Map）加一个灵魂概念（Iterable 惰性序列），外加一个杀手锏语法（字面量里的 if/for）。本章把五件事一次讲清——第 05 章的匿名函数会在这里大量上场。

先看 List 的日常：

```dart
  // ═══ 6.1 List ═══
  var langs = ['Dart', 'Go', 'Rust'];
  langs.add('Kotlin'); // 末尾追加
  langs.insert(0, 'C'); // 指定位置插入
  langs.remove('Go');
  print('langs: $langs');
  print('first=${langs.first} last=${langs.last} length=${langs.length}');
  print('切片 [1..3): ${langs.sublist(1, 3)}');
```

`sublist(1, 3)` 是左闭右开区间——与绝大多数现代语言一致。`first/last` 在空列表上抛异常，判空场景先 `isEmpty`。

## 6.2 字面量构建：Dart 的杀手锏

这是 Flutter 界面代码的语法基石，也是 Dart 相对 Java/C# 独有的表达力：

```dart
  // ═══ 6.2 字面量构建：spread 与集合 if/for（Dart 特色） ═══
  var base = [1, 2, 3];
  var withZero = [0, ...base]; // ... 展开
  var compact = [
    ...base,
    if (base.length > 2) 99, // 条件成立才收入
    for (final x in base) x * 10, // 逐个变换收入
  ];
  print('withZero: $withZero');
  print('compact: $compact');
```

对照"传统写法"感受一下差距：

| 目标 | 传统写法 | 字面量写法 |
|---|---|---|
| 拼接列表 | `var l = [0]; l.addAll(base);` | `[0, ...base]` |
| 条件加入 | `if (cond) l.add(99);` | `[if (cond) 99, …]` |
| 变换收集 | `l.addAll(base.map(…))` | `[for (final x in base) x * 10, …]` |

三者可以任意组合、嵌套，集合还没"出生"逻辑就已写完。Set 与 Map 字面量同样支持这套语法。

## 6.3 Set：唯一性即语义

```dart
  // ═══ 6.3 Set ═══
  var tags = <String>{'dart', 'flutter'};
  tags.add('dart'); // 重复元素被忽略
  var seen = <String>{};
  for (final w in 'to be or not to be'.split(' ')) {
    seen.add(w);
  }
  print('tags: $tags（长度 ${tags.length}）');
  print('去重后: $seen');
  print('并集: ${{1, 2}.union({2, 3})} 交集: ${{1, 2}.intersection({2, 3})}');
```

字面量用花括号 `{…}`（与 Map 区分：有冒号是 Map，没有是 Set）；空 Set 必须带类型参数 `<String>{}`（裸 `{}` 会被当成 Map）。Set 的本职是"去重 + 成员测试（contains，O(1)）"，集合代数 union/intersection/difference 是免费附赠。

## 6.4 Map：键值对

```dart
  // ═══ 6.4 Map ═══
  var scores = {'Alice': 90, 'Bob': 82};
  scores['Carol'] = 95; // 新增/覆盖
  scores.putIfAbsent('Bob', () => 0); // 已存在则不动
  print('scores: $scores');
  print("Bob=${scores['Bob']} Dave=${scores['Dave'] ?? '无'}");
  for (final entry in scores.entries) {
    print('${entry.key}: ${entry.value}');
  }
```

关键认知：`map[缺键]` **返回 null 而不抛异常**（返回类型是 `V?`）——所以读 map 几乎总要配 `??` 兜底（第 10 章）。`putIfAbsent` 与 `[]=` 的差别就是"只在缺席时写入"，惰性初始化缓存的惯用法。

## 6.5 Iterable 操作：一套组合子打天下

List/Set 都是 Iterable，共享一整套变换方法——这套路数与函数式语言的 map/filter 族一致：

```dart
  // ═══ 6.5 Iterable 操作：where/map/any/every/fold ═══
  var nums = [5, 2, 9, 1, 7];
  print('sorted: ${[...nums]..sort()}'); // 拷贝后排序，不动原列表
  print('where>4: ${nums.where((n) => n > 4).toList()}');
  print('map×2: ${nums.map((n) => n * 2).toList()}');
  print('any>8: ${nums.any((n) => n > 8)} / every>0: ${nums.every((n) => n > 0)}');
  print('fold 求和: ${nums.fold(0, (acc, n) => acc + n)}');
  print('reduce: ${nums.reduce((a, b) => a + b)}');
```

| 方法 | 返回 | 一句话 |
|---|---|---|
| `where(test)` | Iterable | 过滤 |
| `map(f)` | Iterable | 逐个变换 |
| `any` / `every` | bool | 存在 / 全部满足 |
| `fold(初值, f)` | 累加类型 | 万能归约，空集合安全 |
| `reduce(f)` | 元素类型 | 无初值归约，**空集合抛错** |
| `sort()` | void | **原地**排序，仅 List 有 |

fold 与 reduce 的取舍：需要非元素类型的累计值（比如从 List<int> 累出一个 Map）或列表可能为空，用 fold。

## 6.6 惰性：Iterable 是"管道"不是"结果"

```dart
  // ═══ 6.6 Iterable 是惰性的：toList() 才落袋 ═══
  var lazy = nums.where((n) => n > 2).map((n) => n * 10); // 还没执行
  print('lazy 运行时类型: ${lazy.runtimeType}');
  print('toList 后: ${lazy.toList()}');
```

`where/map` 返回的是**待执行的管道**（输出 `MappedIterable`），没人消费就不会跑；`toList()/toSet()` 才真正执行并把结果装进新集合。惰性的价值：链式多步操作只遍历一次、能接无限序列；代价见坑位清单——**同一个 Iterable 遍历第二次会重新执行一遍管道**。

## 6.7 不可变视图

```dart
  // ═══ 6.7 不可变列表 ═══
  var frozen = List.unmodifiable([1, 2, 3]);
  // frozen.add(4); // 运行时抛 UnsupportedError
  print('frozen: $frozen');
```

`List.unmodifiable` 是**运行时只读视图**（写它会在运行时抛错）；`const [1, 2, 3]` 是**编译期冻结**（连"试图改"都编译不过的地方更少，但深度冻结且规范化，见第 03 章）；`final list = [...]` 只是引用不可再绑定。三档"不可变"，按需要选最便宜的那档。

## 坑位清单

- **忘 toList 就消费**：`print(nums.map(…))` 打出来的是 `(1, 2, 3)` 这种 Iterable 描述而不是列表——要 `[1, 2, 3]` 就 `.toList()`。
- **reduce 空集合抛错**：源头可能为空的管道一律 fold（有初值）。
- **sort 是原地排序**：`nums.sort()` 之后 nums 变了；要保留原序先拷贝 `[...nums]..sort()`（示例 6.5 的惯用法）。
- **遍历时删元素**：for 循环里 remove 会跳元素，用 `removeWhere(predicate)` 一步到位。
- **`{}` 是 Map**：空 Set 必须写 `<String>{}`，漏类型参数会得到奇怪的 Map 推断。
