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

## 3) stringWithFormat: 与格式说明符（本章最容易踩的坑）

示例里几乎每一行打印都长这样：

```objc
line([NSString stringWithFormat:@"  plain      length=%lu", (unsigned long)plain.length]);
line([NSString stringWithFormat:@"  UTC = %04ld-%02ld ...", (long)c.year, (long)c.month]);
```

为什么明明是 `NSUInteger`，却要写 `(unsigned long)` 再用 `%lu`？因为
**`stringWithFormat:` 底层就是 C 的 `printf` 家族**，它靠格式说明符去
「按位解释」可变参数，**编译器不会帮你做类型检查**——写错了不报错，
只是打印出垃圾值，甚至在 64 位上错位。

对照表（把「OC 类型 → 该用的说明符 → 该做的强转」记牢）：

| OC 类型 | 说明符 | 必须做的强转 |
| --- | --- | --- |
| 任何对象（`NSString`/`NSNumber`/`NSArray`…） | `%@` | 无——会调用对象的 `description` |
| `NSInteger` | `%ld` | `(long)` |
| `NSUInteger`（含 `.length`、`.count`） | `%lu` | `(unsigned long)` |
| `int` / `BOOL`（提升为 int） | `%d` | 无 |
| `double` / `CGFloat` | `%f`（`%.2f` 控位） | 无 |
| C 字符串 `char *` | `%s` | 无——**不能**用 `%@` |
| 指针 | `%p` | 无 |

关键三点：

1. **`NSInteger` 不是 `int`。** 在 64 位上它是 `long`（8 字节），
   用 `%d`（4 字节）读它，参数栈会错位，后面的值全乱。
   所以统一写 `%ld` + `(long)`，跨 32/64 位都对。这也是示例里
   `c.year`（`NSInteger`）一律 `(long)` 的原因。

2. **`.length` / `.count` 是 `NSUInteger`**，用 `%lu` + `(unsigned long)`。
   写成 `%d` 是初学者最常见的错误，且**不报警**。

3. **对象一律 `%@`，`char *` 一律 `%s`**，两者不能混。
   示例里的 `printf("  %s %s\n", ... , [desc UTF8String])` 走的是纯 C 的
   `%s`，因为 `UTF8String` 返回的是 `const char *`；而
   `stringWithFormat:` 里嵌字符串对象就得用 `%@`。

> **坑**：`%@` 要求对象能响应 `description`。传一个已经释放的野指针，
> `%@` 会直接崩在 `description` 上，报错信息往往指向别处，很难查。
> 自定义类想让 `%@` 打印出有用的东西，就重写 `- (NSString *)description`
> （第 04 章的 `Person` 就是这么做的）。

顺带一提，`%@` + `description` 就是 OC 的「toString」机制：
`NSLog(@"%@", obj)`、字符串插值、调试打印，最终都走它。

## 4) NSNumber / NSValue / NSNull

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

## 5) NSArray / NSMutableArray

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

> `sortedArrayUsingSelector:` 返回**新的不可变数组**，原数组不动。
> 想就地排序得用 `NSMutableArray` 的 `sortUsingComparator:`（没有 "ed"）。
> 这类「不可变版返回新对象 / 可变版就地改」的命名对称，贯穿整个 Foundation。

**三种遍历方式**，示例里都用到了：

```objc
// 1) for-in（最常用，顺序 = 下标顺序）
for (NSString *s in langs) { ... }

// 2) 下标（要 index 时）
for (NSUInteger i = 0; i < langs.count; i++) { NSString *s = langs[i]; }

// 3) block 版（能拿到 index，还能中途 stop）
[langs enumerateObjectsUsingBlock:^(NSString *s, NSUInteger idx, BOOL *stop) {
    if (...) { *stop = YES; }   // 置 YES 提前结束，相当于 break
}];
```

> **坑**：**边遍历边改**同一个 `NSMutableArray`（在 for-in 里 `removeObject:`）
> 会抛 `NSGenericException`（"mutated while being enumerated"）。
> 要删元素，用 `removeObjectsInArray:` 收集后统一删，或倒序按下标删。

**可变数组的增删**（示例实测）：

```objc
NSMutableArray *m = [langs mutableCopy];   // 从不可变拷一份可变的
[m addObject:@"C++"];                       // 尾部追加
[m removeObjectAtIndex:0];                  // 按下标删（越界会抛异常）
```

实测：

```
  count=3 first=Swift
  sorted = C, C++, Objective-C
  ok   按 compare: 排序后 C 在最前
  ok   isEqualToArray 做逐元素比较
  ok   isEqual: 对数组同样是逐元素比较
```

## 6) NSDictionary / NSSet

```objc
NSDictionary *dict = @{@"k": @"v"};
dict[@"nope"];        // nil，不是异常
```

- **字典的 key 会被 `copy`**（所以要能响应 `NSCopying`）。用可变对象当 key 是灾难。
- `NSDictionary` 无序 —— 遍历顺序未定义。
- `NSSet` 自动去重，查找是哈希（比数组快）；`NSCountedSet` 记录出现次数。

> **坑（本教程反复出现的一条规则）**：`allKeys` / for-in 遍历字典的
> **顺序未定义**，依赖它输出就会每次都不一样。想要稳定的打印，
> **必须自己排序**——示例正是先
> `[ages.allKeys sortedArrayUsingSelector:@selector(compare:)]`
> 再拼字符串，所以 `ages = Ada=36 Alan=41 Grace=45` 是有序的。

