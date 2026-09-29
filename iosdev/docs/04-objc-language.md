# 04 · Objective-C 语言基础

> 示例：`examples/04_objc_language/`（`Person.h/.m`、`Speaker.h`、`main.m`）
> 实测输出见 `build/04_objc_language/stdout.debug.txt`

iOS 的新代码几乎都是 Swift，但 **Objective-C 绕不开**：

- UIKit / Foundation 的**底层全是 OC**，报错信息里到处是 `-[UIView setFrame:]` 这种 OC 签名；
- 海量**存量项目和第三方库**是 OC 写的；
- Swift 与 OC 的**互操作规则**（`@objc`、`NSObject` 子类、`NS_ASSUME_NONNULL`）只有懂 OC 才理解得了（第 07 章）。

本章用 OC 把语言核心讲透，顺序和第 28 章讲 C 时一样：**先把地基的宽度量出来，再往上盖**。
这本书的第 2 章（数据类型和运算符）、第 3 章（控制语句）就是这块地基，但它是十多年前写的：
里面说 `int` 是「机器字长」、说 `long` 是 64 位而 `int` 是 32 位却同时告诉你 `NSInteger` 就是 `int`、
把「`count` 转成 `BOOL` 会变 0」当成今天的坑来讲。这三条在 2026 年的工具链上都要重测。
所以 §1~§3 全部是量出来的，而不是背出来的。

示例是**纯 Objective-C**（`clang` 编译，不掺 Swift），一次 `clang -O2 -std=gnu11 -fobjc-arc -fmodules
-Wall -Wextra` 编 `Person.m` 与 `main.m` 两个文件，链 Foundation + UIKit，
在模拟器里以 `--selftest` 跑完退出。全章 126 条断言，一条 `FAIL` 都没有。

## 本章的方法：「释放」这件看不见的事怎么变成数字

`main.m` 顶部有三个小道具，本章后面一半的断言都靠它们：

- **`MXCounted`**：一个只有几个属性和 `-dealloc` 的类。每次 `alloc/init` 让文件级计数 `gAlive += 1`，
  `-dealloc` 里 `gAlive -= 1`。于是**对象到底解没释放、什么时候解的**第一次变成可断言的数字。
  §10 的 strong/weak/循环引用/池子排空全靠它。
- **`MXBlockOwner`**：持有一个 `copy` 的 block，并在 `-dealloc` 里把那个 block 调一次。
  block 跑没跑 = 对象解没解，这是 §10 结尾那组「捕获 self vs weak-strong dance」的对照组设计。
- **`MXTapioca`**：自己实现 `NSFastEnumeration`，每批只交 2 个元素，并且把**每次被回调的批次大小记进数组**。
  §3 里「for-in 就是 `countByEnumeratingWithState:objects:count:` 的语法糖」这句话因此有了数字。

另外三条硬约束和别的章一样：**不 `NSLog`**（它写 stderr，会破坏「stderr 必须为空」的判定），
**不打印任何指针值 / 地址 / 环境相关数字**（类名可以打，地址不行；`sizeToFit` 的宽度只断言大小关系，不打印），
**会崩的调用只在独立探针里跑**，原文收在 §14 的「探针记录」里。

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

**属性修饰符**（这张表要记牢，§5 和 §10 各量了它一半）：

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
> 从此互不影响。示例第 5 节实测了这一点，而 §2 量出了更深的一层：**类型上根本问不出可不可变**。

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

## 1) 数据类型：宽度是量的，BOOL 只有一个字节，「空」有四种写法

### 1.1 标量宽度

```
这台机器上的宽度：char=1 short=2 int=4 long=8 long long=8 float=4 double=8 BOOL=1 void *=8
  ok   NSInteger 就是 long 的别名（本机 sizeof=8）：写 OC 时凡是「计数、下标、长度」都用它，别用 int
  ok   NSUInteger 与 NSInteger 同宽（8）；64 位上 CGFloat 就是 double（8）—— 所以 .length 用 %lu + (unsigned long)，%d 是错的
  ok   NSInteger(8) != int(4)：这就是 28 章 §18 里 C 的 int 进 Swift 变 Int32、而 Swift 的 Int 对应 long 的同一个 lp64 数据模型
  ok   BOOL 的 sizeof = 1：它是 signed char，不是一个 bit，也不是 C99 的 _Bool
```

这一行就是本章的「地基验收单」。要背的结论只有三条：

1. **`NSInteger` = `long`（8 字节），不是 `int`（4 字节）**。书里那句「`NSInteger` 就是整数」害人不浅：
   它跟着指针宽度走，在 64 位设备/模拟器上都是 8。凡是「计数、下标、长度」一律用它。
2. **`CGFloat` 在 64 位上就是 `double`**。所以 §13 里 `label.frame.size.width` 是 `double`，
   而 CoreGraphics 的头文件在 32 位时代曾是 `float` —— 这就是当年一堆精度 bug 的来源。
3. **格式符要跟宽度配套**：`NSInteger` → `%ld` + `(long)`；`NSUInteger`（`.length`、`.count`）→ `%lu` +
   `(unsigned long)`；对象 → `%@`；C 字符串 → `%s`；`CGFloat`/`double` → `%f`。写错不报错，只出乱码（第 05 章专门量过一次）。

这条也和第 28 章接上了：C 的 `int` 进 Swift 变 `Int32`、C 的 `long` 变 `Int`，
**同一个 lp64 数据模型**在两边给出同一个答案。

### 1.2 `BOOL` 到底是什么，以及书上那条老 bug 今天还成不成立

```
整数变 BOOL 的三条路，输入都是 256：显式 (BOOL)count = 1、方法 return count = 1、赋给 BOOL 属性再读回 = 1；输入 -1 时显式转换 = 1
  ok   书上那条「count=256 转成 BOOL 会变成 0」的老 bug，在这台 clang/ARC 上量不出来了：三条路都把非零规整成了 1（编译器插了一次 !=0 归一化）
  ok   -1 也是真：ARC 下的 BOOL 转换是「非零即 1」，不是「取低 8 位」
  ok   但结论别用反：BOOL 仍然只有 1 字节宽，转换规整是**编译器行为**、不是语言保证（C 侧的 _Bool 才有「非零变 1」的正规说法）。把 count 直接当 BOOL 返回仍然是坏写法 —— 正确的写法永远是下面这条
  ok   (BOOL)(count != 0)：先比较再返回，任何工具链上都稳定
```

这是本章**推翻教材**的一条。老话是：`BOOL` 是 `signed char`，只有 1 个字节，
所以 `- (BOOL)isValid { return self.items.count; }` 在 `count == 256` 时会截成 0（假）。
今天这台 clang 16 + ARC 上，三条转换路径（显式 `(BOOL)count`、方法里 `return count`、赋给 `BOOL` 属性）
**全部给出 1**，`-1` 也给 1 —— 编译器在整数和 `BOOL` 之间插了一次「`!= 0` 归一化」。

那还要不要改？**要。** 三个理由，按分量排：

- `BOOL` 仍然只有 1 字节宽（上面刚量过），这个归一是**编译器实现行为**，语言层面没写；
  C99 的 `_Bool` 才有「非零变 1」的正规说法。换工具链、换语言模式，规整不一定在。
- 代码会被别人读。`return count;` 出现在返回 `BOOL` 的方法里，读者要停下来想一想 —— 这就是坏写法。
- `(BOOL)(count != 0)`（或者直接 `count > 0`）在任何工具链上都稳定，长度和 `BOOL` 一样是一行。

结论：**书上的坑已经修好了，但修它的方式不该是「靠编译器」**。

### 1.3 字面量的默认类型与三种进制

