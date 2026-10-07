# 27 · Objective-C 运行时：选择器、方法表与「类本身」

> 示例：`examples/27_objc_runtime/main.swift`（OC 侧的证据在 `RTMsg.m`、`RTDecl.m`、`RTDyn.m`）
> 实测输出见 `build/27_objc_runtime/stdout.debug.txt`

前面二十六章都在「API 之上」写代码：视图怎么布局、动画怎么挂、数据怎么存。
这一章往下走一层，走到那些 API 真正站着的地方——**Objective-C 运行时**。
它不是一套框架，是一个动态链接的库（`libobjc`），干的事只有一件：
把「你调了哪个方法」这句话在**运行的时候**翻译出来。

这一层的东西平时看不见，是因为编译器天天替你翻译。一旦它漏出来，就是这些具体的现场：

- storyboard / xib 里填 Swift 类要写 `模块名.类名`，只写类名加载失败（§18）；
- 一个 `@objc` 方法打了补丁「有时灵有时不灵」（§19）；
- `unrecognized selector sent to instance` 崩溃（§8）；
- KVC 把字典转模型搞崩、KVO 摘掉观察者之后崩（§12、§13）；
- 无脑 `performSelector:` 拿到一个「看起来是对象」的东西，`retain` 时崩（§3、§9）；
- `value(forKey:)` 读不到 Swift 自己的属性（§19）。

这本书的第 5、6、7 章讲的就是这一层（runtime 与消息传递、类别与协议、KVC 与 KVO），
但那是十年前写的：里面大量篇幅在手工 `retain`/`release`/`autorelease`、两参数版
`addObserver:forKey:withOptions:`、以及「非正式协议」——今天这三样要么不该再写，要么根本不存在。
所以本章按今天的规则把同一批知识点重写了一遍，并且**补上了 Swift 侧**（§18~§22）：
今天写 iOS 的人主要在 Swift 里，而 Swift 与这一层的关系恰恰是最容易搞错的——
它既不是「完全隔离」，也不是「全都适用」，而是**内存布局共用、消息表分家**。

```
形状   §1  选择器只是名字：唯一化、字符串构造、非 ASCII
空值   §2  nil 接收者的返回值全表（含结构体与 CGAffineTransform）
发送   §3  IMP、methodForSelector: 与 objc_msgSend 家族（x86_64 的 stret / fpret）
隐藏   §4  self 与 _cmd：一份实现服务多个选标
编码   §5  @encode 全表、方法类型编码里的字节偏移、NSMethodSignature
属性   §6  @property 的三件套：访存方法 + ivar + 编码串
变量   §7  ivar 反射、按偏移直写内存、关联对象
转发   §8  消息转发的四级台阶（resolve / 快转发 / 签名 / forwardInvocation）
换脸   §9  换实现的两条路：交换 IMP 与直接替换，以及它的类级别影响
分类   §10 分类合并进方法表、不能加 ivar、+load 与 +initialize 的顺序
协议   §11 协议的运行时视图：方法描述、required/optional、采纳关系
取值   §12 KVC 的候选顺序与集合运算符
观察   §13 KVO 的 isa 换脸、change 字典、通知时机与四条误用
内省   §14 isKindOfClass/isMemberOfClass/responds/conforms 四问，类与元类，运行期造类
通信   §15 target-action、delegate、notification 的 runtime 视角
可变   §16 可变/不可变的类层级与 copy 的实际类
异常   §17 @try/@catch/@finally 的匹配规则
Swift  §18 Swift 类在 ObjC runtime 里长什么样（名字的三种形态）
Swift  §19 @objc 与 @objc dynamic：换实现对两条调用路径的影响不一样
Swift  §20 Swift 侧 KVO：observe(...) 返回的 token
Swift  §21 通知中心：一对多、按名字、发送方不认识接收方
Swift  §22 Mirror 与 runtime：两套反射各管一半
边界   §23 这一章量到了什么、只能记什么、只有真机才能量什么
```

## 本章的方法：这一章的每个数字是怎么来的

本章的示例是**Swift + Objective-C 混编**，这是全教程第一个混编示例，编译流程也就得先讲清楚，
因为它决定了「为什么证据必须由 OC 侧生产」。`run-all.sh` 见到目录里有 `Bridging.h` 就走混编路径：

```
1) swiftc -c -Onone|-O -target x86_64-apple-ios15.0-simulator -module-name objc_runtime \
          -import-objc-header Bridging.h *.swift            # 先编 Swift，产出各 .o
2) clang -c -O2 -std=gnu11 -fobjc-arc -fmodules \
          -Wall -Wextra -Wno-unused-parameter -isysroot $SDK -I <示例目录> *.m   # 再编 OC
3) swiftc … *.o -o <bin> -framework Foundation -framework UIKit -framework SwiftUI  # 链接
4) xcrun simctl spawn <模拟器> <bin> --selftest             # 在模拟器里跑
```

三个细节都是坑：`-module-name` 决定 Swift 类在 ObjC 里的名字前缀（§18 那串 `objc_runtime.` 就从这来）；
OC 侧固定 `-O2`，Swift 侧才分 `-Onone` / `-O` 两个配置；`swiftc -c` 多文件时会把 `.o` 写在**当前目录**
而不是 `-o` 指定的地方，所以脚本 `cd` 进 `build/27_objc_runtime/` 再编。

跑完之后按全教程统一的六条判定验收：编译日志为空（`-Wall -Wextra` 下**有警告就算失败**）、
退出码 0、**stderr 必须为空**、stdout 非空、stdout 不含 TAB/LF/CR 之外的控制字符、
末尾有 `==== 27 结束 ====`；外加 debug 与 release 两份 stdout **逐字节一致**。

这些判定在本章直接派生出四条写法，后面每一节都能看见它们在起作用。

**1) 凡是指针、地址、进程级大数，一律不打值，只打形状。**
IMP 和 Method 都是函数指针，打出来每次运行都不同，还顺手违反判定 4（地址里全是控制字符的可能）。
所以本章对指针只做三件事：**比相等**（`不相等=1`）、**问空不空**（`返回 NULL，不抛异常`）、
**问类名**（`NSStringFromClass`）。`objc_copyClassList` 在这台模拟器上返回两万多，
那个数随系统与已加载库变化，写进断言第二天就会假失败，所以 §14 只写了半句
「进程内注册的类总数是随系统变化的大数，不能拿来断言」，一次都没打。

**2) 顺序不稳定的东西，排序之后才打。**
本章有四处踩过这个雷：`class_copyMethodList`、`class_copyPropertyList` 的返回顺序、
`NSSet` 的枚举顺序、通知观察者的回调顺序。它们在 `-Onone` 与 `-O` 下**真的不一样**，
判定 6 会立刻报「输出差异」。做法统一是：先 `sortedArrayUsingSelector:@selector(compare:)`
再拼成一行，并在输出里明说这是排过序的：

```objc
Method *ms = class_copyMethodList([RTProps class], &mn);
// 方法表的顺序在 -Onone / -O 下会变，输出前排序才能得到「两次编译逐字节相同」的证据
NSMutableArray<NSString *> *msPicked = [NSMutableArray array];
for (unsigned i = 0; i < mn; i++) {
    NSString *name = NSStringFromSelector(method_getName(ms[i]));
    if ([name hasPrefix:@"plain"] || [name hasPrefix:@"roValue"] || [name hasPrefix:@"customGet"]) {
        [msPicked addObject:name];
    }
}
free((void *)ms);
NSArray<NSString *> *msSorted = [msPicked sortedArrayUsingSelector:@selector(compare:)];
```

**3) 中文一律走 `%@`，不走 `%s`。**
runtime 有一批函数返回 `const char *`（`sel_getName`、`method_getTypeEncoding`、`ivar_getName`），
把它们直接塞进 `%s` 打印 ASCII 名字没问题，可一旦那串字节是 UTF-8 的中文，`%@` 之外的路就乱了：
`%s` 不按 UTF-8 解 C 字符串。§1 里就有一次专门留下的对比——同一个中文选标，
先包成 `NSString` 再打就正常，直接交给 `%s` 就是一串乱码，这是本章所有中文都走
`NSStringFromSelector` 的原因（那一条本身就是 §1 的输出之一）。

**4) 会崩、会递归、会死锁的调用，只在独立探针进程里跑，正文引用原文。**
本章有整整一批结论的形状是「这一步会把进程打死」：unrecognized selector、`@try` 之外的
`valueForUndefinedKey:`、给标量键塞 nil、KVO 的四条误用、分类里写 ivar 的编译错误、
钩子里 `[self label]` 的自我递归、`objc_msgSend_stret` 参数顺序写错。
这些一次都没在示例里执行——执行了就没有 stderr 为空、没有退出码 0、也没有后面的小节了。
它们各自单独编一个可执行文件跑一遍，把 stderr/编译诊断的**原文**抄进输出里，
并在前面明写「探针记录」。判断标准很简单：**示例只跑活下来的那些**。

最后一个结构性决定：**OC 侧生产证据，Swift 侧打印与断言**。
理由写在 `RTRuntime.h` 的头一份注释里——很多结论一旦经过 Swift 的类型检查就根本看不到了：
「声明了但没实现」在 Swift 里编译都过不去，而它恰恰是 ObjC 一切动态性的入口。
于是分工是 `RTMsg.m`（§1~§5）、`RTDecl.m`（§6/§7/§10/§11/§16/§17）、`RTDyn.m`（§8~§15）
各返回一个 `NSArray<NSString *> *`，`main.swift` 拿到之后统一打印，Swift 侧自己的
§18~§22 才在 Swift 里就地断言。OC 侧的「黑板」是一根全局数组，一节开始前 `begin` 清空，
动作过程里谁执行谁 `add:` 一行，最后 `end` 整块交出去：

```objc
@implementation RTL
+ (void)begin { [[self bucket] removeAllObjects]; }
+ (void)add:(NSString *)line { [[self bucket] addObject:line]; }
+ (NSArray<NSString *> *)end { return [[self bucket] copy]; }
+ (NSUInteger)count { return [[self bucket] count]; }
@end
```

这样「断言里出现的顺序」就是真实执行顺序，不需要靠打印时机猜。
另有一块 `+record` 用的「永久记录板」，因为 `+load` 早于 `main`，写进普通黑板会被下一节的
`begin` 抹掉（§10 那三条 `+load` 就是这么留下来的）。

## 1) 选择器只是名字：SEL 的唯一化

ObjC 的方法调用不叫「调用」，叫**发消息**：`[greet greet:@"runtime"]` 编译出来是一句
`objc_msgSend(greet, @selector(greet:), @"runtime")`。这里面 `@selector(greet:)` 就是全部身份信息——
它是一个 `SEL`，而 `SEL` 是**方法名字符串在进程里唯一化之后的指针**。
这句话有三层含义，本章第一层就把它量完：

```objc
SEL s1 = @selector(greet:);
SEL s2 = sel_registerName("greet:");
[RTL add:[NSString stringWithFormat:@"同一个字符串走 sel_registerName 得到的 SEL 与 @selector 相等=%d（SEL 是全局唯一化后的指针）", s1 == s2]];
[RTL add:[NSString stringWithFormat:@"NSSelectorFromString(@\"greet:\") 也相等=%d", NSSelectorFromString(@"greet:") == s1]];
[RTL add:[NSString stringWithFormat:@"SEL 的指针值相等性可直接用 ==，也可用 sel_isEqual=%d", sel_isEqual(s1, s2)]];
```

同一份名字的三种构造途径得到**同一个指针**，所以 `SEL` 可以直接用 `==` 比（不必用 `sel_isEqual`，
两者等价，后者只是意图更明白）。这是 ObjC 里极少数能拿 `==` 比的「值语义」对象之一，
根因就是名字被唯一化了。

第二层：**选择器字符串只含关键字标签，不含类型**。`setAge:(int)` 和 `setAge:(NSString *)`
是同一个 SEL；每个参数一个冒号，冒号前后的标签文字进选择器；零参方法不带冒号，
所以 `number` 和 `number:` 是**两个不同的 SEL**。

第三层最要紧：**runtime 只登记名字，不查有没有实现**。

```objc
SEL bogus = NSSelectorFromString(@"noSuchMethodAtAll");
[RTL add:[NSString stringWithFormat:@"    NSSelectorFromString(@\"noSuchMethodAtAll\") -> %@（照样得到一个合法 SEL：runtime 只登记名字，不查有没有实现）",
          NSStringFromSelector(bogus)]];
SEL cnSel = NSSelectorFromString(@"中文选择器名");
[RTL add:[NSString stringWithFormat:@"    名字甚至可以不是 ASCII：sel_registerName(\"中文选择器名\") 与它相等=%d，UTF-8 字节数=%lu —— SEL 认的是「唯一化后的名字」，字符集不设限",
          cnSel == sel_registerName("中文选择器名") ? 1 : 0,
          (unsigned long)strlen(sel_getName(cnSel))]];
```

`@selector(...)` 写错方法名连编译都过不去（编译器会查声明），但 `NSSelectorFromString` 什么也不查，
它只是把一个字符串登记成一个合法 SEL。这一条是本章后面所有崩溃的总根：
`performSelector:`、target-action、xib 连线、`didSelectRowAt` 的手写选标，走的都是这条路。
顺带一个反直觉的事实：选标名字**可以不是 ASCII**，`@"中文选择器名"` 是 6 个汉字 ×3 字节 = 18 个 UTF-8 字节，
`sel_registerName` 与 `NSSelectorFromString` 依然把它唯一化成同一个指针。

```
== §1 选择器与消息的形状 ==
@selector(greet:) 的字符串=greet:
同一个字符串走 sel_registerName 得到的 SEL 与 @selector 相等=1（SEL 是全局唯一化后的指针）
NSSelectorFromString(@"greet:") 也相等=1
SEL 的指针值相等性可直接用 ==，也可用 sel_isEqual=1
两个无参方法的 SEL 不同=1；它们的字符串分别是 number / neverImplemented
选择器字符串只含关键字标签，不含类型：setAge:(int) 与 setAge:(NSString *) 是同一个 SEL，见下
setValue:forKey: 的字符串=setValue:forKey:（每个参数一个冒号，标签文字进选择器）
零参方法的选择器不带冒号：number 的字符串=number；把名字改成带冒号的 number: 就是另一个 SEL，两者不相等=1
@selector 的参数写错会连编译都过不了，但运行时用字符串构造就没人拦：
    NSSelectorFromString(@"noSuchMethodAtAll") -> noSuchMethodAtAll（照样得到一个合法 SEL：runtime 只登记名字，不查有没有实现）
    名字甚至可以不是 ASCII：sel_registerName("中文选择器名") 与它相等=1，UTF-8 字节数=18 —— SEL 认的是「唯一化后的名字」，字符集不设限
    同一段字节要先用 NSStringFromSelector 包成 NSString、再走 %@ 才打得正常：把 sel_getName 的结果直接交给 stringWithFormat 的 %s，中文会变成一串乱码（%s 不按 UTF-8 解 C 字符串）—— 这就是本章所有中文一律走前者的原因
```

最后那一行是「写这一章的方法」而不是「ObjC 的知识」，但值得留在输出里：
一开始本节用 `%s` 打中文选标，输出是一串乱码，看起来像 runtime 出了问题。
单独探针量下来，`sel_getName(NSSelectorFromString(@"拼写"))` 返回的字节正是
`e6 8b bc e5 86 99`——和输入一字不差，三种登记途径拿到的还是同一个指针。
坏的是打印环节，不是 runtime。**凡是「框架看起来错了」的怀疑，先在自己那一侧做对照实验。**

## 2) nil 接收者的返回值全表：不崩 ≠ 安全

「给 nil 发消息不崩」是 ObjC 最有名的一条性质，也是最容易被记成「反正不崩」的一条。
正确的版本要按返回类型分档，而且分档里有几个反直觉的。本章把 `RTGreeter` 写成
每个返回类型各一个方法，然后把同一句消息分别发给一个真对象和一个 `nil`：

```objc
RTGreeter *g = [RTGreeter new];
RTGreeter *nilG = nil;
[RTL add:[NSString stringWithFormat:@"int：真值=%d nil=%d", [g number], [nilG number]]];
[RTL add:[NSString stringWithFormat:@"short=%d/%d  char=%d/%d（char 打出来是整数 65 而不是字母：65 是 'A' 的码点，这一行统一按整数打才看得清 0 从哪来 —— nil 一律给 0）",
          [g smallInt], [nilG smallInt], [g byte], [nilG byte]]];
[RTL add:[NSString stringWithFormat:@"id：真值=%@ nil=%@", [g object], [nilG object]]];
```

实现端的返回值刻意各不相同（`424242`、`'A'`、`3.125L`、`CGRectMake(1.5,2.5,3.5,4.5)`…），
这样「nil 那一列全是 0」不可能是巧合。

```
== §2 nil 接收者的返回值全表 ==
int：真值=424242 nil=0
long long：真值=1234567890123 nil=0
unsigned long long：真值=9876543210987 nil=0
short=33/0  char=65/0（char 打出来是整数 65 而不是字母：65 是 'A' 的码点，这一行统一按整数打才看得清 0 从哪来 —— nil 一律给 0）
BOOL：真值=1 nil=0（0 就是 NO）
float=1.500000 nil=0.000000；double=2.250000 nil=0.000000
long double=3.125000 nil=0.000000
unichar=0x4E2D nil=0x0000
id：真值=一个对象 nil=(null)
Class：真值=RTGreeter nil=(null)
SEL：真值=number nil=(null)
void 方法发给 nil：什么都不发生，程序继续跑
CGRect nil=(0.0 0.0 0.0 0.0)（真值=(1.5 2.5 3.5 4.5)）
CGPoint nil=(0.0 0.0)  CGSize nil=(0.0 0.0)
NSRange nil={0 0}（注意 location 也是 0，不是 NSNotFound）
CGVector nil=(0.0 0.0)  CGAffineTransform nil=(0.0 0.0 0.0 0.0 0.0 0.0)
CGAffineTransform 不是单位矩阵！单位矩阵是 (1 0 0 1 0 0)，nil 给你的是全 0 —— 拿它去乘坐标会把图形压成一点
32 字节结构体（走隐藏指针返回）nil=(0.0 0.0 0.0 0.0)
8 字节结构体（走寄存器返回）nil=(0.0 0.0)
nil 的 length=0、count=0、isEqual nil=0、class=nil
链式调用一路 nil 到底也不崩：[[nilG dictValue] objectForKey:@"k"] 返回 nil
    实测=(null)
```

把这张表读完，四条结论：

- **标量给 0，指针给 nil，void 什么都不发生**。`BOOL` 那条要单看：真值 `1`、nil `0`，
  而 `0` 就是 `NO`——所以 `[nil hasSomeProperty]` 的答案是「没有」，在布尔语境里恰好像对的，
  于是错误被藏起来了。
- **结构体也是全 0**，而且两种返回方式（8 字节走寄存器、32 字节走隐藏指针）都一样。
  这是消息发送机制的副产品：runtime 发现接收者是 nil，就直接把返回缓冲区抹成 0。
- **`NSRange` 的 `location` 是 0，不是 `NSNotFound`**。这条最容易写进业务逻辑：
  `[nil rangeOfThing]` 得到 `{0, 0}`，看着像一个真的位置。
- **`CGAffineTransform` 给的是全 0，不是单位矩阵**。单位矩阵是 `(1 0 0 1 0 0)`，
  全 0 的变换会把任何坐标压成原点。这一条是本章里「不崩但结果有害」的头号样本。

