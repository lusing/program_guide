# 04 · Objective-C 语言基础

> 示例：`examples/04_objc_language/`（`main.m` + `Person.h/.m` + `NSString+Extras.h/.m` + `Speaker.h`）
> 实测输出见 `build/04_objc_language/stdout.clt.txt`

macOS 上即使你写纯 Swift，也躲不开 Objective-C：

1. **AppKit 是 OC 写的**。所有委托协议、所有 API 都是 OC 语义。
2. **Selector / KVO / Bindings** 全靠 OC 运行时。
3. **XIB 里的 outlet/action** 连的是 OC 的 selector 和 ivar。
4. 大量第三方库、系统私有行为、崩溃栈都是 OC 的。

本章不是「OC 语法大全」，是**读得懂、改得动、能排查**所需的最小集合。

## 编译

```bash
clang -O2 -std=gnu11 -fobjc-arc -fmodules -Wall -Wextra -Wno-unused-parameter \
      -isysroot "$(xcrun --show-sdk-path)" -target x86_64-apple-macos12.0 -I . \
      Person.m NSString+Extras.m main.m -o 04_objc_language \
      -framework Foundation -framework AppKit
```

> **坑**：本教程所有 OC 示例用 `printf` 而不是 `NSLog`。
> `NSLog` 写的是**系统日志（stderr）**，而验证脚本要求「stderr 为空」——
> 用了它全部示例都会判失败。生产代码里 `NSLog` 没问题，自测里别用。

## 0) 先看懂一个 OC 类的骨架

后面所有语法都挂在这个骨架上，所以先把它拆开。示例里的 `Person` 类分两个文件：
**`Person.h`（接口/声明）** 和 **`Person.m`（实现）**。这是 OC 的硬规矩——
声明放头文件给别人 `#import`，实现放 `.m` 编进二进制。

```objc
// Person.h
#ifndef Person_h            // include guard：防止同一个头文件被重复 import
#define Person_h

#import <Foundation/Foundation.h>   // 尖括号 = 系统框架；引号 = 自己的文件
#import "Speaker.h"

NS_ASSUME_NONNULL_BEGIN     // 从这里到 END，所有指针默认 nonnull（详见第 07 章）

@interface Person : NSObject <Speaker>   // 类名 : 父类 <遵循的协议>

@property (nonatomic, copy)   NSString *name;   // 对象属性
@property (nonatomic, assign) NSInteger age;    // 标量属性

- (instancetype)initWithName:(NSString *)name age:(NSInteger)age NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;            // 禁掉默认 init

- (NSString *)greeting;                                  // 实例方法
- (BOOL)renameTo:(NSString *)newName error:(NSError **)error;  // 带出参的方法
- (NSInteger)lengthOfName;
- (NSRange)ageRange;                                     // 返回结构体

@end

NS_ASSUME_NONNULL_END
#endif
```

逐条拆解：

**`@property (属性字) 类型 *名字;`** —— 声明一个属性，编译器自动给你生成
getter、setter 和一个带下划线的实例变量（`_name`）。括号里的字决定内存语义：

| 属性字 | 含义 | 什么时候用 |
| --- | --- | --- |
| `nonatomic` | 非原子（不加锁，快） | 几乎总是写它；`atomic` 是默认值但很少需要 |
| `strong` | 强引用（持有对象，引用计数 +1） | 一般对象属性的默认 |
| `weak` | 弱引用（不持有；对象释放后自动变 nil） | delegate、父子视图回指，**防循环引用** |
| `copy` | 赋值时先 `copy` 一份再持有 | `NSString` / `NSArray` / `NSDictionary` / block——凡是有可变子类的，一律 `copy` |
| `assign` | 直接赋值（不管理引用计数） | 标量（`NSInteger`、`BOOL`、`CGFloat`、结构体） |
| `readonly` | 只生成 getter | 对外只读、对内可改的属性 |

