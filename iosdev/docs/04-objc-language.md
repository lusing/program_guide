# 04 · Objective-C 语言基础

> 示例：`examples/04_objc_language/`（`Person.h/.m`、`Speaker.h`、`main.m`）
> 实测输出见 `build/04_objc_language/stdout.debug.txt`

iOS 的新代码几乎都是 Swift，但 **Objective-C 绕不开**：

- UIKit / Foundation 的**底层全是 OC**，报错信息里到处是 `-[UIView setFrame:]` 这种 OC 签名；
- 海量**存量项目和第三方库**是 OC 写的；
- Swift 与 OC 的**互操作规则**（`@objc`、`NSObject` 子类、`NS_ASSUME_NONNULL`）只有懂 OC 才理解得了（第 07 章）。

本章用 OC 把语言核心讲透。示例是**纯 Objective-C**（`clang` 编译，不掺 Swift）。

## 0) 先看一个 OC 类的骨架

OC 把接口和实现**分成两个文件**：`.h`（`@interface`，对外声明）和 `.m`（`@implementation`，实现）。

```objc
// Person.h
#import <Foundation/Foundation.h>
#import "Speaker.h"

NS_ASSUME_NONNULL_BEGIN                    // 区域内指针默认 nonnull（见第 07 章）

@interface Person : NSObject <Speaker>     // 继承 NSObject，遵循 Speaker 协议

@property (nonatomic, copy)   NSString *name;      // 属性
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, readonly) NSInteger lengthOfName;   // 只读

- (instancetype)initWithName:(NSString *)name age:(NSInteger)age NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;       // 禁用默认 init，强制走上面那个
- (NSString *)greeting;
- (BOOL)renameTo:(NSString *)newName error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
```

逐块拆解：

**`#import`**：和 C 的 `#include` 一样，但**自带去重**（不会重复包含），所以 OC 里几乎不用写 `#ifndef` 头文件保护 —— 不过本例仍加了 `#ifndef Person_h`，是好习惯。

**`@interface Person : NSObject <Speaker>`**：
- `: NSObject` 是继承。**几乎所有 OC 类都继承 `NSObject`**（它提供 `alloc`/`init`/`description`/引用计数等）。
- `<Speaker>` 是**遵循协议**（可多个，逗号分隔），≈ Swift 的 `: Speaker`。

**属性修饰符**（这张表要记牢）：

| 修饰符 | 含义 | 何时用 |
|---|---|---|
| `nonatomic` | 非原子（不加锁，快） | iOS 上几乎总是它 |
| `atomic`（默认） | 原子读写（加锁，慢，且**不**等于线程安全） | 很少显式用 |
| `strong` | 强引用（持有对象，引用计数 +1） | 一般对象 |
| `weak` | 弱引用（不持有，对象释放后自动置 nil） | delegate、防循环引用 |
| `copy` | 赋值时**拷贝**一份（常用于 `NSString`、block） | 有可变子类的类型 |
| `assign` | 直接赋值（不管理引用计数） | 标量：`int`/`NSInteger`/`BOOL`/`CGFloat` |
| `readonly` | 只生成 getter | 计算属性、只读暴露 |

> **为什么 `NSString` 属性用 `copy` 不用 `strong`**：`NSString` 有个可变子类
> `NSMutableString`。如果别人把一个 `NSMutableString` 赋给你的 `strong` 属性，
> 之后他改那个可变串，你手里的值会**跟着变**。`copy` 会先拷一份不可变副本，
> 从此互不影响。示例第 2 节实测了这一点。

**方法签名的读法**：

```
- (BOOL)renameTo:(NSString *)newName error:(NSError **)error;
│  │      │        │                  │
│  │      │        │                  └ 第二段参数标签 + 类型
│  │      └ 第一段参数标签 + 类型
│  └ 返回类型
└ “-” 是实例方法；“+” 是类方法（如 +[UIColor systemBlueColor]）
```

这个方法的**完整名字（selector）**是 `renameTo:error:` —— 冒号是 selector 的一部分。
Swift 会把它读成 `rename(to:error:)`（第 07 章）。