```
sizeof(56)=4（装得进 int 就是 int）、sizeof(9999999999999)=8（十进制大常数一路往上找：int->long->long long）、sizeof(0xFFFFFFFF)=4（十六进制允许 unsigned，所以停在 unsigned int）、sizeof(56u)=4、sizeof(56L)=8
  ok   大整数字面量默认是 64 位：赋给 int 会静默截断（编译器诊断见本章末尾的探针记录）
  ok   浮点字面量默认是 double：1.5 占 8 字节，写 1.5f 才是 float —— CGFloat 属性上写 1.5 没事，写成 float 变量就要吃一次隐式窄化
  ok   `float f = 0.1;` 一声不响（-Wall -Wextra 零诊断，见本章末尾探针），但值已经变了：float 读回 double 是 0.10000000149011612，字面量本身是 0.10000000000000001 —— 差在第 8 位有效数字上，单精度只有 6~7 位可靠
050 是八进制 = 40（不是 50！）、0177 是八进制 = 127、0xFF 是十六进制 = 255；同一个十进制 40 的五种打法：%d=40 %o=50 %#o=050 %x=28 %#x=0x28
  ok   前导 0 就是八进制：`050` 是 40 不是 50 —— 这是 OC/C 里最难查的笔误之一（`0xFF` 才是十六进制）
  ok   0b 开头的二进制字面量是 clang 扩展，标准 C11 没有（写进跨编译器头文件时要小心）
```

三条要点：

- **整数常量的类型是「第一个装得下它的类型」**，而且十进制和十六进制的候选表不一样：
  十进制只在 `int → long → long long` 里找（全是有符号），十六进制额外允许 `unsigned int`，
  所以 `0xFFFFFFFF` 停在 4 字节，而 `9999999999999` 直接到 8 字节。这一条决定了它传给可变参数函数、
  赋给窄变量时到底丢不丢东西。
- **浮点字面量默认 `double`**。`float f = 0.1;` 在 `-Wall -Wextra` 下**一个诊断都没有**（探针 13 记了这条），
  但值已经在第 8 位有效数字上变了。工程后果：几何、动画、传感器数值用 `CGFloat`/`double`，
  只有和 C API/图形缓冲区打交道时才用 `float`，并且**别拿 `float` 和字面量比相等**。
- **前导 0 是八进制**。`050` 是 40。这个笔误在颜色值、权限位、超时秒数里都出现过，而它编译得过、跑得起来、
  只是数值不对。书里用 `%o` / `%#o` 展示进制，本例把 `%d %o %#o %x %#x` 五列并排打出来，
  就是为了让你看清「同一个数在不同格式符下长什么样」。

### 1.4 四种「空」

```
  ok   nil、Nil、NULL 是同一个值 ((void *)0) 的三个拼写：nil 给对象指针、Nil 给类对象、NULL 给 C 指针
  ok   给 nil 发消息不执行也不崩，NSString *.length 得到 0（这是 OC 省掉满屏判空的原因，返回值全表见 27 章 §2）
  ok   [NSNull null] 是一个真实存在的对象，跟 nil 不是一回事：它专门用来填进集合里代表「这里有个位置，但没有值」
  ok   数组里放 NSNull：count=3，第二格取出来是 NSNull 这个类（不是 nil）—— 因为集合根本不收 nil：往 NSMutableArray 里 addObject:nil 会抛异常（下面 §3 的 @try 里接住了一次，原文打进输出）
  ok   字面量 @[@1, nil] 连编译都过不去（诊断见本章末尾），运行时抛的是 addObject: 那一条：nil 洞只能拿 NSNull 填
```

`nil` / `Nil` / `NULL` **值是同一个**（`((void *)0)`），区别只在「写给谁用」：对象指针、类对象、C 指针。
这一条很多人背错，觉得它们是三种不同的东西。真正独立的是第四个：**`NSNull` 是一个真实对象**。
它存在的唯一理由就是本节下面这两句话：

- 集合**不收 nil**：`@[ @1, nil ]` 连编译都过不去（探针 8），`[arr addObject:nil]` 运行时抛
  `NSInvalidArgumentException`（§3 里用 `@try` 真的接住了一次，原文在输出里）；
- 于是 JSON 里那个 `null`（第 05 章）落进 `NSArray`/`NSDictionary` 时，Foundation 只能给你一个
  占位对象 —— 那就是 `[NSNull null]`。取到它不等于取到「没有」，得**显式问** `[x isKindOfClass:[NSNull class]]`。

### 1.5 `@()` 装箱出来的类，和字符串的三个类

```
  ok   @(...) 就是 NSNumber 字面量：@42 -> 42（类名 NSConstantIntegerNumber）、@(3.5).doubleValue=3.5、@(YES).boolValue=真
同为 NSNumber，四种造法的类名全不一样：@42=NSConstantIntegerNumber、[NSNumber numberWithInt:42]=__NSCFNumber、@(3.5)=NSConstantDoubleNumber、@(YES)=__NSCFBoolean
  ok   同样是 42，@42 和 [NSNumber numberWithInt:] 是两个不同的对象（!=），但内容相等（isEqual:）：类名不同 + 对象不同，都在提醒一件事 —— 类的真身是私有实现，只能问 isKindOfClass:，绝不能拿 [x class] == [Y class] 当身份判断
  ok   不管类名叫什么，isKindOfClass:[NSNumber class] 都为真：这才是该用的判断
  ok   容器字面量 @[] / @{} / @() 全是 Foundation 对象的语法糖，没有新类型：@[@1] 就是一个 NSArray
同一个内容三个类：@"abc" 是 __NSCFConstantString，拼出来的短串 "abc" 是 NSTaggedPointerString，拼出来的长串是 __NSCFString
  ok   内容相等（isEqual: 这条路径）
  ok   字面量在编译期落进常量池（__NSCFConstantString），运行时拼出来的短串走 NSTaggedPointerString（指针本身就编码了内容，见下面 §2 的 `==`），长串才是堆上的 __NSCFString —— 内容一样的字符串有三个不同的类
```

这段是本章给「类名」这件事上的第一课。**同样一个 42，四种造法给出四个不同的类名**：
`NSConstantIntegerNumber` / `__NSCFNumber` / `NSConstantDoubleNumber` / `__NSCFBoolean`。
一个字符串内容，三个类名：常量池的、tagged pointer 的、堆上的。

工程规则从这两行里长出来：

1. **判断类型只用 `isKindOfClass:`**，永远不要 `if ([x class] == [NSString class])`，
   更不要拿 `NSStringFromClass` 的返回值去比字符串 —— 那四个类名都是私有实现，
   换一个系统版本就可能变（§14 的「换机器会变的东西」专门记了这一条）。
2. **别以为字面量便宜**：`@42` 每次都是一个新的装箱对象（这条实测在 §2 的第一行，`@42 != @42` 的那个分支）。
   高频循环里拿 `NSNumber` 当计数器，代价是每次一次对象分配。

### 1.6 枚举与结构体

```
裸 enum MXPlainColor{{1,2,4}} 的 sizeof = 4；NS_ENUM(NSInteger, MXLevel) 的 sizeof = 8；NS_OPTIONS(NSUInteger, MXFeature) 的 sizeof = 8
  ok   NS_ENUM 把底类型写死成 NSInteger（本机 8 字节）—— 28 章 §9 量了「裸 enum 的底类型编译器自己挑」，NS_ENUM/NS_OPTIONS 就是为了不再让它挑
  ok   NS_OPTIONS 是位标志：用 | 合起来、用 & 问开没开；拿 == 问「等于这一组」会漏掉组合，C 枚举不检查组合是否合法（28 章 §9 实测）
  ok   NS_ENUM 的值就是整数，可以显式给也可以顺延
  ok   结构体赋值是整块拷贝（sizeof(NSRange)=16）：改了副本，原件不动 —— 和对象赋值（只拷指针，见 §5）正好相反，这是 OC 里唯一已有的值语义
```