> **为什么 `name` 是 `copy` 不是 `strong`**：如果调用方传进来一个
> `NSMutableString`，用 `strong` 会直接持有它——之后对方偷偷改内容，
> 你的 `name` 就跟着变了。`copy` 先拷一份不可变的，谁也动不了。
> 这是 OC 面试和实战都最常考的一条。

**方法声明的解剖**：

```objc
- (BOOL)renameTo:(NSString *)newName error:(NSError **)error;
│  │     │        │                  │
│  │     │        │                  └─ 第二个参数标签 + 类型
│  │     │        └─ 第一个参数标签 + 类型
│  │     └─ 方法名第一段
│  └─ 返回类型（写在括号里）
└─ '-' 实例方法；'+' 是类方法（工厂方法，如 +array、+stringWithFormat:）
```

**关键观念**：`renameTo:error:` 是**一个** selector，由两段拼成，不是两个方法。
OC 的方法名天生带参数标签，这也是为什么 Swift 导入后能变成
`rename(to:error:)` 这种可读的名字。

**`instancetype`** 表示「返回当前类的实例」，比写 `id` 更精确——
子类调用时编译器知道返回的是子类。构造器一律用它。

**`NS_DESIGNATED_INITIALIZER` / `NS_UNAVAILABLE`**：前者标记「指定初始化器」
（所有初始化最终都要走它），后者把不该用的 `init` 禁掉。
这两条影响 Swift 侧的 `init` 继承（第 07 章会看到）。

再看实现：

```objc
// Person.m
#import "Person.h"

static NSString *const MXRenameErrorDomain = @"MXRenameErrorDomain";  // 错误域常量

@implementation Person

- (instancetype)initWithName:(NSString *)name age:(NSInteger)age {
    self = [super init];          // ① 永远先让父类初始化
    if (self == nil) {            // ② 父类可能失败返回 nil
        return nil;
    }
    _name = [name copy];          // ③ 直接写实例变量，不走 setter
    _age = age;
    return self;                  // ④ 返回自己
}

- (NSString *)greeting {
    return [NSString stringWithFormat:@"你好，我是%@，%ld 岁", self.name, (long)self.age];
}

- (NSString *)description {       // 覆盖 NSObject 的 description（≈ Swift 的 CustomStringConvertible）
    return [NSString stringWithFormat:@"<Person %@ age=%ld>", self.name, (long)self.age];
}
@end
```

- **`self = [super init]` 这个四步套路是 OC 构造器的固定写法**，背下来。
  `init` 可能返回一个**不同于传入 self** 的对象（甚至 nil），所以必须接收返回值再判断。
- **构造器里用 `_name`（实例变量）而不是 `self.name`（属性 setter）**：
  初始化期间对象还没完全建好，调 setter 可能触发 KVO 或子类重写的副作用。
  直接写 ivar 最安全。（反过来，**析构 `dealloc` 里也别用属性**，同理。）
- **`%@` 打对象、`%ld` 打 `NSInteger`（要 `(long)` 转换）**——这是 OC 格式化的大坑，
  第 05 章专门讲。
- `description` 是调试时 LLDB `po` 打印的内容，等价于 Swift 的
  `CustomStringConvertible`。

**点语法 vs 消息发送**：`person.name` 和 `[person name]` **完全等价**，
点语法只是属性的读写糖。读是 `person.name`，写是 `person.name = @"x"`
（等于 `[person setName:@"x"]`）。方法调用一般还是用方括号。

## 1) 消息发送

```objc
Person *person = [[Person alloc] initWithName:@"小明" age:30];
printf("greeting : %s\n", [person greeting].UTF8String);
```

OC 里没有「函数调用」，只有**消息发送**：`[receiver selector]`。
这个区别不是玄学：

- 编译期不检查 receiver 有没有这个方法（只有警告）
- 运行期才由 objc_msgSend 查表找实现
- 找不到就走 **消息转发**（能救回来），再不行才 crash

相关工具：

