# 21 · 序列化与持久化

> 对应示例：[`examples/21_serialize/21_serialize.io`](../examples/21_serialize/21_serialize.io)
>
> 本章的结论偏「能力边界」：这个构建里的 `serialized` **只对没有本地槽的对象成立**，
> 有槽对象会自己递归到栈溢出（21.4 实测）。带槽对象的持久化必须自己写（21.7）。

## 21.1 serialized 是唯一入口：没有 Serialize 对象

一句话：Io 的序列化就是 `Object serialized` 这一个槽，没有 `Serialize` 对象，
没有 `toString` / `toObject`，也没有格式版本。

实测输出：

```text
-- 21.1 serialized 是唯一入口：没有 Serialize 对象
Object 上有 serialized = true
Object 上有 justSerialized = true
Object 上有 serializedSlots = true
Lobby 上有 Serialize 这个槽 = false
Lobby 上有 SerializationStream 这个槽 = true
try(Serialize toString(list(1))) 的结果 = Exception
同上，异常消息 = Object does not respond to 'Serialize'
serialized 的参数是流，不是 nil 才用它 = method(stream, if(stream ==(nil), setSlot("stream", SerializationStream clone)) ;
justSerialized(stream) ;
stream output)
```

源码（`libs/iovm/io/Serialize.io`）就这四行是全部的门面：

```io
Object do(
	serialized := method(stream,
		if(stream == nil, stream := SerializationStream clone)
		justSerialized(stream)
		stream output
	)
	justSerialized := method(stream,
		stream write(<proto 名>, " clone do(\n")
		self serializedSlots(stream)
		stream write(")\n")
	)
	serializedSlots := method(stream,
		self serializedSlotsWithNames(self slotNames, stream)
	)
	serializedSlotsWithNames := method(names, stream,
		names foreach(slotName,
			stream write("\t", slotName, " := ")
			self getSlot(slotName) serialized(stream)
			stream write("\n")
		)
	)
)
```

`serialized` 可以接一个 `SerializationStream`（缓冲区），不接就自己造一个。
`SerializationStream` 只有 `seen` / `output` 两个槽和一个 `write`。

> **为什么重要**：整个序列化机制是**用 Io 自己写的**（不是原语）。这意味着它的
> 行为完全由这几个方法决定——21.4 的爆栈也是这几个决定的。

## 21.2 各类型的产物：写出来的是可回读的 Io 源码

一句话：产物不是 JSON 也不是二进制，而是**一句可求值的 Io 源码**。

实测输出：

```text
-- 21.2 各类型的产物：写出来的是可回读的 Io 源码
数字 serialized = 42
浮点 serialized = 3.5
nil serialized = nil
true serialized = true
false serialized = false
字符串 serialized = "hi"
带引号的串 serialized = "say \\\"hi\\\""
List serialized = list(1, 2, 3);
嵌套 List serialized = list(list(1, 2);, 3);
Map serialized = Map clone do(atPut("b", 2);atPut("a", 1););
Block serialized = block(v, v +(1))

固定 Date serialized = Date clone do(setYear(2020) setMonth(1) setDay(2) setHour(3) setMinute(4) setSecond(5));
嵌套 List 的产物（内层多了个分号） = list(list(1, 2);, 3);
回读后与原值相等 = true
但它 asString 出来把内层的数字印成带引号的串 = list(list("1", "2"), 3)
其实内层元素还是 Number = true
```

每种类型有自己的 `justSerialized`：

| 类型 | 产物形状 | 备注 |
|---|---|---|
| `nil` / `true` / `false` | `nil` / `true` / `false` | 字面量 |
| `Number` | `asSimpleString` | `42`、`3.5` |
| `Sequence` | `escape asSimpleString` | 加引号、转义，所以可回读 |
| `List` | `list(a, b);` | 结尾带分号 |
| `Map` | `Map clone do(atPut(k, v);…);` | 按插入序写 |
| `Block` | `code` | **只有代码，没有作用域** |
| `Date` | `Date clone do(setYear(…) …);` | 用 setter 拼 |

两个实测出来的显示/产物瑕疵：