`NS_ENUM` / `NS_OPTIONS` 不是「打字少一点」的宏。第 28 章 §9 已经量过：裸 `enum` 的底类型
（有没有符号、多宽）是编译器自己挑的，而且**挑的结果会传到 Swift 那边去**（`CLColor.rawValue` 变成
`UInt32` 就是这么来的）。`NS_ENUM(NSInteger, …)` 的全部意义就是**把底类型写死**，
让 Swift 敢把它翻成真正的 `enum`、让 `NS_OPTIONS` 翻成 `OptionSet`。今天写 OC 头文件，
裸 `enum` 一个都不该留。

`NS_OPTIONS` 的用法两条：合起来用 `|`，问开没开用 `& …  != 0`。
**不要**写 `if (features == MXFeatureDark)` 来问「开了暗色吗」—— 那是问「只开了暗色」。

最后那条结构体是本章埋的伏笔：`NSRange` / `CGPoint` / `CGRect` 是 C 结构体（28 章 §7），
**赋值 = 整块拷贝**；对象**赋值 = 只拷指针**。Swift 的「值类型 vs 引用类型」这条分界，
OC 早就有，只是它藏在类型系统外面，得靠你看右边的写法是 `NSRange` 还是 `Person *`。

## 2) 运算符：三处会咬人的地方

### 2.1 算术、自增、优先级、位运算

```
  ok   整数除法是「截断」不是「四舍五入」：7/2=3、7%2=1
  ok   负数除法向零取整、余数跟着被除数的符号：-7/2=-3、-7%2=-1（28 章 §1 在 C 里量过同一条，Swift 的 / 和 % 也一样 —— 向下取整那套是 Python）
  ok   两边只要有一个是浮点就走浮点除法：先 (double) 再除，或者把一边写成 2.0
  ok   先除后乘会把 7 变成 6：`count / pageSize * pageSize` 这种「算回去」的写法一定丢精度，顺序换成先乘后除
  ok   i++ 交的是旧值（5）、++i 交的是新值（7）：两个都写在一行里就是自伤，表达式里只用 ++i 或直接分成两句
  ok   * 比 + 先绑定：括号不要省
  ok   位运算的优先级反直觉：& 比 | 紧，所以 4|2&1 其实是 4|(2&1)=4（想要「先合再掩」的那个数是 0）
  ok   移位的优先级比 + 还低：1+2<<2 其实是 (1+2)<<2=12，不是 1+(2<<2)=9
      上面两条「不写括号」的原式 clang 都会警告（-Wbitwise-op-parentheses / -Wshift-op-parentheses），所以这里必须带括号写；诊断原文见本章末尾的探针记录
  ok   1u << 31 = 2147483648（无符号才安全），同一个位模式当 int 读就是 -2147483648：标志位一律用无符号底
  ok   负数右移这台机器上是算术移位（-8>>1=-4，符号位复制）：标准只说「实现定义」，可移植的代码先转无符号再移
  ok   CHAR_BIT=8，sizeof(int)*CHAR_BIT = 32 位：范围是 2^31-1 = 2147483647
```

值得单独说的四条：

- **`7/2*2 == 6`**。「先除后乘」是分页、网格、缩放这类代码里最常见的精度事故。
  顺序换成 `7*2/2` 才对，或者一开始就用 `double`。
- **位运算和移位的优先级比算术运算低**，而且是**反着**人的直觉：`4 | 2 & 1` 不是「先合再掩」。
  好消息是这三条 clang 全部会警告（探针 1 抄了原文），所以「写着别扭」会被编译器当场抓住 ——
  本章示例为了不污染编译日志，必须带括号写，正文里那两条式子于是长得不漂亮，但结论是真的。
- **`1 << 31` 是坑，`1u << 31` 才是标志位**。有符号数左移进符号位在标准里是未定义行为，
  而 `int` 读那个位模式就是 `-2147483648`。这就是 `NS_OPTIONS` 一律用 `NSUInteger` 底类型的原因。
- **负数右是实现定义**。这台机器是算术移位（符号位复制），但可移植的写法是先转无符号再移。

### 2.2 短路不是「大概」，是数出来的

```
    && 短路：左半边为假时右半边根本不跑（下面只有一行日志）
      求值了 && 的左边（假）
  ok   && 只求了 1 次边（实测 sideEffects=1）：左边已经假了，右边连求值都不会发生
    || 短路：左半边为真时右半边根本不跑
      求值了 || 的左边（真）
  ok   || 只求了 1 次边（实测 sideEffects=1）：把便宜的条件放左边、贵的放右边，短路就是免费的性能
      求值了 &（不是 &&）的左边（假）
      求值了 & 的右边
  ok   单个 & 不短路：两边都求了值（实测 sideEffects=2）—— 布尔逻辑用 &&，& 只留给位运算
  ok   三目 ?: 也是表达式，能直接返回字符串对象；别写成嵌套 if 再声明一个 __block 变量
  ok   三目可以嵌套但两层就到头了：第三层开始就该写 if/else（可读性问题，不是语法问题）
```

这段的写法值得学一下：短路这种「看不见」的语义，靠**让每一次求值都加一下计数器并打一行**来证明。
`&&`/`||` 各只求值 1 次、`&` 求值 2 次，日志行数就是证据。
两个可以直接抄进工作的结论：

- **顺序有性能含义**：把便宜的条件（比整数、判 nil）放左边，贵的（查表、算字符串）放右边。
- **`if (x != nil && [x length] > 0)`** 这种链之所以安全，完全是短路的功劳 —— 反过来说，
  一旦有人把 `&&` 写成 `&`，右边就会在不该执行的时候执行。这条改动**编译器不警告**（除非像探针里那样两边都是布尔字面量）。

### 2.3 对象不能拿 `==` 比内容 —— 而它**常常**是对的

```
五组「内容相同」的字符串，左边是 `==`（比指针），右边是 `isEqual:`（比内容）：
      字面量 vs 字面量        ：== 对、isEqual: 对
      字面量 vs 拼出的短串    ：== 错、isEqual: 对
      拼出的短串 vs 拼出的短串：== 对、isEqual: 对
      拼出的长串 vs 拼出的长串：== 错、isEqual: 对
      长字面量 vs 拼出的长串  ：== 错、isEqual: 对
  ok   这就是 `==` 比内容最危险的地方：它不是永远错，而是**看长度和存储方式碰运气** —— 字面量在常量池里被合并（对），短 ASCII 串走 tagged pointer、指针本身就编码了内容（也对），长串在堆上是两个对象（错）
  ok   isEqual: 五组全对：它比的是内容，跟对象怎么存、存在哪无关。字符串用 isEqualToString:，其它对象用 isEqual:
  ok   isEqual: 成立的对象 hash 必须相等（反过来不要求）：NSSet / NSDictionary 的键就是靠 hash + isEqual: 两步找到的，所以拿可变对象当键会出事（05 章实测）
  ok   __NSCFString 和 NSTaggedPointerString 都 isKindOfClass:NSString（可变与不可变是同一个类簇的两个分支），所以类型问不出「它可不可变」—— 想挡住外部改动只有一条路：属性写 copy（§5 实测）
  ok   NSNumber 比内容用 isEqual: / 比大小用 compare:，不是 ==：`@1 + @2` 更是根本编译不过（编译器诊断见本章末尾）
  ok   集合的 isEqual: 是逐个元素比：NSArray 看顺序（反过来就不等），NSSet 不看顺序
```

这张表是本章最有用的产出。「**别用 `==` 比对象内容**」这句正确的口诀，
理由经常被讲错成「因为 `==` 永远比指针，所以永远不对」。**它不是永远错**：

- 两个字面量 `@"abc" == @"abc"` → **对**（编译期常量池合并成同一个对象）；
- 两个运行时拼出来的短 ASCII 串 → **也对**（tagged pointer：内容直接编在指针值里，所以两个「不同对象」的指针值相同）；
- 长串 → **错**（堆上两个对象）；字面量 vs 拼出来的 → **错**。

