# 05 · Foundation（Objective-C 篇）：字符串、集合、数据

> 示例：`examples/05_objc_foundation/main.m`
> 实测输出见 `build/05_objc_foundation/stdout.debug.txt`

Foundation 是**跨 Apple 平台通用**的一层：本章讲的每个类，在 macOS 上一字不差
（想更深入的 Unicode / 格式符细节，可对照仓库里的 `macosdev/docs/05`）。iOS 上你还会
天天遇到 `UserDefaults`、plist、`Codable`（第 18 章），底下全是这套值类型。

本章只讲 **OC 特有的坑**；Swift 侧的桥接差异见第 06 章。

## 1) NSString：length 是 UTF-16 码元数，不是字符数

```objc
NSString *precomposed = @"café";        // é 是一个码位      → length = 4
NSString *decomposed  = @"cafe\u0301";  // e + 组合重音符    → length = 5
```

同一个「café」有两种合法的 Unicode 写法，**直接比较不相等**：

```objc
[precomposed isEqualToString:decomposed];   // NO
NSString *a = [precomposed precomposedStringWithCanonicalMapping];
NSString *b = [decomposed  precomposedStringWithCanonicalMapping];
[a isEqualToString:b];                      // YES —— 规范化后相等
```

> **坑**：从网络、文件、粘贴板读进来的字符串，你不知道它是哪种写法。要做「相等」判断
> 或当字典 key 之前，**先规范化**。emoji 更夸张：`👍🏽`（thumbs-up + 肤色修饰符）的
> `length` 是 4。**永远别用 `length` 当「字符数」，也别用 `characterAtIndex:` 遍历字符。**

## 2) 拼接、切分、查找 与 NSRange

```objc
NSString *joined = [@[@"Swift", @"Objective-C", @"Cocoa"] componentsJoinedByString:@" / "];
NSArray  *parts  = [joined componentsSeparatedByString:@" / "];
NSRange   found  = [joined rangeOfString:@"Cocoa"];      // UTF-16 偏移
```

`NSRange` 是 `{ NSUInteger location; NSUInteger length; }`，三条约定：

- 找不到时 `location == NSNotFound`（= `NSUIntegerMax`），`length == 0`；
- **`NSNotFound` 不是 -1**。判断必须写 `range.location == NSNotFound`；
- `rangeOfString:` 返回的是 **UTF-16 偏移**，配合 `substringWithRange:` 取子串。

`NSMutableString` 可就地 `appendString:` / `insertString:atIndex:`。

## 3) 格式说明符：本章最容易踩的坑

`stringWithFormat:` 底层就是 C 的 `printf`，**编译器不做类型检查**，写错不报错、只出乱码。
示例里那些强转就是为此：

```objc
line([NSString stringWithFormat:@"  emoji length=%lu", (unsigned long)emoji.length]);
```

| OC 类型 | 说明符 | 必须做的强转 |
|---|---|---|
| 任何对象 | `%@` | 无（走 `description`） |
| `NSInteger` | `%ld` | `(long)` |
| `NSUInteger`（`.length`/`.count`） | `%lu` | `(unsigned long)` |
| `int`/`BOOL` | `%d` | 无 |
| `double`/`CGFloat` | `%f` | 无 |
| C 字符串 `char *` | `%s` | 无（**不能**用 `%@`） |

> `NSInteger` 在 64 位上是 `long`，用 `%d` 读它会让参数栈错位、后面的值全乱。
> 统一 `%ld`+`(long)` / `%lu`+`(unsigned long)` 就对。

## 4) NSNumber / NSValue / NSNull

```objc
NSNumber *n1 = @42, *n2 = @42.0;
[n1 isEqualToNumber:n2];                 // YES —— 按**数值**比较
strcmp(n1.objCType, n2.objCType) != 0;   // objCType 不同（整数 vs 浮点编码）
```

> **坑**：`@42` 和 `@42.0` 用 `isEqual:` 相等（比数值）；想知道底层类型只能看 `objCType`。
> 小整数 `NSNumber` 是 **tagged pointer**，`@1 == @1` 的指针比较可能真成立，但那是实现
> 细节 —— **永远用 `isEqual:`**。

`NSValue` 包任意 C 结构体（`NSRange`/`CGPoint`…）；`NSNull` 是集合里的「空位」
（集合不能放 nil），且是**单例**，可直接 `==` 比指针。

## 5) NSArray / NSMutableArray

```objc
NSArray<NSString *> *langs = @[@"Swift", @"Objective-C", @"C"];
langs.firstObject; langs.lastObject; langs[1];     // 下标 = objectAtIndex:
[langs indexOfObject:@"C"];                        // 找不到返回 NSNotFound
NSMutableArray *m = [langs mutableCopy];
[m addObject:@"C++"]; [m removeObjectAtIndex:0];   // 可变版就地增删
```

- **不可变版返回新对象、可变版就地改**：`sortedArrayUsingComparator:`（返回新数组）
  vs `sortUsingComparator:`（就地排）。这个命名对称贯穿整个 Foundation。
- `containsObject:`/`indexOfObject:` 用 `isEqual:`，自定义对象要正确实现 `isEqual:`+`hash`。
- **下标越界抛 `NSRangeException`**（不是返回 nil）。
- **遍历中修改**同一个可变数组会抛 `NSGenericException`（"mutated while being enumerated"）。

实测：

```
  sorted = C, C++, Objective-C
  ok   排序后 C 在最前
```

## 6) NSDictionary / NSSet

```objc
NSDictionary *ages = @{@"Ada": @36, @"Grace": @45, @"Alan": @41};
ages[@"Nobody"];        // nil，不是异常
```