- 嵌套 `List` 的产物是 `list(list(1, 2);, 3);`——内层的结束分号留在了参数位置上。
  Io 的解析器容忍它，回读结果与原值相等（实测 `= true`）。
- 但回读后的嵌套 List，`asString` 会把内层的数字印成带引号的字符串
  （`list(list("1", "2"), 3)`），而 `at(0) at(0)` 仍然是 `Number`。**这是 `asString` 的
  显示假象，不要拿它当数据判断依据。**

> **为什么重要**：产物是「源码」这件事有两个直接后果——回读等于 `doString`（21.3 的
> proto 问题就从这来），以及**产物可以被 `eval` 执行**（21.8 的安全与版本问题也从这来）。

## 21.3 往返：proto 是「同一个」还是「重新求值」

一句话：产物是 `<proto 名> clone do(…)`，回读时**按名字重新查找** proto。

实测输出：

```text
-- 21.3 往返：proto 是「同一个」还是「重新求值」
pt type = Point
pt serialized 原文 = Point clone do(
)

回读后 proto 是同一个 Point = true
重绑定 Point 后，回读仍是老 Point 吗 = false
重绑定 Point 后，回读是新 Point 吗 = true
名字不存在时 = Object does not respond to 'NoSuchProto'
```

实验：

```io
Point := Object clone
pt := Point clone
pointText := pt serialized
(Lobby doString(pointText)) proto isIdenticalTo(Point)      // true

oldPoint := Point
Point = Object clone                                        // 把名字抢走
(Lobby doString(pointText)) proto isIdenticalTo(oldPoint)   // false
(Lobby doString(pointText)) proto isIdenticalTo(Point)      // true
```

所以答案是：**proto 不是「被序列化下来的东西」，而是回读那一刻按名字重新求值的结果。**

- 名字还在、且指向同一个对象 → `isIdenticalTo` 为真，方法、`proto` 链全都在。
- 名字被重绑定 → 你拿到的是**新对象**的 clone。
- 名字不存在（换了进程、换了库版本、改了名） → `Object does not respond to 'NoSuchProto'`。

> **为什么重要**：这是序列化最核心的坑。它意味着 Io 的序列化**不能跨版本、不能跨改名**，
> 也意味着「反序列化」的语义依赖**求值环境**，不依赖字节流本身。

## 21.4 大坑：对象一旦有本地槽，serialized 直接栈溢出

一句话：`Object serialized` 只对「没有任何本地槽」的对象成立；有槽就爆栈。

实测输出：

```text
-- 21.4 大坑：对象一旦有本地槽，serialized 直接栈溢出
无本地槽的对象 serialized 原文 = [Object clone do(
)
]
无本地槽的对象 slotNames = list()
有本地槽的对象 slotNames = list("x")
有本地槽的对象 serialized 的异常消息 = Stack overflow: frame depth exceeded 10000
两个槽也一样 = Stack overflow: frame depth exceeded 10000
嵌套在 List 里的对象也一样 = Stack overflow: frame depth exceeded 10000
手工点名槽位就不会爆栈 = [	x := 1
]
```

最小复现：

```io
(Object clone) serialized                        // ok   → "Object clone do(\n)\n"
(Object clone do(x := 1)) serialized             // 爆栈 → Stack overflow: frame depth exceeded 10000
list(Object clone do(x := 1)) serialized         // 同样爆栈
```

爆栈来自 `serializedSlotsWithNames` 里那一句（21.1 的源码）：

```io
self getSlot(slotName) serialized(stream)
```

而 `serialized` 里的 `justSerialized(stream)` 是**没有接收者的裸消息**。只要对象真有本地槽，
这条裸消息就会一层层解析回外层对象，于是「序列化自己 → 遍历槽 → 序列化自己」递归到爆栈。
空对象没有槽，遍历一次就结束，所以它躲过去了。

**正解：别让框架自己遍历槽，自己点名。**

```io
st := SerializationStream clone
obj serializedSlotsWithNames(list("x", "y"), st)
st output
```

实测这一条是安全的（输出 `\tx := 1\n`）。

> **为什么重要**：这是本章最实用的一条。你不需要「修好」`serialized`——只要绕开
> 自动遍历，用 `serializedSlotsWithNames` 自己列白名单，序列化反而更可控（等于白名单）。