于是真正的规则更硬：**结果取决于字符串的长度和存储方式**。一段今天全对的代码，
把测试数据从 `"abc"` 换成 `"abcdefghij"` 就开始挂 —— 这比「永远错」危险得多，
因为永远错的东西没人会去用。

顺带三条：

- `isEqual:` 成立 ⇒ `hash` 相等（反向不要求）。`NSSet`/`NSDictionary` 找键是「先按 hash 分桶、再 `isEqual:` 确认」，
  所以**拿可变对象当字典的键**会在你改了它之后再也查不到 —— 第 05 章实测这条。
- 可变与不可变是**同一个类簇的两个分支**：`NSMutableString` 实例 `isKindOfClass:[NSString class]]` 为真。
  所以「它可不可变」在类型上问不出来，只能在**赋值那一刻**用 `copy` 挡住（§5 实测）。
- 集合的 `isEqual:` 是逐元素比：`NSArray` 看顺序，`NSSet` 不看。断言里想比两个数组，
  用 `isEqualToArray:`（或直接 `isEqual:`），别自己拼字符串比。

## 3) 控制语句：C 的那套全都在，OC 另加两样

### 3.1 分支

```
  ok   if / else if 链从上往下第一个成立的就走它，后面的判断根本不发生：条件顺序就是优先级
  ok   一层判断用三目，别写四行 if/else
  ok   switch 只能分支整型（枚举底层就是整型，见 §1）：case 值必须是编译期常量
  ok   少写一个 break 就顺着掉下去：28 章 §2 量过这台机器的 clang 只认 __attribute__((fallthrough))，五种「// fall through」注释写法都还会警告
```

`switch` 的两条硬限制用探针各钉了一次：

- **只能分支整型**。`switch (someNSString)` 直接是编译错误
  （`statement requires expression of integer type ('NSString *__strong' invalid)`，探针 3）。
  所以 OC 里没有「按字符串分支」的语法，要么 `if/else if` + `isEqual:`，要么先把字符串映射成枚举。
- **`case` 值必须是编译期常量**，不能是范围（GNU 扩展的 `case 1 ... 9:` 除外，别写进要跨编译器的代码）。

掉 `break` 那一整块（`-Wimplicit-fallthrough` 到底什么时候响、什么写法才压得住）在第 28 章 §2
量得最细，本章只把「OC 完全继承这一套」这句钉住。

### 3.2 循环与 for-in 的真面目

```
  ok   for / while / do-while 三种写法算出同一个和（10）：OC 的循环完全继承 C 的那套（逐条对照见 28 章 §2），唯一的区别是 do-while 无条件先跑一次
  ok   do{...}while(NO) 也跑了一次：条件是「跑完再看」
      每批交付的个数记下来是 2、2、1、0（共回调 4 次）
  ok   for-in 遍历自造容器：拿到 5 个元素、和=15，协议方法被回调 4 次 —— 5 个元素按每批 2 个交付就是 2、2、1，之后再被问一次、交 0 个表示结束。for-in 就是 countByEnumeratingWithState:objects:count: 的语法糖，一次一批不是一次一个
  ok   enumerateObjectsUsingBlock: 给到 index 和一个 *stop 开关；把 *stop 置 YES 就中断，等效于 break
  ok   *stop 只是让这一轮枚举提前收尾，容器本身没动过
  ok   for-in 遍历 NSDictionary 拿到的是键（3 个），值要自己取：和=119
  ok   字典的遍历顺序不保证：只能断言「集合相同」，绝不能断言「第一个是谁」—— 依赖顺序的写法会在下一次系统升级里坏掉
  ok   对 nil 做 for-in 不崩、一次都不进（nil 的 countByEnumerating... 消息落到 nil 上返回 0）：省掉判空
```

`for-in` 这一节是本章给「语法糖」三个字的第一次**数字化**。`MXTapioca` 只有 5 个元素，
每批只交 2 个，实测输出把批次序列原样打了出来：**2、2、1、0，一共回调 4 次**。
所以：

- `for (X *x in coll)` 不是一次一个，是**一次一批**（默认批大小由系统给的 `buffer` 决定）；
- 最后一次调用返回 0 才算结束；
- 想自己写可枚举的类，要实现的是 `countByEnumeratingWithState:objects:count:`，
  而不是「一个 next 方法」。

三条工程结论：

1. **`enumerateObjectsUsingBlock:` 只多给两样**：`idx` 和 `*stop`。要序号或要中断就用它，否则 for-in 更短。
2. **字典的遍历顺序不保证**。示例的断言因此写成「取到的键组成的**集合**等于全部键」，
   绝不写成「第一个是谁」。凡是依赖字典顺序的 UI/报表代码，都要在中间插一个显式的排序步骤。
3. **对 `nil` 做 for-in 安全**（一次都不进）—— 这一条省掉了满屏的判空。
   但注意：`for (NSNumber *n in nil)` 直接写 `nil` 是**编译错误**（探针 7：
   `the type 'void *' is not a pointer to a fast-enumerable object`），得有个变量。
   「运行时安全」和「编译期可写」是两件不同的事，本章后面还会撞见几次。

### 3.3 `@autoreleasepool` 与 `@try`

```
  ok   @autoreleasepool { } 就是一个作用域块，顺序执行，没有别的魔法
  ok   @throw 之后同一个块里剩下的语句全部跳过：@catch 接手（拿到的是那个 NSException 对象），@finally 无论如何都跑，然后从 @try 之后继续往下走
      实际接到的那一条：catch：name=MXDemo reason=故意抛一个
      对照一条量不得的：整数除零（10/0）不是 NSException，它是硬件陷阱，@catch 接不住，进程当场就没（探针记录见本章末尾）
  ok   这一条就是 §1 那个 NSNull 的存在理由：数组放不下 nil，只能放一个「代表没有」的对象
  ok   裸写 `@throw;` 是「原样重抛当前这个异常」，不再新建对象：外层接到的还是同一个 NSException（name 一点没变）。异常匹配规则（谁写得具体谁先接）细节在 27 章 §17
      抛与接的顺序记录：内层 try -> 内层 catch MXInner -> 内层 finally -> 外层 catch MXInner
      但工程规则是：日常不用 @try 挡错误。可预期的失败走 NSError **（§11），不可恢复的才让它崩；OC 的异常不保证在 ARC 下不泄漏中间对象，所以第三方库里通常只用来兜底
```

`@try` 的顺序用一根 `trail` 数组记录，实测就是 `try -> catch -> finally`、嵌套时
`内层 try -> 内层 catch -> 内层 finally -> 外层 catch`。这些语法本身不难，难的是两条边界：

- **`@catch` 只能接住 OC 对象异常**。§1 那个 `addObject:nil` 抛的是 `NSInvalidArgumentException`，接得住；
  而**整数除零是硬件陷阱**，探针 14 的原文是 `Child process terminated with signal 8: Floating point exception`
  （退出码 136），前面那行日志根本没打出来 —— 不是异常，`@catch` 与它无关。
  同样的还有空指针解引用（signal 11）。**别指望用 `@try` 把崩溃兜住**。
- **能接住不等于该接**。`unrecognized selector`（探针 15）也能被 `@catch` 接住，
  但接住就等于把一个「类型写错了」的 bug 藏起来。日常规则仍然是一条：
  **可预期的失败走 `BOOL` + `NSError **`（§11），不可恢复的才让它崩**。
  异常在今天的 OC 里主要是兜底工具 —— 以及读懂别人旧代码时的一个考点。

`@autoreleasepool { }` 的**内存语义**在 §10 量，这里只把它当语法看完：它是一个作用域块，
顺序执行，没有别的魔法。

