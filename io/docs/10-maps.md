# 10 · 映射

> 对应示例：[`examples/10_maps/10_maps.io`](../examples/10_maps/10_maps.io)

## 10.1 Map clone 建表：atPut 写入、at 读取、hasKey 判断、size 计数

一句话：`Map clone` 造空表，写入用 `atPut`，读取用 `at`，`size` 数的是条目。

```text
-- 10.1 Map clone 建表：atPut 写入、at 读取、hasKey 判断、size 计数
空表的 size = 0
空表的 isEmpty = true
写入三个之后的 size = 3
m at("a") = 1
hasKey("a") / hasKey("zz") = true,false
hasValue(3) / hasValue(9) = true,false
排序后的键 = a,b,c
排序后的值 = 1,2,3
```

```io
m := Map clone
m atPut("b", 2)
m atPut("a", 1)
m atPut("c", 3)
m at("a")            // 1
m hasKey("zz")       // false
m keys sort          // list("a", "b", "c")
```

`keys` 和 `values` 给的都是 `List`，所以 `sort` 直接可用；注意这一行里的 `排序后的键` 是我们自己 `sort` 出来的，不是为了好看——原因见 10.4。

> **为什么重要**：Io 里「表」有两条实现路径：`Map`（哈希表）和 `Object`（槽表）。`Map` 只管哈希那半边，`size` / `keys` / `hasKey` 都只看条目，完全无视挂在上面的槽——这一点在 10.6 会变成陷阱。

## 10.2 缺键给 nil、键必须是 Sequence、删不存在的键不报错

一句话：读缺键、删缺键都安静地过，只有**键的类型不对**才抛异常。

```text
-- 10.2 缺键给 nil、键必须是 Sequence、删不存在的键不报错
m at("zz") 是 nil 吗 = true
拿数字当键的异常消息 = argument 0 to method 'atPut' must be a Sequence, not a 'Number'
atIfAbsentPut("b", 9) 返回 = 9
再 atIfAbsentPut("b", 100) 返回的是老值 = 9
这时候的 size = 2
删一个不存在的键之后 size 还是 = 2
removeAt 返回的是表自己吗 = true
再删掉 a，剩下的键是 = b
```

```io
m := Map clone
m atPut("a", 1)
m at("zz")                        // nil，不报错
try(m atPut(1, "x")) error        // argument 0 to method 'atPut' must be a Sequence, not a 'Number'
m atIfAbsentPut("b", 9)           // 9，顺手写进去
m atIfAbsentPut("b", 100)         // 还是 9，已存在就不覆盖
m removeAt("zz")                  // 安静地什么都不做，返回 m 本身
```

键只能是 `Sequence`（字符串是典型代表），数字键会被直接拒绝。`removeAt` 的返回值和 List 相反：Map 的 `removeAt` 返回**表自己**，所以 `m removeAt("a") removeAt("b")` 这种链式是合法的。

> **为什么重要**：`atIfAbsentPut` 的返回值是「当前的值」而不是「有没有写进去」。做计数器时 `atPut(k, (m atIfAbsentPut(k, 0)) + 1)` 这类写法要清楚它在干什么——已存在时会拿老值。

## 10.3 Map 默认 asString 打的是地址，永远不要打进输出

一句话：`Map` 的默认 `asString` 是 `Map_0x...`，每次都不一样，任何要落盘的输出都得自己拼。

```text
-- 10.3 Map 默认 asString 打的是地址，永远不要打进输出
m asString 里有 Map_0x 这种地址前缀吗 = true
内容一样的两张表，asString 相同吗 = false
要确定性就自己拼 = x=1
```

```io
m := Map clone
m atPut("x", 1)
n := Map clone
n atPut("x", 1)
m asString                        // "Map_0x...:"，地址
(m keys sort) map(k, k .. "=" .. (m at(k) asString)) join(",")   // "x=1"
```

两张内容完全相同的表，`asString` 也不同——因为打的是对象地址。要确定性的字符串，就用 `keys sort` 之后自己拼；示例里把这个动作抽成了 `kv(m)` 和 `rankedPairs(m)` 两个小工具。

> **为什么重要**：凡是「默认 `asString` 里带 0x 的对象」（`Map`、`Object`、方法、块）都不能直接进输出。这类东西一旦被写进「期望输出」的快照，测试就变成了随机的。

## 10.4 keys / values 的顺序不可依赖：先 sort 再打

一句话：同一进程里、同样插入序是稳定的，但换一个插入顺序就变；规范没有承诺任何顺序。

```text
-- 10.4 keys / values 的顺序不可依赖：先 sort 再打
同一进程、同样插入序的两份表，keys 顺序相同吗 = true
换一个插入顺序，keys 顺序还相同吗 = false
keys 顺序就是插入顺序吗 = false
sort 之后两份表一定一样吗 = true
排序后的键才是可以打的东西 = a,b,c,d,e,f
```