`nil` 的 `length`/`count`/`isEqual:`/`class` 那行说明它为什么能链式调用一路到底：
每个环节都返回 0 或 nil，于是 `[[nilG dictValue] objectForKey:@"k"]` 是 nil 而不是崩溃。
**代价是错误不再以崩溃的形式出现，而是以一个 0 的形式继续往下跑。**
凡是「读到一个 0 / 一个空」会改变业务含义的地方，`nil` 的宽容就是 bug 的温床，
该写的判断是「接收者到底是不是 nil」，而不是「结果看起来对不对」。

## 3) IMP 与 objc_msgSend 家族：把编译器藏起来的那一步摊开

`[obj method]` 是语法糖，糖纸剥开是三个零件：**接收者**、**SEL**、**IMP**。
IMP（implementation）就是方法实现的函数指针。本节把同一句消息用四种方式发出去，
让它们给出同一个数：

```objc
    typedef int (*IntFn)(id, SEL);
    IntFn direct = (IntFn)[g methodForSelector:@selector(number)];
    [RTL add:[NSString stringWithFormat:@"[g number]=%d", [g number]]];
    [RTL add:[NSString stringWithFormat:@"methodForSelector: 拿到 IMP 后直接调=%d（必须自己补 self 和 _cmd）", direct(g, @selector(number))]];
    IMP fromClass = class_getMethodImplementation([RTGreeter class], @selector(number));
    [RTL add:[NSString stringWithFormat:@"class_getMethodImplementation 拿到的是同一个 IMP=%d", fromClass == (IMP)direct]];
    [RTL add:[NSString stringWithFormat:@"((IntFn)objc_msgSend)(g, @selector(number))=%d", ((IntFn)objc_msgSend)(g, @selector(number))]];
```

关键是那个函数指针类型：**前两个参数必须是 `id` 和 `SEL`**，也就是 §4 要讲的 `self` 与 `_cmd`。
拿到 IMP 之后直接调，编译器不再替你补这两个隐藏参数——忘了补就是拿栈上的垃圾当 `self`。

```
== §3 IMP、methodForSelector 与 objc_msgSend 家族 ==
[g number]=424242
methodForSelector: 拿到 IMP 后直接调=424242（必须自己补 self 和 _cmd）
class_getMethodImplementation 拿到的是同一个 IMP=1
((IntFn)objc_msgSend)(g, @selector(number))=424242
带对象参数的：objc_msgSend(g, greet:, @"runtime")=你好，runtime
8 字节结构体用普通 objc_msgSend 取回=(31.0 32.0) —— 对，寄存器返回时不需要特殊函数
double 用普通 objc_msgSend=2.250000（和直接 [g doubleNum] 相等=1）
x86_64 上 32 字节的 CGRect 必须用 objc_msgSend_stret，且**返回地址是第一个参数**：取到=(1.5 2.5 3.5 4.5)
它与消息发送的结果相等=1
探针记录：把 stret 方法的返回值按 CGRect(*)(id,SEL) 从普通 objc_msgSend 里取，不是拿到脏数据，而是当场 SIGSEGV（见本章诚实边界）。
浮点返回值的两个通道（每组前一个是 objc_msgSend，后一个是 objc_msgSend_fpret）：double 2.250000 vs 2.250000（相等=1）；float 1.500000 vs 1.500000（相等=1）；long double 3.125000 vs 3.125000（相等=1）
    诚实结论：本机（x86_64 模拟器）上三种浮点返回类型走哪个通道都取到同一个值，连 sizeof(long double)=16 的这个「最像会变坏」的类型也没变坏 —— 所以这一章不能声称「用普通 objc_msgSend 读浮点返回值一定读到脏的」。两个通道并存说明的是 ABI 里浮点寄存器与整数寄存器分家（stret 那条就是分家的代价），至于哪个通道才算「正规」，Apple 把 fpret 单独列出来本身就是在给答案。
找不到的选标：class_getMethodImplementation 返回一个**内部桩**而不是 NULL，所以「IMP 非空」不代表方法存在（见 §8 的 doesNotRecognizeSelector）=1
self 走子类=[ss tag] -> 子类的 tag ← 基类的 tag
super 走父类=[ss viaSuper] -> 基类的 tag
objc_msgSendSuper 手工版 -> 基类的 tag
[ss viaRuntimeSuper]（方法内部自己构造 objc_super）-> 基类的 tag
注意：super 不是对象，它是「从父类开始查方法表」的编译期记号；[super m] 的接收者依然是 self
```

`objc_msgSend` 家族有四个变体，选哪个**不由方法决定，由返回类型的 ABI 决定**：

| 函数 | 什么时候用 | 本节的证据 |
| --- | --- | --- |
| `objc_msgSend` | 返回对象、标量、指针，以及**寄存器返回的小结构体** | `RTPair`（2 个 float，8 字节）直接取回 `(31.0 32.0)` |
| `objc_msgSend_stret` | **x86_64** 上返回需要走内存的大结构体 | `CGRect`：`(&返回地址, 接收者, _cmd, …)` |
| `objc_msgSend_fpret` | 返回浮点（x86_64 上 xmm/st 分家的产物） | 三个浮点类型两通道实测同值 |
| `objc_msgSendSuper` | 接收者是「从父类开始查」的结构体指针 | 手工版与 `[super tag]` 结果一致 |

两条必须记住的：

1. **`stret` 的返回地址是第一个参数**，不是「没有返回值时的第 0 个参数」。
   写成 `objc_msgSend_stret(g, @selector(rectValue))` 会把 `g` 当返回缓冲区，
   探针里那次是当场 SIGSEGV——不是脏数据，是硬崩。另外这条只在 **x86_64** 成立：
   arm64 的 ABI 没有结构体返回的专用变体，`objc_msgSend_stret` 在那个架构上不存在
   （示例用 `#if defined(__x86_64__)` 分流，本教程跑在 x86_64 模拟器上，所以打的是 x86_64 那一支）。
2. **浮点这一档本章不装懂**。文档说浮点返回值要走 `fpret`，本机实测三个类型两个通道都给同一个正确值，
   连 16 字节的 `long double` 都没坏——所以正文只写「两通道并存说明浮点寄存器与整数寄存器分家」，
   不写「不走 fpret 就会读到脏值」。这类「我量不出来但文档这么说」的差距，本章一律留在输出里明说。

最后一组是 `super`。`struct objc_super` 有两个字段：`{接收者, 从哪个类开始查}`，
而「接收者」填的还是 `self`：

```objc
@interface RTSuperSub : RTSuperBase
@end
@implementation RTSuperSub
- (NSString *)tag { return [@"子类的 tag ← " stringByAppendingString:[super tag]]; }
- (NSString *)viaSuper { return [super tag]; }
- (NSString *)viaRuntimeSuper {
    struct objc_super sup = { self, class_getSuperclass(object_getClass(self)) };
    NSString *(*fn)(struct objc_super *, SEL) = (NSString *(*)(struct objc_super *, SEL))objc_msgSendSuper;
    return fn(&sup, @selector(tag));
}
@end
```

`[ss tag]` 打出 `子类的 tag ← 基类的 tag`（子类的实现里 `[super tag]` 又拼上父类的结果），
`[ss viaSuper]` 和手工构造 `objc_super` 的 `objc_msgSendSuper` 都给 `基类的 tag`。
结论是那句常被说错的话：**`super` 不是对象，没有「super 这个接收者」存在**。
它是一个编译期记号，意思只有「查方法表时从父类那层开始」，收消息的还是 `self`。
这也解释了 §13 的一个现象：KVO 换了 isa 之后 `[super setFoo:]` 仍然能绕过 KVO 的子类。

顺带本节还量了一件很实用也很容易记错的事：**问一个不存在的选标要不到 IMP = NULL**。
`class_getMethodImplementation` 返回的是 runtime 的内部桩（非 NULL），
所以「拿到 IMP」不能当作「方法存在」的证据，能用的证据只有 `respondsToSelector:`（§14）。

## 4) self 与 _cmd：每个方法都偷偷多收两个参数

任何 ObjC 方法，编译器都往它前面塞两个参数：`self` 和 `_cmd`。
上一节的函数指针类型已经这么写了，本节直接看它有什么用。
构造办法是让两个方法的**实现文字完全一样**，只有 `_cmd` 会不同：

```objc
@implementation RTAlias
- (NSString *)whichOneA { return [@"同一个实现看到 _cmd=" stringByAppendingString:NSStringFromSelector(_cmd)]; }
- (NSString *)whichOneB { return [@"同一个实现看到 _cmd=" stringByAppendingString:NSStringFromSelector(_cmd)]; }
@end
```

```
== §4 self 与 _cmd 两个隐藏参数 ==
两个方法的实现文字一模一样，但 _cmd 不同：[a whichOneA]=同一个实现看到 _cmd=whichOneA；[a whichOneB]=同一个实现看到 _cmd=whichOneB
两个不同的 IMP（编译器不会替你去重）=1
把 A 的 IMP 装到 B 上之后，两者共用一份实现；靠 _cmd 仍然分得清：[a whichOneB]=同一个实现看到 _cmd=whichOneB
这就是「一份实现 + 多个选标」的做法，系统的 initWithCoder:/copyWithZone: 之类都靠 self/_cmd 拿到上下文
```

三件事：这两个字面相同的实现**编译出两个不同的 IMP**（clang 不做这种去重）；
用 `method_setImplementation` 把 A 的实现装到 B 上之后，两个选标共用一份代码，
而输出仍然分得清——因为实现自己看得见 `_cmd`；这就是「一份实现服务多个选标」的机制。

系统里到处在用这个套路：`-initWithCoder:` 里必须知道自己是哪个类（`self`）、
`-copyWithZone:` 里要知道被问的是哪个协议方法（`_cmd`）、
KVO 自动生成的子类（§13）用同一个 setter 实现处理多个键（靠 `_cmd` 分辨），
以及 §9 的 swizzle：**交换之后名字和实现对不上号，全靠 `_cmd` 才不迷路**。
写 Hook 的时候这一点是救命的：补丁方法里想知道「原本被叫的是哪个选标」，只能读 `_cmd`。

## 5) @encode 与方法类型编码：带字节偏移的签名

ARC 之后你几乎不会手写编码串，但**读**它的机会很多：
`method_getTypeEncoding`、`property_getAttributes`、`ivar_getTypeEncoding`、
`NSMethodSignature`、以及 §8 转发里必须给的 `methodSignatureForSelector:`。
本章把 `@encode(...)` 一次打全：

```objc
[RTL add:[NSString stringWithFormat:@"ObjC 专有：id=%s Class=%s SEL=%s 对象指针=%s block=%s",
          @encode(id), @encode(Class), @encode(SEL), @encode(RTGreeter *), @encode(void (^)(int))]];
[RTL add:[NSString stringWithFormat:@"    block 的编码 %s 与 C 函数指针的编码 %s 不是一回事：block 是 ObjC 对象，函数指针不是",
          @encode(void (^)(int)), @encode(int (*)(void))]];
```

```
== §5 @encode 与方法类型编码 ==
整型：char=c short=s int=i long=q long long=q
无符号：uchar=C ushort=S uint=I ulong=Q ullong=Q
浮点与布尔：float=f double=d long double=D _Bool=B BOOL=B C++ bool=B void=v
整数宽度：NSInteger=q NSUInteger=Q CGFloat=d unichar=S ptrdiff_t=q size_t=Q
指针与字符数组：void*=^v char*=* const char*=r* 函数指针=^?
ObjC 专有：id=@ Class=# SEL=: 对象指针=@ block=@?
    block 的编码 @? 与 C 函数指针的编码 ^? 不是一回事：block 是 ObjC 对象，函数指针不是
CoreFoundation 桥：CFStringRef=^{__CFString=}（不透明结构体指针）NSNumber=@ NSDate=@
结构体：CGRect={CGRect={CGPoint=dd}{CGSize=dd}}
          CGPoint={CGPoint=dd}  CGSize={CGSize=dd}
          NSRange={_NSRange=QQ}  CGVector={CGVector=dd}  CGAffineTransform={CGAffineTransform=dddddd}
自定义结构体：RTPair(2 个 float)={RTPair=ff}  RTQuad(4 个 double)={RTQuad=dddd}
数组与枚举：int[4]=[4i]  double[2]=[2d]  enum NSComparisonResult=q
sizeof：char=1 short=2 int=4 long=8 long long=8 指针=8 float=4 double=8 long double=16 BOOL=1
long double 在本机是 16 字节，而 @encode 给的字母仍是 'D'；CGFloat(8)=double，NSInteger(8)=long
方法类型编码里带**字节偏移**：number -> i16@0:8
                        greet: -> @24@0:8@16
拆解：'i16@0:8' = 返回 int；16 是帧上参数总大小；'@0' self 在第 0 字节；':'8 _cmd 在第 8 字节；'i16' 第一个显式参数在第 16 字节
结构体返回值直接写在最前面：rectValue -> {CGRect={CGPoint=dd}{CGSize=dd}}16@0:8
                        pairValue -> {RTPair=ff}16@0:8
NSMethodSignature 把同一份编码拆成可用零件：greet: 返回类型=@ 参数个数=3（含 self、_cmd）
    逐个参数类型：[0]=@ [1]=: [2]=@ 
声明了却没实现的方法问签名（neverImplemented）-> nil（签名来自方法表，不来自声明）
    签名拿不到 => 完整转发也建立不起 NSInvocation => 直接 doesNotRecognizeSelector:，这是 §8 最后一级台阶的成因
```

先记住「字母表」的规律，比背表有用：

- 小写字母是**有符号/浮点**（`c s i q f d D`），大写是**无符号**（`C S I Q`），
  所以 `long` 和 `long long` 都是 `q`（8 字节有符号），`int` 是 `i`。
- `@` 是对象、`#` 是类、`:` 是选标、`^X` 是指向 X 的指针、`*` 是 C 字符串、`r` 前缀是 const。
- 结构体是 `{名字=字段字母}`，可以嵌套；`NSRange` 的名字是 **`_NSRange`**（内部那层带下划线）。
- **`BOOL`、`_Bool`、C++ `bool` 全是 `B`**，而 `unichar` 是 `S`（它就是 `unsigned short`）。
- `NSInteger`=`q`、`NSUInteger`=`Q`、`CGFloat`=`d`——这三个是把 §2 那张「宽度」问题一次性回答：
  在这个架构上它们就是 `long`/`unsigned long`/`double`。

再看方法编码里那串数字，这是很多人第一次看到会以为是版本号的：

```
方法类型编码里带**字节偏移**：number -> i16@0:8
                        greet: -> @24@0:8@16
```

`i` 是返回类型，`16` 是参数帧总大小，之后每个参数是「类型 + 它在帧上的字节偏移」：
`@0` 是 `self` 在第 0 字节、`:8` 是 `_cmd` 在第 8 字节、`@16` 是第一个显式参数在第 16 字节。
**前两个偏移永远是 `@0` 和 `:8`**——`self` 与 `_cmd` 就是从这里被塞进去的，
上一节的隐藏参数在这一节有了字节级的证据。偏移量还能验算：`greet:` 的 `@16` 之后总大小 `24`，
正好 16+8；`setProtoProp:` 是 `v24@0:8@16`（§11 里出现）。
结构体返回值则直接写在最前面，`rectValue -> {CGRect={CGPoint=dd}{CGSize=dd}}16@0:8`。

`NSMethodSignature` 是同一份编码的「面向对象版」，也是 §8 慢速转发必须造出来的东西。
最后一组是本节最有实际价值的一条：**签名来自方法表，不来自声明**。
`neverImplemented` 在 `@interface` 里声明了、从没有实现，
`instanceMethodSignatureForSelector:` 给它 `nil`。这条性质直接决定了
「一个 unrecognized selector 是走完整转发还是当场 abort」——
第三级转发要你先给签名，可如果类里连声明都没有，签名无从建立，
于是 runtime 不再往下问，直接 `doesNotRecognizeSelector:`。§8 的最后一级台阶就是它。

## 6) @property 在 runtime 里是三样东西，不是一样

`@property (nonatomic, copy) NSString *strCopy;` 这一行在源码里是一个声明，
在 runtime 里却是**三条独立记录**：一对访存方法、一个 ivar、一条属性记录（带编码串）。
把这一节读完，「属性」这个词在 ObjC 里就再也不是一个黑盒了。
示例里的 `RTProps` 刻意写了 19 个属性，把能踩到的修饰符一次铺满：

```objc
@interface RTProps : NSObject {
    int _manualBacking;
}
@property (nonatomic, assign) int plain;
@property (nonatomic, assign) int manual;
@property (nonatomic, strong) NSString *strStrong;
@property (nonatomic, copy) NSString *strCopy;
@property (nonatomic, weak) RTProps *weakRef;
@property (nonatomic, readonly) int roValue;
@property (nonatomic, getter=customGet) int customGetter;
@property (nonatomic, setter=mySet:) int customSetter;
@property (nonatomic) CGRect rect;
@property (nonatomic) void (^blockProp)(int);
@property (nonatomic) Class classProp;
@property (nonatomic) id anything;
@property (nonatomic) NSObject *typedObj;
@property (nonatomic) NSArray<NSString *> *genericArr;
@property (nonatomic) BOOL boolProp;
@property (nonatomic) const char *cString;
@property (nonatomic) long double longDoubleProp;
@property (nonatomic) NSInteger integerProp;
@end
@implementation RTProps
@synthesize manual = _manualBacking;   // 显式绑到已存在的 ivar，不再自动生成 _manual
@end
```

`class_copyPropertyList` 把 19 个属性连编码串一次打全：

```
== §6 属性在 runtime 里的三件套 ==
class_copyPropertyList(RTProps) 报出 19 个属性 —— 只算本类，不含继承自 NSObject 的
    assocViaCategory => T@"NSString",&,N
    plain => Ti,N,V_plain
    manual => Ti,N,V_manualBacking
    strStrong => T@"NSString",&,N,V_strStrong
    strCopy => T@"NSString",C,N,V_strCopy
    weakRef => T@"RTProps",W,N,V_weakRef
    roValue => Ti,R,N,V_roValue
    customGetter => Ti,N,GcustomGet,V_customGetter
    customSetter => Ti,N,SmySet:,V_customSetter
    rect => T{CGRect={CGPoint=dd}{CGSize=dd}},N,V_rect
    blockProp => T@?,C,N,V_blockProp
    classProp => T#,&,N,V_classProp
    anything => T@,&,N,V_anything
    typedObj => T@"NSObject",&,N,V_typedObj
    genericArr => T@"NSArray",&,N,V_genericArr
    boolProp => TB,N,V_boolProp
    cString => Tr*,N,V_cString
    longDoubleProp => TD,N,V_longDoubleProp
    integerProp => Tq,N,V_integerProp
对照组：只写了实例方法的 RTBaseThing 属性数=0（所以 0 个属性是「没写 @property」的正常表现）
把编码串拆成结构化零件（property_copyAttributeList）：plain -> {T,i} {N,} {V,_plain} 
单个字母的含义（实测编码串里出现过的）：'&'=strong 'C'=copy 'W'=weak 'N'=nonatomic 'R'=readonly 'G='自定义 getter 'S='自定义 setter 'V'=背后的 ivar 名
    weakRef=T@"RTProps",W,N,V_weakRef  strCopy=T@"NSString",C,N,V_strCopy
    roValue=Ti,R,N,V_roValue（没有 S，因为只读）
    blockProp=T@?,C,N,V_blockProp —— block 属性被自动加上 'C'（copy），这是 ARC 时代 block 语义的默认值
    只读属性的 getter 也在方法表里：instanceMethodSignatureForSelector(roValue) 参数数=2，而 setRoValue: 问不到=nil
一个 @property 实际生成的方法（挑出来的，已按字典序排好）： customGet plain roValue（RTProps 实例方法总数=39）
自动合成的 ivar：_plain 存在=1；@synthesize 显式绑到 _manualBacking 的那条也在 ivar 表里（见 §7）
strong / copy 的差别只有在「装进去的对象后来被改了」才看得见：
    源对象改成 原始内容，后来被改了 之后：strong 读到=原始内容，后来被改了（同一个对象，跟着变）；copy 读到=原始内容（当时拷了一份，不变）
    两者的实际类别：strong 那份=__NSCFString  copy 那份=__NSCFString
    池内：weakRef 指得到=是  宿主被 weak 看到=1
池一结束：宿主对象消失（weak 看到 nil），它身上的 weak 属性也随之变成 nil；strong 属性则把内容一起拖到释放
```