## 4) 消息发送：OC 的灵魂

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
  ok   实例方法返回正确字符串
  ok   doubleAge 返回 72
  ok   给 nil 发返回标量的消息得到 0（不崩）
  ok   给 nil 发返回对象的消息得到 nil（不崩）
  ok   readonly 属性给 nil 也是 0
  nil 返回结构体：location=0（未定义，别用）
  ok   知道「nil 返回结构体不可靠」这条规则本身
```

> **坑**：返回**结构体**（`NSRange`/`CGRect`/`CGPoint`）时，nil 消息给的是未定义值。
> 别写 `NSRange r = [maybeNil someRange]; if (r.length == 0) …` 这种依赖它的逻辑。
> 这条「nil 消息安全」既是便利（省掉大量判空），也是陷阱（bug 被静默吞掉）。
> 返回值按类型分的完整表在 27 章 §2，那里连「返回 `long double`」「返回 `_Complex`」都量了。

还有一件事本章先记一笔，27 章 §8 会拆开：**发不出去的消息不会立刻失败**。
运行时还有「动态方法解析 → 消息转发 → `forwardingTargetForSelector:` → …」四级台阶，
最后才抛 `unrecognized selector`（探针 15 的调用栈里那行 `___forwarding___` 就是它）。

## 5) 属性与点语法

点语法 `p.age` 只是 `[p age]` / `[p setAge:]` 的**语法糖**，本质还是发消息：

```objc
p.age = 40;          // == [p setAge:40]
NSInteger a = p.age; // == [p age]
```

```
  ok   点语法写属性生效
  ok   点语法读 = getter 方法调用
  ok   readonly 计算属性 lengthOfName = 3
  ok   copy 属性不受原可变串后续修改影响
  ok   @property 在运行时其实就是三条东西：一个 ivar、一个 getter、一个 setter（方法表细节见 27 章 §6）
  ok   readonly 属性根本没有 setter：`q.lengthOfName = 3` 编译不过，但 `[q setLengthOfName:]` 在 id 上调用编译期不报错、运行时崩（探针记录见本章末尾）
  ok   对象赋值拷的是指针：改 sameAsQ 就是改 q 本身。结构体赋值拷的是整块内存（§1），两者完全不同 —— Swift 里「值类型 vs 引用类型」这条分界，OC 早就有了，只是藏在类型系统外面
  ok   同一个 init、同一个 36：走 ivar（init 里）得到 36，走 setter（外部赋值）得到 72 —— 「init 里必须写 _ivar」不是风格问题，是因为子类随时可能重写 setter
```

最后两条是这一节新加的**证据**，不是复述规矩。

**`readonly` 只生成 getter。** 用 `respondsToSelector:@selector(setLengthOfName:)` 一问就知道：没有。
所以 `q.lengthOfName = 3` 是编译错误（探针 5：`assignment to readonly property`）。
但如果对象是 `id`，`[someId setLengthOfName:@1]` 编译期**一声不响**，运行时才炸成
`unrecognized selector`（探针 15）—— 这一对在 §3.2 已经出现过一次：
「运行时安全」和「编译期可写」是两回事。

**`init` 里写 `_ivar` 而不是 `self.xxx =`，是有数字的。** 示例造了个坏孩子子类：

```objc
@interface MXSetterTwists : Person
@end
@implementation MXSetterTwists
- (void)setAge:(NSInteger)age {
    super.age = age * 2;      // 走 super 的 setter，别写成 self.age = …（那是无限递归）
}
@end
```

`Person` 的 init 里写的是 `_age = age;`，所以 `initWithName:@"Ada" age:36` 得到 **36**；
而外面 `twist.age = 36` 走 setter，得到 **72**。同一个类、同一个值、两个结果。
这就是「铁律」的实证：init 期间你无法知道 `self` 的真实类是什么，
而**子类随时可能重写那个 setter**。四步构造器写法因此不是风格：

```objc
- (instancetype)initWithName:(NSString *)name age:(NSInteger)age {
    self = [super init];              // ① 先让父类初始化
    if (self == nil) return nil;      // ② 判空（父类可能失败）
    _name = [name copy];              // ③ 直接写 ivar（此时对象还没完全就绪，别调 setter）
    _age = age;
    return self;                      // ④ 返回 self
}
```

`copy` 语义那一条（给可变串，属性拷一份，之后原串再改也不影响）实测通过，
而 §2.3 已经说明了它为什么**必须**存在：可变与不可变在类型上问不出来。

## 6) id / SEL / 动态性

OC 是**动态语言**：类型检查很多发生在运行时。

- **`id`** = 「任意对象指针」（本身就是指针，不写星号）。`id obj = p;`
- **`SEL`** = 方法名的运行时表示，用 `@selector(greeting)` 得到。
- **`Class`** = 类对象本身，用 `[Person class]` 得到。

```
  ok   isKindOfClass: 运行时判类型
  ok   respondsToSelector: 问对象会不会这个方法
  ok   performSelector: 动态调用（pragma 局部静音泄漏告警）
  whisper = （Ada 小声说）
  ok   @optional 方法先 respondsToSelector: 再调
```

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

**`@optional` 协议方法调用前必须先问**（否则对象没实现就崩，崩的原文见探针 15）：

```objc
id<Speaker> speaker = p;
if ([speaker respondsToSelector:@selector(whisper)]) {
    [speaker whisper];
}
```

SEL 的唯一化、`@selector` 编译成什么、IMP 怎么直接拿 —— 全是 27 章 §1/§3 的内容。本章只需要
「三件套 + 两个问句」这一层。

## 7) 协议（protocol）：OC 的多态

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

```
  ok   通过协议调用 required 方法
  ok   speakTimes:2 说了两遍
  ok   conformsToProtocol: 运行时问「你声明过遵循这个协议吗」：面向协议解耦的那一半靠它兜底
  ok   instancesRespondToSelector: 问的是「这个类的实例会不会」，不用先造对象 —— 协议里的 @required 有没有真被实现，问一句就知道（编译器只在「显式声明遵循却没实现」时警告，见本章末尾探针记录）
  ok   同一个 selector 问两种对象，一个会一个不会：这就是 delegate 只认 id<Protocol>、调用前先问一遍的原因
```

> `<NSObject>` 写在协议声明里，表示「遵循者也得是 NSObject 家族」，这样
> `respondsToSelector:` 这类 NSObject 方法才保证可用。

「编译器只在**显式声明遵循却没实现**时警告」这条用探针补全了：`@interface MXNoImpl : NSObject <MXS>`
而 `MXS` 有 `@required -speak` 时，clang 给
`warning: method 'speak' in protocol 'MXS' not implemented [-Wprotocol]`（探针 11）。
反过来，`id<Speaker>` 拿到一个**没有声明遵循**的对象，编译器完全不查 —— 所以 delegate 的
调用前那一问不是洁癖，是唯一的护栏。

## 8) 分类（category）：不改源码给类加方法

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

```
  ok   分类方法已合并进 Person
  ok   分类不改变类型，运行时同一张方法表
  ok   分类最常见的用途就是这个：给 NSString / NSDate 这类已有类贴工具方法，不改源码、不建子类
  ok   分类方法在 `id` 上一样能调：编译期根本不查它是哪个类的方法表 —— 灵活的另一面是「两个分类实现同名方法时，结果由加载顺序决定」，那一条在 27 章 §10 量过