**`instancetype`**：表示「返回当前类的实例」。比写 `id` 好，因为子类调用时编译器知道
返回的是子类类型。构造器一律用 `instancetype`。

**`NS_DESIGNATED_INITIALIZER` / `NS_UNAVAILABLE`**：前者标记「指定初始化器」（其它 init
最终都要走它）；后者禁用某个 init（这里禁掉 `init`，强制用 `initWithName:age:`）。

## 1) 消息发送：OC 的灵魂

OC 调方法不是「函数调用」，而是**给对象发消息**：

```objc
[接收者 方法名:参数1 第二段标签:参数2]
```

底层是运行时函数 `objc_msgSend(接收者, selector, 参数...)`，它拿 selector 去对象的
**方法表**里查实现。这带来一个和几乎所有静态语言都不同的性质：

**给 `nil` 发消息不会崩溃，只是「什么都不发生」。** 返回值有规律：

```objc
Person *nobody = nil;
[nobody doubleAge];    // 返回标量 → 0
[nobody greeting];     // 返回对象 → nil
[nobody ageRange];     // 返回结构体 → ★未定义值，别依赖★
```

实测：

```
== 消息发送 与 nil ==
  ok   给 nil 发返回标量的消息得到 0（不崩）
  ok   给 nil 发返回对象的消息得到 nil（不崩）
  ok   readonly 属性给 nil 也是 0
  nil 返回结构体：location=0（未定义，别用）
```

> **坑**：返回**结构体**（`NSRange`/`CGRect`/`CGPoint`）时，nil 消息给的是未定义值。
> 别写 `NSRange r = [maybeNil someRange]; if (r.length == 0) …` 这种依赖它的逻辑。
> 这条「nil 消息安全」既是便利（省掉大量判空），也是陷阱（bug 被静默吞掉）。

## 2) 属性与点语法

点语法 `p.age` 只是 `[p age]` / `[p setAge:]` 的**语法糖**，本质还是发消息：

```objc
p.age = 40;          // == [p setAge:40]
NSInteger a = p.age; // == [p age]
```

`copy` 语义实测（给一个可变串，属性拷一份不可变副本）：

```objc
NSMutableString *mutable = [NSMutableString stringWithString:@"Grace"];
Person *q = [[Person alloc] initWithName:mutable age:45];
[mutable appendString:@"!!!"];        // 改原始可变串
// q.name 仍是 @"Grace"，不受影响 —— 因为属性是 copy
```

**在 `init` 里写 ivar（`_name`），不走 setter**：

```objc
- (instancetype)initWithName:(NSString *)name age:(NSInteger)age {
    self = [super init];              // ① 先让父类初始化
    if (self == nil) return nil;      // ② 判空（父类可能失败）
    _name = [name copy];              // ③ 直接写 ivar（此时对象还没完全就绪，别调 setter）
    _age = age;
    return self;                      // ④ 返回 self
}
```

这四步是 OC 构造器的**铁律**。直接写 `_name` 而不是 `self.name = …`，是因为子类可能
重写了 setter，在 init 阶段调用会触发未预期的行为。

## 3) id / SEL / 动态性

OC 是**动态语言**：类型检查很多发生在运行时。

- **`id`** = 「任意对象指针」（本身就是指针，不写星号）。`id obj = p;`
- **`SEL`** = 方法名的运行时表示，用 `@selector(greeting)` 得到。
- **`Class`** = 类对象本身，用 `[Person class]` 得到。

```objc
id obj = p;
[obj isKindOfClass:[Person class]];        // 运行时判类型
SEL sel = @selector(greeting);
[p respondsToSelector:sel];                // 问：你会这个方法吗？
```

**`performSelector:` 的 ARC 坑**：用它在运行时动态调用一个**返回对象**的方法时，
编译器会警告 `-Warc-performSelector-leaks` —— 因为 ARC 不知道这个动态 selector
返回的对象该不该 release，怕泄漏。标准处理是用 `#pragma` 局部静音，并心里有数：

```objc
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
id result = [p performSelector:sel];
#pragma clang diagnostic pop
```

**`@optional` 协议方法调用前必须先问**（否则对象没实现就崩）：