读法（这条串就是 §5 那张字母表加上属性专属的前缀）：

- 第一个字段 `T` 后面紧跟的是**类型的 @encode**：`Ti` 是 `int`，`Tq` 是 `NSInteger`，
  `TB` 是 `BOOL`，`TD` 是 `long double`，`Tr*` 是 `const char *`，`T@?` 是 block，
  `T#` 是 `Class`，`T@"NSString"` 是「对象，且声明类型是 NSString」，
  `T{CGRect=…}` 把整个结构体编码塞了进来（`rect` 那条）。
- 中间单个字母是修饰符：`&`=strong、`C`=copy、`W`=weak、`N`=nonatomic、`R`=readonly。
- `G`/`S` 只在改名时出现：`getter=customGet` 给 `GcustomGet`，`setter=mySet:` 给 `SmySet:`。
- `V` 后面是**背后 ivar 的名字**：`V_plain`。`manual` 那条是 `V_manualBacking`，
  因为 `@synthesize manual = _manualBacking;` 把它绑到了手写的那个 ivar 上。
- `assocViaCategory`（分类里声明的属性，§7 用关联对象实现）只有 `T`、`&`、`N`，**没有 `V`**——
  它没有 ivar。这一个字母的缺失就是「分类加不了 ivar」的直接证据。

三条只有实测才讲得清楚的：

1. **`blockProp` 被自动加了 `C`**。今天写 `@property (nonatomic) void (^blockProp)(int);`
   不写 `copy`，属性串里照样是 `T@?,C,N,V_blockProp`：ARC 时代 block 的默认语义就是拷贝。
   这一条解释了为什么「strong 一个 block」在现代 ObjC 里不再泄漏——但它也意味着
   「strong/copy 在 block 上等价」，而不是「copy 可以省」。
2. **只读属性也有 ivar、也有 getter，但没有 setter**。`setRoValue:` 问签名问不到（`nil`），
   而 `roValue` 的签名参数数是 2（`self` + `_cmd`）。所以 KVC 给只读属性赋值会去找 ivar（§12 的候选顺序）。
3. **`strong` 与 `copy` 的差别只能靠「之后改源对象」看出来**，而且两者的实际类**都是 `__NSCFString`**——
   打类名分不出它们，因为拷出来的那份也是同一个不可变类。这是本章最容易被写错的一条：
   「`copy` 属性读出来是另一种类型」是想当然；差别在**内容跟着不跟着变**：

```objc
NSMutableString *src = [@"原始内容" mutableCopy];
q.strStrong = src;
q.strCopy = src;
[src appendString:@"，后来被改了"];
// strong 读到 原始内容，后来被改了（同一个对象）；copy 读到 原始内容（当时拷了一份）
```

`NSString *` 参数用 `copy`、`NSMutableString *` 属性用 `strong`，这条老规矩的理由就在这里：
`strong` 一个可变字符串等于把「别人还能改你的属性」写进契约里。

## 7) ivar 反射：偏移量、按字节直写，以及关联对象的真实形状

属性表只回答「有没有声明属性」，ivar 表回答「这个对象到底占多少内存、每个字段在第几字节」。
`class_copyIvarList` 把 `RTProps` 的 18 个 ivar 连类型编码和**偏移**一起打出来：

```
== §7 ivar 反射与关联对象 ==
class_copyIvarList(RTProps)=18 个 ivar；@property 只是造 ivar 的最常见方式，不是唯一方式
    _manualBacking  类型编码=i  偏移=8
    _boolProp  类型编码=B  偏移=12
    _plain  类型编码=i  偏移=16
    _roValue  类型编码=i  偏移=20
    _customGetter  类型编码=i  偏移=24
    _customSetter  类型编码=i  偏移=28
    _strStrong  类型编码=@"NSString"  偏移=32
    _strCopy  类型编码=@"NSString"  偏移=40
    _weakRef  类型编码=@"RTProps"  偏移=48
    _blockProp  类型编码=@?  偏移=56
    _classProp  类型编码=#  偏移=64
    _anything  类型编码=@  偏移=72
    _typedObj  类型编码=@"NSObject"  偏移=80
    _genericArr  类型编码=@"NSArray"  偏移=88
    _cString  类型编码=r*  偏移=96
    _integerProp  类型编码=q  偏移=104
    _longDoubleProp  类型编码=D  偏移=112
    _rect  类型编码={CGRect="origin"{CGPoint="x"d"y"d}"size"{CGSize="width"d"height"d}}  偏移=128
探针记录：object_getIvar 去读一个 int 型 ivar 会当场 SIGSEGV —— 它把 4321 这个整数当对象指针解引用并 retain。这对函数只能用于对象类型的 ivar（本章不执行）。
读标量 ivar 要用 C 的方式：char* 基址 + ivar_getOffset(16) 强转 int* -> 4321；写回一个 999 之后属性读到 999
对象型 ivar（_strStrong）object_getIvar -> 用 object_setIvar 放进去的；偏移=32
问一个不存在的 ivar：class_getInstanceVariable -> NULL（返回 NULL，不抛异常）
元类的 ivar 表是空的（0 个）——「类变量」在 ObjC 里没有对应物，只能用 static 全局模拟；实例大小 RTProps=160，NSObject 本身占 8（一个 isa 指针）
分类不能加 ivar（探针诊断原文：error: instance variables may not be placed in categories），关联对象是官方替代：
    用分类属性 assocViaCategory 写一次 -> 读回=(null)
    再读=存进关联表；另一个实例读同一个 key=(null)（关联表按「宿主对象 + key」两维存）
    policy 原始值：ASSIGN=0 COPY=771 RETAIN=769 COPY_NONATOMIC=3 RETAIN_NONATOMIC=1
    设成 nil 等价于移除：remove 之后=(null)
    关联对象的生命周期完全跟着宿主：宿主 dealloc 时它的整张关联表被 objc_removeAssociatedObjects 清掉（探针：拿一个 weak 指针跟宿主，宿主释放后 weak 变 nil，同时另一个仍活着的实例读同一个 key 得到 nil —— 值不会串到别的对象上，也不会比宿主活得久）
```

这张偏移表自己就会说话，值得逐条读：

- **偏移 8 起**：0～7 是 `isa`（`NSObject` 本身占 8 字节，最后一行直接给了这个数）。
- **`int` 是 4 字节、指针对齐**：`_manualBacking@8`、`_boolProp@12`（BOOL 只占 1 字节，
  但下一个 `int` 要落在 4 的倍数上，所以 `_plain@16`）——12 到 16 之间那 3 字节是填充。
- **所有对象型 ivar 都是 8 字节步长**：`@32 @40 @48 @56 @64 @72 @80 @88`。
  `_weakRef@48` 和 `_strStrong@32` 占的一样大：**weak 不是「更小的指针」，它只是多了一张注册表**。
- **`_rect` 跳到 128**，而 `_longDoubleProp@112`：`long double` 在这台机器上占 16 字节
  （§5 的 `sizeof` 那行已经量到 16），112+16=128，正好接上；`CGRect` 本身 32 字节，
  128+32=160，和最后一行的 `实例大小 RTProps=160` 对得上。**偏移表 + sizeof 表 = 完整的内存布局**。
- **`_rect` 的编码带了字段名**（`{CGRect="origin"{CGPoint="x"d"y"d}…}`），
  而 §5 的 `@encode(CGRect)` 给的是不带名字的 `{CGRect={CGPoint=dd}{CGSize=dd}}`。
  同一种类型两种写法：带引号名字的来自 Objective-C 声明里的 struct 定义，是「更完整的那份」。

**`ivar_getOffset` + 指针算术 = 绕开一切访问器直接读写内存。**
这一句在本章是双刃剑，所以两半都写出来：

```objc
Ivar plain = class_getInstanceVariable([RTProps class], "_plain");
int *slot = (int *)((char *)(__bridge void *)p + ivar_getOffset(plain));
*slot = 999;     // 属性读到 999
```

`(char *)` 这个转换必须有——`void *` 不许做算术，而 `__bridge` 是 ARC 下把 `id` 变成裸指针的唯一合法通道。
它的用处是**读**（KVO 调试、理解布局、§13 解释「为什么直写 ivar 不发通知」），
**写**只在本章这种自产自销的对象上安全：真实对象里 `*slot = 999` 会绕过 `weak` 的注册、
绕过 `copy` 语义、绕过 KVO、绕过 `didSet`，而且一旦写的是对象型 ivar 就直接破坏引用计数。
同一段里那条「探针记录」就是这个禁令的证据：`object_getIvar` 去读一个 `int` ivar 会 SIGSEGV，
因为它把 `4321` 当成对象指针去解引用并 `retain`。这对函数只认对象类型的 ivar。

后半段是关联对象——分类加 ivar 的官方替代品。四条实测性质，前两条最容易被误用：

- **`policy` 的原始值不是 0/1/2/3 那种整齐的数**：`ASSIGN=0 RETAIN_NONATOMIC=1 COPY_NONATOMIC=3
  RETAIN=769 COPY=771`。规律在八进制里：原子那两条是「非原子的值 + `01400`（十进制 768）」，
  所以 `769 = 01401`、`771 = 01403`。也就是说这个 enum 不是序号而是**位域**，
  只能整个传进去，别自己按位拼——而且它压根不是 `strong/copy/weak` 的三档，
  **没有 weak 这一档**：关联对象不能是 weak，想弱引用只能自己包一个 `NSHashTable`/`__weak` 容器。
  这一行存在的意义是：见到 `771` 不要以为是 enum 写错了。
- **存储维度是「宿主对象 + key 指针」两维**：换一个实例读同一个 key 得到 `(null)`。
  所以 key 必须用 `static const void *kRTKeyA = &kRTKeyA;` 这种「取自己的地址」的写法，
  字符串字面量当 key 是不行的（同名字面量会被合并，不同模块的同类名会撞）。
- **设成 nil 等于移除**，`objc_setAssociatedObject(host, key, nil, policy)` 与
  `objc_removeAssociatedObjects(host)` 是这条性质的两种写法。
- **生命周期完全跟着宿主**：宿主 dealloc 时整张关联表被清掉，值不会串到别的对象上，
  也不会比宿主活得久。这条在 §9 的 Hook 里是保命的：给 `UITableViewCell` 关联一个 delegate，
  cell 释放它就释放，不需要摘。

`ASSIGN` 那一档（原始值 0）是唯一**不持有**的策略，
`OBJC_ASSOCIATION_ASSIGN` 挂一个对象上去就是悬垂指针——本章只打它的数值，从不这样用。

## 8) 消息转发的四级台阶：一次调用问四次

一个对象收到自己方法表里没有的消息，不会立刻崩。runtime 会**按固定顺序给它四级补救机会**，
全用完才 `doesNotRecognizeSelector:`。本章把四级分开搭，每级一个类，
并用一根 `gTrace` 日志板把「哪一级被问了、按什么顺序」记下来：

```objc
static NSMutableArray *gTrace;   // 当前小节的日志板
static NSString *RTJoin(NSArray<NSString *> *log) { return [log componentsJoinedByString:@" | "]; }

@interface RTResolver : NSObject
@end
@implementation RTResolver
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    RTLog(gTrace, [NSString stringWithFormat:@"①resolve(%@)", NSStringFromSelector(sel)]);
    if (sel == @selector(magicGreet)) {
        IMP imp = imp_implementationWithBlock(^NSString *(id self) {
            RTLog(gTrace, @"block 版实现被调到");
            return @"这是运行时才造出来的方法";
        });
        // 类型编码要和 block 的真实形状一致；写错了编译器不管，脏数据到下一次真访问才炸
        BOOL ok = class_addMethod(self, sel, imp, "@@:");
        RTLog(gTrace, [NSString stringWithFormat:@"class_addMethod=%d", ok]);
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}
@end
```

```
== §8 消息转发的四级台阶 ==
第 1 级 resolveInstanceMethod:：类里从没声明过 magicGreet，先问一次 respondsToSelector -> 1，可日志已经长了 2 条（①resolve(magicGreet) | class_addMethod=1）—— 这一问不是被动查询：runtime 先给类一次「你要不要现在补方法」的机会，补上了就回答 1
    紧接着第一次调用 -> 这是运行时才造出来的方法；日志=①resolve(magicGreet) | class_addMethod=1 | block 版实现被调到
    第二次调用 -> 这是运行时才造出来的方法；整份日志里 ①resolve 只出现过 1 次 —— 方法进了缓存，解析只跑一次，被重复的只有实现本身（①resolve(magicGreet) | class_addMethod=1 | block 版实现被调到 | block 版实现被调到）
    解析成功后再问 respondsToSelector -> 1（runtime 把新加的方法当真的）
第 2 级 forwardingTargetForSelector:：替身接住 -> 替身对象接住了；顺序=②forwardingTarget(askName) | 替身的 askName 被调；原对象自己 respondsToSelector(askName)=0（快转发不会让它「声称会」）
第 3 级 methodSignature + forwardInvocation:：连方法名都不存在 -> 慢速转发造出来的返回值；顺序=③a 签名(anythingAtAll) | ③b 转发(anythingAtAll) 原返回类型=@ 参数数=2
把前两级主动放弃、只留第三级：-> 前两级都不肯让，最后一级谈成了；完整顺序=链:①resolve 故意返回 NO | 链:②forwardingTarget 返回 nil | 链:③a 只好给签名 | 链:①resolve 故意返回 NO | 链:③b forwardInvocation 自己处理
同一个选标、换一个实例再问一次：-> 前两级都不肯让，最后一级谈成了；日志又走满 5 条（转发没有跨实例的缓存，每级都要重问）
探针记录（只能记，不能跑）：
    ① 四级全放弃时 doesNotRecognizeSelector: 抛 NSInvalidArgumentException，stderr 是 “*** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason: '-[T noSuchMethodAtAll]: unrecognized selector sent to instance 0x…'”，随后 SIGABRT；
    ② 这个异常能被普通的 @try/@catch(NSException*) 接住（§17 同一套机制），所以“线上偶尔能看到 unrecognized selector 被 catch”不是幻觉；
    ③ 第 1 级里 class_addMethod 的编码写成 @"@" 而 block 实际返回 NSString：编译无警告，调用方按 id 取值当场就是脏指针，retain 时 SIGSEGV —— 编码串是唯一没人检查的部分。
```

四级的分工与代价，一张表：

| 级别 | 钩子 | 能做什么 | 代价 |
| --- | --- | --- | --- |
| 1 | `+resolveInstanceMethod:` / `+resolveClassMethod:` | **现在补一个方法**（`class_addMethod`） | 只能给出 IMP + 编码串；编码写错没人查 |
| 2 | `-forwardingTargetForSelector:` | **换个对象来接**（返回替身） | 参数、返回值都得兼容；快，不用造 `NSInvocation` |
| 3 | `-methodSignatureForSelector:` + `-forwardInvocation:` | **改参数、改返回值、转发给任意多个对象** | 慢，要建签名和 `NSInvocation` |
| 4 | `-doesNotRecognizeSelector:` | 抛异常，进程结束 | 前三级全放弃才走到这里 |

本节输出里有四条只有跑过才知道的：

1. **`respondsToSelector:` 不是被动查询**。示例一上来只做了一次
   `[r respondsToSelector:@selector(magicGreet)]`，`magicGreet` 在这个类里**从没声明过**，
   可日志已经长出 2 条（`①resolve(magicGreet) | class_addMethod=1`），而且回答是 `1`。
   因为这一问同样会走第 1 级：runtime 先问类「你要不要现在补方法」，补上了就答 `YES`。
   这条性质的用处是让 `respondsToSelector:` 变成**主动**的（很多框架就是这么实现「按需装方法」的），
   坑是你写一个 `if ([obj respondsToSelector:x])` 时，可能顺手触发了别人的 `+resolveInstanceMethod:`。
2. **解析只跑一次，实现会被重复调用**。第二次调用同一选标时 `①resolve` 只出现过 1 次
   （示例专门数了一遍），而 `block 版实现被调到` 出现了 2 次——补上的方法进了 runtime 的方法缓存，
   之后就是普通调用。
3. **快转发不会让原对象「声称会」**：`RTFastForwarder` 把消息交给替身之后，
   它自己 `respondsToSelector:@selector(askName)` 仍然是 `0`。
   所以「`respondsToSelector:` 为 NO 但消息能接住」是**合法状态**，别拿它当 bug 判据。
4. **转发没有跨实例的缓存**。示例最后连续对**两个不同的 `RTChain` 实例**发同一个选标
   `nobodyHasThis`，第二次的日志又走满 5 条。第 2 点说的是「同一实例 + 同一选标」的方法缓存，
   这条说的是「每级钩子都要重问」——两件不同的事，很容易记成一件。

还有一条藏在 `RTChain` 的输出顺序里，值得单独指出来：

```
链:①resolve 故意返回 NO | 链:②forwardingTarget 返回 nil | 链:③a 只好给签名 | 链:①resolve 故意返回 NO | 链:③b forwardInvocation 自己处理
```

`③a`（要签名）**出现了两次 `①resolve`**，而且第二次在 `③b` 之前。
也就是说 `methodSignatureForSelector:` 之后 runtime 又回去问了一遍 `+resolveInstanceMethod:`：
签名建立起来之后它再给类一次补方法的机会（补上了就不用慢转发）。
这条顺序不是文档里的表格能看出来的，只有把 `gTrace` 打全才看得见。
上一节末尾那条伏笔在这里也接上了：**声明了却没实现的方法给不出签名**（§5 的 `neverImplemented`），
第 3 级建不起 `NSInvocation`，于是直接落到第 4 级 abort。

第 3 级唯一要做对的一件事是 `setReturnValue:`：

```objc
- (void)forwardInvocation:(NSInvocation *)invocation {
    NSString *result = @"慢速转发造出来的返回值";
    NSString *hold = result;                 // setReturnValue 要一个能活到调用方取值的地址
    [invocation setReturnValue:(void *)&hold];
}
```

传的是**「返回值的地址的地址」**（`&hold`，`hold` 是一个局部 `NSString *`），
而且 `hold` 必须活得比这一次调用久。写 `char buf[]`、写一个临时 `id` 都要注意作用域。
`invocation.methodSignature` 里还能读出「原返回类型=@、参数数=2」——这是慢转发唯一能改返回值的地方。

探针那三条留了本节最重要的两个禁令：
**编码串没有任何人检查**（第 1 级 `class_addMethod` 写 `@encode` 写错了不报错，调用方按 `id` 取值就是脏指针）；
**四级全放弃的崩溃是 `NSInvalidArgumentException` + SIGABRT**，但它**可以被 `@try` 接住**（§17 同一套机制），
所以「线上偶尔看到 unrecognized selector 被 catch 掉」不是幻觉，而是同一件事的另一面。

## 9) 换实现的两条路：交换 IMP 与直接替换

这是所有「打补丁 / Hook / 埋点 / 热修」的底层机制，两个 API：

```objc
method_exchangeImplementations(mDo, mLabel);   // ① 交换两个方法记录的实现
IMP old = method_getImplementation(labelNow);  // ② 只替换，旧 IMP 自己存下来
method_setImplementation(labelNow, (IMP)RTLabelHook);
```