> **坑（本教程反复出现的规则）**：`allKeys` / for-in 遍历字典的**顺序未定义**。想要稳定
> 输出**必须自己排序** —— 示例先 `[ages.allKeys sortedArrayUsingSelector:@selector(compare:)]`
> 再拼串，所以打印出 `ages = Ada=36 Alan=41 Grace=45`。

- 字典 key 会被 `copy`（要能响应 `NSCopying`），用可变对象当 key 是灾难。
- 可变字典 `obj[key] = value` 既能改也能加；`removeObjectForKey:` 对不存在的 key 静默无副作用。
- `NSSet` 自动去重、哈希查找（比数组快）；`NSCountedSet` 记录出现次数。

## 7) NSData

```objc
NSData *data = [@"Cocoa" dataUsingEncoding:NSUTF8StringEncoding];
NSString *back = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
```

> **坑**：`initWithData:encoding:` 在数据不是合法 UTF-8 时**返回 nil**（不抛异常）。
> 读外部数据一定要判 nil。

`NSMutableData` 可 `appendData:` / `appendBytes:length:`。iOS 上 `Data` 是网络请求、
文件读写、图片编码的通用载体（第 17、18 章）。

## 8) NSDate / NSCalendar

**`NSDate` 就是一个时间点**（不含时区、不含日历），内部以 2001-01-01 参考日期存储，
但常用 1970 纪元的 API：

```objc
NSDate *epoch = [NSDate dateWithTimeIntervalSince1970:1700000000];
epoch.timeIntervalSince1970;   // 1700000000
```

要拿「年月日」必须过 `NSCalendar` + `NSTimeZone`：

```objc
NSCalendar *utc = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
utc.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
NSDateComponents *c = [utc components:NSCalendarUnitYear|NSCalendarUnitMonth|... fromDate:epoch];
```

实测同一个时间戳在 UTC 和 GMT+8 下差一天：

```
  UTC = 2023-11-14 22:00
  ok   UTC 下是 2023-11 22 点
  ok   东八区跨到 15 号早上 6 点
  ok   en_US_POSIX 输出稳定
```

> **坑**：`NSDateFormatter` 默认跟系统 locale 走，用户在 12 小时制地区会输出「下午10:00」，
> 写出去再读回来解析不了。**凡是机器读写的固定格式，钉死 `en_US_POSIX`**：
> ```objc
> fmt.locale   = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
> fmt.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
> ```
> 只有「给用户看」的日期才用系统 locale。另外 `NSDateFormatter` 创建很慢，要复用。

## 9) NSJSONSerialization

```objc
NSData *json = [NSJSONSerialization dataWithJSONObject:payload
                                              options:NSJSONWritingSortedKeys error:&err];
```

实测：

```
  json = {"name":"iOS","tags":["ui","mobile"],"version":18}
  ok   加 SortedKeys 后输出稳定（可 diff/缓存）
  ok   解析回来是 NSDictionary
```

- **加 `NSJSONWritingSortedKeys`** 才能稳定输出（否则 key 顺序随机，diff/缓存全乱）。
- 顶层必须是 array 或 dictionary（不能是裸字符串）。
- 解析：`JSONObjectWithData:options:error:` 返回 `id`，用 `isKindOfClass:` 判类型再用；
  失败返回 nil 并填 error，**一定要判 nil**。
- 解析出来的数字**全是 `NSNumber`**，JSON 没有 int/double 之分、也没有 Date。

> iOS 新代码更常用 Swift 的 `Codable`（第 06、18 章），类型安全得多；
> `NSJSONSerialization` 主要用于 OC 代码、或需要动态字典结构的场景。

## 坑清单

| 现象 | 原因 |
|---|---|
| 中文字符串长度不对 | `length` 是 UTF-16 码元数，不是字符数 |
| 两个「看起来一样」的串不相等 | Unicode 组合/分解写法不同，先规范化 |
| `range.location == -1` 判断失败 | `NSNotFound` 是 `NSUIntegerMax`，不是 -1 |
| `%d` 打印 `.count`/`NSInteger` 出乱码 | 要用 `%lu`+`(unsigned long)` / `%ld`+`(long)` |
| `@42` 和 `@42.0` 相等 | NSNumber 按数值比较；看类型用 `objCType` |
| JSON 每次 key 顺序不同 | 没加 `NSJSONWritingSortedKeys` |
| 日期差一天/差 8 小时 | `NSCalendar` 没指定 `timeZone` |
| 日期串写出去读不回来 | `NSDateFormatter` 没钉 `en_US_POSIX` |
| 数组越界崩溃 | 下标越界抛 `NSRangeException`（不是返回 nil） |
| for-in 里删元素崩溃 | 遍历中修改集合抛 `NSGenericException` |

## 小结

- `NSString.length` 是 UTF-16 码元数；比较前先规范化。
- `stringWithFormat:` 就是 `printf`：对象 `%@`、`NSInteger` `%ld`+`(long)`、
  `NSUInteger` `%lu`+`(unsigned long)`、`char *` `%s`，编译器不查错。
- `NSNotFound` ≠ -1；`NSNumber` 比数值；`NSNull` 是单例空位。
- 不可变版返回新对象、可变版就地改；遍历中别改集合；字典要稳定输出先排序 key。
- 日期一定指定 calendar + timeZone，`NSDateFormatter` 钉 `en_US_POSIX`；JSON 加 sortedKeys。

下一章：`06-swift-foundation.md` —— 同一批类型的 Swift 面孔：值语义、可选、Codable、桥接。