```objc
[person isKindOfClass:[Person class]]      // 是不是这个类（含子类）
[person isMemberOfClass:[Person class]]    // 是不是正好这个类
[person respondsToSelector:@selector(greeting)]
[person conformsToProtocol:@protocol(Speaker)]
```

实测：

```
类         : Person
父类       : NSObject
是不是 Person : true
是不是 NSString : false
greeting   : 你好，我是小明，30 岁
description: <Person 小明 age=30>
```

`description` 相当于 Swift 的 `CustomStringConvertible`，
调试时 LLDB 的 `po` 打的就是它。

## 2) nil 消息：最省心也最容易误判的一条规则

```objc
Person *nobody = nil;
[nobody greeting];       // 返回 nil，不崩
[nobody lengthOfName];   // 返回 0，不崩
```

| 返回值类型 | 发给 nil 的结果 |
| --- | --- |
| 对象指针 | `nil` |
| 整数 / BOOL | `0` / `NO` |
| 浮点 | `0.0` |
| **结构体**（NSRange/CGRect…） | **未定义**，可能拿到垃圾 |

实测：

```
发给 nil 的返回值 : nil
向 nil 取值      : 0
向 nil 取 struct : 未定义（不要依赖）
多次发送安全      : true
```

**结构体那条是真正的坑**：x86_64 上常常恰好返回全 0，arm64 上未必。
示例里故意**不打印**那个值 —— 它会随架构和编译器变。

nil 消息的连带后果：

```objc
if (dict[@"key"].length > 0) { ... }   // dict 为 nil → 0 > 0 → false，静默走 else
```

一个拼写错的 key、一个忘了初始化的属性，都能让整段逻辑**静默失效**。
这是 OC 代码里最难查的一类 bug。

## 3) SEL 与动态性

```objc
SEL greetingSel = @selector(greeting);
NSString *name = NSStringFromSelector(greetingSel);      // "greeting"
Class cls = NSClassFromString(@"Person");                // 运行时按名字找类
```

ARC 下 `performSelector:` 会告警：

```
warning: performSelector may cause a leak because its selector is unknown
```

因为编译器不知道返回值该由谁持有。现代代码要么直接调用，要么用
`NSInvocation`，要么显式关掉警告：

```objc
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
NSString *viaPerform = [person performSelector:greetingSel];
#pragma clang diagnostic pop
```

> **坑**：本教程要求**编译零告警**。用 `#pragma` 关警告可以，
> 但必须写清楚为什么 —— 不然就是把问题藏起来。

实测：

```
selector 名字 : greeting
有没有这个键 : true
有没有这个键 : false
performSelector: 你好，我是小明，30 岁
和直接调用一致 : true
NSClassFromString("Person") : Person
NSClassFromString("NotExist") : Nil
```

## 4) 协议与分类

**协议（protocol）** ≈ Swift 的 protocol，但方法可以是 `@optional`：

```objc
@protocol Speaker <NSObject>
- (NSString *)speakTimes:(NSInteger)times;
@optional
- (void)didFinishSpeaking;
@end
```

声明变量时写 `id<Speaker> speaker;`（Swift 里是 `any Speaker`）。

**分类（category）** 给已有类加方法，不用改源码：

```objc
@interface NSString (Extras)
- (NSString *)mx_reversedString;
@end
```

实测：

```
遵循 Speaker 协议 : true
协议方法     : 你好，我是小明，30 岁 / 你好，我是小明，30 岁
分类方法（字符串倒序）: fedcba
分类方法（再倒一次）: abcdef
```

> **坑**：分类方法名**必须加前缀**（这里是 `mx_`）。
> 系统类被多个库同时加同名分类方法时，谁生效是未定义的。

分类只能加**方法**，不能加实例变量。想加存储用**关联对象**
（`objc_setAssociatedObject`）或者直接子类化。

## 5) block

OC 的 block ≈ Swift 闭包，语法是 `^returnType(args)`：

