# 05 · Foundation（Objective-C 篇）：字符串、集合、数据

> 示例：`examples/05_objc_foundation/main.m`
> 实测输出见 `build/05_objc_foundation/stdout.clt.txt`

Foundation 是 AppKit 的地基：`NSString`、`NSArray`、`NSDictionary`、
`NSData`、`NSDate`、`NSJSONSerialization`……本章讲这几个类里
**OC 特有的坑**（Swift 侧的差异见第 06 章）。

## 1) NSString：length 是 UTF-16 码元数，不是字符数

```objc
NSString *plain       = @"Cocoa";       // length = 4
NSString *precomposed = @"café";        // é 是一个码位      → length = 4
NSString *decomposed  = @"cafe\u0301";  // e + 组合重音符    → length = 5
```

实测：

```
  plain      length=4
  precomposed length=4
  decomposed length=5
  ok   纯 ASCII 时 length 等于字符数
  ok   预组合 é 只占一个 UTF-16 码元
  ok   分解写法占两个码元（e + U+0301）
```

**同一个「café」有两种合法写法，直接比较不相等：**

```objc
expect([precomposed isEqualToString:decomposed] == NO, @"两种写法直接比较不相等");
NSString *canonA = [precomposed precomposedStringWithCanonicalMapping];
NSString *canonB = [decomposed  precomposedStringWithCanonicalMapping];
expect([canonA isEqualToString:canonB], @"规范化之后两者相等");
```

> **坑**：从文件、网络、粘贴板读进来的字符串，你不知道它是哪种写法。
> 要做「相等」判断或当字典 key 之前，**先规范化**。
> 这也是为什么 Swift 的 `String` 自己做了规范化而 `NSString` 没有。

emoji 更夸张：

```
  emoji length=4
  ok   emoji 的 length 也是 UTF-16 码元数（代理对 + 修饰符）
```

`👍🏽` =  thumbs-up（代理对，2 个码元）+ 肤色修饰符（2 个码元）= 4。

**结论：永远不要用 `length` 当「字符数」用**，也不要用
`characterAtIndex:` 去遍历「字符」。

## 2) 拼接、切分、查找

```objc
NSString *joined = [@[@"Swift", @"Objective-C", @"Cocoa"] componentsJoinedByString:@" / "];
NSArray  *parts  = [joined componentsSeparatedByString:@" / "];
NSRange   found  = [joined rangeOfString:@"Cocoa"];     // UTF-16 偏移
```

**`NSRange` 的三条约定：**

```objc
typedef struct { NSUInteger location; NSUInteger length; } NSRange;
```

- 找不到时 `location == NSNotFound`（= `NSUIntegerMax`），`length == 0`
- **`NSNotFound` 不是 -1**。用 `int` 接收会得到 -1，用 `NSUInteger` 又容易和 0 搞混
- 判断**必须**写 `range.location == NSNotFound`，不要写 `== -1`

实测：

```
  joined = Swift / Objective-C / Cocoa
  ok   数组拼成字符串
  ok   按分隔符切回 3 段
  ok   第二段是 Objective-C
  ok   rangeOfString 给出的是 UTF-16 偏移
  ok   用 NSRange 可以取回子串
  ok   找不到时 location 是 NSNotFound
  ok   找不到时 length 是 0
  ok   NSMutableString 就地改
```

## 3) NSNumber / NSValue / NSNull

```objc
NSNumber *n1 = @42;      NSNumber *n2 = @42.0;
[n1 isEqualToNumber:n2];   // YES —— 按**数值**比较
strcmp(n1.objCType, n2.objCType) != 0;   // objCType 不同（整数编码 vs 浮点编码）
```

> **坑**：`@42` 和 `@42.0` 用 `isEqual:` 是**相等**的 —— NSNumber 比的是数值。
> 想知道底层编码（类型）只能看 `objCType`（返回 `"i"` / `"d"` / `"q"` 这类 C 字符串）。
>
> **坑**：小整数的 `NSNumber` 是 **tagged pointer**（值直接编码在指针里），
> 所以 `@1 == @1` 的指针比较可能真成立 —— 但这是实现细节，**永远用 `isEqual:`**。

`NSValue` 包任意 C 结构体；`NSNull` 是集合里的「空位」（集合不能放 nil）：

```objc
NSValue *range = [NSValue valueWithRange:NSMakeRange(3, 7)];
NSValue *point = [NSValue valueWithPoint:NSMakePoint(12, 34)];
NSArray *withHole = @[@"a", [NSNull null], @"c"];
```

`[NSNull null]` 是**单例**，可以直接 `==` 比指针。

## 4) NSArray / NSMutableArray

```objc
NSArray<NSString *> *langs = @[@"Swift", @"Objective-C", @"C"];
langs.firstObject;  langs.lastObject;  langs[1];        // 下标 = objectAtIndex:
[langs containsObject:@"C"];                            // 用 isEqual: 判断
[langs indexOfObject:@"C"];                             // 找不到返回 NSNotFound
```