```objc
id<Speaker> speaker = p;
if ([speaker respondsToSelector:@selector(whisper)]) {
    [speaker whisper];
}
```

## 4) 协议（protocol）：OC 的多态

协议 ≈ Swift 的 protocol / C++ 的纯虚接口。分 `@required`（必须实现）和
`@optional`（可选）：

```objc
@protocol Speaker <NSObject>
@required
- (NSString *)speakTimes:(NSInteger)times;
@optional
- (NSString *)whisper;
@end
```

**面向协议编程**：变量类型写成 `id<Speaker>`，就只依赖「它会 speakTimes:」，
不关心它到底是 Person 还是别的类 —— 这是 OC 里解耦的主要手段（delegate 模式的基础）。

```objc
id<Speaker> s = p;
NSString *said = [s speakTimes:2];   // 通过协议调用
```

> `<NSObject>` 写在协议声明里，表示「遵循者也得是 NSObject 家族」，这样
> `respondsToSelector:` 这类 NSObject 方法才保证可用。

## 5) 分类（category）：不改源码给类加方法

分类能在**不继承、不改原类源码**的前提下，往一个已有类里「贴」方法：

```objc
@interface Person (Vip)                 // 括号里是分类名
- (NSString *)vipGreeting;
@end

@implementation Person (Vip)
- (NSString *)vipGreeting {
    return [NSString stringWithFormat:@"[VIP] %@", [self greeting]];
}
@end
```

运行时，分类的方法被**合并进 Person 的方法表**，所有 Person 实例都能用，
但类型不变（`isKindOfClass:[Person class]` 仍为真）。Swift 的 `extension` 与之神似。

> **坑**：分类里**不要**添加属性存储（分类不能自动合成 ivar）；也**不要**覆盖原类
> 已有的方法（行为未定义，取决于加载顺序）。分类适合加工具方法，不适合改核心行为。

## 6) block：OC 的闭包

block 是 OC 的匿名函数/闭包。语法把返回类型和 `^` 写在前面：

```objc
NSInteger (^add)(NSInteger, NSInteger) = ^NSInteger(NSInteger a, NSInteger b) {
    return a + b;
};
add(2, 3);   // 5
```

block 常作为参数（回调、比较器、枚举）：

```objc
NSArray *sorted = [nums sortedArrayUsingComparator:^NSComparisonResult(NSNumber *a, NSNumber *b) {
    return [a compare:b];
}];
```

> **block 与循环引用**：block 会**强引用**它捕获的对象。如果 `self` 持有一个 block、
> block 又捕获了 `self`，就形成循环引用，两者都释放不掉。解法是 weak-strong dance：
> ```objc
> __weak typeof(self) weakSelf = self;
> self.completion = ^{
>     __strong typeof(weakSelf) strongSelf = weakSelf;   // block 内再强引用一次，防中途释放
>     if (!strongSelf) return;
>     [strongSelf doSomething];
> };
> ```
> 这是 OC 内存管理的头号坑，Swift 里对应 `[weak self]` 捕获列表。

## 7) 错误处理：NSError 二级指针

OC 没有异常（日常不用 `@try`）。约定是：**方法返回 BOOL/nil 表示成败，错误经二级指针 `NSError **` 传出**：

```objc
NSError *err = nil;
BOOL ok = [p renameTo:@"" error:&err];   // 传 &err
if (!ok) {
    NSLog(@"%@", err.localizedDescription);   // err 被填充
}
```

```objc
- (BOOL)renameTo:(NSString *)newName error:(NSError **)error {
    if (newName.length == 0) {
        if (error != NULL) {             // 调用方可能传 NULL（不关心 error）
            *error = [NSError errorWithDomain:MXRenameErrorDomain
                                         code:1001
                                     userInfo:@{NSLocalizedDescriptionKey: @"名字不能为空"}];
        }
        return NO;
    }
    self.name = newName;
    return YES;
}
```

`NSError` 三要素：**domain**（错误域字符串）、**code**（整数）、**userInfo**（字典，
`NSLocalizedDescriptionKey` 放人类可读描述）。实测：