本节的写法很讲究：**先量，后动，最后确认没留脏状态**——
换过一次就再换回来，钩子装完就用存下来的 `originalLabel` 还原，
末了再比一次 `doWork` 的 IMP 是不是最初那个。这样后面的小节不会读到本节留下的补丁。

```
== §9 换实现：交换 IMP 与直接替换 ==
动手前：doWork 编码=v16@0:8（首字母 v=返回 void，16=帧大小，@0 self 在第 0 字节、:8 _cmd 在第 8 字节）label 编码=@16@0:8（首字母 @=返回对象）
    两个实现是两个不同的指针（只能比相等，不能打印值）：不相等=1
① 交换前调 doWork：日志=doWork 本体
    method_exchangeImplementations 之后调 doWork：日志=（空 —— 实际跑到了 label 的实现里）
    编码挂在方法记录上、实现挂在 IMP 上：交换之后 doWork 的编码仍是 v16@0:8，label 仍是 @16@0:8（换的只是实现指针，名字/签名/调用约定都不动）
    所以「拿 void 方法的返回值当对象用」这一步本章不敢跑：探针里那次它拿到的寄存器残留恰好还是个能 retain 的活对象，连 hash 都跑通了（见 §9 末的探针记录）—— 不每次都崩才是最坏的情况。
    再交换一次就还原：调 doWork 的日志=doWork 本体
② method_setImplementation（只换不交换）：调 label -> 「label 本体+钩子」，日志=钩子:前 | 钩子:后
    钩子里必须把旧 IMP 存下来直接调。探针记录：如果钩子里改写成了 [self label]，那就是自己调自己 —— 无限递归直到 SIGSEGV（栈溢出），而不是「先跑一遍原实现」。
    钩子是**类级别**的：换实现之后再调 doWork 不产生任何钩子日志（条数=2），但换一个新建的实例调 label 也一样被钩
    新实例的 label -> 「label 本体+钩子」（确认：老IMP 返回的字符串 + 钩子后缀）
    用存下来的 originalLabel 还原：label -> 「label 本体」，钩子日志条数=0
    最后确认 doWork 的 IMP 也还是原封不动的那个（相等=1）—— 本节没留下任何改动给后面的小节
探针记录（交换签名不一致的那次调用，只能单独跑）：
    把 doWork/label 交换之后，用 __unsafe_unretained 接 [t label] 的返回值，再交给 ARC 并调 hash：
    after swap: doWork enc=v16@0:8 label enc=@16@0:8
    unsafe_unretained 接到 void 实现的返回值：isNil=0
    交给 ARC 之后还活着：140704254635504
    —— 那次没崩，是因为寄存器里残留的正是一个还活着的对象；换一个时机它就是野指针，retain 时 SIGSEGV。结论：交换只用在同签名方法之间（打补丁的惯用法就是「同名同签名的一进一出」），别拿它换返回类型。
```

五条必须记住的：

- **编码挂在方法记录上，实现挂在 IMP 上**。交换之后 `doWork` 的类型编码**仍是** `v16@0:8`，
  `label` 仍是 `@16@0:8`——换的只是那个函数指针。这就是为什么交换签名不同的方法是灾难：
  调用方按 `doWork` 的编码（返回 void）去取 `label` 的实现（返回对象）留下的东西。
- **交换两次等于没交换**，这是 `method_exchangeImplementations` 的惯用法：
  补丁方法里 `[self newDoWork]` 实际调的是原实现（因为名字和实现对调了）。
  这个「靠 `_cmd` 绕回原实现」的技巧只有交换版能用，`setImplementation` 版必须自己存旧 IMP。
- **钩子里绝对不能写成 `[self label]`**。那是自己调自己——无限递归直到栈溢出 SIGSEGV（探针记录）。
  正确写法是把旧 IMP 存进全局，然后 `((NSString *(*)(id, SEL))gOldLabelIMP)(self, _cmd)`：

```objc
static IMP gOldLabelIMP = NULL;
static NSString *RTLabelHook(id self, SEL _cmd) {
    RTLog(gTrace, @"钩子:前");
    NSString *(*orig)(id, SEL) = (NSString *(*)(id, SEL))gOldLabelIMP;
    NSString *r = orig(self, _cmd);
    RTLog(gTrace, @"钩子:后");
    return [r stringByAppendingString:@"+钩子"];
}
```

- **换实现是类级别的，不是实例级别的**。装上钩子之后，**换一个新建的实例**调 `label` 照样被钩
  （`新实例的 label -> 「label 本体+钩子」`）。这条直接决定了影响面：一次 swizzle 影响整个进程
  里这个类的**所有**对象，包括 UIKit 内部正在用的那些。这也是为什么线上补丁要么只加不改、
  要么用 `+load` 保证只装一次（§10）。
- **`doWork`（返回 void）的返回值不能当对象用**，本节把这一条留在了探针里而不是示例里：
  探针那次拿到的是寄存器残留，恰好还是一个活对象，`hash` 都跑通了——
  **不每次都崩才是最坏的情况**。结论是那句老规矩：交换只用在同签名方法之间。

## 10) 分类：方法会合并，ivar 加不了，+load 抢在 main 之前

分类（category）是 ObjC 给已有类补方法的手段，也是 runtime 层面**没有独立存在**的东西——
它的方法被**合并进原类的方法表**：

```objc
@interface RTBaseThing (Extra)
- (NSString *)fromCategory;
@end
@implementation RTBaseThing (Extra)
- (NSString *)fromCategory { return @"分类补的方法"; }
@end
```

```
== §10 分类、+load 与 +initialize ==
分类给已有类补方法：[t fromCategory]=分类补的方法（t 的源码里从没写过这个方法）
分类方法是**合并进原类的方法表**的：class_copyMethodList(RTBaseThing)=fromCategory fromPrimary（分类与主实现不分家；顺序已排序，方法表本身的顺序不保证稳定）
分类给类加的是方法，不是 ivar：RTBaseThing 的 ivar 数=0（一个都没有）
探针记录：在分类里写 { int addedIvar; } 的编译诊断是 error: instance variables may not be placed in categories —— 所以才有 §7 的关联对象。
探针记录：分类里重写主类已有的方法，clang 给 warning: category is implementing a method which will also be implemented by its primary class，而运行期确实是分类的实现盖住主实现（链接顺序决定谁赢，别依赖）。
+load / +initialize 的时机（前两条发生在 main 之前，是 +record 记下来的）：
    +load RTLoadOrder1（父类自己）
    +load RTLoadOrder2（子类）
    +load RTLoadOrder1(Late) 分类
    alloc 子类实例之后，日志=5 条（父类 initialize 先于子类）
    再 alloc 一个父类实例，日志仍然是 6 条：父类的 +initialize 只在第一次收到消息时跑，不会重复
```

三组事实：

1. **分类与主实现不分家**：`class_copyMethodList(RTBaseThing)` 把 `fromCategory` 和 `fromPrimary`
   混在一起列出来，没有任何标记区分来源。所以「这个方法在不在」只能按选标问，
   而**两个分类实现同一个选标时，谁赢由链接顺序决定**——探针里 clang 给的是
   `warning: category is implementing a method which will also be implemented by its primary class`，
   而运行期确实分类那份盖住主实现。**别依赖这个顺序**，要区分就用不同的名字。
2. **分类不能加 ivar**：`RTBaseThing 的 ivar 数=0`。想给别人的类挂状态只能走 §7 的关联对象；
   编译诊断原文在探针记录里（`error: instance variables may not be placed in categories`）。
3. **`+load` 早于 `main`，顺序是：父类自己 → 子类 → 分类**。
   这三行日志是 `+load` 里 `[RTL record:]` 写进「永久记录板」的
   （普通黑板会被下一节的 `begin` 抹掉，这就是记录板存在的理由）。
   注意第三行：`RTLoadOrder1 (Late)` 是**父类的分类**，可它的 `+load` 排在**子类之后**——
   这一轮的顺序不是「父类 → 父类的分类 → 子类」，而是「所有类（父先子后）→ 所有分类」。
   所以「`+load` 里顺序可控」这句话最多只能说「父类先于子类」，分类的位置**不要依赖**。

`+initialize` 的部分（最后两行）是另一套时机：

- **第一次收到消息时才跑**，不是 `alloc` 之前；
- **父类先于子类**——示例里 `[RTLoadOrder2 new]` 之后日志从 3 条变成 5 条，
  多出的两条正是父类和子类的 `+initialize`；
- **只跑一次**：再 `alloc` 一个父类实例，日志仍是 6 条（后面那次 `[o2 ping]` 记了一条，
  所以从 5 到 6 是 `ping`，而父类的 `+initialize` 没有重复出现）；
- **一个坑**：`+initialize` 会被「第一次碰这个类的任何方法」触发，包括 `+load` 里
  或别的类的 `+initialize` 里间接调用，所以它**必须能重入**、且不要依赖 `self` 已就绪。
  这段代码里 `[o2 ping]` 调的是**继承来的实例方法**，问的却是 `RTLoadOrder2`
  ——这种「父类的 `+initialize` 因为子类的动作先跑了」正是 `+initialize` 里做注册会出问题的形状。

`+load` 的真实约束（本章只能记，不能跑，因为它会死锁）：它在 dyld 加载阶段执行，
**此时 Foundation 还没完全就绪**，里面只允许做「往 runtime 登记」这一类事
（`method_setImplementation`、`class_addMethod`、`objc_registerClassPair`），
不能调 UIKit、不能起线程、不能 `dispatch_sync` 到主队列。示例把 `+load` 里的动作压到只有一行 `[RTL record:]`。

## 11) 协议在 runtime 里是一份可读的方法清单

协议今天的主要作用是**给编译器和人看**（`@optional` / `@required`），但它在 runtime 里也真的存在：
一份 `Protocol`，带着自己的方法描述表。

```objc
@protocol RTBase1 <NSObject>
- (void)baseRequired;
@end
@protocol RTDerived1 <RTBase1>
@optional
- (void)derivedOptional;
@property (nonatomic, copy) NSString *protoProp;
+ (NSInteger)derivedClassMethod;
@end
@interface RTProtoUser : NSObject <RTDerived1>
@end
@implementation RTProtoUser
- (void)baseRequired {}
@end
```

```
== §11 协议的运行时视图 ==
@protocol(RTDerived1) 的名字=RTDerived1；它等于 NSProtocolFromString(@"RTDerived1") 吗=1
查一个不存在的协议名：NSProtocolFromString(@"没定义过的协议")=nil
protocol_isEqual(@protocol(RTDerived1), @protocol(RTBase1))=0（派生协议不等于父协议）
RTDerived1 继承了 1 个协议：RTBase1
协议里的实例方法（含 optional）3 个：
    derivedOptional  类型编码=v16@0:8
    protoProp  类型编码=@16@0:8
    setProtoProp:  类型编码=v24@0:8@16
    其中 @required 的实例方法 0 个：-
    协议里的类方法 1 个：derivedClassMethod
协议里的属性 1 个：protoProp （属性也会被拆成 getter/setter 两个方法描述，上面方法数里就能看到）
protocol_getMethodDescription 查单个可选方法：name=derivedOptional types=v16@0:8
    同一个方法但只问 optional 段（baseRequired 是 @required）：name=(nil) —— 按 required/optional 分开查会查空
采纳关系：[类 conformsToProtocol:RTDerived1]=1 父协议 RTBase1=1 NSObject=1 无关的 NSCopying=0
class_copyProtocolList(RTProtoUser)=1 个：RTDerived1（只列**直接**采纳的，父协议要靠 conformsToProtocol: 问）
只实现了必需的 baseRequired：respondsToSelector(baseRequired)=1 respondsToSelector(derivedOptional)=0（optional 没实现也不报错，调用前必须自己问）
非正式协议（只在 NSObject 分类里声明、从不实现）：[NSObject instancesRespondToSelector:informalNeverImplemented]=0；[NSString instancesRespondToSelector:]=0
    也就是说：光声明一个 NSObject 分类方法，所有对象都「编译得过、运行时不响应」—— 这就是历史上非正式协议的写法，今天用 @optional 正式协议替代
```

五个点：

- **`protocol_copyMethodDescriptionList(aProtocol, isRequired, isInstanceMethod, outCount)`**
  两个布尔位决定问哪一格：本例 `NO,YES`（实例方法，含 optional）给 3 个；`YES,YES`
  （@required 的实例方法）给 **0 个**——`baseRequired` 在**父协议**里，这一档查的是
  「本协议自己声明的 required」。这条 API 的语义分界很容易踩，示例把它明打在输出里。
- **协议里的属性也会被拆成方法**：`protoProp` 在方法清单里出现两条（`@16@0:8` 的 getter、
  `v24@0:8@16` 的 setter），和 §5 的编码规律完全一致（`set…:` 帧大小 24）。
  所以「协议里的 @property」在 runtime 层就是两个方法声明，没有 ivar 一说。
- **`protocol_getMethodDescription` 按 required/optional 分开查会查空**：
  拿 `baseRequired`（一个 @required 方法）去问 optional 段（`isRequired=NO`）给 `name=(nil)`。
  这一条的实际用法是：**判断「协议允不允许你不实现」，不是判断「你有没有实现」**——
  后者永远要靠 `respondsToSelector:`（下一行）。
- **`class_copyProtocolList` 只列直接采纳的**（1 个：`RTDerived1`），
  而 `conformsToProtocol:` 会把父协议链算进来（`RTBase1=1`、`NSObject=1`、无关的 `NSCopying=0`）。
  所以「这个类认不认这个协议」只能用 `conformsToProtocol:` 问，遍历列表问不到。
- **optional 没实现也不报错**：`RTProtoUser` 只实现 `baseRequired`，
  `respondsToSelector:@selector(derivedOptional)` 是 0，编译器一个字都不说。
  这一条决定了协议的正确用法：**调用前自己问**（§15 的 delegate 那段代码就是这么写的）。

最后两行是本教程要专门纠正的一处：书里第 7 章花了不少篇幅讲**非正式协议**
（在 `NSObject` 分类里声明一批方法，让所有对象「看起来都会有」）。
示例照做了一个：`@interface NSObject (RTInformal) - (NSString *)informalNeverImplemented; @end`，
然后问 `[NSObject instancesRespondToSelector:]` 和 `[NSString instancesRespondToSelector:]`——**都是 0**。
「声明了就等于所有对象都会有」从来没成立过，runtime 只认方法表。
今天的替代写法就是 `@optional` 正式协议 + 调用前 `respondsToSelector:`。

## 12) KVC：按名字猜的候选顺序，与只有 valueForKeyPath: 认的 @ 运算符

KVC（`valueForKey:` / `setValue:forKey:` / `valueForKeyPath:`）不是「反射的语法糖」，
它是一套**按名字猜**的查找规则。猜的顺序是固定的，本章把每一档都造出来让它是非分明：

```objc
@interface RTKVGetters : NSObject            // 三个候选方法都在
- (NSString *)getName; - (NSString *)name; - (NSString *)isName;
@end
@interface RTKVIvars : NSObject {            // 一个方法都没有，四个候选 ivar 都在
    NSString *_name; NSString *name; NSString *isName; NSString *_isName;
}
@end
@interface RTKVNoIvarAccess : NSObject { NSString *_name; }
+ (BOOL)accessInstanceVariablesDirectly;     // 返回 NO
@end
```

「谁压过谁」不能只看一轮，所以每个名次都配一组**把上一轮赢家拿掉**的类：
`RTKVGettersNoGet`（没有 `getName`）、`RTKVGettersIsOnly`（只剩 `isName`）、
`RTKVIvarsNoUnder`（没有 `_name`）、`RTKVIvarsNoIsUnder`（只剩裸 `name` 与 `isName`）、
`RTKVIvarsIsOnly`（只剩 `isName`）。这些类的 ivar 值不靠各写一遍 init，
是示例用 `object_setIvar` 按 ivar 名字现填的（§7 的那套 runtime 写法反过来给本节服务）。

```
== §12 KVC：候选顺序与集合运算符 ==
读值时的候选顺序（先方法后 ivar，全部按名字猜）。量法：把上一轮的赢家拿掉，剩下的里谁赢就是下一个名次：
    三个候选方法都在 -> 方法 getName
    拿掉 getName 只剩两个 -> 方法 name
    再拿掉 name 只剩 isName -> 方法 isName
    方法一个都没有，四个候选 ivar 都在 -> 下划线 ivar _name
    拿掉 _name（还剩裸 name / isName / _isName）-> ivar _isName
    再拿掉 _isName（只剩裸 name 与 isName）-> 裸 ivar name
    最后只剩 isName -> ivar isName
    驼峰键 theName 命中 _theName -> 驼峰键也能命中下划线 ivar
    同样只有 ivar，但 +accessInstanceVariablesDirectly 返回 NO：读 name -> 抛了 NSUnknownKeyException（关掉 accessInstanceVariablesDirectly 之后不再退到 ivar）（对照组上面那条能读到）
写值：setValue:forKey: 实际调的就是 setNick: —— 点语法读到 KVC 写进来的；key 是字符串，编译器一个字都不检查
    写值也是按名字猜：set<Key>: 与 _set<Key>: 同时存在 -> 调到的是 set<Key>:
    拿掉 set<Key>:、只剩 _set<Key>: -> 调到的还是 _set<Key>:（第二个候选名真的会被查到）
    一个 setter 都没有、只有 ivar _title：写完之后用 object_getIvar 读回=没有 setter，直接写 ivar（写值也会退到 ivar，和读值是同一套候选）
字典也能被 KVC：@{@"nick":@"字典里的"} 的 valueForKey:@"nick" -> 字典里的（走 objectForKey:，不是找属性）
集合运算符（只有 valueForKeyPath: 认 @ 前缀）：
    @sum.integerValue -> 11，实际类是 NSDecimalNumber（不是普通 NSNumber，别拿它做 ==）
    @avg.floatValue=3.6666666666666666666666666666666666666 @min.floatValue=1 @max.floatValue=7 @count=3
    运算符后面那段（@sum.floatValue 里的 floatValue）是「对每个元素再取一次键」，写成 .self 就取元素本身。
    @distinctUnionOfObjects.self 去重：a,b,a -> a | b；@unionOfObjects.self 不去重 -> a | b | a
    元素本身还是集合时要用 @unionOfArrays.self：[[a,b],[c]] -> a | b | c
    空数组：@sum=0 @count=0（这俩给 0），@avg=(nil) @min=(nil)（这俩直接是 nil）—— 「取个值塞进 NSInteger」就会在这里静默变成 0
to-many 集合上的 KVC 会广播：
    [people valueForKey:@"nick"] -> 甲 | 乙（pluck 出一个新数组，顺序跟 people 一致；元素自己不会响应 nick，靠广播）
    [people setValue:forKey:@"nick"] 之后：a.nick=批量写入 b.nick=批量写入（两个都被写）
    NSSet 上同样能广播，读回来的类型是 __NSSetI（1 个元素；两个人现在值一样，集合并成了 1 个 —— 集合不保证顺序，所以排序后才打：批量写入）
    空数组上广播：count=0，结果=没抛（一个元素都没有，等于什么都没做，也不报错）
    探针记录：@first / @last 这两个「文档里列了」的运算符在 iOS 18 的 Foundation 上根本没实现，[nums valueForKeyPath:@"@first.floatValue"] 直接抛 NSInvalidArgumentException：“[<NSConstantArray 0x…> valueForKeyPath:]: this class does not implement the first operation.”（@last 同一条，把 first 换成 last）—— 想拿首尾元素就老实写 firstObject / lastObject。
    ① [obj valueForKey:@"没这个键"] -> NSUnknownKeyException，reason 是 “[<类名 0x…> valueForUndefinedKey:]: this class is not key value coding-compliant for the key 没这个键.”；
    ② [obj setValue:nil forKey:@"一个 int 属性"] -> NSInvalidArgumentException，reason 是 “[<类名 0x…> setNilValueForKey]: could not set nil as the value for the key ….” —— 给标量键传 nil 一定要先挡掉；
    ③ 这两条正是「字典转模型遇到多余字段就崩」「xib 连线连到已删掉的属性上就崩」的底层原因：KVC 的键是字符串，编译期无人把关。
```