- **`NSArray` 不可变，`NSMutableArray` 可变**。Swift 的 `let/var` 是编译期，
  这里是**类型**层面。
- `containsObject:` 用 `isEqual:`，所以自定义对象要正确实现 `isEqual:` + `hash`。
- **`NSArray` 是值语义的外观、引用语义的实现**：
  `copy` 一个不可变数组通常只是 retain。

排序：

```objc
NSArray *sorted = [langs sortedArrayUsingSelector:@selector(compare:)];
NSArray *custom = [langs sortedArrayUsingComparator:^NSComparisonResult(id a, id b) { ... }];
```

实测：

```
  count=3 first=Swift
  sorted = C, C++, Objective-C
  ok   按 compare: 排序后 C 在最前
  ok   isEqualToArray 做逐元素比较
  ok   isEqual: 对数组同样是逐元素比较
```

## 5) NSDictionary / NSSet

```objc
NSDictionary *dict = @{@"k": @"v"};
dict[@"nope"];        // nil，不是异常
```

- **字典的 key 会被 `copy`**（所以要能响应 `NSCopying`）。用可变对象当 key 是灾难。
- `NSDictionary` 无序 —— 遍历顺序未定义。
- `NSSet` 自动去重，查找是哈希（比数组快）；`NSCountedSet` 记录出现次数。

实测：

```
  ok   字面量字典有 3 项
  ok   下标取值
  ok   不存在的 key 取到 nil（不是异常）
  ages = Ada=36 Alan=41 Grace=45
  ok   NSSet 自动去重
  ok   containsObject 是哈希查找，比数组快
  ok   NSCountedSet 记录出现次数
```

## 6) NSData

```objc
NSData *data = [@"Cocoa" dataUsingEncoding:NSUTF8StringEncoding];
NSString *back = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
```

> **坑**：`initWithData:encoding:` 在**数据不是合法 UTF-8 时返回 nil**（不是抛异常）。
> 读外部文件时一定要判 nil。

`NSMutableData` 可以 `appendData:` / `appendBytes:length:`。

实测：

```
  ok   NSData 按字节计长度
  ok   按 UTF-8 解回字符串
  ok   非法 UTF-8 解码返回 nil
  ok   NSMutableData 追加字节
```

## 7) NSDate / NSCalendar

**`NSDate` 就是一个时间戳**（2001-01-01 起的秒数，不是 1970）。

要拿「年月日」必须过 `NSCalendar` + `NSTimeZone`：

```objc
NSCalendar *cal = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
cal.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
NSDateComponents *c = [cal components:NSCalendarUnitYear|NSCalendarUnitMonth|... fromDate:d];
```

实测（同一个时间戳在 UTC 和 GMT+8 下差一天）：

```
  UTC = 2023-11-14 22:00
  ok   UTC 下是 2023 年
  ok   UTC 下是 11 月
  ok   UTC 下是 22 点
  GMT+8 = day 15, hour 6
  ok   东八区是早上 6 点
  ok   东八区已经跨到 15 号
```

> **坑**：`NSDateFormatter` 非常慢（创建一次要几毫秒）。
> 高频格式化要**复用**一个实例。而且它默认跟系统 locale 走，
> 写测试时要显式钉住 `locale`。

## 8) NSJSONSerialization

```objc
NSData *json = [NSJSONSerialization dataWithJSONObject:dict
                                               options:NSJSONWritingSortedKeys
                                                 error:&error];
```

实测：

```
  json = {"name":"Cocoa","tags":["ui","mac"],"version":2}
  ok   加 SortedKeys 后输出稳定
```

- **加 `NSJSONWritingSortedKeys`** 才能让输出稳定（否则 key 顺序随机）。
  任何要 diff / 比对 / 缓存的 JSON 都该加。
- 顶层必须是 array 或 dictionary（不能是裸字符串），否则报错。
- 解析回来的数字**全是 `NSNumber`**，具体是 int 还是 double 由实现决定 ——
  不要依赖 `objCType`。

## 9) 坑清单

| 现象 | 原因 |
| --- | --- |
| 中文字符串长度不对 | `length` 是 UTF-16 码元数，不是字符数 |
| 两个「看起来一样」的字符串不相等 | Unicode 组合/分解写法不同，先规范化 |
| `range.location == -1` 判断失败 | `NSNotFound` 是 `NSUIntegerMax`，不是 -1 |
| `@42` 和 `@42.0` 相等 | NSNumber 按数值比较；看类型用 `objCType` |
| JSON 输出每次 key 顺序都不一样 | 没加 `NSJSONWritingSortedKeys` |
| 日期差一天/差 8 小时 | `NSCalendar` 没指定 `timeZone` |
| 数组越界崩溃 | OC 数组下标越界抛 `NSRangeException`（不是返回 nil） |

## 小结

- `NSString.length` 是 UTF-16 码元数；比较前先规范化；遍历用 `enumerateSubstringsInRange`。
- `NSNotFound` ≠ -1。
- `NSNumber` 比数值，`NSNull` 是单例空位。
- 日期一定要指定 calendar + timeZone；JSON 一定要加 sortedKeys。