## 21.5 循环引用与不可序列化的对象

一句话：**没有循环引用检测**（`seen` 是死代码），不可序列化的对象**静默丢数据**。

实测输出：

```text
-- 21.5 循环引用与不可序列化的对象
自引用 List 的异常 = Stack overflow: frame depth exceeded 10000
自引用 Map 的异常 = Stack overflow: frame depth exceeded 10000
File serialized（路径没进去） = [File clone do(
)
]
File 的 path 是 = /tmp
Coroutine serialized 的异常 = CFunction defined for type Coroutine but called on type Object
```

`SerializationStream` 里那个 `seen` 槽看起来就是给「已见过的对象」做去重的：

```io
SerializationStream := Object clone do(
	init := method(
		self seen := Map clone
		self output := Sequence clone
	)
	…
)
```

但 `Serialize.io` 全文件里 `seen` **只在 init 被赋值这一次**，没有任何地方读它或写它——
去重逻辑只在作者脑子里。于是自引用直接爆栈。

不可序列化的对象更阴：`File` 的路径存在 C 侧的数据指针里，不是 Io 槽，
所以产物是 `File clone do()`——**不报错，但 path 丢了**，回读出来是个没有路径的 File。
`Coroutine` 则会报 `CFunction defined for type Coroutine but called on type Object`。

> **为什么重要**：序列化最危险的不是「报错」，是「成功了但少了一半数据」。
> 对一个 File / Socket / 协程句柄来说，持久化本身就没有语义——要持久化的是
> 「路径」这个字符串，而不是句柄对象。

## 21.6 写进文件再读回来：别忘了 asUTF8

一句话：`File setContents` 写的是字符串的**内部表示**，序列化产物是纯 ASCII 时刚好安全，
含中文的串就必须先 `asUTF8`。

实测输出：

```text
-- 21.6 写进文件再读回来：别忘了 asUTF8
写出去的字节数 = 91
产物本身的码点数 = 91
读回来的字节数与产物码点数相同 = true
读回后 port = 8080
读回后 name = io-demo
读回后 tags = list("a", "b")
含中文的串直接 setContents 的字节数（码点数的 4 倍） = 8
它的码点数 = 2
```

完整往返：

```io
text := persist serialized
f := File with(tmpPath)
f remove
f setContents(text asUTF8)          // 关键：asUTF8
back := File with(tmpPath) contents  // 读回来是字节串
reloaded := Lobby doString(back)     // 回读 = doString
reloaded at("name")                  // "io-demo"
```

为什么必须 `asUTF8`：Io 的编码按内容自动升级——纯 ASCII 是 `uint8`（一码点一字节），
含中文升到 `uint32`（**每码点 4 字节**）。`setContents` 直接倒内部表示，写出的是 4 字节
一码点的鬼东西。第 14 章讲过这条，这里用实测数字钉一下：`"中文"` 的 `size` 是 2，
但直接 `setContents` 写出 **8** 字节；`asUTF8 size` 才是真正的 UTF-8 字节数 **6**。

序列化产物的写法也提醒一句：`Map` 的键值是 `atPut("name", "io-demo")`，产物里全是 ASCII，
所以本例的 91 字节 = 91 码点。

> **为什么重要**：持久化的下半场是编码。Io 里没有「文本模式打开」，只有
> 「内部表示」和「UTF-8 字节」两个东西，写文件时永远要显式选后者。

## 21.7 asString 是给人看的，不可逆；自己写一份键值持久化

一句话：`asString` 只负责好看，`serialized` 才负责可回读；要稳就自己定格式。

实测输出：

```text
-- 21.7 asString 是给人看的，不可逆；自己写一份键值持久化
字符串 asString（引号没了） = hi
它的 serialized（引号还在） = "hi"
doString("hi") 的结果 = Object does not respond to 'hi'
doString("hi" serialized) 的结果 = hi
Map asString 里有地址 = true
Map serialized 里没有地址 = false
自制的键值格式（键按 sort 排过，顺序确定）：
debug=1
name="io-demo"
port=8080
解出来 port 的类型 = Number
解出来 name = io-demo
```

对照一眼就清楚：