**读值的顺序（方法三档 + ivar 四档）**，按 `key`（首字母大写记作 `Key`）：

1. 方法：`-getKey` → `-<key>` → `-is<Key>`（三档全部实测到位：`方法 getName`、`方法 name`、`方法 isName` 依次胜出）
2. ivar（只有 `+accessInstanceVariablesDirectly` 返回 `YES` 才轮到这一族）：
   `_<key>` → `_is<Key>` → `<key>` → `is<Key>`
3. 都不中 → `valueForUndefinedKey:` → 默认抛 `NSUnknownKeyException`

第 2 族的第二名是这节最值得记的一次纠正：**`_is<Key>` 排在裸 `<key>` 前面**。
「拿掉 `_name` 还剩三个」那一轮赢的是 `ivar _isName`，而不是 `裸 ivar name`——
只有把 `_isName` 也拿掉，裸 `name` 才升到第一名。
网上和旧书里流传的「`_key` → `key` → `isKey`」少了 `_isKey` 这一档、还把顺序记反了，
而 Apple 文档的表格（`_<key>`、`_is<Key>`、`<key>`、`is<Key>`）与实测逐档吻合。
背顺序不是为了考试：类里同时有 `_isReady` 和 `isReady` 两个 ivar 时，
`valueForKey:@"ready"` 读到的是**前者**，这种「代码看着没写错、值却是另一个」的 bug 只能靠这张表定位。

**写值**是同一套思路的另一张表，实测到的名次：`set<Key>:` → `_set<Key>:` → 直接写 ivar
（最后一个候选连 setter 都没有也能写进去，示例用 `object_getIvar` 把值读回来证明落点）。

其余三条本节的结论：
**驼峰键也能命中下划线 ivar**（`theName` → `_theName`），这一条是「字典转模型能省掉一堆映射代码」的全部依据；
`accessInstanceVariablesDirectly` 那个开关是最实用的发现——返回 `NO` 之后，
只有 ivar 的对象读不出值而是**抛异常**，它能当「显式声明哪些键允许直写」的守门人，
但代价是失败形态从「静默读到 nil」变成「崩溃」，用它就要接住异常；
字典本身也能被 KVC（`valueForKey:` 走 `objectForKey:`，不是找属性）。

**集合运算符**只在 `valueForKeyPath:` 里认 `@` 前缀，`valueForKey:@"@sum"` 是不行的。
形状是 `@运算符.对每个元素再取的键`，`.self` 表示元素本身。本节量到的东西：

- `@sum.integerValue` 得到 `11`，可它的**实际类是 `NSDecimalNumber`**。
  拿它 `==`、或者强转成 `NSNumber *` 再用 `intValue` 之外的方式都会绕回来；
  这一条是「聚合结果拿去比较莫名失败」的根源。
- 空数组上四个运算符的**形状不一致**：`@sum=0`、`@count=0` 给 0，而 `@avg`、`@min` **直接是 nil**。
  「取个值塞进 `NSInteger`」就在这里静默变成 0——和 §2 那条「nil 给你的 0 看着像真值」是同一类错误。
- `@distinctUnionOfObjects.self` 去重（`a | b`）、`@unionOfObjects.self` 不去重（`a | b | a`）、
  元素本身还是集合时要用 `@unionOfArrays.self`。三者只差一个词，输出差别一眼可见。
- **`@first` / `@last` 在这一版 Foundation 上根本没实现**，`valueForKeyPath:@"@first.floatValue"`
  直接抛 `NSInvalidArgumentException`（探针记录原文：`this class does not implement the first operation`）。
  文档列表里有、跑起来没有——**这就是本章不背文档、只跑示例的理由**。

**to-many 广播**是 KVC 最被低估的性质：向一个数组 `valueForKey:@"nick"`，
数组本身没有 `nick`，runtime 会**对每个元素各取一次**再打包成新数组（pluck）；
`setValue:forKey:` 反过来是**批量写入**，两个人都被写。`NSSet` 上同理，
读回来的是集合（本例 `__NSSetI`，且因为两个人值一样了之后**并成了 1 个元素**——
这正是「别拿集合的元素数当记录数」的现场教材）。空数组上广播不报错，等于什么都没做。

三条崩溃原文（`valueForUndefinedKey:`、`setNilValueForKey:`、xib 连线）留成探针记录，
它们的共同点是 **key 是字符串，编译期没人把关**。凡是把外部 JSON/字典直接
`setValuesForKeysWithDictionary:` 灌进模型的代码，都要先想「多一个字段会怎样」——
答案是走 `setValue:forUndefinedKey:`，默认抛异常。稳的写法是重写它、把不认识的键吞掉。

## 13) KVO：isa 被换成一个偷偷生成的子类

KVC 是「按名字取值」，KVO 是「按名字挂回调」。它的实现方式在本章前面所有机制里最巧：
**给你这个对象换一个动态生成的子类的 isa，在那个子类里覆盖 setter，
再重写 `-class` 让你看不出来**。

```objc
[obj addObserver:obs forKeyPath:@"counter"
         options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
         context:(void *)0x1];
```

```
== §13 KVO：isa 换脸与通知时机 ==
加观察之前：object_getClass(obj)=RTKVOSubject，[obj class]=RTKVOSubject（两个一样）
加完观察：object_getClass(obj)=NSKVONotifying_RTKVOSubject，而 [obj class] 仍是 RTKVOSubject —— KVO 把 isa 换成一个偷偷生成的子类，但重写 -class 让你看不出来
    这个动态子类的父类=RTKVOSubject；它自己列出的属性数=0；它**自己**的方法表（已排序）=_isKVOA class dealloc setCounter: —— 里面只有这几条：覆盖 setter 来发通知、覆盖 -class 把换脸藏住、覆盖 -dealloc 做收尾，外加一个 _isKVOA 标记；注意表里并没有 isMemberOfClass:（它怎么还能答对，见 §14）
    同一件事用 class_getInstanceMethod 问也返回非空，所以那个 API 证明不了覆盖 —— 它沿继承链往上找，父类本来就有 setCounter:（上面那段用的是 class_copyMethodList，只看这一层）
    options 里有 Initial，所以注册当场就通知一次：counter kind=1 keys=kind,new ctx=1
走 setter（obj.counter = 5）-> counter kind=1 keys=kind,new,old ctx=1
    再赋一次同样的值 5 -> 日志条数=1（NSNumber 属性也照发，KVO 不做「值变了才通知」的判断）
绕过 setter、按 ivar 偏移直写 _counter（属性读到=42）-> 日志条数=0 —— KVO 挂在 setter 上，不轮询内存
手动 willChange 单独一次：通知条数=0；补上 didChange 之后总数=1 —— 通知是在 didChange 时发的（ counter kind=1 keys=kind,new,old ctx=1）
改一个没观察的属性 title -> 日志条数=0（挂钩是按 keyPath 分别建立的）
拼错的键路径不会当场报错：注册 @"counterTypo" 成功（isa=NSKVONotifying_RTKVOSubject），但改 counter 的日志条数=1 —— 静默失效，比崩溃更难查
按 context 精确取消之后：isa 恢复成 RTKVOSubject，再改 counter 的日志条数=0
    再确认一次已经彻底摘干净：日志条数=0
自定义 setter + 手动 willChange/didChange 也能被观察：value kind=1 keys=kind ctx=NULL | value kind=1 keys=kind ctx=NULL
探针记录（KVO 的四条只能记不跑）：
    ① iOS 上根本没有两参数版的 -addObserver:forKeyPath:（那是 macOS 的旧接口），写出来编译报 error: no visible @interface for 'X' declares the selector 'addObserver:forKeyPath:' —— 必须用四参数 options:context:；
    ② 观察者没实现 observeValueForKeyPath:ofObject:change:context:（也没转给 super）时抛 NSInternalInconsistencyException：“<观察者>: An -observeValueForKeyPath:ofObject:change:context: message was received but not handled.” 然后 SIGABRT；
    ③ 取消一个并不存在的观察抛 NSRangeException：“Cannot remove an observer <A 0x…> for the key path "k" from <B 0x…> because it is not registered as an observer.” —— 探针里把观察者搞反时，报错打出来的地址看着像被观察对象，很容易认错人；
    ④ 同一观察者对同一路径注册两次不报错（探针：两次 add 都成功），但一次 remove 只消一层，剩下那层会在对象释放后继续通知 —— KVO 的经典崩溃就这么来的；要么配 context 精确移除，要么用 block 版封装保证只注册一次。
```

先说换脸的证据，这一组对照是本章最漂亮的一处：

| 问法 | 加观察前 | 加观察后 |
| --- | --- | --- |
| `object_getClass(obj)`（真 isa） | `RTKVOSubject` | **`NSKVONotifying_RTKVOSubject`** |
| `[obj class]`（消息） | `RTKVOSubject` | `RTKVOSubject` |
| `class_getSuperclass(isa)` | — | `RTKVOSubject` |
| 动态子类自己的属性表 | — | 0 个 |
| 动态子类**自己**的方法表 | — | `_isKVOA class dealloc setCounter:` |

`object_getClass` 是 C 函数、不走消息，所以看得到真相；`[obj class]` 是消息，
KVO 覆盖的就是它。**这条区别在 §14 还有一处对照**（`[sub class] == object_getClass(sub)` 相等=1，
只在没被 KVO 换脸时成立）。而那张方法表就是 KVO 的全部家当：
**不加属性、只覆盖三个方法加一个标记**——拦 setter 发通知、盖 `-class` 藏住换脸、
`-dealloc` 收尾、`_isKVOA` 给自己留个可识别的记号。

这里有个容易被绕过去的 API 陷阱，示例专门打了一条：判断「子类有没有覆盖某个方法」
**不能用 `class_getInstanceMethod`**——它沿继承链往上找，`RTKVOSubject` 本来就有 `setCounter:`，
所以在动态子类上问永远返回非空，是假证据。要看覆盖只能用 `class_copyMethodList` 列这一层
（本节为此加了 `RTOwnMethodNames` 这个辅助函数，§14 的 `isMemberOfClass:` 那一问也用它）。

四条通知时机，每条都会坑一次真实代码：

- **走 setter 才通知**。按 ivar 偏移直写 `_counter`（§7 那招），属性读到 42、日志条数 0。
  「KVO 挂在 setter 上，不轮询内存」——这就是为什么必须用 `self.counter = 5` 而不是 `_counter = 5`。
- **不做「值变了才通知」的判断**。连着赋两次同一个值 `5`，第二次照样通知一条。
  想要「变了才动」得自己在回调里比 `NSKeyValueChangeOldKey`。
- **通知发在 `didChange` 那一刻**：单调 `willChangeValueForKey:` 日志条数是 0，
  补上 `didChange` 之后总数变 1（而 change 字典里的 `kind` 与键照常）。
  这条给了「自定义 setter 也能被观察」的通路：`RTKVOManual` 完全自己写 setter，
  里面手动一对 `willChange`/`didChange`，外面 KVO 就收得到（本节最后一行）。
  CoreData 的惰性 fault、`@dynamic` 属性靠的全是这个开关。
- **`options` 决定 change 字典里有哪些键**：带 `Initial` 时注册当场通知一次，
  且那一行只有 `keys=kind,new`（没有 old，因为还没旧值）；正常赋值是 `kind,new,old`。
  反过来 `options:0` 时回调照样触发，可读不到值——§20 的 Swift 侧把这条量得更狠。

`counterTypo` 那条是本章最阴的一处：**拼错的键路径注册成功、isa 照样换脸、
可改 `counter` 的时候收不到通知**（日志条数是别的键留下的那 1 条）。
KVO 不校验键存在（校验要走到 ivar/属性表，它选择不查），于是错误形态是「静默失效」。
比崩溃难查得多，而且**没有任何日志**。稳妥做法是注册之前先
`[obj.class instanceMethodSignatureForSelector:@selector(setCounter:)]` 或
`respondsToSelector:` 自己确认一遍。

摘干净的过程也值得看一眼：按 `context` 精确 `removeObserver:forKeyPath:context:` 之后，
**isa 恢复成 `RTKVOSubject`**（动态子类整个被丢掉），再赋值日志条数 0。
`context` 在观察者回调里打成 `ctx=1`/`ctx=NULL`——它就是那个「不靠对象身份区分注册」的凭证，
§20 会看到 Swift 的 block 版把它换成了 token。

## 14) 内省四问、类与元类，以及运行期造一个类

`isKindOfClass:` / `isMemberOfClass:` / `respondsToSelector:` / `conformsToProtocol:`
这四问长得像一套，实际问的是四件不同的事。示例用一个继承链 + 一个 `<NSCopying>` 把它们铺全：

```
== §14 内省：四个容易混的问题与类/元类 ==
四个最容易混的内省问题：
    [sub isKindOfClass:RTIntBase]=1（含祖先）vs [sub isMemberOfClass:RTIntBase]=0（只看自己）
    [sub isMemberOfClass:RTIntSub]=1（自己当然是）；[base isKindOfClass:RTIntSub]=0（父类不是子类）
    [str isKindOfClass:RTIntSub]=0；[nil isKindOfClass:任何类]=0（nil 接收者返回 NO，不崩，所以 `if (![x isKindOfClass:]) return;` 对 nil 也安全）
    最后一组给「判类型该用哪个」定实测边界：拿 §13 那个会被 KVO 换脸的对象再问一遍：
        没人观察它的时候：isKindOfClass=1，isMemberOfClass=1，object_getClass=RTKVOSubject
        换脸期间：isKindOfClass=1，isMemberOfClass=1，[kv class]=RTKVOSubject —— 三个答案和上面一模一样，「KVO 会让 isMemberOfClass: 翻脸」这个流行说法在这里被实测否定
        为什么没覆盖也能答对：动态子类自己的方法表里 isMemberOfClass: 查得到=0（§13 那张表里没有它），可答案仍然是「是这个类的成员」—— 只能说明 NSObject 的 -isMemberOfClass: 内部是拿 [self class] 去比对的，而 -class 被 KVO 覆盖了，所以它跟着一起被带偏（这条是从两个实测结果推出来的，不是背来的）
        唯一的破绽在 runtime 那条路上：object_getClass=NSKVONotifying_RTKVOSubject —— 内省四问没有一个能告发 KVO
        摘掉观察者：object_getClass 恢复成 RTKVOSubject（对照 §13 的 isa 换回来），四问的答案从头到尾就没变过
类与元类：object_getClass(实例)=RTIntSub；object_getClass(RTIntSub 这个类)=RTIntSub；class_isMetaClass(RTIntSub)=0，class_isMetaClass(它的元类)=1
    元类的父类=RTIntBase（NSObject 是根，它的元类的 superclass 就是 NSObject）；[sub class] 和 object_getClass(sub) 相等=1（没被 KVO 换 isa 时两者一样）
方法从哪里来：class_copyMethodList(RTIntSub) 只列本类的 2 个（copyWithZone: onlyOnSub，已排序），但 class_getInstanceMethod(RTIntSub, onlyOnBase) 也找得到=1 —— 后者会沿继承链往上找
    实例方法版：[sub respondsToSelector:onlyOnBase]=1，[RTIntSub instancesRespondToSelector:onlyOnBase]=1（问的是「这个类的实例会不会」，不用造对象）
    类方法版：[RTIntSub respondsToSelector:subClassOnly]=1，[RTIntBase respondsToSelector:subClassOnly]=0（类方法也继承，但只在子类这层加的方法父类问不到）
    问一个没实现的选标：[sub respondsToSelector:绝不存在]=0（返回 NO，不崩）
协议采纳：[RTIntSub conformsToProtocol:NSCopying]=1，[RTIntBase 同样的问题]=0，实例也能问 [sub conformsToProtocol:NSCopying]=1；class_copyProtocolList(RTIntSub)=1 个（它自己写的 <NSCopying>）
按名字找类：objc_getClass("RTIntSub")=RTIntSub；NSClassFromString(@"RTIntSub")=RTIntSub；查一个没有的名字 -> NULL（不崩）
运行时造一个类：objc_allocateClassPair + class_addMethod + objc_registerClassPair，之后用 NSClassFromString(@"RTBuilt") 实例化并调 hey -> 动态注册出来的类的方法
    拿同一个名字再分配一次：objc_allocateClassPair 返回 nil（重复分配得到 nil，不崩；进程内注册的类总数是随系统变化的大数，不能拿来断言）
```

四问的分界，一句话版本：**`isKindOfClass:` 问「是不是这一族」，`isMemberOfClass:` 问「是不是这个类本身」，
`respondsToSelector:` 问「会不会这件事」，`conformsToProtocol:` 问「认不认这份契约」**。
示例用一个继承链（`RTIntSub : RTIntBase`）+ 一个 `<NSCopying>` 把四问铺全，
最后再拿 §13 那个会被 KVO 换脸的对象把前两问重跑一遍——那一遍把一条流行说法跑掉了。
本节的证据里三处最有用：

- **`isKindOfClass:` 才是判类型的那个**，但理由和常见说法不一样。常见说法是
  「KVO 换了 isa，所以 `isMemberOfClass:` 会翻脸」——本节实测**否定了这条**：
  被观察的对象在换脸期间 `isKindOfClass:`、`isMemberOfClass:`、`[obj class]` 三个答案全都不变，
  KVO 把内省四问瞒得滴水不漏（唯一的破绽是 C 函数 `object_getClass`）。
  `isMemberOfClass:` 真正的问题在**普通继承**上：`RTIntSub` 的实例
  `[sub isMemberOfClass:RTIntBase]=0`——它明明是那一族的成员。
  库把你的对象塞进一个子类（或你自己用了子类）时，这一问就答错，
  所以**判断类型一律 `isKindOfClass:`**；真需要「精确类型」时比 `object_getClass`，别比消息版 `-class`。
- `[nil isKindOfClass:X]` 返回 `NO` 而不崩（§2 的 nil 表在 BOOL 上的特例），
  所以 `if (![x isKindOfClass:[NSThing class]]) { return; }` 对 nil 也安全——
  这是 ObjC 里少数可以放心链下去的判断。
- **类方法也继承，但只在子类这层加的方法父类问不到**：
  `[RTIntSub respondsToSelector:@selector(subClassOnly)]=1`、`[RTIntBase …]=0`。
  这一条常被误当成「类方法不继承」。

类与元类那一组是 ObjC 最劝人的部分，示例只打**类名**而不打指针：
实例的 `object_getClass` 是它的类；类的 `object_getClass` 是它的**元类**
（`class_isMetaClass` 分别是 0 和 1）；元类的父类是父类的元类，根是 `NSObject`。
实际要记的只有一句：**实例方法查类、类方法查元类**，其余时候你永远不碰元类。
`[sub class] == object_getClass(sub)` 那条也留在这里，因为它在 §13 是反例、这里是正例。

本节最后跑了一段真正的「运行期造类」，这段代码就是 §9 那些热修框架的最小内核：

```objc
Class built = objc_allocateClassPair([NSObject class], "RTBuilt", 0);
IMP imp = imp_implementationWithBlock(^NSString *(id self) { return @"动态注册出来的类的方法"; });
if (class_addMethod(built, @selector(hey), imp, "@@:")) {
    objc_registerClassPair(built);
    id instance = [[NSClassFromString(@"RTBuilt") alloc] init];
    builtResult = [instance performSelector:@selector(hey)];
}
```