```

本章给 `NSString` 贴的那个工具方法是工程里最常见的形状：

```objc
@interface NSString (MXHelper)
- (NSString *)mx_shout;
@end
@implementation NSString (MXHelper)
- (NSString *)mx_shout {
    return [[self stringByAppendingString:@"！！！"] uppercaseString];
}
@end
```

**前缀是纪律**：分类方法名一律带 `mx_` / 公司缩写前缀。因为你贴到 `NSString` 上的方法
和别人的分类、甚至未来系统自己的方法同名时，**行为由加载顺序决定**（27 章 §10 量过合并顺序），
那类 bug 复现不出来。

> **坑**：分类里**不要**添加属性存储。这不是「不建议」，是编译器会直接告诉你 ——
> 分类里写 `@property` 会得到两条警告（探针 10）：
> `property 'mx_tag' requires method 'mx_tag' to be defined - use @dynamic or provide a method implementation in this category`
> 和它的 setter 版本。分类**不自动合成 ivar**。硬要存，只能上关联对象（27 章 §7 量过它的真实形状和生命周期）。

## 9) block：OC 的闭包

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

```
  ok   block 可像函数一样调用
  ok   block 作为排序比较器
  ok   排序结果末位是 8
  ok   没标 __block 的捕获是「按值拷贝进块」（读到旧的 1），标了 __block 才是引用同一个变量（读到新的 100）：1 + 100 = 101 就是这两种捕获的差
  ok   block 就是个对象，可以存起来反复调（次数是数出来的）
```

**捕获是「按值」的，`__block` 才是「按变量」**。这一条用 `1 + 100 = 101` 量出来了：
块里读那个没标记的变量，读到的是**捕获那一刻的副本**（1），外面再改成 100 也没用；
标了 `__block` 的读到 100。反过来，块里想**写**外面的变量，不标 `__block` 直接是编译错误
（探针 6：`variable is not assignable (missing __block type specifier)`）。

本章正文里一共用了四次 `__block`（§2 的副作用计数、§3 的 `viaBlock`/`brokeEarly`、§9 的 `blockCalls`），
每一次都是这条编译器错误逼出来的 —— 这不是示例啰嗦，是「块内改局部变量」在 OC 里就必须这么写。
Swift 的捕获列表是另一套规则（06 章），别混。

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
> **这一条在本章不是背诵，§10 最后四组断言把它量成了「报信 block 跑了几次」。**

## 10) ARC 与内存管理：把「释放」量成数字

OC 现在都用 **ARC**（Automatic Reference Counting，自动引用计数）：编译器在合适的地方
插入 retain/release，你不用手写。规则四条（strong / weak / 循环引用 / copy）在上面已经列过，
这一节用 `MXCounted` 的 `-dealloc` 计数把它们**逐条测一遍**。

```
    起点：进程里 MXCounted 还活着 1 个（本章到这里造过 1 个）
  ok   alloc/init 之后：活的个数 +1
  ok   把唯一的 strong 置 nil，ARC 当场就发了 release：对象立刻释放（不用等池子）
  ok   登记进池子的对象活着
  ok   autorelease 语义：即使把引用置 nil 对象**也还活着**，它只是被记在当前池的账上，等池子排空才释放
  ok   出了 @autoreleasepool 那一层，登记过的对象才真的 dealloc —— 这就是「池子排空」的确切含义（上面那条 strong 置 nil 立刻释放，对比的就是这一条）
  ok   50 轮循环 + 每轮一个内层池：循环内最高水位 = 1（就是起点值），循环外也回到 1 —— 大循环里造临时对象要包池，这是 06 章 Swift 侧同一条规则的 OC 版
  ok   weak 引用正常读，但它不持有对象（活的个数没因它 +1）
  ok   出了作用域对象释放，weak 自动变 nil：这就是 delegate 一律写 weak 的原因 —— 它既不会把宿主拖住，也不会变成野指针
  ok   配对造好：活的个数 +2
  ok   离开作用域、局部强引用全断了，活的个数却还是 3（该是 1）：x 持有 y、y 持有 x，谁先到 0 都轮不到 —— 这 2 个对象漏了，且永远不会被发现在进程里
  ok   把其中一条改成 weak：这一对正常释放，个数回到起点 —— 「打破循环」就是把父子/宿主与 delegate 之间那一条边变弱
```

四组实验，四句结论：

1. **strong 断开 = 立刻释放；`__autoreleasing` = 等池子排空**。
   同一个 `@autoreleasepool` 块里，把 strong 局部变量置 nil，计数当场回去；
   换成 `__autoreleasing` 变量，置 nil 之后对象**还活着**，出块才 dealloc。
   这就是「池子排空」的确切含义，也是 `main()` 外面那层池子存在的理由。
   「50 轮循环 + 每轮一个内层池」那条给的是工程用法：**循环里造大量临时对象要包池**，
   不然最高水位会一路堆到循环结束（Swift 侧同一条规则在 06 章）。
2. **weak 不持有，而且自动置 nil**。两条都要：它既不会把宿主拖住（所以 delegate 一律 weak），
   也不会变成野指针（所以出作用域之后读它是 `nil`，回到 §4 那条「给 nil 发消息安全」）。
   对照一下 `__unsafe_unretained`：也不持有，但**不会**置 nil —— 那是悬垂指针，读它就是 28 章 §15 说的那类 UB。
3. **循环引用是能被量出来的**。两个对象互指 strong，出作用域之后计数**不动**（3，该是 1），
   这两个对象在进程里永远漏；把其中一条边改成 weak，立刻回到起点。
   这里没有用 Instruments，是因为示例必须 headless、必须可断言 —— 而 dealloc 计数就是同一件事的最小模型。
4. **block 捕获 self 的循环，clang 在编译期就看得见**：
   `warning: capturing 'owner' strongly in this block is likely to lead to a retain cycle [-Warc-retain-cycles]`
   ＋ `note: block will be retained by the captured object`（探针 12）。示例为了保持编译日志干净，
   用 `#pragma` 局部静音了那一行 —— 但你要知道：**这一条警告值得当成错误来对待**。

最后那三组对照把 §9 的 weak-strong dance 钉死了：

```
  ok   block 还没跑：对象仍在手里
  ok   strong/copy 属性 + 一个不捕获任何东西的 block：对象正常释放，dealloc 里的 block 跑了 1 次（这是对照组）
  ok   block 里引用了 owner：copy 属性强引用 block、block 强引用 owner —— 循环成立，对象永远不释放，dealloc 里那个报信 block 一次都没跑。这就是 OC 的头号内存坑（clang 甚至会在编译期就警告它，诊断见本章末尾）
  ok   换成 weak-strong dance（块外 weak、块内再临时转 strong）：对象正常释放，block 跑了 1 次 —— 和上面那条唯一的区别就是捕获的是 weak 还是 self
```

对照组 → 1 次；捕获 `owner` → **0 次**（对象根本没走到 `-dealloc`）；weak-strong dance → 1 次。
「为什么块里要先 `__strong typeof(weakSelf) strongSelf = weakSelf;`」的答案也在这四行里：
弱引用只保证不循环，**不保证执行到那一行时对象还在**，所以要在块内 momentarily 转强一次再判空。

> 对比 Swift：Swift 也是 ARC，`weak`/`unowned` 对应 OC 的 `weak`/`__unsafe_unretained`；Swift 的
> `[weak self]` 捕获列表对应 OC 的 weak-strong dance。语言不同，内存模型一致（06 章把这套在 Swift 里再量一遍）。

## 11) 错误处理：NSError 二级指针

OC 没有异常（日常不用 `@try`，见 §3.3）。约定是：**方法返回 BOOL/nil 表示成败，错误经二级指针 `NSError **` 传出**：

```objc
NSError *err = nil;
BOOL ok = [p renameTo:@"" error:&err];   // 传 &err
if (!ok) {
    err.localizedDescription;            // err 被填充（本章不打日志，见 §0 的判定约束）
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

```
  ok   空名字改名失败返回 NO
  ok   错误经二级指针传出，err 被填充
  ok   错误码 1001
  ok   自定义错误域
  ok   userInfo 里的本地化描述
  ok   成功时返回 YES 且 err 不被填
  ok   改名成功