| 值 | `asString` | `serialized` |
|---|---|---|
| `"hi"` | `hi`（引号没了，回读报 `does not respond to 'hi'`） | `"hi"`（可回读） |
| `Map clone atPut("a", 1)` | `Map_0x…:`（**地址**，回读无意义） | `Map clone do(atPut("a", 1);)` |

自己写一份白名单格式（本例里的 `toKV` / `fromKV`），好处是三件事都能自己控：

```io
toKV := method(m,
    parts := List clone
    m keys sort foreach(k,                    // sort：产物顺序确定
        v := m at(k)
        if(v isKindOf(Number),
            parts append(k .. "=" .. v asString),
            parts append(k .. "=" .. "\"" .. v asString .. "\"")
        )
    )
    parts join("\n")
)
```

产物 `debug=1 / name="io-demo" / port=8080`，`fromKV` 解回来还能看出
`port` 是 `Number`、`name` 是 `Sequence`——**类型信息是显式的**，不依赖 eval 环境。

> **为什么重要**：Io 自带的序列化把「数据」和「代码」混在一起（产物是要 eval 的源码），
> 换来的是极简实现。要跨版本、跨进程、要防注入时，白名单格式反而更省心。

## 21.8 版本兼容：序列化串里没有版本号

一句话：产物没有版本字段、没有魔数头，第一行的类型名就是唯一的「格式标记」。

实测输出：

```text
-- 21.8 版本兼容：序列化串里没有版本号
Map 产物里含 version 字样 = false
List 产物里含 version 字样 = false
Date 产物里含 version 字样 = false
产物第一行的类型名就是唯一的「格式标记」 = list
Io 自己的版本号在别处 = 20260302
```

所以「版本兼容」这件事在 Io 里是这样落地（或者说不落地）的：

- 产物能不能读，只取决于那句源码在新 VM 里**还解析得出来吗**。
- 改名 / 删槽 / 换 proto 名 → 老文件直接 `Object does not respond to '…'`（21.3 实测）。
- 想稳：自己在格式里带版本（21.7 的 `toKV` 加一行 `v=1`），或者干脆别用 `doString` 回读。
- 另一个必须知道的事实：产物是**可执行源码**。序列化数据来自不可信来源时，
  回读等于 `eval`——别对别人的字节流调 `doString`。

> **为什么重要**：没有版本号不是「缺功能」，而是「格式就是语言本身」的必然结果。
> 语言格式的版本，就是 Io 的版本。要独立演进的格式，就得自己定义。

## 21.9 坑位清单

1. **没有 `Serialize` 对象** → 序列化入口只有 `obj serialized`（配 `SerializationStream`），`toString`/`toObject` 一律不存在。
2. **有本地槽的对象 `serialized` 直接爆栈** → 用 `serializedSlotsWithNames(list("x"), stream)` 自己列白名单（21.4）。
3. **proto 是回读时按名字重新求值** → 改名或重绑定后拿到的是新对象，跨版本必须自己带版本号（21.3）。
4. **没有循环引用检测** → `SerializationStream` 的 `seen` 是死代码，自引用 List/Map 一律 `Stack overflow`（21.5）。
5. **`File serialized` 静默丢掉 path** → 产物是 `File clone do()`，句柄类对象要持久化的是路径字符串而不是对象（21.5）。
6. **`Block serialized` 只写代码不带作用域** → 产物 `block(v, v +(1))` 回读后丢掉了闭包捕获，别指望它能恢复上下文（21.2）。
7. **嵌套 List 的产物带内层分号** → `list(list(1, 2);, 3);`，Io 能容忍但这不是合法惯用式，跨语言读写要自己控格式（21.2）。
8. **`asString` 不可逆、`Map asString` 还带地址** → 持久化只用 `serialized` 或自定义格式，`asString` 只给人看（21.7）。
9. **`setContents` 写内部表示** → 含中文的串必须先 `asUTF8`，否则每码点 4 字节（实测 `"中文"` 写出 8 字节） （21.6）。
10. **回读等于 `eval`** → `Lobby doString(产物)` 会执行源码，不可信来源的序列化数据别直接回读（21.8）。

---

上一章：[20 · 单元测试](20-testing.md) · 下一章：[22 · 性能陷阱与基准](22-performance.md)