```objc
NSInteger (^doubler)(NSInteger) = ^NSInteger(NSInteger value) {
    return value * 2;
};

__block NSMutableString *trace = [NSMutableString string];
void (^recorder)(NSString *) = ^(NSString *label) {
    [trace appendFormat:@"%@ ", label];   // __block 让外部变量在 block 里可写
};
```

- 不加 `__block`，block 里只能**读**外部变量（它被 const 拷贝进来）。
- block 会自动 copy 捕获到的对象，所以要注意循环引用（见下）。

**循环引用**：block 捕获 `self`，`self` 又持有这个 block → 谁都不释放。
标准写法：

```objc
__weak typeof(self) weakSelf = self;
self.completion = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;   // 进来先转强，防止半路被释放
    if (!strongSelf) return;
    [strongSelf doSomething];
};
```

实测：

```
block 调用 : 42
__block 累积 : 一 二 三
按长度排序 : pear,apple,orange
```

## 6) NSError：OC 的「异常替代品」

OC 的异常（`NSException`）**只用于程序员错误**（越界、未实现的方法）。
可预期的失败一律用 `NSError **` 出参：

```objc
NSError *error = nil;
BOOL ok = [person renameTo:@"" error:&error];
if (!ok) {
    printf("错误域 : %s\n", error.domain.UTF8String);
    printf("错误码 : %ld\n", (long)error.code);
    printf("描述   : %s\n", error.localizedDescription.UTF8String);
}
```

约定（**必须遵守，这是 Cocoa 的 API 契约**）：

- 方法返回 `NO` / `nil` 时，`error` 才有意义；
- **成功时 `error` 的值未定义**，哪怕你传进去的是非 nil 也可能被改。

实测：

```
空名字是否成功 : false
错误域     : MXRenameErrorDomain
错误码     : 1001
本地化描述 : 名字不能为空
合法改名   : true
成功后 error 必须被忽略 : nil（约定如此）
```

Swift 里这套自动变成 `try` / `throws`：

```swift
try person.rename(to: "")
```

这是 OC → Swift 桥接里最舒服的一条。

## 7) Foundation 的容错习惯

```
空数组 firstObject : nil        ← 不是崩溃
越界取值会抛异常，所以先数一遍 : 0
字面量字典 : v
查不存在键 : nil                ← 不是崩溃
装箱      : 42 / objCType=i
NSValue range: location=3 length=4
```

- 集合取**不存在**的元素 / key → `nil`（安全）
- 数组**越界下标** → 抛 `NSRangeException`（不安全）

这一半安全一半不安全，是 OC 代码里最需要小心的地方。

## 8) @try/@catch

```objc
@try {
    [words objectAtIndex:99];
} @catch (NSException *exception) {
    printf("异常名 : %s\n", exception.name.UTF8String);
} @finally {
    printf("finally 执行 : true\n");
}
```

实测：

```
异常名     : NSRangeException
reason 非空 : true
finally 执行 : true
捕获到异常 : true
```

**只在必要处用**。OC 的常见风格是「先检查再访问」，而不是「包一层 try」：
`@try` 在 ARC 下不能保证所有资源都被正确释放， exception 穿过 ARC
代码时可能泄漏。

## 9) ARC 与内存管理

OC 用**引用计数**管理内存：每个对象有个计数器，`retain` +1、`release` -1，
归零就 `dealloc`。**ARC（Automatic Reference Counting）** 不是垃圾回收——
它只是让**编译器在编译期自动插入** `retain` / `release` / `autorelease`，
你不再手写。开了 `-fobjc-arc`（本教程一律开），规则是：

- 一个对象被「强引用」着就不会被释放；最后一个强引用消失，它立刻 dealloc。
- 你**不写** `retain` / `release` / `autorelease`，也**不重写** `dealloc` 去调 `[super dealloc]`
  （ARC 帮你调）。`dealloc` 只用来做「释放非 OC 资源」（关文件、移除 KVO 观察、注销通知）。

ARC 下你真正要操心的只有三件事：