三步是硬性顺序：**allocate（拿到还没注册的类）→ 加方法/加协议 → register（一次性定型）**。
注册之后再想加方法就得改用 `class_addMethod` 直接打到已注册的类上，
而重复 `objc_allocateClassPair` 同一个名字返回 **nil**（不崩）。
最后那句「进程内注册的类总数是随系统变化的大数，不能拿来断言」是本教程的输出纪律：
`objc_copyClassList` 在这台机器上给两万多，那个数随已加载的动态库变，写进断言就是假失败。

## 15) 对象通信三件套：target-action、delegate、notification

ObjC 里有三种「让另一个对象干件事」的手段，它们**在 runtime 层的差别就是「谁在什么时候才知道对方是谁」**。
示例手写了一个最小版的 `UIControl`，让差别可见：

```objc
@interface RTCommSource : NSObject
@property (nonatomic, strong) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, strong) id<RTCommDelegate> delegate;
- (NSInteger)fire;
@end
@implementation RTCommSource
- (NSInteger)fire {
    if ([self.delegate respondsToSelector:@selector(sourceShouldFire:)] &&
        ![self.delegate sourceShouldFire:self]) {
        return -1;                       // 被 delegate 一票否决
    }
    id t = self.target;
    if (t && [t respondsToSelector:self.action]) {
        ((void (*)(id, SEL))objc_msgSend)(t, self.action);
        return [(RTCommSink *)self.target hits];
    }
    return -2;                           // 没人接，静默失败
}
@end
```

```
== §15 对象通信：target-action、delegate、notification ==
目标-动作：SEL 当数据存着、target 当对象存着，运行时才 objc_msgSend —— 触发两次后 sink.hits=2 （这就是 UIControl 那套东西的最小模型：发送方编译期完全不认识接收方）
    换成带 sender 的动作：hits 从 2 跳到 12（一次 +10）—— sender 就是这么传过去的
    target 置 nil 再触发：返回 -2、hits 仍是 12（整个调用无声消失 —— 控件「点了没反应」多半就是这个）
    action 写成不存在的选标：@selector 编译得过，但 respondsToSelector 拦下了，返回 -2（少了这句判断，就是 §8 结尾那条 unrecognized selector 崩溃）
委托（delegate）：@optional 的方法必须先 respondsToSelector 再问，这次 gate 说不给发 -> 返回 -1、hits=12（一对一、由被通知的一方决定；数据源是它「只负责供数据」的特例）
    不设 delegate 时那段判断直接跳过：hits=13（委托为 nil 是常态，不是错误）
通告（NSNotificationCenter）：一对多、按名字广播，发送方不知道谁在听 —— 实际收发在 Swift 侧跑（见 §21）：
    两条容易记反的规则（§21 实测）：block 版 addObserver(forName:object:queue:using:) **不会**自动解绑，忘了 removeObserver 就是「对象都释放了还被叫起来干活」；selector 版 addObserver:selector:object:queue: 反而会自动解绑；
    中心是全局的：名字拼错 = 永远收不到（编译器不管），所以通知名一律用常量，别散着写字符串。
    目标-动作 / 委托 / 通知三者怎么选：一个控件对一个处理者用 target-action；一个对象问另一个对象「能不能」用 delegate；多处想知道同一件事才用 notification。绑定（KVO 之外 macOS 的 Cocoa Bindings）iOS 上没有。
```

`SEL` 在这里是**存在属性里的数据**（`@property (nonatomic, assign) SEL action;`），
`target` 是**存在属性里的对象**，两者都到 `fire` 那一刻才凑成一句 `objc_msgSend`。
本节量到的四种失败形态，就是控件调试时的四句话：

- **`target` 为 nil 时整个调用无声消失**（返回 `-2`，`hits` 不动）——
  「按钮点了没反应」在 runtime 层就是这一条。`UITouch` 那一层早就做了这个判断，所以你从来看不到崩溃。
- **`action` 写成不存在的选标，`@selector` 编译得过**，
  拦下它的是那句 `respondsToSelector:`。**把这句判断删掉，就是 §8 那条 unrecognized selector 崩溃**——
  这是本章前后最直接的因果。
- **带 `sender` 的动作靠多传一个参数实现**：`onTapFrom:` 里 `sender ? 10 : 1`，
  一次跳 10。这就是 `addTarget:action:@selector(x:)` 与 `@selector(x)` 的全部区别。
- **delegate 是「由被通知的一方决定」**：`RTCommGate` 返回 `NO`，`fire` 返回 `-1`，
  `hits` 一次都不加。而 `@optional` 的方法必须先 `respondsToSelector:` 再问（§11 的结论在这里落地）。
  `delegate` 为 nil 是常态而不是错误——那句判断为 nil 时直接跳过，`hits` 正常加到 13。

三者的选择规则（本教程反复用同一套话）：

| 手段 | 关系 | 谁决定 | 编译期能查吗 |
| --- | --- | --- | --- |
| target-action | 一个控件对一个方法 | 发送方 | 选标能查（`@selector`），target 不能 |
| delegate / datasource | 一个对象问另一个对象拿决定或数据 | **被问的一方** | 协议名能查，`@optional` 方法不能 |
| notification | 谁发谁不管，多少人都行 | 双方都不认识对方 | **都不能查**（名字是字符串） |

通知那一栏的「都不能查」是本章后面 §21 的全部动机：那两条容易记反的解绑规则、
`userInfo` 的残留、按 `object` 指针过滤，只有真的跑一遍才记得住。§15 故意把收发留在 Swift 侧，
是因为 OC 侧的 `NSNotificationCenter` 观察者和 Swift 侧的是同一套东西，而**解绑语义的差别在两边都成立**。

## 16) 可变/不可变：类层级、copy 的实际结果，与逐层都要问一遍

`NSString`/`NSMutableString` 这对名字看着像两个平行类，runtime 里却是**父子**：

```objc
[RTL add:[NSString stringWithFormat:@"可变类的**父类**就是不可变那个：NSMutableString->%@  NSMutableArray->%@  NSMutableDictionary->%@  NSMutableSet->%@",
          NSStringFromClass(class_getSuperclass([NSMutableString class])),
          NSStringFromClass(class_getSuperclass([NSMutableArray class])),
          NSStringFromClass(class_getSuperclass([NSMutableDictionary class])),
          NSStringFromClass(class_getSuperclass([NSMutableSet class]))]];
```

```
== §16 可变/不可变的类层级与 copy 的实际结果 ==
可变类的**父类**就是不可变那个：NSMutableString->NSString  NSMutableArray->NSArray  NSMutableDictionary->NSDictionary  NSMutableSet->NSSet
可变对象 copy 出来的实际类=__NSArrayI（不可变）；mutableCopy 出来的=__NSArrayM（可变）
    之后再改源：copy 的那份 count=2（不受影响），mutableCopy 的那份 count=2（也不受影响，两者都是各自的一份容器）
copy 是**浅拷贝**：外层容器新建了，内层对象还是同一个 —— 改 orig 的内层数组，副本看到 count=2
    内外层是同一个对象=1
plist 往返之后**逐层**问类：源字典=__NSDictionaryM 回来=__NSDictionaryM（外层竟然还是可变的），但里层的 NSMutableString 回来=NSTaggedPointerString（成了不可变的 tagged pointer）
    结论：「走一遍序列化就全都不可变」是想当然 —— 容器每一层的实际类要各自问，别拿顶层那层推断整棵树；里层之所以丢可变性，是因为 plist 格式里只有字符串这一种类型，没有「可变字符串」这档
```

四条要点：

- **`copy` 与 `mutableCopy` 的差别是「结果可不可变」，两者都新建容器**。
  之后再改源数组，两份的 `count` 都停在 2 —— 「`mutableCopy` 会跟着源变」是错的，
  它只是**结果**可变。这一条写错的人通常是在 `enumerateKeysAndObjectsUsingBlock:`
  里改源集合，那才是真崩的位置（改的是副本，遍历就安全了）。
- **打出来的实际类是 `__NSArrayI` / `__NSArrayM` / `__NSDictionaryM`，不是 `NSArray`**。
  公开类和私有实现类的区别要在 `NSStringFromClass` 里才看得见，而**类型判断要用
  `isKindOfClass:`**（§14），别拿 `isMemberOfClass:` 或字符串比类名。
  §6 那条「strong 与 copy 的属性实际类都是 `__NSCFString`」是同一件事的另一面。
- **`copy` 是浅拷贝**，这是本节唯一的「重复强调」，因为它每年都要再踩一次：
  外层容器新建了，**内层对象还是同一个**——示例直接比了 `orig.kids[0] == copied.kids[0]`，等于 1，
  改 `orig` 的内层数组，副本那边 `count` 就跟着从 1 变成 2。
  要深拷贝得自己一层层 `mutableCopy`，或者走 §17 之外那条路（`NSCoding`/`Codable` 往返）。
- **序列化不会替你统一可变性**。走一遍 plist 往返：顶层字典**仍然是 `__NSDictionaryM`**，
  而里层的 `NSMutableString` 变成 `NSTaggedPointerString`。所以「容器每一层的实际类要各自问」，
  别拿顶层推断整棵树。里层丢可变性的原因也顺手可推：plist 格式里只有「字符串」这一种类型，
  没有「可变字符串」这档。

`NSTaggedPointerString` 这个名字值得单独记：**短字符串不是堆上的对象，而是把内容直接编进指针值里**
（tagged pointer）。本节那个只有 `"x"` 一个字符的值走完 plist 往返之后就变成了它——
这是运行时内部优化 leaking 到类名上的一个现场样本，也解释了为什么
`[s isKindOfClass:[NSString class]]` 对它依然为真：tagged pointer 的类查询是 runtime 伪造的。
实际写代码时的启示只有一条：**别拿 `NSStringFromClass` 的输出当类型判断依据**，
`__NSArrayI`、`NSTaggedPointerString`、`__NSDictionaryM` 这些名字只用来读懂日志和崩溃现场。

## 17) @try/@catch/@finally：匹配规则与「谁写得具体谁先接」

ARC 之后 ObjC 异常**不该用来做控制流**（性能、且 ARC 下 `@try` 块里的对象生命周期有额外约束），
但系统会抛它——`objectAtIndex:` 越界、KVC 找不到键、KVO 摘错观察者（§12、§13）全是异常。
所以这一节讲的是**读得懂、接得住**，而不是拿它当 `do/catch` 用。

```objc
@try {
    [trace appendString:@"try 开始；"];
    @throw [NSException exceptionWithName:@"RTPlain" reason:@"普通异常" userInfo:@{ @"code": @1 }];
} @catch (RTHotTea *e) {
    [trace appendString:@"被 RTHotTea 块抓住（不该发生）；"];
} @catch (NSException *e) {
    [trace appendFormat:@"被 NSException 块抓住：name=%@ reason=%@ userInfo 有 %@；", e.name, e.reason, e.userInfo[@"code"]];
} @finally {
    [trace appendString:@"finally 一定执行；"];
}
```

```
== §17 异常：@try/@catch/@finally 的匹配规则 ==
① 抛 NSException，两个 @catch 按「具体优先」匹配 -> try 开始；被 NSException 块抓住：name=RTPlain reason=普通异常 userInfo 有 1；finally 一定执行；
② 自定义 NSException 子类：谁写得具体谁先接 -> 内层只写了 NSException，子类异常被它抓住；外层写了 RTHotTea，就轮到它：太烫；finally；
③ 抛非异常对象 -> @throw 可以抛任意对象，@catch(id) 之外还能按类接：接到 我根本不是 NSException，就是个 NSString；
④ 系统抛的异常能被同样的 @try 接住（越界是 NSRangeException）： NSRangeException：reason 是越界信息；
⑤ 嵌套 @try 与「@catch 里再 @throw」-> 接住内层后再抛一次；内层 finally（即使正在往外抛也先跑完）；外层再接：RTInner；
⑥ 探针记录：本章之外还有两条只能记不能跑 —— 没人接的 NSException 会让进程 SIGABRT（stderr 打整段 reason 与调用栈）；Swift 侧的 do/catch 抓不到 ObjC 的 @throw（不是同一种错误通道）。
```

四条规则，本节的六段实验各证一条：

1. **多个 `@catch` 按「具体优先」匹配**，不是按书写顺序。
   第 ① 段同时写了 `RTHotTea`（一个 `NSException` 子类）和 `NSException`，
   抛的是普通 `NSException`，于是走第二类块（第一段那个「不该发生」的分支确实没走）。
2. **`@finally` 一定执行**，包括「正在往外抛」的时候。
   第 ⑤ 段专门量了这个：`@catch` 里 `@throw e;` 再抛一次，
   日志顺序是 `接住内层后再抛一次；内层 finally（即使正在往外抛也先跑完）；外层再接：RTInner`。
   清理代码放 `@finally` 是唯一可靠的；`@catch` 里再 `@throw` 是包装异常的标准写法。
3. **`@throw` 可以抛任意对象**，`@catch` 也能按类接。第 ③ 段抛了一个 `NSString`，
   被 `@catch (NSString *s)` 接住（而不是 `@catch (id)`）。这解释了为什么
   「`@catch (NSException *)` 接不住一切」——它只接 `NSException` 那一族。
4. **系统抛的异常是同一套机制**，所以能接。第 ④ 段越界抛出的是 `NSRangeException`，
   `name` 读回来就是它。而 §8 那条「unrecognized selector 能被 `@try` 接住」也在这里闭环。

第 ④ 段顺带处理了一个输出纪律问题：reason 的开头带接收者类名和地址
（`*** -[__NSArrayI 0x…]`），所以代码里只判断「是不是以类名开头」，
把结果打成 `reason 以接收者类名开头` 或直接引用「越界信息」，**地址一次都没打出来**。

两条留成探针记录（一次都没在示例里执行）：**没人接的异常会让进程 SIGABRT**
（stderr 打整段 reason 与调用栈）；**Swift 的 `do/catch` 抓不到 ObjC 的 `@throw`**——
它们不是同一条错误通道。今天 Swift 侧唯一的正确姿势是：
ObjC API 用 `NSError **` 返回错误的按 `throws` 桥接，抛异常的（KVC/KVO 那一类）**只能靠不犯错**，
或者在 OC 侧包一层 `@try` 再转成 `Result`。

## 18) Swift 类在 ObjC runtime 里长什么样：名字的三种形态

从这一节起，视角换到 Swift 这一侧。示例在同一个文件里放了两个类，专门用来对照：

```swift
/// 继承 NSObject 的 Swift 类：对 ObjC runtime 完全可见
class RTSwiftVisible: NSObject {
    var swiftStored = 1          // 纯 Swift 存储属性：runtime 看不见，KVC 也摸不到
    @objc var exposed = 2        // 标了 @objc 的属性才进 ObjC 的属性/方法表
    @objc func plainTag() -> String { "普通 @objc 方法" }
    @objc dynamic func dynamicTag() -> String { "dynamic @objc 方法" }
    func swiftOnly(_ x: Int) -> Int { x + 1 }
}

/// 不继承 NSObject 的纯 Swift 类
final class RTSwiftPure {
    var a = 1
    var b = "两"
    func doThing() -> String { "纯 Swift 方法" }
}
```

先解决一个每个人都会撞一次的问题：**Swift 类在 ObjC 里叫什么**？

```swift
let objcName = NSStringFromClass(Swift.type(of: v))
expect(objcName == "objc_runtime.RTSwiftVisible", …)
expect(NSClassFromString(objcName) === cls, …)
```

```
== §18 Swift 类在 ObjC runtime 里长什么样 ==
  Swift 的 type(of:) = RTSwiftVisible；NSStringFromClass = objc_runtime.RTSwiftVisible；OC 侧的 class_getName = objc_runtime.RTSwiftVisible
  ok   Swift 类的 ObjC 名字是「objc_runtime.RTSwiftVisible」= 模块名.类名，不是裸类名，也不是 `_TtC…` 那种 mangling：NSStringFromClass 会替普通 Swift 类把名字反解出来（class_getName 拿到的是同一串）。但泛型和编译器合成的类型就还是原始 mangling —— 见 §22 里那个 `_TtGCs26_…$` 的字典，以及下面纯 Swift 类的隐式父类。
  ok   拿 NSStringFromClass 给的那整串反查 NSClassFromString 能找回来；而 NSClassFromString("RTSwiftVisible") = nil —— 类名本身不是它的 ObjC 名，这就是「storyboard 里 Swift 类要填 模块名.类名」的根因。
  ok   OC 侧的 object_getClass（RTIsaOf）拿到的是同一个类对象：true
  ok   继承 NSObject 的 Swift 类走的就是这套消息机制：isKind(of: NSObject) = true
  ok   @objc 方法在 runtime 里就是一个真选标：#selector(plainTag) 的名字是 "plainTag"，responds(to:) = true
  ok   纯 Swift 方法照样能调（swiftOnly(1) = 2），但它在 runtime 里不可见 —— 见下一条
  ok   按 Swift 名字猜的选标 "swiftOnly:" 在 runtime 里问不到（responds = false）：没标 @objc 的方法根本不进 ObjC 方法表，KVC / perform / target-action 全都碰不到它。
  ok   问一个彻底不存在的方法：responds = false（和 OC 一样只回答 NO，不崩）
  runtime 眼里的成员：RTSwiftVisible 的 ivar 数 = 2，属性数 = 1，实例大小 = 24 字节（NSObject 本身 8 字节）
  ok   Swift 的存储属性会照实变成 ObjC ivar（2 个：swiftStored 与 exposed），但只有 @objc 那个进属性表（1 个）—— 「有 ivar」和「KVC 能读到」是两件事，§12 的候选顺序里 ivar 那一档就是给前者留的门。
```

`objc_runtime` 这个前缀不是写出来的，是 `run-all.sh` 传给 `swiftc` 的 `-module-name`
（`mod="${name#*_}"`，即目录名去掉 `27_` 之后剩下的部分）。
**Xcode 里它就是 target 的 Product Module Name**，所以同一个类在别的工程里前缀不同——
这条正好解释了为什么 storyboard 里填类名要带模块名，以及为什么把类挪进新 target 之后
xib 里的连线会集体失效（runtime 反查不到那个名字）。
ObjC 的名字有**三种形态**，本章都量到了：

| 形态 | 例子 | 什么时候出现 |
| --- | --- | --- |
| `模块名.类名` | `objc_runtime.RTSwiftVisible` | 普通 Swift 类，`NSStringFromClass` 会反解 |
| 原始 mangling | `_TtCs12_SwiftObject`、`_TtGCs26_SwiftDeferredNSDictionarySSSi_$` | 编译器合成的类型、泛型特化（§22） |
| 裸类名 | `RTGreeter` | ObjC 类（没有模块名这一说） |

## 19) @objc 与 @objc dynamic：同一次交换，两条路径的反应不同

这是本章对「今天写 Swift 的人」最有直接价值的一节。
把 §9 的 `method_exchangeImplementations` 用到 Swift 类的方法上，
然后**从两个方向各调一次**：Swift 里直接 `v.plainTag()`，OC 侧用 `objc_msgSend` 进来
（`RTCallThroughObjC` 就是 §3 那句话：先 `respondsToSelector:`，再 `objc_msgSend`）。

```swift
method_exchangeImplementations(m1, m2)   // plainTag <-> RTSwizzlePatch.plainTag
method_exchangeImplementations(m3, m4)   // dynamicTag <-> RTSwizzlePatch.dynamicTag
let swiftPlainAfter = v.plainTag()
let objcPlainAfter = RTCallThroughObjC(v, "plainTag")
```