```

`NSError` 三要素：**domain**（错误域字符串）、**code**（整数）、**userInfo**（字典，
`NSLocalizedDescriptionKey` 放人类可读描述）。四条纪律：

1. **只在失败时填 `*error`，成功路径别把它清空**（写 `*error = nil` 是多余的，判 `error != NULL` 才动手）。
2. **调用方可能传 `NULL`** —— 他不关心原因，只想知道成没成。所以填之前必须问 `if (error != NULL)`。
3. **`&err` 是「把 err 的地址交出去」**，这就是 28 章 §6「C 只有一个返回值，多出来的结果靠地址带出去」在 OC 里的样子。
4. domain 用反向 DNS 字符串常量，code 是**你自己那个域里**的编号（1001 不是全局唯一）。

> 这个「BOOL + NSError**」签名，Swift 会自动翻译成 `throws`（第 07 章；28 章 §22 实测过翻译的条件）——
> `try p.rename(to: "x")`。这就是 Swift 错误处理能那么干净的由来。

## 12) description 与 `%@`

`%@` 打印对象时，走的是对象的 `- (NSString *)description`。默认实现是
`<Person: 0x6000…>`（没用），所以自定义类要重写它：

```objc
- (NSString *)description {
    return [NSString stringWithFormat:@"<Person %@ age=%ld>", self.name, (long)self.age];
}
```

```
  ok   %@ 打印的是重写后的 description
  ok   description 格式符合自定义
```

> 打印标量注意格式符：`NSInteger` 用 `%ld` + `(long)`，`NSUInteger`（`.length`）用
> `%lu` + `(unsigned long)`，对象用 `%@`，C 字符串用 `%s`。写错**不报错**、只出乱码。
> （Foundation 篇第 05 章会专门展开，`%s` 打 UTF-8 中文的那一半在 28 章 §17。）

顺带一条**本章自己的工程规则**：`description` 里**不要放指针值和绝对路径**。
这不是风格 —— 本教程的六条判定里有一条是「stdout 不含 TAB/LF/CR 之外的控制字符」，
还有一条是「debug 与 release 两份 stdout 逐字节一致」，地址每次都变，一放进去示例就永远绿不了。
真实工程里同理：把地址、时间戳、随机量打进日志，就等于放弃了「两份日志可比」这件事。

## 13) OC 一样能写 UIKit

OC 不是「只能写逻辑」——UIKit 本身就是 OC 框架，OC 用起来最直接：

```objc
UILabel *label = [[UILabel alloc] init];
label.text = [p greeting];
[label sizeToFit];
UIColor *c = [UIColor systemBlueColor];    // 类方法用 +，调用写成 [类 方法]
```

```
  ok   OC 一样能构造 UIKit 控件
  ok   OC 调 UIKit 类方法（systemBlueColor）
  ok   同一段文字、更大的字号：sizeToFit 把 frame 改大了（具体数字取决于字体渲染，所以只断言「变大且非零」）。关键是单位 —— UIKit 的几何值全是 point，不是像素
  ok   UIKit 的所有几何值单位都是 point，屏幕自己有一个 displayScale（这台设备上是整数倍，1pt = scale 个像素）：换算细节在 10/14 章展开，本章只把「frame 不是像素」这件事钉住
```

headless（没有 `UIApplicationMain`、没有窗口）也能构造控件、调 `sizeToFit`、读 `frame` ——
这是本教程全部 28 个示例能跑起来的前提。两条注意：

- **`frame` 的单位是 point**（`CGFloat`，也就是 §1 量的那个 8 字节 double），像素 = point × `displayScale`。
  截图、绘图、`UIImage` 的 `size` vs 像素尺寸（第 12、21 章）全在这里分岔。
- **注意这里没有打印任何具体宽度**。字号渲染出来的宽度依赖系统字体与文本布局，属于「换台机器就变」的量，
  所以断言只写「变大且非零」。这条纪律同样是从六条判定里长出来的。

## 14) 本章的边界：量出来的 / 只能记的 / 留给别的章

示例最后自己打了一份清单，这份清单是本章的「诚实边界」：

```
  量出来的（上面每一条 ok 都来自这次运行，换优化级别结果一致）：
    标量宽度表、NSInteger/CGFloat/BOOL 的真实宽度、整数变 BOOL 的三条路（都是 1，不是书上说的截成 0）、
    字面量默认类型、八进制/十六进制、五种进制打法、float 窄化后的真实值、
    nil/Nil/NULL/NSNull 的四种含义、@() 与 @"" 的四个真实类名、tagged pointer 让 `==` 时灵时不灵的五组结果、
    短路的确切求值次数（&&、|| 各 1 次，单个 & 是 2 次）、for-in 的批次序列（2、2、1、0 共 4 次回调）、
    strong 置 nil 立刻释放 vs __autoreleasing 等池子排空、循环引用扣住 2 个对象不放、weak-strong dance 放行、
    子类重写 setter 之后 init 里 _ivar 与 self.xxx 的两种结果（36 vs 72）。
  只记不跑的（示例里一行都没执行，全部来自独立探针，正文以「探针记录」引用编译器/运行时原文）：
    不带括号的 4|2&1 与 1+2<<2、(a==0)&(b==1) 三个优先级警告；int big = 9999999999999 的 -Wconstant-conversion；
    switch 一个对象指针、@1 + @2、readonly 属性赋值、block 改无 __block 的外层变量、for-in nil、
    @[@1, nil]、@(nil) 七个编译错误；分类里 @property 不实现、声明遵循协议却不实现两个警告；
    整数除零的硬件陷阱、给对象发一个它没有的 selector（unrecognized selector）。