```io
a := Map clone
list("a", "b", "c", "d", "e", "f") foreach(k, a atPut(k, 1))
c := Map clone
list("f", "e", "d", "c", "b", "a") foreach(k, c atPut(k, 1))

a keys join(",") == c keys join(",")          // false：顺序跟插入历史有关
a keys join(",") == "a,b,c,d,e,f"             // false：也不是插入顺序
a keys sort join(",") == c keys sort join(",") // true：排完才可比
```

本机实测：同一进程内、同样的插入序列确实是稳定的（所以 `a` 和 `b` 比出来是 `true`），但只要插入顺序一换，`keys` 的顺序就跟着变，而且它既不等于插入序、也不是排序序——它只是哈希桶的摆放顺序。所以**代码里凡是把 `keys` / `values` 送去打印、比较、落盘的地方，都必须先 `sort`**。

> **为什么重要**：这是「本机能跑」和「可靠」的典型分界。示例里我们连 `a keys join(",")` 的原文都不打出来——只打「两份是否相同」这种布尔量。这样即使换了实现或换了 VM，输出依然是逐字节确定的。

## 10.5 遍历：foreach(k, v, ...) 与 keys sort + foreach

一句话：`foreach` 的顺序跟着 `keys` 走，所以「与顺序无关的累加」可以放心用，要输出就得先排序。

```text
-- 10.5 遍历：foreach(k, v, ...) 与 keys sort + foreach
foreach 求和（与顺序无关，可以放心用） = 6
keys sort 之后逐项收集 = a:1,b:2,c:3
m map(k, v, ...) 的结果排序后 = 10,20,30
select 出来的也是 Map，键排序后 = a,c
```

```io
total := 0
m foreach(k, v, total = total + v)              // 顺序无关，安全

lines := List clone
(m keys sort) foreach(k, lines append(k .. ":" .. (m at(k) asString)))

(m map(k, v, v * 10)) sort                      // map 返回 List，排序后再用
(m select(k, v, v != 2)) keys sort              // select 返回 Map，也要 sort
```

`foreach(k, v, ...)` 一次把键和值都给你；`map` 和 `select` 也是 `(k, v, ...)` 两参形态。`map` 只收表达式的结果、返回 `List`，`select` 保留条目、返回 `Map`。

> **为什么重要**：判据是「这个操作对顺序敏感吗」。求和、计数、求最大值都不敏感；拼接字符串、取「第一个」「最后一个」、比较两份输出是否相等，都敏感——后者一律先 `sort`。

## 10.6 Map 与对象：:= 建的是槽，atPut 建的才是条目

一句话：`Map` 同时是哈希表和对象，`atPut` 走哈希、`:=` 走槽，两套东西互不相认。

```text
-- 10.6 Map 与对象：:= 建的是槽，atPut 建的才是条目
m size（只数条目） = 1
hasKey("a") / hasKey("b") = true,false
hasSlot("a") / hasSlot("b") = true,true
m at("b") 是 nil 吗 = true
但 m b 能取到 = 2
keys 里只有条目键 = a
asObject 之后的 type = Object
o a（条目变成了槽） = 1
Object clone do(...) 才是造对象的写法，槽有 = x,y
```

```io
m := Map clone
m atPut("a", 1)      // 条目：进哈希表
m b := 2             // 槽：挂在对象上，不是条目
m size               // 1
m hasKey("b")        // false
m hasSlot("b")       // true
m at("b")            // nil
m b                  // 2

o := m asObject      // 条目变成槽
Object clone do(x := 1; y := 2)   // 造对象的标准写法，多个槽用分号
```

`Map clone do(a := 1)` 并不会得到「一个装了两个条目的表」——它得到的是「一张空表 + 两个普通槽」。想造对象就用 `Object clone do(...)`；想把表变成对象就 `asObject`；反过来 `List asMap` 是另一条路（它要求表项是「键值对」形状）。

> **为什么重要**：`hasKey` 和 `hasSlot` 是两个世界的问题，混用是 bug 的温床。经验规则：**要 `keys` / `size` / 遍历，用 `atPut`；要当对象用（`o field`、方法查找、proto 链），才用 `:=`。**

## 10.7 与 List 互转、按 value 排序、分组、merge

一句话：`asList` 给 `[键, 值]` 列表，排序要自己搭比较器，分组用 `groupBy`，`merge` 不改原表。