```
== §19 @objc 与 @objc dynamic：换实现对两种方法的影响不一样 ==
  动手前：Swift 直接调 plainTag() = 普通 @objc 方法；dynamicTag() = dynamic @objc 方法
  动手前：从 OC 侧 objc_msgSend 进来 = 普通 @objc 方法 / dynamic @objc 方法
  交换之后：Swift 直接调 plainTag() = 普通 @objc 方法；dynamicTag() = 补丁版 dynamic 实现
  交换之后：从 OC 侧进来 = 补丁版实现 / 补丁版 dynamic 实现
  ok   只标 `@objc`（没有 dynamic）的方法：Swift 里的直接调用**绕过 objc_msgSend**，走 Swift 自己的入口，换 IMP 换不到它 —— 只有从 OC/runtime 进来的那条路变了。这就是「同一个 hook 有时灵有时不灵」的全部原因。
  ok   同一次交换，OC 路径立刻拿到了补丁版实现：补丁版实现
  ok   `@objc dynamic`：编译器把这个调用直接写成 objc_msgSend，于是**两条路径一起被换**（Swift 侧读到「补丁版 dynamic 实现」）。代价是每个调用多一次消息发送；收益是 KVO、swizzle、CoreData 惰性加载才 work —— 那几个框架都明确要求你写 dynamic，原因就在这。
  ok   补丁类自己被命中 3 次：交换后凡是走 ObjC 消息入口的调用都落进了 RTSwizzlePatch，计数在它那一侧，说明 runtime 认的是实现指针不是名字。
  ok   再各交换一次还原：plainTag = 普通 @objc 方法，dynamicTag = dynamic @objc 方法，IMP 指针回到最初那两个 = true（本节不给后面的小节留脏状态；线上更稳的做法是记下旧 IMP 用 method_setImplementation 还原，见 §9）
  ok   Swift 的 #selector 在编译期检查方法存在（写错编译不过），NSSelectorFromString 什么都不查 —— 和 §1 的结论一致：选标就是名字，编译器只替 #selector 这一条把关。
  ok   同一个类上，@objc 属性能被 KVC 摸到（value(forKey:"exposed") = Optional(2)），纯 Swift 的 swiftStored 摸不到 —— 探针记录：对它调 value(forKey:) 抛 NSUnknownKeyException，正是 §12 那两条崩溃的 Swift 版本。
```

四行输出把「有时灵有时不灵」这件玄学事讲成了机械事实：

| 方法声明 | Swift 里直接调 | OC/runtime 进来 |
| --- | --- | --- |
| `@objc func plainTag()` | **换不动**（走 Swift 入口） | 换成补丁版 |
| `@objc dynamic func dynamicTag()` | 换成补丁版 | 换成补丁版 |

`@objc` 只是**把方法登记进 ObjC 的方法表**（让别人能找到它），
不改变 Swift 自己的调用方式——Swift 里 `v.plainTag()` 仍然是一句直接调用（甚至可能被开销削减）。
`dynamic` 才真的把那句调用改写成 `objc_msgSend`，于是所有消息机制（换实现、KVO、`perform`）才管得着它。
这就是那三条常见困惑的同一个答案：

- 为什么给 `UITableView` 的某个方法打 hook 有时不生效——那个方法在 Swift 侧的直接调用不经过消息表；
- 为什么 CoreData 的托管属性必须 `@objc dynamic`——惰性 fault 靠 KVO 式的取值，而 KVO 靠消息；
- 为什么第三方「方法替换」库要么要求你加 `dynamic`，要么干脆只作用于 OC 类。

`RTSwizzlePatch.hits >= 3` 那条是本节自己的对照组：
补丁类里的计数被命中 3 次（两次从 OC 侧、一次从 Swift 侧的 `dynamic` 调用），
说明 runtime 认的确实是**实现指针**。而本节结尾把两次交换各再做一遍还原回去
（比较过 IMP 指针确实回到最初那两个），这样 §20 的 KVO 才不会被本节的补丁污染。

最后一条同时把 §1、§12 结到 Swift 上：`#selector` 编译期查方法存在、`NSSelectorFromString` 什么都不查；
`@objc var exposed` 能被 `value(forKey:)` 读到（`Optional(2)`），
纯 Swift 的 `swiftStored` 读不到（探针里抛 `NSUnknownKeyException`——§12 那两条崩溃的 Swift 版）。

## 20) Swift 侧 KVO：observe(...) 返回的 token 就是 §13 那套机制的自动版

Swift 的 `observe(_:options:_:)` 不是另一套东西，它把 §13 那三件事各代做了一遍：
注册（自动给出 keyPath 字符串）、回调（block 取代 `observeValueForKeyPath:`）、摘除（token 取代 context）。

```swift
class RTKVOHolder: NSObject {
    @objc dynamic var count: Int = 0
    @objc dynamic var label: String = "初始"
}
let token = holder.observe(\.count, options: [.initial, .new, .old]) { obj, change in
    var keys: [String] = ["kind"]                 // change.kind 在 Swift 侧永远带着
    if change.newValue != nil { keys.append("new") }
    if change.oldValue != nil { keys.append("old") }
    keys.sort()
    seen.append("count=\(obj.count) keys=\(keys.joined(separator: ","))")
}
```

```
== §20 Swift 侧 KVO：observe(...) 返回的 token 就是 §13 那套机制的自动版 ==
  注册前 isa = objc_runtime.RTKVOHolder
  注册后 isa = ..NSKVONotifying_objc_runtime.RTKVOHolder；Swift 看到的类型仍是 RTKVOHolder；keyPath 字符串 = count
  ok   block 版 observe 走的还是同一套 KVO：isa 被换成 ..NSKVONotifying_objc_runtime.RTKVOHolder（原名前面拼上 NSKVONotifying_，因为 Swift 类名本身带模块名，这一串里出现了两个点），而 Swift 侧的类型名一个字没变 —— §13 那个「偷偷生成子类」的机制在 Swift 里被完整复用。
  ok   initial + 两次赋值共通知 3 次：count=0 keys=kind,new | count=1 keys=kind,new,old | count=2 keys=kind,new,old
  ok   invalidate 之后再赋值，通知次数仍是 3 —— 与 OC 的 removeObserver 等价，但凭证是 token 本身，不存在 §13 探针里「把观察者对象传错」那种用法。
  ok   token 和宿主一起待在作用域里：这一轮命中 1 次，带回来的新值是「作用域内改一次」；作用域一结束 token 先被释放，KVO 自动把观察者摘掉 —— 宿主和观察者一起消失，就不会踩到 §13 探针里「宿主先走、观察者还挂着」那种崩溃。
  ok   options 一个都不传：回调照样触发 1 次，可 change.newValue 是 nil（true）—— 「观察者明明在跑，读到的值全是空的」就是这么来的，要新值必须显式写 options: [.new]（这一条与 §13 OC 侧「change 字典里有哪些键」是同一件事，只是 Swift 把键包成了 options）。
  ok   把 observe 的返回值直接丢掉（没接 token）：赋值之后命中 0 次 —— 通知没建立。这是 Swift 版 KVO 最常见的「一行代码写对了却不生效」。
```

那串有两个点的 `..NSKVONotifying_objc_runtime.RTKVOHolder` 是本章最容易看错的一行，
拆开它是：`NSKVONotifying_` + `objc_runtime.RTKVOHolder`。
因为 Swift 类名自己带模块名（§18），KVO 的前缀拼上去之后就出现了两个点。
**同一个 isa 换脸机制，在 Swift 类上照常工作**，`#keyPath` 给出的键名字符串也照常是 `count`。

三条属于「Swift 版 KVO 才知道」的性质，本示例都专门跑了一遍：

1. **`options` 不给就没有值**。`local.observe(\.label) { … }` 不带 options，
   回调**触发 1 次**而 `change.newValue == nil`。这一条在 OC 侧也存在（§13 的 change 字典），
   但 Swift 把字典包成了强类型字段，于是失败形态从「字典里没这个键」变成「可选值是 nil」——
   更难察觉。写 KVO 时 `options: [.new]` 要当成默认项。
2. **token 必须接住**。`_ = holder2.observe(…)` 之后赋值，命中 **0 次**：
   `NSKeyValueObservation` 是那个注册的凭证，它一释放注册就一起消失。
   这是 Swift KVO 的头号「代码看起来对却不生效」。
3. **token 和宿主待在同一个作用域里最安全**。示例用 `scope { … }` 造了一个真作用域，
   里面同时持有宿主和 token，出作用域自动摘除——这正好避开 §13 探针里那两条崩溃
   （「宿主先走、观察者还挂着」和「重复注册只摘一层」）。

`invalidate()` 与出作用域这两条路径的差别也值得记住：前者是**主动**摘（示例里摘完计数停在 3），
后者是**随生命周期**摘。线上代码更倾向主动摘，因为「作用域结束」在 Swift 里
不等于「这一刻」——闭包捕获、循环引用都能把它推后。

## 21) 通知中心：一对多、按名字、发送方不认识接收方

§15 把 OC 侧的三者摆完，通知那一路的实际收发放在这里跑，
因为 Swift 侧的 API 形状更容易暴露两条相反的规则：

```swift
let tokenA = nc.addObserver(forName: name, object: nil, queue: nil) { note in
    aHits += 1
    lastObject = note.object.map { String(describing: type(of: $0)) } ?? "nil"
    lastKeys = (note.userInfo?.keys.map { String(describing: $0) } ?? []).sorted().joined(separator: ",")
    wasMain = Thread.isMainThread
}
```

```
== §21 通知中心：一对多、按名字、发送方不认识接收方 ==
  ok   object 传 nil 的观察者收到 1 次；object 限定为 gate 的那个仍是 0 次 —— 通知按「名字 + object 是否是同一个指针」过滤，userInfo 只是随车行李
  ok   带回来的是发送方的类型名 RTSwiftVisible（不打印指针），userInfo 的键排序后 = alpha,beta；block 里 Thread.isMainThread = true（queue 传 nil 表示就在发送线程上同步执行）
  ok   换成 gate 发送：A 累计 2 次、B 累计 1 次、限定 other 的 C 是 1 次 —— 同一条通知每个匹配的观察者各收一份，顺序不保证（别依赖注册先后，UIKit 自己也不依赖）
  ok   第二次没带 userInfo：A 里的 lastKeys 被这次事件刷成空串（现在是 ""）、lastObject 跟着变成 NSObject —— 回调里那些「记到变量里」的状态每次都被覆盖，别把上一次的残留当成这一次的内容；要判断本次有没有带数据，只能在 block 里当场看 note.userInfo 是不是 nil。
  ok   全部 removeObserver 之后再发一次：三个计数都停在 0 —— block 版（addObserver(forName:object:queue:using:)）不会自动解绑，必须自己摘（返回的那个 token 就是摘它用的凭证）。
  selector 版观察者在场时：命中 1 次
  ok   同一个通知名，换成 selector 版：观察者出了作用域（deinit 跑过了 = true）再发一次，命中次数停在 1 —— 既不崩也不再响，Foundation 替它自动解绑了。block 版不自动解绑、selector 版自动解绑，这两条正好记反。
  通知名就是字符串（RT.Ch27.Ping）：拼错编译得过、永远收不到，所以名字一律收成常量或扩展，别散着写字符串。
  和 §15 的三者对比：target-action 是「一个控件对一个方法」，delegate 是「一个对象问另一个对象拿决定/拿数据」，notification 是「谁在听我不知道」。前两个编译期至少有名字可查，第三个连查都没得查。
```

本节最花篇幅的是**最后那两条相反的解绑规则**，而且它是被「量」出来的：
`RTDeadObserver` 是个 `NSObject` 子类，用 selector 版注册，靠 `deinit` 里的标记证明它真的被释放了：

```swift
final class RTDeadObserver: NSObject {
    static var hits = 0
    static var dealloced = false
    @objc func ping(_ note: Notification) { RTDeadObserver.hits += 1 }
    deinit { RTDeadObserver.dealloced = true }
}
scope {
    let dead = RTDeadObserver()
    nc.addObserver(dead, selector: #selector(RTDeadObserver.ping(_:)), name: name, object: nil)
    nc.post(name: name, object: nil, userInfo: nil)   // 命中 1 次
}
nc.post(name: name, object: nil, userInfo: nil)       // 仍然是 1 次，且没崩
```

- **selector 版（`addObserver:selector:object:queue:`）会随目标释放自动解绑**：
  观察者出了作用域、`deinit` 跑过，再发一次通知——既不崩也不再响。
- **block 版（`addObserver(forName:object:queue:using:)`）不会自动解绑**：
  它返回的那个 `NSObjectProtocol` token 才是摘它用的凭证，忘了 `removeObserver` 就是
  「对象都释放了还被叫起来干活」。**iOS 9 之后这条也没变**，很多人记的是反的。

这两条正好是 §15 里那句「两条容易记反的规则」的下文，示例特意让 OC 侧那节引用本节（"§21 实测"），
免得有人把结论读成一处孤立的口头规矩。

其余三条是通知机制的本体：**过滤条件只有「名字 + object 是不是同一个指针」**
（`object: nil` 的观察者全收，限定 `gate` 的只收 `gate` 发的那次）；
**每个匹配的观察者各收一份、顺序不保证**（别依赖注册先后，UIKit 自己也不依赖）；
**`queue` 传 nil 就在发送线程上同步执行**（`Thread.isMainThread = true`）。
倒数第二条那个「状态被覆盖」的断言值得多看一眼：`lastKeys` 在第二次事件（不带 `userInfo`）之后
被刷成空串，`lastObject` 变成 `NSObject`。**回调里往外部变量记状态，每次都会被下一次事件覆盖**，
要判断「这一次有没有带数据」只能在 block 里当场看 `note.userInfo`。

## 22) Mirror 与 runtime：两套反射各管一半，谁也不能替谁

这一节把「Swift 有反射，还要 runtime 干什么」这个常见误解拆掉。
先看那个最容易答错的对照组——**纯 Swift 类在 runtime 里到底存不存在**：

```
== §22 Mirror（Swift 反射）与 runtime（ObjC 反射）各管一半 ==
  Mirror 看 RTSwiftPure：a,b = 1,两
  ok   Swift 的 Mirror 能读出纯 Swift 类的存储属性（a,b）；runtime 那边并不是「彻底查无此人」，而是「只查得到布局、查不到行为」—— 下面把两半边都量出来。
  runtime 看 RTSwiftPure：ivar 2 个（a@16 b@24），方法 0 个，属性 0 个，实例大小 40 字节，父类 = _TtCs12_SwiftObject / _TtCs12_SwiftObject，NSClassFromString("objc_runtime.RTSwiftPure") 查得到 = true
  ok   同一个纯 Swift 类：ivar 表读得到 2 个（连偏移都算得出来，§7 那套 ivar_getOffset 在这也能用），方法表 0 个、属性表 0 个 —— 「runtime 不认识 Swift」这句话的正确版本是：内存布局它是共用的，**消息表才是分家的**。
  ok   NSClassFromString("objc_runtime.RTSwiftPure") = true：连不继承 NSObject 的纯 Swift 类都能按「模块名.类名」反查到，所以查不到的一定是裸类名（§18 那条），不是 Swift 类。
  ok   父类不是 NSObject（_TtCs12_SwiftObject / _TtCs12_SwiftObject）：那串 _TtC 开头的就是 Swift 自己的根类在 runtime 里的原始 mangling，§18 说「普通 Swift 类的名字会被反解成 模块名.类名」，编译器合成的类型不在反解名单里，露出的还是底层的名字。
  ok   同一个文件里的两个类并排看：RTSwiftVisible 是 2 个 ivar + 5 个 ObjC 方法（dynamicTag,exposed,init,plainTag,setExposed:），RTSwiftPure 是 2 个 ivar + 0 个方法 —— 决定「KVC/KVO/swizzle/perform 能不能用」的是那张方法表，而它只在方法写上 @objc 的那一刻才有内容。
  ok   struct 只有 Mirror 能看（x,y）：它连类对象都没有，ObjC runtime 侧完全不存在 —— 所以「拿 KVC 给 struct 批量赋值」这种从 OC 带过来的想法在 Swift 里必须换思路（Codable、手写 init）。
  枚举：无关联值的 .tea -> displayStyle=enum，children 0 个；带关联值的 .point(x:1,y:2) -> children [point=(x: 1, y: 2)]
  ok   无关联值的 case，Mirror 的 children 是 0 个（case 名既不在 label 里也不在 value 里，String(describing:) 才给得到「tea」）：要遍历 case 只能自己声明 CaseIterable（tea,coffee）—— 这是从 OC 的枚举（§5 里 @encode 出来就是个 int，随便拿 KVC 塞进去都行）过来最容易猜错的一点。
  ok   带关联值的 case，Mirror 才给出 point=(x: 1, y: 2)：label 是 case 名，value 是整个元组 —— Swift 的枚举是「带 tag 的 union」，runtime 那一侧连这种类型都表达不了（§5 的类型编码里没有它的位置）。
  ok   CaseIterable 是编译期合成的表（tea,coffee），和 §14 那个「运行期造类」的思路正好相反：Swift 的反射要么编译期就知道（Mirror/CaseIterable），要么根本不给。
  分类型靠 displayStyle，不用猜 children：struct=struct class=class collection=collection enum=enum
  ok   这四种 displayStyle 就是 Mirror 全部的分类能力 —— 它能读值、能分类型，但没有任何写接口，也列不出「这个模块里有哪些类」；反过来 runtime 能列类、能改实现，却看不见 struct/enum/泛型。两套反射各管一半，谁也不能替谁。
  桥接之后再问 runtime：Swift 数组在 `id` 位置上的实际类是 Swift.__SwiftDeferredNSArray，字典是 _TtGCs26_SwiftDeferredNSDictionarySSSi_$
  ok   Swift 的 Array/Dictionary/String 一旦落到 `id` 位置上就变成对应的 Foundation 类（isKind(of: NSArray) = true）：所以 §16 的「copy 之后实际类」那套结论对它们同样成立，而 §12 的 KVC 也能直接作用在一个 Swift 数组上。
  ok   同一个 NSStringFromClass，对泛型类就不反解了：字典的名字是 _TtGCs26_SwiftDeferredNSDictionarySSSi_$（_TtGC…$ 是 Swift 泛形的原始 mangling）—— 崩溃日志里两种名字都会出现，认得前缀才知道哪条路能反解。
  同一个类，两套反射各看到什么：runtime 的属性表 = exposed；Mirror 的 children = swiftStored,exposed
  ok   runtime 只认 @objc 那一个（exposed），Mirror 两个都认（swiftStored,exposed）—— 结论：Swift 侧的通用反射用 Mirror/Codable，要和 UIKit/KVO/xib 打交道的部分才需要 runtime，两边不能互相替代。
```

这一节里最该记住的是**那句被改写的话**。
「纯 Swift 类在 ObjC runtime 里根本不存在」是流传很广的错话，实测结果是：

| 问什么 | `RTSwiftPure`（不继承 NSObject） | `RTSwiftVisible`（继承 NSObject） |
| --- | --- | --- |
| ivar 表 | **2 个**（`a@16 b@24`） | 2 个 |
| 方法表 | **0 个** | 5 个（`dynamicTag,exposed,init,plainTag,setExposed:`） |
| 属性表 | **0 个** | 1 个（只有 `@objc var exposed`） |
| 实例大小 | 40 字节 | 24 字节 |
| `NSClassFromString("模块名.类名")` | **查得到** | 查得到 |
| 父类 | `_TtCs12_SwiftObject`（不是 NSObject） | `NSObject` |

也就是说：**内存布局 runtime 是共用的（它连偏移都算得出来），消息表才是分家的**。
`RTSwiftPure` 的父类那串 `_TtCs12_SwiftObject` 是 Swift 自己的根类的原始 mangling——
§18 说「普通 Swift 类的名字会被反解成 `模块名.类名`」，而编译器合成的类型不在反解名单里。
这个差别在崩溃日志里天天遇到：两种名字都会出现，认得 `_TtC` / `_TtGC…$` 前缀才知道哪条路能反解。