```

### 探针记录（15 条原文）

下面每条都是独立小程序在同一套工具链（Apple clang 16 / iPhoneSimulator18.2.sdk /
`x86_64-apple-ios15.0-simulator` / 同一台模拟器）上真跑出来的原文，示例本身一行都没执行它们。
文件名是探针自己起的，地址按本章的规矩抹成 `0x…`：

```
   1) 优先级三兄弟。源码：int a=4,b=2,c=1; return (a | b & c) + (1 + 2 << 2);
      p1.m:2:57: warning: '&' within '|' [-Wbitwise-op-parentheses]
      p1.m:2:57: note: place parentheses around the '&' expression to silence this warning
      p1.m:2:67: warning: operator '<<' has lower precedence than '+'; '+' will be evaluated first [-Wshift-op-parentheses]
      再来一条布尔的：`(x==0) & (y==1)` 报 warning: use of bitwise '&' with boolean operands [-Wbitwise-instead-of-logical]
      三条都是 -Wall -Wextra 默认就响的，所以本章正文里那两条式子必须带括号写。
   2) 大常数塞进 int。源码：int big = 9999999999999;
      w_int.m:1:28: warning: implicit conversion from 'long' to 'int' changes value from 9999999999999 to 1316134911 [-Wconstant-conversion]
      「数据会丢」这句话书里只写在正文里，clang 直接把丢完的结果打给你看。
   3) switch 一个对象。源码：NSString *s=@"a"; switch (s) {…}
      e_switch.m:2:38: error: statement requires expression of integer type ('NSString *__strong' invalid)
   4) NSNumber 相加。源码：NSNumber *n = @1 + @2;
      e_numadd.m:2:35: error: invalid operands to binary expression ('NSNumber *' and 'NSNumber *')
   5) 给 readonly 属性赋值。源码：q.lengthOfName = 3;
      e_roset.m:2:87: error: assignment to readonly property
   6) block 改外层变量。源码：int x=1; void(^b)(void)=^{ x=2; };
      e_blockcap.m:2:52: error: variable is not assignable (missing __block type specifier)
   7) 对 nil 做 for-in。源码：for (NSNumber *n in nil) {…}
      main.m:400:9: error: the type 'void *' is not a pointer to a fast-enumerable object
      —— 编译器不许拿 nil 当容器；本章正文改成 `id nothing = nil;` 才过，运行时那次「不进循环」是量出来的。
   8) 集合字面量里放 nil。源码：NSArray *a = @[ @1, nil ];
      e_arrnil.m:2:38: error: collection element of type 'void *' is not an Objective-C object
   9) 装箱 nil。源码：id x = nil; NSNumber *n = @(x);
      e_atnil.m:2:44: error: illegal type 'id' used in a boxed expression
  10) 分类里写 @property。源码：@interface NSString (MX) @property (nonatomic,copy) NSString *mx_tag; @end
      w_catprop.m:5:17: warning: property 'mx_tag' requires method 'mx_tag' to be defined - use @dynamic or provide a method implementation in this category [-Wobjc-property-implementation]
      w_catprop.m:5:17: warning: property 'mx_tag' requires method 'setMx_tag:' to be defined …（getter/setter 各一条）
      分类不能自动合成 ivar，这两条警告就是它的官方说法；硬要存只能上关联对象（27 章 §7）。
  11) 声明遵循协议却不实现。源码：@interface MXNoImpl : NSObject <MXS> @end，MXS 有 @required -speak
      w_protodecl.m:8:17: warning: method 'speak' in protocol 'MXS' not implemented [-Wprotocol]
  12) 故意留的循环引用。源码：owner.onRelease = ^{ [owner hash]; };
      main.m:739:56: warning: capturing 'owner' strongly in this block is likely to lead to a retain cycle [-Warc-retain-cycles]
      main.m:739:13: note: block will be retained by the captured object
      —— 循环引用是编译器真能看出来的那一类，正文用 pragma 局部静音才让它跑起来。
  13) float 窄化一声不响。源码：float f = 0.1;（-Wall -Wextra 零诊断）
      但一旦拿它和 double 字面量比，就冒出：warning: floating-point comparison is always true; constant cannot be represented exactly in type 'float' [-Wliteral-range]
  14) 整数除零。源码：volatile int zero=0; int bad = ten / zero;
      xcrun simctl spawn … 的原文：Child process terminated with signal 8: Floating point exception（退出码 136）
      前面那句 NSLog 一行都没打：它不是 NSException，@catch 接不住，进程当场就没。
  15) 给对象发一个它没有的 selector。源码：[(@[@1]) performSelector:NSSelectorFromString(@"thisOneDoesNotExistAtAll")];
      *** Terminating app due to uncaught exception 'NSInvalidArgumentException', reason:
          '-[NSConstantArray thisOneDoesNotExistAtAll]: unrecognized selector sent to instance 0x…'
      顺带三个信息量很大的细节：这次是「uncaught exception」（@try 能接住它，但接住就等于把 bug 藏了）；
      调用栈里有 ___forwarding___（27 章 §8 那四级台阶就是从这里开始的）；而打出来的类名是 NSConstantArray，
      不是 NSArray —— §1 那句「别拿 [x class] 当身份」再一次被运行时亲自证明。
```

还有一条是这次改示例时**撞上的**，值得单独记：

> `__autoreleasing MXCounted *a = [[MXCounted alloc] initWithTag:2];` 如果后面一行都不读它，
> clang 报 `warning: variable 'a' set but not used [-Wunused-but-set-variable]`，
> 并且在 `-O2` 下**真的把这次分配消掉了** —— 那一版「池子排空前还活着」的断言直接 FAIL。
> 读一下 `a.tag` 之后才恢复。**度量必须被观测**，这句话在编译器这一层也成立。

### 换一台机器会变的东西

```
  换一台机器（arm64 真机）会变的东西：所有 sizeof 数字里 long/NSInteger/CGFloat/指针那一列本来就是 8，不变；
    会变的是 tagged pointer 那套类名（NSTaggedPointerString 的具体存在与长度阈值）和 NSString 私有类名 —— 所以本章从不拿类名做判断，只打印出来给你认日志。
```

把这三档分开写清楚，是为了以后你读到本章某个数字时知道该信它多少：**宽度是这台机器的**（lp64，
arm64 上同样成立）、**`==` 那张表里的「对/错」是系统实现给的**（换版本可能整体变）、
**断言的结论是语言/编译器规则**（可迁移）。

## 坑清单

| 现象 | 原因 |
|---|---|
| `[nil someMethod]` 没崩但逻辑不对 | nil 消息静默返回 0/nil，bug 被吞 |
| nil 消息拿结构体得到怪值 | 返回结构体时 nil 消息是未定义值 |
| `NSString` 属性被外部偷偷改了 | 用了 `strong` 而非 `copy`，被赋了 `NSMutableString` |
| delegate 导致对象释放不掉 | delegate 用了 strong，形成循环引用 —— 改 weak |
| block 里 self 释放不掉 | block 强引用 self，需 weak-strong dance（编译器会警告 `-Warc-retain-cycles`） |
| `performSelector:` 编译告警 | ARC 不知返回对象的生命周期，用 pragma 局部静音 |
| 分类加属性崩溃 | 分类不能合成 ivar，只能用关联对象（编译器给两条警告） |
| `%d` 打印 `.length` 出乱码 | 它是 `NSUInteger`，要 `%lu` + `(unsigned long)` |
| `@"abc" == b ? …` 时灵时不灵 | `==` 比的是指针；常量池合并和 tagged pointer 会让它**碰巧**对 |
| `if (arr.count)` 在 256 个元素时行为怪异 | `BOOL` 只有 1 字节，靠编译器归一化才没错；写 `count > 0` |
| `050` 变成 40 | 前导 0 是八进制 |
| `int n = 9999999999999;` 数值不对 | 大常数默认 `long`，赋给 `int` 截断（`-Wconstant-conversion`） |
| `4 \| 2 & 1` 算出怪数 | 位运算优先级；`&` 比 `\|` 紧，`<<` 比 `+` 松 —— 全带括号 |
| 字典 for-in 的顺序在不同版本上不一样 | 字典遍历顺序不保证；先取 `allKeys` 排序再遍历 |
| `@try` 没接住崩溃 | 除零、空指针是硬件信号，不是 `NSException` |
| `[obj performSelector:NSSelectorFromString(…)]` 崩 unrecognized selector | 动态 selector 没有编译期检查，调用前先 `respondsToSelector:` |

## 本章能带走的东西

1. **`NSInteger` 是 `long`（8 字节），`CGFloat` 是 `double`，`BOOL` 是 1 字节。**
   宽度是量的；格式符必须配套（`%ld`/`%lu` + 强转）。
2. **`return count;` 当 `BOOL` 这件事，今天的编译器替你兜住了，但别依赖它** —— 写 `count != 0`。
3. **字面量有默认类型**（大整数默认 64 位、浮点默认 `double`），前导 0 是八进制。
4. **`nil`/`Nil`/`NULL` 是同一个值的三种拼写；`NSNull` 是另一个东西**：集合不收 nil，所以要有占位对象。
5. **`==` 比对象内容是「碰运气」**：常量池合并和 tagged pointer 会让它对一半。
   比内容用 `isEqual:`/`isEqualToString:`，判类型用 `isKindOfClass:`，**永远别拿 `[x class]` 当身份**。
6. **短路、`for-in` 的批次、ARC 的释放时机、循环引用、weak-strong dance 全都被数成了数字**：
   这三样「看不见的语义」都有可断言的证据，也有可抄进工作的写法。
7. **`init` 里写 `_ivar`**：子类重写 setter 之后 36 与 72 的区别就是它的理由。
8. **可预期的失败走 `BOOL` + `NSError **`；`@try` 只兜底，而且接不住硬件陷阱。**
9. **头文件里的枚举一律 `NS_ENUM` / `NS_OPTIONS`**：把底类型写死，Swift 那边才翻得过去（28 章 §18/§22）。

下一章：`05-objc-foundation.md` —— Foundation 的字符串、集合、数据、JSON（OC 篇）。