**可变字典**：`obj[key] = value` 既能改也能加，`removeObjectForKey:`
对不存在的 key **静默无副作用**（不报错）：

```objc
NSMutableDictionary *s = [@{@"theme": @"dark"} mutableCopy];
s[@"theme"] = @"light";     // 已存在的 key → 改值
s[@"autoSave"] = @YES;      // 新 key → 新增
[s removeObjectForKey:@"notThere"];   // 不存在 → 什么都不发生
```

> 想「key 不存在才设」用 `setObject:forKey:` 也一样会覆盖；
> 真正的判空写法是 `if (s[key] == nil) { s[key] = ...; }`。

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

## 7) NSData

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

## 8) NSDate / NSCalendar

**`NSDate` 就是一个时间点**（不含时区、不含日历）。它内部以
「**参考日期** 2001-01-01 00:00:00 UTC 起的秒数」存储，但你几乎不会直接碰它——
常用的是两个 1970 纪元（Unix epoch）的 API，示例正是这么造的时间点：

```objc
NSDate *epoch = [NSDate dateWithTimeIntervalSince1970:1700000000];
epoch.timeIntervalSince1970;   // 1700000000
```

> 别被两个纪元绕晕：`timeIntervalSinceReferenceDate` 是 2001 起，
> `timeIntervalSince1970` 是 1970 起，差 978307200 秒。日常一律用 1970 那对，
> 跟 Unix/JSON 的时间戳互通。

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

> **坑**：`NSDateFormatter` 默认跟**系统 locale** 走。用户在 12 小时制地区，
> 你写出去的就是 `下午10:00` 之类，再读回来解析不了。**凡是「机器读写」的
> 固定格式，都要钉死 `en_US_POSIX`**（它保证数字、分隔符不随地区变）：
>
> ```objc
> NSDateFormatter *fmt = [NSDateFormatter new];
> fmt.locale   = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
> fmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
> fmt.dateFormat = @"yyyy-MM-dd HH:mm";
> ```
>
> 只有「给用户看」的日期才用系统 locale（`dateStyle`/`timeStyle`）。
> 另外 `NSDateFormatter` **创建很慢**（几毫秒级），高频格式化要复用实例。

## 9) NSJSONSerialization

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

**解析（round-trip）**：`JSONObjectWithData:options:error:` 返回 `id`，
真实类型要靠 `isKindOfClass:` 判断后再用：

```objc
NSError *err = nil;
id parsed = [NSJSONSerialization JSONObjectWithData:json options:0 error:&err];
if ([parsed isKindOfClass:[NSDictionary class]]) {
    NSDictionary *d = parsed;
    d[@"name"];              // NSString
    [d[@"version"] intValue]; // NSNumber → 取标量
}
```

> **坑**：JSON **没有** Date、没有 int/double 之分、没有「有序对象」。
> 日期只能编成字符串或时间戳数字自己约定；解析出来一律是
> `NSString` / `NSNumber` / `NSArray` / `NSDictionary` / `NSNull` 五种。
> 解析失败返回 `nil` 并填 `error`，**一定要判 nil**。

## 10) 坑清单

| 现象 | 原因 |
| --- | --- |
| 中文字符串长度不对 | `length` 是 UTF-16 码元数，不是字符数 |
| 两个「看起来一样」的字符串不相等 | Unicode 组合/分解写法不同，先规范化 |
| `range.location == -1` 判断失败 | `NSNotFound` 是 `NSUIntegerMax`，不是 -1 |
| `%d` 打印 `.count`/`.length` 出乱码 | 它们是 `NSUInteger`，要 `%lu` + `(unsigned long)` |
| `%d` 打印 `NSInteger` 后参数全错位 | 64 位上它是 `long`，要 `%ld` + `(long)` |
| `%@` 打印 C 字符串（或反之）崩溃 | 对象用 `%@`，`char *` 用 `%s`，不能混 |
| `@42` 和 `@42.0` 相等 | NSNumber 按数值比较；看类型用 `objCType` |
| JSON 输出每次 key 顺序都不一样 | 没加 `NSJSONWritingSortedKeys` |
| 日期差一天/差 8 小时 | `NSCalendar` 没指定 `timeZone` |
| 日期字符串写出去读不回来 | `NSDateFormatter` 没钉 `en_US_POSIX` |
| 数组越界崩溃 | OC 数组下标越界抛 `NSRangeException`（不是返回 nil） |
| for-in 里删元素崩溃 | 遍历中修改集合抛 `NSGenericException` |

## 小结

- `NSString.length` 是 UTF-16 码元数；比较前先规范化；遍历用 `enumerateSubstringsInRange`。
- `stringWithFormat:` 就是 `printf`：对象 `%@`、`NSInteger` 用 `%ld`+`(long)`、
  `NSUInteger`（`.length`/`.count`）用 `%lu`+`(unsigned long)`、`char *` 用 `%s`。编译器不查错。
- `NSNotFound` ≠ -1。
- `NSNumber` 比数值，`NSNull` 是单例空位。
- 不可变版返回新对象、可变版就地改（`sortedArray…` vs `sortUsing…`）；遍历中别改集合。
- 日期一定要指定 calendar + timeZone；`NSDateFormatter` 钉 `en_US_POSIX`；JSON 一定要加 sortedKeys。