### 9.1 属性语义（strong / weak / copy / assign）

第 0) 节的表已经列全。一句话总结：**对象默认 `strong`；
有可变子类的（`NSString`/`NSArray`/`NSDictionary`/block）一律 `copy`；
回指型（delegate、父视图）用 `weak`；标量用 `assign`。**

### 9.2 循环引用（retain cycle）—— ARC 下唯一的内存泄漏来源

ARC 能自动释放，**但救不了循环引用**：A 强持有 B、B 又强持有 A，
两个计数都永远 ≥ 1，谁都释放不了。三种最常见：

```objc
// ① block ↔ self：block 捕获 self，self 又持有这个 block
self.completion = ^{
    [self doSomething];      // ← block 强引用了 self，self 强引用 block，泄漏
};

// 标准解法：weak-strong dance
__weak typeof(self) weakSelf = self;
self.completion = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;  // 进来先转强
    if (!strongSelf) return;                          // 已经释放就直接退出
    [strongSelf doSomething];                         // 用的时候是强引用，不会半路被释放
};
```

```objc
// ② delegate：必须 weak，否则「我持有我的代理、代理又持有我」
@property (nonatomic, weak) id<MyDelegate> delegate;   // ← 永远 weak
```

```objc
// ③ 父子视图互相强引用：父 view 强持有子 view 是对的，
//    子 view 回指父 view 必须 weak（AppKit 里 NSView.superview 就是 weak）
```

> **怎么发现**：Instruments 的 Leaks / Allocations，或者给类写个 `dealloc`
> 打个断点——该释放时断不住，就是被谁强引用着。Xcode 的 Memory Graph 能直接画出环。

### 9.3 与 CoreFoundation 的桥接

Foundation 对象（`NSString`）和 CoreFoundation 对象（`CFStringRef`）
其实是**同一个东西的两种指针**（toll-free bridging），但 ARC 只管 Foundation 这一侧。
互转时要显式告诉编译器「所有权归谁」：

| 桥接关键字 | 含义 | 用在 |
| --- | --- | --- |
| `__bridge` | 只转指针，**不转移所有权** | 临时把 OC 对象传给 CF 函数、CF 对象传给 OC（不接管释放） |
| `__bridge_transfer` | CF → OC，**把释放责任交给 ARC** | 拿到一个 +1 的 CF 对象（如 `CFBridgingRelease`） |
| `__bridge_retained` | OC → CF，**ARC 多持有一次，你要自己 `CFRelease`** | 把 OC 对象交给 CF 长期持有（`CFBridgingRetain`） |

```objc
NSString *ns = @"hello";
CFStringRef cf = (__bridge CFStringRef)ns;      // 借用，不管释放
// ...
CFStringRef owned = CFStringCreateCopy(NULL, cf); // +1，要自己释放
NSString *back = (__bridge_transfer NSString *)owned;  // 把释放责任交给 ARC
```

> 日常 AppKit 开发里直接写 `__bridge` 的机会不多，但读系统 API
> （`CGImage`、`CGColor`、`CFDictionary`）时一定会撞到。记住「谁 +1 谁释放」就不会错。

## 小结

- OC 是消息发送，不是函数调用；nil 消息安全（但结构体返回值未定义）。
- 类分 `.h`（声明）/`.m`（实现）；构造器走 `self = [super init]` 四步，里面用 ivar 不用 setter。
- 属性语义：对象 `strong`、有可变子类的一律 `copy`、回指 `weak`、标量 `assign`。
- 协议方法可 `@optional`；分类给已有类加方法（一定加前缀）。
- block 捕获外部变量要 `__block`；注意 weak-strong dance 防循环引用。
- 可预期的错误走 `NSError **`，异常只留给程序员错误。
- ARC 自动管引用计数，但**救不了循环引用**；CF 桥接记「谁 +1 谁释放」。
- 生产代码用 `NSLog`，自测代码用 `printf`（`NSLog` 写 stderr）。