```
  ok   空名字改名失败返回 NO
  ok   错误经二级指针传出，err 被填充
  ok   错误码 1001
  ok   自定义错误域
  ok   userInfo 里的本地化描述
  ok   成功时返回 YES 且 err 不被填
```

> 这个「BOOL + NSError**」签名，Swift 会自动翻译成 `throws`（第 07 章）——
> `try p.rename(to: "x")`。这就是 Swift 错误处理能那么干净的由来。

## 8) description 与 `%@`

`%@` 打印对象时，走的是对象的 `- (NSString *)description`。默认实现是
`<Person: 0x6000…>`（没用），所以自定义类要重写它：

```objc
- (NSString *)description {
    return [NSString stringWithFormat:@"<Person %@ age=%ld>", self.name, (long)self.age];
}
```

> 打印标量注意格式符：`NSInteger` 用 `%ld` + `(long)`，`NSUInteger`（`.length`）用
> `%lu` + `(unsigned long)`，对象用 `%@`，C 字符串用 `%s`。写错**不报错**、只出乱码。
> （Foundation 篇第 05 章会专门展开。）

## 9) ARC 与内存管理

OC 现在都用 **ARC**（Automatic Reference Counting，自动引用计数）：编译器在合适的地方
插入 retain/release，你不用手写。规则：

- **strong**：持有，计数 +1；最后一个 strong 消失时对象释放。
- **weak**：不持有，对象释放后自动置 nil（避免野指针）。**delegate 一律 weak**。
- **循环引用**：A strong 持 B、B strong 持 A → 谁都释放不掉。用 weak 打破，
  或 block 里用 weak-strong dance（见第 6 节）。
- **`copy`**：对 `NSString`/block 拷一份，避免外部可变对象偷偷改你的值。

> 对比 Swift：Swift 也是 ARC，`weak`/`unowned` 对应 OC 的 `weak`；Swift 的
> `[weak self]` 捕获列表对应 OC 的 weak-strong dance。语言不同，内存模型一致。

## 10) OC 一样能写 UIKit

OC 不是「只能写逻辑」——UIKit 本身就是 OC 框架，OC 用起来最直接：

```objc
UILabel *label = [[UILabel alloc] init];
label.text = [p greeting];
[label sizeToFit];
UIColor *c = [UIColor systemBlueColor];    // 类方法用 +，调用写成 [类 方法]
```

## 坑清单

| 现象 | 原因 |
|---|---|
| `[nil someMethod]` 没崩但逻辑不对 | nil 消息静默返回 0/nil，bug 被吞 |
| nil 消息拿结构体得到怪值 | 返回结构体时 nil 消息是未定义值 |
| `NSString` 属性被外部偷偷改了 | 用了 `strong` 而非 `copy`，被赋了 `NSMutableString` |
| delegate 导致对象释放不掉 | delegate 用了 strong，形成循环引用 —— 改 weak |
| block 里 self 释放不掉 | block 强引用 self，需 weak-strong dance |
| `performSelector:` 编译告警 | ARC 不知返回对象的生命周期，用 pragma 局部静音 |
| 分类加属性崩溃 | 分类不能合成 ivar，只能用关联对象 |
| `%d` 打印 `.length` 出乱码 | 它是 `NSUInteger`，要 `%lu` + `(unsigned long)` |

## 小结

- OC = **头/实现分离** + **消息发送**（`[obj method:]`，底层 `objc_msgSend`）。
- **nil 消息安全**（标量 0 / 对象 nil / 结构体未定义）—— 既是便利也是陷阱。
- 属性修饰符：`nonatomic/strong/weak/copy/assign/readonly`；`NSString` 用 `copy`，delegate 用 `weak`。
- 动态性：`id`/`SEL`/`Class`、`respondsToSelector:`、`performSelector:`（ARC 有坑）、分类。
- 多态靠**协议**，解耦靠 `id<Protocol>`。
- 错误处理靠 **BOOL + NSError** 二级指针，Swift 会翻译成 `throws`。
- 内存靠 **ARC**：strong/weak/copy，头号敌人是循环引用。

下一章：`05-objc-foundation.md` —— Foundation 的字符串、集合、数据、JSON（OC 篇）。