`struct`/`enum`/泛型这三类 runtime 是**真的看不见**（struct 连类对象都没有），
而 Mirror 全能读；反过来 Mirror 没有写接口、列不出「这个模块里有哪些类」、
也永远改不了任何实现。所以两套反射的分工是硬的：

| | Mirror（Swift 反射） | ObjC runtime |
| --- | --- | --- |
| 读任意 Swift 值 | ✅ | ❌（struct/enum/泛型看不见） |
| 分类型（`displayStyle`） | ✅ 四种：struct/class/collection/enum | 只有 class |
| 写值、改实现 | ❌ | ✅ |
| 枚举进程里的类 | ❌ | ✅ |
| 遍历枚举 case | ❌（无关联值的 case `children` 是 **0 个**）——要 `CaseIterable` | ✅（`@encode` 出来就是个整数） |
| 桥接后的 Foundation 类型 | — | ✅（`Array` 落到 `id` 位置变成 `__SwiftDeferredNSArray`） |

枚举那两行是从 OC 转 Swift 的人最容易猜错的：`Mirror(RTSwiftEnum.tea).children` **是 0 个**，
case 名既不在 label 里也不在 value 里，只有 `String(describing:)` 给得到 `tea`；
带关联值的 `.point(x: 1, y: 2)` 才给出 `point=(x: 1, y: 2)`（label 是 case 名，value 是整个元组）。
`CaseIterable` 是**编译期合成的一张表**（`tea,coffee`），和 §14 那个「运行期造类」的思路正好相反：
Swift 的反射要么编译期就知道，要么根本不给。

## 23) 本章的量到的、记下的、留给真机的

```
== §23 本章的边界 ==
  量到了的：选择器唯一性、nil 返回值表、objc_msgSend 家族（含 x86_64 的 stret 分路）、类型编码全表、属性三件套、
            ivar 偏移与直写、关联对象、四级转发顺序、换实现的类级别影响、分类与 +load 顺序、协议的方法描述、
            KVC 候选顺序与集合运算符、KVO 的 isa 换脸与通知时机、内省四问、target-action/delegate/通知、
            copy 的实际类、@try 的匹配规则，以及 Swift 侧的名字（普通类反解成「模块名.类名」，泛型和编译器合成的类型仍是 _TtC/_TtGC…$）、
            @objc vs @objc dynamic 两条调用路径、block 版 KVO（含「不传 options 时 newValue 全是 nil」）、通知中心、Mirror 与 runtime 各管哪一半。
  只能记不跑的（示例一行都没执行，全部来自独立探针进程，正文以「探针记录」引用原文）：
    unrecognized selector、valueForUndefinedKey、给标量键塞 nil、KVO 的四条误用（两参数接口在 iOS 上不存在、
    没实现 observeValueForKeyPath、摘错观察者、重复注册）、分类里加 ivar 的编译错误、钩子自己调自己的无限递归、
    把 void 方法的返回值当对象用（那次侥幸没崩的调用）、objc_msgSend_stret 参数顺序写错。
  真机才量得到的：KVO 在后台线程被 UIKit 观察时的表现、+load 里调 UIKit 引起的死锁、Swift 并发检查下 perform 的告警。
  这本书（第 5/6/7 章）里已经过时的写法，本章一律按今天的规则改写：手工 retain/release/autorelease 计数
    （ARC 之后不该出现，§7 只讲「ARC 会在哪里插哪几条调用」）、两参数 addObserver:forKeyPath:（iOS 上根本没有）、
    把非正式协议当主要手段（今天用 @optional 正式协议，§11）、把「消息转发」和「委托」混为一谈（§8 是 runtime 兜底，§15 是设计约定）。

全部断言通过
==== 27 结束 ====
```

## 本章的诚实边界

```
  1) 架构只覆盖了 x86_64 模拟器。objc_msgSend_stret 只在 x86_64 存在，arm64 的 ABI 没有结构体返回
     专用变体（示例用 #if defined(__x86_64__) 分流，另一支的文字是「本机不是 x86_64」）。
     所以 §3 里 stret 那一组、以及浮点两通道那一条，都只在 x86_64 上量过；换 arm64 真机重跑，
     stret 那几行会整个消失，fpret 的对照也做不了。这是本章最大的一块不确定性，明写在输出里。
  2) 浮点返回值「该走哪个通道」没有量出差别。本机 double/float/long double 三种返回类型
     走 objc_msgSend 与 objc_msgSend_fpret 都给正确值（§3 那一行），所以本章不声称
     「不走 fpret 会读到脏数据」。Apple 单独列出 fpret 这件事本身是有的，但那是 ABI 层的约定，
     在这台机器上不可观测。
  3) 崩溃、递归、死锁一类的结论全部来自独立探针进程，示例一次都没执行它们。
     探针的输出只在「探针记录」那几行里以原文引用，并且刻意把地址写成 0x…、把类名写成 <类名>：
     崩溃日志里的地址本身每次不同，抄进文档就违反判定 4。
  4) 类名里的模块名前缀随 target 变。objc_runtime 这个前缀来自脚本的 -module-name（目录名去掉 27_），
     Xcode 里它就是 Product Module Name。§18/§20/§22 里所有带模块名的字符串
     （objc_runtime.RTSwiftVisible、..NSKVONotifying_objc_runtime.RTKVOHolder）换个工程就会变，
     断言里比的是「形状」（有没有前缀、有没有两个点），不是字面常量。
  5) 版本相关的东西都标了「这一版」：@first/@last 不存在（iOS 18 的 Foundation）、
     tagged pointer 字符串的具体形态、plist 往返后可变性的保留方式、KVO 动态子类的属性表为空，
     都是这台 iPhoneSimulator18.2.sdk 上量到的。换 SDK 请重跑示例，别照抄本章的数字。
  6) 只讲了机制，没讲工程用法。本章不出现任何「所以线上该怎么打补丁」的实现：
     真实的方法替换要考虑线程安全（§9 的换实现是类级别的，随时可能有别的线程正在调）、
     多次加载（同一个类被两个动态库各自 swizzle）、以及 Swift 的 exclusive access 检查。
     §8/§9/§14 三段合起来够读懂别人的 Hook 代码，但要自己写，这些坑本章没覆盖。
  7) ARC 的插入点只提了一句、没有量。书里第 5 章大量篇幅的手工 retain/release/autorelease 计数
     在本章一律不出现；§7 只在关联对象那里说了「谁持有」。ARC 在哪些边界插 retain/autorelease、
     autorelease pool 什么时候真的回收、`__bridge`/`__bridge_retained`/`CFRelease` 的账怎么算，
     本章只在 §7 的 `(char *)(__bridge void *)p` 那里用了一次，没有展开。
  8) Swift 的反射只到 Mirror 的读能力为止。Codable、Property Wrapper、result builder、
     Swift 自己的 metadata（不是 ObjC 类）一律没碰；§22 只回答「runtime 能不能看见 Swift 的东西」
     这一个问题。而 ObjC 侧的 objc_copyClassList / 类枚举那套本章刻意没打数字（判定 1）。
  9) 单线程。本章所有断言都在主线程跑完（§21 那句 Thread.isMainThread = true 就是它的证据），
     所以「消息表的线程安全」「+load 与 dispatch_once 的配合」「KVO 在后台线程的通知时机」
     都没测，也不该由本章的结论去推。
 10) 两处「常见说法」被实测推翻，本章一律按实测写：KVC 的 ivar 候选里 `_isKey` 排在裸 `key`
     前面（§12 用消除法逐档量出来的，不是背文档表格），以及「KVO 会让 isMemberOfClass: 翻脸」
     其实不成立（§14：四问的答案在换脸期间一个字都没变）。
     其中「NSObject 的 -isMemberOfClass: 内部是拿 [self class] 去比对」这一句是对两个实测结果
     （动态子类方法表里没有它 + 答案照常 YES）的最小解释，Foundation 的实现本章读不到源码；
     而「四问都告发不了 KVO、只有 object_getClass 能」是直接量到的，可以放心用。

  一句话：这一章把「一行方法调用在 runtime 层到底是什么」讲透了，
  凡是能打印的都在两种优化级别下各打了一遍并逐字节比对；
  凡是会把进程打死的，只留原文引用，不做结论外推。
```

## 本章要背下来的东西

- **SEL 只是唯一化之后的名字**：`@selector`、`sel_registerName`、`NSSelectorFromString` 三条路得到
  同一个指针，可以直接 `==`；名字里只有标签和冒号，**不含类型**，`setAge:(int)` 和
  `setAge:(NSString *)` 是同一个 SEL；runtime 只登记名字不查实现，所以 `performSelector:`
  拼错照样得到一个合法 SEL。
- **给 nil 发消息不崩，但它给的是 0**：标量 0、指针 nil、BOOL 是 `NO`、结构体全 0。
  三个会咬人的特例——`NSRange.location` 是 **0 而不是 NSNotFound**、
  **`CGAffineTransform` 是全 0 而不是单位矩阵**、`[nil length]` 是 0。
- **`objc_msgSend` 家族按返回类型选**：对象/标量/寄存器小结构体用 `objc_msgSend`；
  x86_64 上大结构体用 `objc_msgSend_stret` 且**返回地址是第一个参数**（写错是硬崩不是脏数据）；
  浮点用 `objc_msgSend_fpret`；`super` 是 `objc_msgSendSuper` 收 `struct objc_super{self, 父类}`。
  **`class_getMethodImplementation` 对不存在的选标返回内部桩而不是 NULL**，「IMP 非空」≠「方法存在」。
- **每个方法都多收 `self` 与 `_cmd` 两个隐藏参数**：编码串里 `@0` 和 `:8` 就是它们的字节偏移；
  一份实现可以挂到多个选标上，靠 `_cmd` 分辨。
- **@encode 字母表**：`c s i q f d D B v` 有符号/浮点、大写 `C S I Q` 无符号；
  `@`=对象、`#`=类、`:`=选标、`@?`=block（≠`^?` 函数指针）、`^{__CFString=}`=CF 类型；
  `NSInteger=q`、`NSUInteger=Q`、`CGFloat=d`、`unichar=S`；方法编码带偏移（`@24@0:8@16`），
  **签名来自方法表而不是声明**，声明未实现的方法签名是 nil——这就是完整转发失败的原因。
- **一个 `@property` = 访存方法 + ivar + 一条属性记录**：编码串里 `T` 是类型 @encode，
  `&`=strong、`C`=copy、`W`=weak、`N`=nonatomic、`R`=readonly、`G`/`S`=改名、`V`=ivar 名；
  block 属性**自动带 `C`**；`strong` 与 `copy` 的差别只在「之后改源对象」才看得见，
  而两者实际类都是 `__NSCFString`，**别拿类名区分它们**。
- **ivar 表给的是真实内存布局**：偏移从 8 开始（isa），`int` 4 字节对齐、指针 8 字节、
  `long double` 16 字节、`CGRect` 32 字节，加起来就是 `class_getInstanceSize`；
  元类 ivar 表是空的（**ObjC 没有类变量**，只能 `static`）；
  `ivar_getOffset` + `(char *)(__bridge void *)p` 能直写内存，但会绕过 weak/copy/KVO/引用计数，
  `object_getIvar` 读标量 ivar 会**当场崩**。
- **分类不能加 ivar，关联对象是官方替代**：key 用 `static const void *k = &k;`（**按指针认**），
  存储是「宿主 + key」两维，`policy` 原始值 0/1/3/769/771 是位域不是序号、**且没有 weak 档**；
  设 nil 等于移除，宿主 dealloc 时整张表被清。
- **消息转发四级，顺序固定**：`+resolveInstanceMethod:`（能现场补方法，
  **`respondsToSelector:` 也会触发它**）→ `forwardingTargetForSelector:`（换对象，
  但原对象 `respondsToSelector:` 仍为 NO）→ `methodSignatureForSelector:` + `forwardInvocation:`
  （唯一能改返回值，`setReturnValue:` 传的是「返回值的地址」）→ `doesNotRecognizeSelector:`。
  拿到签名之后 runtime 还会**再问一次 resolve**；转发钩子**没有跨实例缓存**。
- **换实现是类级别的、编码不跟着换**：`method_exchangeImplementations` 只换 IMP，
  方法记录上的类型编码不动；交换两次等于没交换（补丁方法里靠这个绕回原实现）；
  `method_setImplementation` 的钩子**必须存旧 IMP 直接调**，写 `[self label]` 就是无限递归；
  新建实例照样被钩；只在**同签名**方法之间交换。
- **`+load` 早于 `main`，顺序是「所有类（父先子后）→ 所有分类」**，里面只能登记不能干活；
  **`+initialize` 在第一次收到消息时跑、父类先于子类、只跑一次**，可能重入，别依赖初始化状态。
- **协议的 runtime 视图只回答「允不允许」**：`protocol_copyMethodDescriptionList` 的两个布尔位
  是「required?」×「实例方法?」，**父协议的方法查不到**；协议里的 `@property` 会拆成两个方法描述；
  `class_copyProtocolList` 只列直接采纳，**采纳关系只能靠 `conformsToProtocol:` 问**；
  `@optional` 没实现不报错，**调用前必须 `respondsToSelector:`**；非正式协议（NSObject 分类里声明）
  今天已经没有任何作用。
- **KVC 的候选顺序是实测出来的，不是背文档背来的**：读值先试方法
  `getKey` → `key` → `isKey`，再退到 ivar `_key` → **`_isKey`** → `key` → `isKey`
  （**`_isKey` 在裸 `key` 前面**，这一档最常被漏记），都不中就 `NSUnknownKeyException`；
  写值是 `setKey:` → `_setKey:` → 直接写 ivar；
  `+accessInstanceVariablesDirectly` 返回 NO 会把「静默读到 nil」变成「崩」；
  **集合运算符只在 `valueForKeyPath:` 里认**，`@sum` 返回 `NSDecimalNumber`（别 `==`），
  空数组上 `@avg`/`@min` 是 **nil** 而 `@sum`/`@count` 是 0，**`@first`/`@last` 这一版 iOS 上没实现**；
  to-many 上 KVC 会**广播**（读是 pluck、写是批量赋值）。
- **KVO 的本质是换 isa**：`object_getClass` 看得到 `NSKVONotifying_…`而 `[obj class]` 看不出来
  （动态子类不加属性，自己只覆盖 `_isKVOA class dealloc setCounter:` 四条）；
  **走 setter 才通知**、**不做「值变了才通知」判断**、
  **通知发在 `didChange`**（自定义 setter 靠手动 will/didChange 也能被观察）；
  挂钩按 keyPath 分别建立、**拼错的键路径静默失效**（注册成功、isa 照换，就是收不到）；
  按 `context` 摘干净之后 isa 会恢复。
- **四问各管一件事**：`isKindOfClass:` 含祖先（**判断类型用它**）、`isMemberOfClass:` 只看自己
  （普通子类就会答错，但**KVO 换脸骗不到它**——它内部走的是被一起覆盖掉的 `-class`，
  §14 实测否定了「KVO 会让 isMemberOfClass: 翻脸」这条流行说法）、
  `respondsToSelector:` 问会不会（类方法也继承，
  但只在子类加的方法父类问不到）、`conformsToProtocol:` 问认不认契约；
  `[nil isKindOfClass:X]` 是 NO 不崩。想知道**真 isa** 只有 C 函数 `object_getClass`。
  判断「有没有覆盖」必须用 `class_copyMethodList` 看这一层，`class_getInstanceMethod` 会沿继承链找、永远给你非空。
  运行期造类的硬顺序是 **allocate → addMethod → register**，重名 allocate 返回 nil。
- **target 为 nil 是「点了没反应」而不是崩溃**；action 写错选标 `@selector` 编译得过，
  拦住它的是 `respondsToSelector:`——**删掉这句判断就变成 unrecognized selector**。
  delegate 由**被通知的一方**决定，`delegate == nil` 是常态。
- **可变类的父类就是不可变那个**；`copy`/`mutableCopy` **都新建外层容器**，
  但 `copy` 是**浅拷贝**（内层对象还是同一个）；实际类是 `__NSArrayI`/`__NSDictionaryM`/
  `NSTaggedPointerString` 这些私有类，**只能 `isKindOfClass:` 判断**；
  走一遍 plist 不统一可变性，**每一层都要各自问**。
- **`@try` 的匹配是「具体优先」不是书写顺序**，`@finally` 即使正在往外抛也先跑完，
  `@throw` 能抛任意对象、`@catch` 能按类接，所以 `@catch(NSException *)` 接不住一切；
  没人接就 SIGABRT，而 **Swift 的 `do/catch` 抓不到 ObjC 的 `@throw`**。
- **Swift 类的 ObjC 名是 `模块名.类名`**（前缀来自 `-module-name`/Product Module Name），
  `NSClassFromString("裸类名")` 是 nil —— storyboard/xib 里填类名要填带前缀那串；
  泛型和编译器合成的类型不反解，日志里就是 `_TtCs12_SwiftObject`、`_TtGCs26_…$` 这种原始 mangling。
- **`@objc` 让方法进表、`@objc dynamic` 让调用走消息**：只标 `@objc` 的方法在 Swift 里直接调用
  **绕过 `objc_msgSend`**，换 IMP 换不到它（从 OC 侧进来的那条会换到）；
  `dynamic` 两条路一起换——KVO、swizzle、CoreData 惰性加载要求 `dynamic` 全是因为这个。
- **Swift KVO 的三条硬规矩**：被观察的属性要 `@objc dynamic`；
  **不写 `options: [.new]` 就 `newValue == nil`**（回调明明触发但读不到值）；
  **`observe` 返回的 `NSKeyValueObservation` 必须接住**，丢掉 token 等于没注册。
- **通知的两条解绑规则正好相反**：**block 版 `addObserver(forName:object:queue:using:)` 不会自动解绑**，
  必须自己 `removeObserver(token)`；**selector 版 `addObserver:selector:object:queue:` 会随目标释放自动解绑**。
  过滤只看「名字 + object 指针」，`queue` 传 nil 就在发送线程同步跑，
  多个观察者各收一份且**顺序不保证**；通知名是字符串，一律收成常量。
- **Mirror 管 Swift 类型、runtime 管消息表**：纯 Swift 类**布局共用**（ivar 2 个、偏移都算得出）、
  **消息表分家**（方法 0、属性 0）；`struct` 连类对象都没有；无关联值的 enum case
  `children` 是 0 个（要 `CaseIterable`）；Mirror 只能读、不能写、列不出类清单；
  Swift 的 `Array/Dictionary/String` 落到 `id` 位置上会变成 Foundation 的类，
  §16 那套「copy 之后的实际类」对它们同样成立。

把这一章收拢成一句话：**ObjC 的方法调用就是「按名字找实现」——名字唯一化、实现挂在类的方法表上、
找不到就按四级顺序问、问到了就缓存；类本身也是对象，所以方法表可以运行时改。**
今天的 Swift 只把这条链路开放了一部分（`@objc` 才进表、`dynamic` 才走消息），
但 UIKit、KVC/KVO、xib、CoreData、以及几乎所有「打补丁」的手段仍在这条链路上跑。
所以这一章的判据和前面二十六章一样，只是更硬：**凡是「按理说应该」的机制，
先把它打印出来再说**——本章每一条看起来像常识的结论，背后都是一行实测输出。

下一章把镜头拉回语言交界处的另一侧：**C 语言层与 Swift/OC 互操作**（书本第 4 章）。

---

上一章：[26 SQLite3 与 CoreData](26-sqlite-coredata.md) · 下一章：[28 C 语言层](28-c-layer.md)