```text
-- 10.7 与 List 互转、按 value 排序、分组、merge
asList 每项是 [键, 值]，排序后拼出来 = x:3 y:1 z:3
按 value 降序、同值按 key 升序 = x:3,z:3,y:1
select 留下 value > 1，键是 = x,z
map 只取 value * 10，返回的是 List = 10,30,30
detect 返回 [键, 值] = list("y", 1)
merge 返回新表 = w,x,y,z
m 自己没被改 = x,y,z
groupBy 的键（是 asString 出来的字符串） = 0,1
所以偶数齿在 "0"、奇数齿在 "1" = list(2, 4) list(1, 3, 5)
```

```io
m := Map clone
m atPut("x", 3); m atPut("y", 1); m atPut("z", 3)

m asList                                  // list(list("x", 3), ...)，顺序不可依赖
(m asList) map(p, (p at(0)) .. ":" .. (p at(1) asString)) sort

// 按 value 降序、同值按 key 升序（比较器要两个形参，见 09.6）
(m keys map(k, list(k, m at(k)))) sortBy(block(p, q,
    if(p at(1) == q at(1), (p at(0)) < (q at(0)), (p at(1)) > (q at(1)))))

list(1, 2, 3, 4, 5) groupBy(v, (v % 2) asString)   // Map，键是字符串
```

`groupBy` 的键是**表达式 `asString` 之后的字符串**，所以取的时候要写 `g at("0")`、`g at("1")`，以数字 key 去取是取不到的。`merge` 返回合并后的新表，原表不动；`select` 返回 `Map`、`map` 返回 `List`、`detect` 返回 `[键, 值]` 两元列表——三个函数三种返回形状。

> **为什么重要**：Map 的「按值排序」没有内置 API。标准做法就是「转成 `[键, 值]` 列表 → 自己写比较器排序」。比较器里同时指定值和键的次序（值降序、键升序），结果才与 `keys` 的原始顺序无关，才是确定性的。

## 10.8 实战：词频计数器

一句话：Map 最经典的用法就是计数器——`at` 读不到给 nil，补个 0 再写回去。

```text
-- 10.8 实战：词频计数器
不同词的个数 = 3
总词数（values 求和） = 6
按词排序输出 = io=3,is=2,small=1
按次数降序、同次数按词升序 = iox3,isx2,smallx1
```

```io
words := list("io", "is", "small", "io", "is", "io")
counts := Map clone
words foreach(w,
    c := counts at(w)
    if(c == nil, c = 0)
    counts atPut(w, c + 1)
)

counts size                                   // 3
counts values reduce(x, y, x + y)             // 6
(counts keys sort) map(k, k .. "=" .. (counts at(k) asString)) join(",")
```

计数三步：`at` 拿老值 → nil 就当作 0 → 写回 `+1`。输出一律走 `keys sort`，排名一律走「转 `[键, 值]` 再排序」。

> **为什么重要**：`if(c == nil, c = 0)` 这一行就是 Io 版的「默认值」——Io 没有默认参数，`c` 拿不到就用 `nil` 兜底（见 08 章）。把它记成肌肉记忆，Map 计数的写法就固定下来了。

## 10.9 坑位清单

1. **以为 `m x := 1` 往表里塞了个条目** → `:=` 建的是普通槽，`size` / `hasKey` 都看不见它；条目必须用 `atPut`。
2. **拿数字或别的非 Sequence 当键** → `atPut` 直接抛 `argument 0 to method 'atPut' must be a Sequence, not a 'Number'`，键要先 `asString`。
3. **把 `Map` 本身打印出来** → 默认 `asString` 是 `Map_0x...`（地址）；用 `keys sort` 自己拼确定性字符串。
4. **直接打印 `m keys` / `m values` 或拿它做断言** → 顺序不做承诺（实测换插入顺序就变）；一律先 `sort`。
5. **依赖 `foreach` 的输出顺序** → 它的顺序跟着 `keys` 走；求和、计数这类顺序无关的可以放心用，落盘输出要先 `sort`。
6. **以为 `at` 缺键会抛异常** → 缺键给 nil，不报错；只有键的类型不对才抛异常。
7. **以为 Map 的 `removeAt` 返回被删掉的值** → 它返回表自身（List 的 `removeAt` 才返回元素），删不存在的键也不报错。
8. **以为 `atIfAbsentPut` 会覆盖已有值** → 已存在时返回老值且不写入；返回的始终是「当前的值」。
9. **记混 `select` / `map` / `detect` 的返回形状** → `select` 给 Map、`map` 只收值给 List、`detect` 给 `list(key, value)`。
10. **把 `groupBy` 的键当数字用** → 键是表达式 `asString` 出来的字符串，取法要 `g at("0")`，写 `g at(0)` 取不到。

---

上一章：[09 · 列表](09-lists.md) · 下一章：[11 · 块与闭包](11-blocks.md)
