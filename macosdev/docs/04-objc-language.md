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

## 9) 内存管理一句话版

ARC 下你需要关心的只有三点：

1. **`strong` / `weak` / `copy` / `assign`** 的属性语义。
   `NSString` / `NSArray` 这类有可变子类的，**属性一律写 `copy`**。
2. **循环引用**：block ↔ self、delegate（用 `weak`）、父子视图互相强引用。
3. **桥接**：CoreFoundation 对象与 Foundation 对象互转要 `__bridge` /
   `__bridge_transfer` / `__bridge_retained`。

## 小结

- OC 是消息发送，不是函数调用；nil 消息安全（但结构体返回值未定义）。
- 协议方法可 `@optional`；分类给已有类加方法（一定加前缀）。
- block 捕获外部变量要 `__block`；注意 weak-strong dance。
- 可预期的错误走 `NSError **`，异常只留给程序员错误。
- 生产代码用 `NSLog`，自测代码用 `printf`（`NSLog` 写 stderr）。
