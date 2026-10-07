# 05 · Foundation（Objective-C 篇）：字符串、值类型与容器

> 示例：`examples/05_objc_foundation/main.m`
> 实测输出见 `build/05_objc_foundation/stdout.debug.txt`

Foundation 是**跨 Apple 平台通用**的一层：本章讲的每个类，在 macOS 上一字不差
（更深的 Unicode / 格式符细节可对照仓库里的 `macosdev/docs/05`）。iOS 上你还会天天遇到
`UserDefaults`、plist、`Codable`（第 18 章），底下全是这套值类型。

这一章是《iOS开发从入门到精通》第 8 章（Foundation 框架）在 2026 年工具链上的**全部落点**：
那本书用 40 页讲了 `NSString` 的四种创建方式、格式说明符表、`NSNumber`/`NSValue`/`NSNull`、
数组的六种遍历、四种排序、字典与集合、`NSData`、日期三件套、JSON 序列化。本章按同样的顺序
把这批 API 全部实测一遍，一共 16 节、**178 条断言**（一条 `FAIL` 都没有，debug 与 release
两份输出逐字节一致）。

为什么要重测：那本书是十多年前写的，里面**至少三条**「著名的坑」在本机上是**错的或说反了**
（`%d` 打 `NSUInteger` 会不会让参数栈错位、可变对象当字典 key 会不会失效、`NSDateFormatter`
的 style 输出能不能写死），还有几条它只是**罗列方法名**而没有讲语义差别
（`containsObject:` vs `indexOfObjectIdenticalTo:`、`valueForKey:` vs `valueForKeyPath:`、
`setByAddingObject:` vs `unionSet:`）。本章逐条给结论。

三条硬约束和第 04 章一样：**不 `NSLog`**（它写 stderr，会破坏「stderr 必须为空」的判定），
**不打印任何指针值 / 地址 / 路径 / 文件字节数 / 环境相关数字**（类名可以打，地址不行），
**会崩的调用只在独立探针里跑**，原文收在 §16 的「探针记录」里 —— 本章 §10 那三条异常是
唯一被放进示例的：它们**被 `@try` 接住了**，所以进程照样正常退出。

## 0) 本章的三个小道具

```objc
// 类名不是地址，可以安全打印；但它是**私有实现**，只能当证据看，不能当身份判断用。
static NSString *MXCls(id obj) { return NSStringFromClass([obj class]); }

// 把「这个方法来了几次」变成数字（§8 的 makeObjectsPerformSelector: 用它计数）
@interface MXGreeter : NSObject
@property (nonatomic, copy) NSString *name;
- (void)sayHello;
@end

// §12 的哈希契约实验：只重写 isEqual:，故意不重写 hash
@interface MXUser : NSObject <NSCopying> /* name / pass */ @end
@interface MXHashedUser : MXUser @end   // 这个补上了 hash
```

`MXCls` 是本章用得最多的一个函数：Foundation 的每个类都有一堆**私有子类**
（`NSConstantArray`、`__NSArrayM`、`__NSSetI`、`NSTaggedPointerString`…），把类名打出来是
**理解「你拿到的到底是什么」的最快办法**；但正因为它们是私有实现，04 章就立过规矩：
**判断类型只能问 `isKindOfClass:`，不能拿 `[x class] == [Y class]` 当身份**。本章的类名
断言全都印在输出里当证据，而**逻辑判断**一律走 `isKindOfClass:`。

## 1) NSString 的创建：同一串内容的四条路

```objc
NSString *lit    = @"Cocoa";                                  // 编译期常量
NSString *copied = [NSString stringWithString:lit];           // 类方法便利构造
NSString *fromC  = [NSString stringWithUTF8String:"Cocoa"];   // 从 C 字符串转
NSString *made   = [[NSString alloc] initWithFormat:@"%@%@", @"Co", @"coa"];  // 运行时拼
```

实测：

```
  四条路 = Cocoa | Cocoa | Cocoa | Cocoa
  ok   四条路造出的串**内容**全等：isEqualToString: 比内容，不看怎么造出来的
  ok   字面量与 stringWithString: 是同一个对象（常量池里那份）：stringWithString: 遇到不可变串就返回自己
  ok   initWithFormat: 走的是运行时拼接，一定是新对象：内容一样不等于同一个
  ok   四条路的返回值都是 NSString —— 但**具体是哪一个 NSString 私有子类**见 04 章 §数据类型（四）
  码元数组造的串 = AB😀（length=4）
  ok   stringWithCharacters: 收的是 UTF-16 码元，4 个码元就是 length 4
  ok   前两个码元是 'A' 'B'
  ok   后两个码元（一个代理对）合起来才是一个 emoji：拆开半个就是乱码
```

书上列了这四种创建方式，但没讲**它们的对象身份差别**。实测出三条结论：

- **`stringWithString:` 遇到不可变串会直接返回同一个对象**（`lit == copied` 成立）。
  它不是「拷贝」，是「给我一个 NSString」—— 优化掉了。想要一份真副本要用
  `[lit copy]`（对不可变串同样返回自己！）或 `mutableCopy`。
- **`initWithFormat:` 一定是新对象**。内容一样不等于同一个（04 章 §运算符（三））。
- 还有第五条路：**`stringWithCharacters:length:` 直接收 UTF-16 码元数组**。
  这一条是 §3 整节的物理来源 —— 你能亲手把「两个码元拼成一个 emoji」这件事做出来。

> `unichar` 是 `unsigned short`，即一个 UTF-16 码元。`{ 'A', 'B', 0xD83D, 0xDE00 }`
> 造出 `AB😀`，`length` 是 **4**，但用户看到的是 3 个字符。

## 2) 格式说明符：`stringWithFormat:` 底层就是 `printf`

`stringWithFormat:` 不做类型检查，**编译器不做、运行时也不做**：说明符和参数对不上，
轻则乱码，重则段错误。示例把 21 个说明符排成一行全打一遍：

```objc
NSString *spec = [NSString stringWithFormat:
    @"对象=%@ int=%d NSInteger=%ld NSUInteger=%lu zd=%zd tu=%tu "
    @"float=%f 定点=%.2f 带宽度=%8.3f g=%g 指数=%e 字符=%c C串=%s "
    @"十六=%x 大写十六=%X 八进制=%o 补零=%05d 左对齐=[%-4d|] 百分号=%%d%%", ...];
```

实测：

```
  对象=Cocoa int=42 NSInteger=-7 NSUInteger=5 zd=-7 tu=5 float=3.141590 定点=3.14 带宽度=   3.142 g=3.14159 指数=3.141590e+00 字符=x C串=C-style 十六=2a 大写十六=2A 八进制=52 补零=00042 左对齐=[42  |] 百分号=100%
  ok   %@ 打对象走 -description（§12）
  ok   NSInteger 用 %ld+(long)、NSUInteger 用 %lu+(unsigned long)：这是 64 位上唯一不折腾的写法
  ok   %ld 的等价写法是 %zd（C99 的 ssize_t），%tu 对应 ptrdiff_t —— 但 Apple 代码里九成还是 %ld+(long)
  ok   %.2f 管小数位、%8.3f 里的 8 是**总宽**（含小数点），不足就在左边补空格
  ok   负号是「左对齐」：%-4d 把 42 推到左边
  ok   %05d 用 0 补齐到 5 位：写日期/序号定宽时靠它
  ok   %x 小写十六、%X 大写、%o 八进制：42 的三种写法
  ok   %s 收 char*（不是 NSString*！），%c 收 int（这里从 unichar 显式降下来）
  同一个值：4294967297 当 int 读就是 1
  ok   64 位的 NSUInteger 塞进 %d（或先转 int）只会留低 32 位：2^32+1 变成 1 —— 编译器不会拦你，探针里那条 -Wformat 才是它唯一的提示
  ok   %.*f 的精度由**参数**给（不是写在格式串里）：这是把宽度做成变量的唯一合法办法
```

这张表就是书上那张「格式符表」的完整版（书里只有 `%@ %d %f %@` 那几行）。**注意
`%8.3f` 打出来是 `   3.142`**：宽度 8 是**总宽**（含小数点），不是小数位数 —— 这条书上是
用文字说的，示例把它打出来了。

### 2.1 本章要纠正的第一条流传说法

老教程（含本书第 8 章的写法）会说：「用 `%d` 打 `.count` 会让**参数栈错位**，后面的值全乱」，
并以此解释为什么必须写 `(unsigned long)`。**在本机的 ABI 上这句话不成立**：

- x86_64 SysV 调用约定下，可变参数**不靠格式串推算步长**，每个整数参数各占一个寄存器/栈槽。
  探针实测：`%d` 配一个 `NSUInteger`，**只取低 32 位**，单参数和多参数都照常打出正确值。
- **真正的两个危险**是：
  1. **截断** —— `(int)0x100000001ULL` 是 `1`（上面那条断言实测的就是它）；数组超过 42 亿个
     元素当然不会有，所以日常不炸，但它是**静默的**。
  2. **整数与浮点不在同一条流水线上** —— 整数走通用寄存器、浮点走 SSE 寄存器。
     用 `%f` 配一个 `int` 打出来是 `nan`；用 `%d` 配一个 `double` 打出一个和原值无关的
     大整数（本次探针给 `1390411937`，换机器会变，所以只记在 §16）。

所以规矩照旧（**`%lu`+`(unsigned long)` / `%ld`+`(long)`**），但理由是「截断 + 编译器会警告」，
不是「参数栈错位」。**编译器那条 `-Wformat` 警告才是这套强转存在的唯一原因** ——
判定 1 要求编译日志为空，原文记在 §16 第 1、2、3 条。

## 3) 长度、遍历与编码：`length` 不是字符数

```objc
NSString *zh = @"你好 iOS";
zh.length;                                        // 码元数
[zh lengthOfBytesUsingEncoding:NSUTF8StringEncoding];   // 字节数
[zh characterAtIndex:0];                          // 一个 unichar
unichar buf[8]; [zh getCharacters:buf range:NSMakeRange(0, 4)];
```

实测：

```
  你好 iOS: length=6 UTF-8字节=10 码元数组直读前2=你 好
  ok   length 是 UTF-16 码元数：两个汉字各 1 个码元 + 空格 + iOS 三个 = 6
  ok   同一串的 UTF-8 是 10 字节（汉字 3 字节 ×2 + 空格 + iOS 三个字母）：**length 数码元、lengthOfBytes 数字节，永远是两回事**
  ok   characterAtIndex: 给的是 unichar（UTF-16 码元），不是字符 —— 汉字在 BMP 里刚好一个码元，所以看起来对
  ok   getCharacters:range: 批量取码元，第 4 个是 'i'
  ok   😀 在 UTF-16 里是**两个**码元（0xD83D 0xDE00）：characterAtIndex: 拿到的是残缺的一半，这就是「别用 characterAtIndex: 遍历」的原因
  ok   enumerateSubstrings:ByComposedCharacterSequences 才按「用户看到的字符」切：一个 emoji = 一段
  a👍🏽b: length=6 UTF-8=10 用户字符=3
  ok   👍🏽 的 length 是 4（拇指代理对 + 肤色修饰符代理对），但它是**一个**用户字符：6 个码元 / 3 个字符 / 10 个 UTF-8 字节
  预组合 length=4 / 分解 length=5
  ok   两种合法写法：预组合 4 个码元、分解 5 个码元
  ok   看起来一模一样，isEqualToString: 说是**不相等**：它逐码元比，不懂 Unicode 规范化
  ok   precomposedStringWithCanonicalMapping 归一之后才相等 —— 拿外部数据当 key/去重之前必须先做这一步
  ok   NSString → NSData(UTF-8) → NSString 往返无损
  ok   cStringUsingEncoding: 给的是**临时**的 const char*：出了这条语句就可能失效，要留存就自己拷
  ok   非法 UTF-8 解码**返回 nil**（不是崩溃、不是异常、也不是替换字符）：读外部字节流必须判 nil
```

`a👍🏽b` 这一行是本章最该记住的一个数字：**6 个码元 / 3 个用户字符 / 10 个 UTF-8 字节**，
三个数都不等于「字符数」。iOS 上你要按「用户看到的字符」处理文本（光标移动、字数统计、
截断显示）时，**唯一的正确工具是
`enumerateSubstringsInRange:options:usingBlock:` 配 `NSStringEnumerationByComposedCharacterSequences`**
（或 Swift 的 `string.count`，它走 `Character` 即字素簇，见第 06 章）。

> **坑**：从网络、文件、粘贴板读进来的字符串，你不知道它是预组合还是分解写法。
> 要做「相等」判断或当字典 key 之前，**先 `precomposedStringWithCanonicalMapping` 规范化**。
> `isEqualString:` 配 `compare:options:` 里的 `NSDiacriticInsensitiveSearch` 只解决音标，
> 不解决组合/分解。

编码转换三句实话：`dataUsingEncoding:` 出去、`initWithData:encoding:` 回来（**解不开返回
nil，不抛**）；`cStringUsingEncoding:` 给的是 **Foundation 持有的临时缓冲区**，别存下来；
`lengthOfBytesUsingEncoding:` 才是字节数，`length` 是码元数。

## 4) 比较、排序与大小写

```objc
NSComparisonResult r = [@"a" compare:@"b"];   // NSOrderedAscending == -1
[@"ABC" caseInsensitiveCompare:@"abc"];       // NSOrderedSame
[@"cafe" compare:@"café" options:NSDiacriticInsensitiveSearch];   // NSOrderedSame
[files sortedArrayUsingSelector:@selector(localizedStandardCompare:)];
```

实测：

```
  NSOrderedAscending=-1 Same=0 Descending=1
  ok   三个比较结果是 -1/0/1：这就是 sort 用的比较器返回值，别自己发明第四种
  ok   compare: 按**码位**顺序比：a<b 同向
  ok   中文按码位比：甲 U+7532 > 乙 U+4E59，所以「甲」排在后面 —— 想按拼音排不是 compare: 的活
  ok   caseInsensitiveCompare: 忽略大小写
  ok   compare:options: 的 NSDiacriticInsensitiveSearch 忽略音标：cafe 与 café 视为相等
  compare: → section10, section2, section9
  localizedStandardCompare: → section2, section9, section10
  ok   compare: 排出来 section10 在 section2 前面：逐字符比，'1' < '2'，它不懂数字
  ok   localizedStandardCompare: 是「Finder 排序」那套（数字按大小、忽略音标标点）：文件名列表要用它，别用 compare:
  ok   hasPrefix:/hasSuffix: 判头判尾：扩展名、scheme、前缀路由全靠它
  ok   isEqualToString: 区分大小写，和 compare: 是两条路
  ok   三个变形都返回**新串**（stringBy… 那一族在 OC 里也叫 xxxString，都不改原件）
  切完 = [||Cocoa||ObjC||]（7 段，含空段）
  ok   componentsSeparatedByCharactersInSet: + invertedSet = 「按所有非字母数字切开」，比手写循环稳 —— 但**连续两个分隔符之间会切出一个空串**，开头的空白也算：所以「  Cocoa, ObjC」出来 7 段而不是 2 段，段数别当成有效词数
  ok   去首尾空白用 stringByTrimmingCharactersInSet:（首尾的空格、逗号后的都不算「首尾」）—— 它**不碰中间的字符**，所以剩下 Cocoa、逗号、空格、ObjC 共 11 个码元
```

`section10 / section9 / section2` 这两行是本章最实用的一个对比：**`compare:` 不懂数字**。
任何「文件列表」「章节名」「版本号」的排序，用户期待的是
`localizedStandardCompare:`（Finder 那套自然序），不是 `compare:`。

`componentsSeparatedByCharactersInSet:` 那条也值得记：**连续分隔符之间会产生空串**。
`@"  Cocoa, ObjC \n"` 按「非字母数字」切开得到 **7 段**（开头两个空段、Cocoa、空段、ObjC、
两个空段），不是 2 段。「切出来的段数」不能当「有效词数」用，得 `objectsPassingTest:`
或自己判空。土耳其语大小写（`localizedCapitalizedString` / `diacriticInsensitive`）
是另一套：`tr` 里 `i` 的大写是 `İ`，示例只做了 `capitalizedString` 的英文断言。

## 5) 替换、删除与 `NSMutableString`

```objc
NSString *replaced = [src stringByReplacingOccurrencesOfString:@"This is" withString:@"An example of"];
NSMutableString *mstr = [NSMutableString stringWithString:src];
NSUInteger times = [mstr replaceOccurrencesOfString:@"is" withString:@"IS"
                                            options:0 range:NSMakeRange(0, mstr.length)];
```

实测：

```
  ok   不可变串的 stringByReplacing… 返回新串，原件一个字没动：这就是「不可变版返回新对象」。注意替换的是**能匹配上的那一段**（This is → An example of），后面的 string A 原样留着
  ok   replaceOccurrencesOfString:withString:options:range: 就地改，且**返回换了几次**（这里两次）
  ok   不可变版的替换是「一次全换」：aaa → aaaaaa
  增删之后 = iOSCocoa / UIKit
  ok   insertString:atIndex: / appendString: / deleteCharactersInRange: 三个动作都在**同一块内存**上改：下标是 UTF-16 码元，删错长度就是另一种串
  ok   stringWithCapacity: 只是**预留**，不是上限：它不影响正确性，只影响重分配次数
  ok   替换成空串 = 删除：把分隔符换成空串确实能删掉它们，但正式做法是 deleteCharactersInRange:
```

两条容易被略过的细节：

- `replaceOccurrences…` **返回替换次数**（`NSUInteger`），`stringByReplacing…` 不返回任何计数。
  「改了几处」这种需求只有可变版能满足。
- 示例那段 `insertString:@"iOS " atIndex:0` → `appendString:@" / UIKit"` →
  `deleteCharactersInRange:NSMakeRange(3, 1)` 最后得到 `iOSCocoa / UIKit`：
  三个动作**都在同一个对象上**（`ops` 的指针自始至终没换），删的是下标 3 那个空格。
  「下标是码元」在这里是实打实的：删错一位就是 `iSOCocoa…`。

## 6) `NSNumber`：装箱与 `objCType` 全表

```objc
NSNumber *nChar = [NSNumber numberWithChar:'A'];
NSNumber *nInt = @42, *nLong = @42L, *nLL = @42LL;
NSNumber *nF = @3.5f, *nD = @3.5, *nB = @YES, *nU = @42u;
nInt.objCType;              // 一个 C 字符串，见 §28 的 @encode
```

实测：

```
  objCType: char=c int=i long=q longlong=q float=f double=d bool=c uint=I
  ok   numberWithChar 的编码是 "c"（signed char）、@42 是 "i"（int）：这就是 28 章 §3 的 @encode 字符
  ok   long 和 long long 在 64 位上**编码相同**（都是 "q"）：装箱之后再也分不出这两者
  ok   BOOL 的编码也是 "c"：NSNumber 里 YES 和一个 char 是同一编码的不同值 —— objCType 分不出布尔，这就是为什么取布尔必须用 boolValue
  ok   @3.5f 是 "f"、@3.5 是 "d"：浮点字面量的默认类型（04 章 §数据类型（二））一路带进装箱结果
  ok   isEqualToNumber: 按数值相等，两个却是不同对象：数值相等 ≠ 同一个对象（04 章 §运算符（三）的同一课）
  ok   @42 和 @42.0 数值相等、compare: 也判平：NSNumber 的比较看**值**不看编码
  ok   取值随你挑，但**转换会砍**：@3.5 的 intValue 是 3（向零截断，不是四舍五入）、@42 的 doubleValue 是 42.0、@YES 的 boolValue 是真：装箱类型不是取值的门槛，也不替你保住精度
  ok   stringValue 给的是「按格式渲染后」的串：拼日志方便，但别拿它当持久化格式
  ok   NSString 的 intValue 是「从头读能读的部分」：读到非数字就停，读不出就 0 —— 它不报错，所以脏数据会安静变成 0
  ok   intValue 不认十六进制：@"0x10" 是 0，不是 16 —— 要按进制解析得用 NSNumberFormatter 或 strtol（28 章）
  ok   NSValue 能装 NSRange（结构体不是对象，装箱才能进集合）
  ok   valueWithCGPoint: 这类**几何便利方法不在 Foundation 里，在 UIKit**：只 import Foundation 编译期就没有这个方法（探针记录见 §16）
  ok   通用做法是 valueWithBytes:objCType: + getValue:：整块 memcpy，尺寸由你保证 —— 装错了不会报错，只会读出垃圾
  ok   集合里的「空位」是 NSNull 单例，可以比指针：它不是 nil，是个真实存在的对象（04 章 §数据类型（三））
```

书上的 `NSNumber` 一节只有「`@()``numberWithInt:`」这种造法对照，本章补上它没有的四件事：

1. **`objCType` 全表**（输出那一行）。`long` 和 `long long` 在 64 位上**同编码 `q`**，装箱之后
   再也分不出；`BOOL` 也是 `c`，所以 `objCType` **分不出布尔** —— 想保住布尔只能自己走
   `boolValue`。
2. **取值的转换会砍**：`@3.5` 的 `intValue` 是 **3**（向零截断）。书里说「装箱类型不是取值的
   门槛」是对的，但它没提醒你**精度也不归它管**。
3. **`NSString` 的 `intValue` 语义**（书上有这段代码但没讲透）：`@"12abc"` → 12、`@"abc"` → 0、
   `@"  7"` → 7、`@"-3.9"` → -3、`@"0x10"` → **0**。它**从不报错**，所以脏数据安静变 0。
   要按进制/语言解析数字，用 `NSNumberFormatter`（第 28 章）。
4. **`valueWithCGPoint:` 不在 Foundation 里，在 UIKit** —— 只 `#import <Foundation/Foundation.h>`
   编译期就没有这个方法；更阴的是运行时注册也依赖 UIKit 镜像被加载（§16 第 4 条）。
   本章因此 `#import <UIKit/UIKit.h>`。

`NSValue` 的通用做法是 `valueWithBytes:objCType:` + `getValue:`：整块 memcpy，尺寸由你保证 ——
**装错了不会报错，只会读出垃圾**。`NSNull` 是单例，`== [NSNull null]` 是安全的（04 章 §数据
类型（三）已实测过 `NSNull` 与 `nil` 的区别）。

## 7) `NSArray`：创建、取值与不可变语义

实测：

```
  ok   字面量与 initWithObjects:…nil 造的数组内容相等：末尾那个 nil 只是**结束哨兵**，不占位置
  ok   下标 langs[i] 就是 objectAtIndexedSubscript:，越界是异常不是 nil（§10 实测）
  ok   空数组的 firstObject/lastObject 是 nil（**不崩**）：这是判空的捷径，但拿 nil 当「没有」时要小心它也可能是「有个 nil 元素」
  ok   addObject:/addObjectsFromArray:/insertObject:atIndex:/removeObject:/removeObjectAtIndex:/replaceObjectAtIndex:withObject: —— 可变数组的六个动作，书名全是 add/remove/replace/insert 开头
  ok   arrayByAddingObject: 是**不可变版**的「追加」：返回新数组，原件还是 3 个
  ok   indexOfObject: 找不到给 NSNotFound（= NSUIntegerMax），不是 -1：判它只能 == NSNotFound
  ok   containsObject: 走 isEqual:（找到），indexOfObjectIdenticalTo: 走指针（找不到）：**两个方法的差别就是内容相等与身份相等的差别**
  ok   subarrayWithRange: 与 objectsAtIndexes: 是一对：前者给连续区间，后者给任意下标集合（NSIndexSet）
  ok   arrayWithObjects:count: **不收 nil**（数着 count 个槽读，读到 nil 就抛）：字面量 @[] 走的正是这条路，所以 @[@"a", nil] 里那个洞必须拿 NSNull 填（异常原文见下面 §10）
```

这一节里最值钱的三条是书上没讲的：

- **`containsObject:` 用 `isEqual:`，`indexOfObjectIdenticalTo:` 用指针**。自定义对象没重写
  `isEqual:` 时两者一致；重写了就不一致。示例用两个内容相同的对象实测：`containsObject:` YES、
  `indexOfObjectIdenticalTo:` `NSNotFound`。
- **`firstObject`/`lastObject` 对空数组返回 nil 且不崩**，而下标越界是异常（§10）。所以判空
  用 `count` 或 `firstObject`，**别用 `arr[0]` 试**。
- **`NSNotFound` 是 `NSUIntegerMax`，不是 -1**（老规矩，本章再钉一次）。

`subarrayWithRange:`（连续区间）与 `objectsAtIndexes:`（任意 `NSIndexSet`）是一对；
`arrayByAddingObject:`/`arrayByAddingObjectsFromArray:` 是不可变版的「追加」—— 返回新数组。

## 8) 遍历家族：同一个数组的五种走法

```objc
for (NSUInteger i = 0; i < nums.count; i++) total += nums[i].integerValue;   // 索引
for (NSNumber *n in nums) byForIn += n.integerValue;                         // for-in
for (NSNumber *n in nums.objectEnumerator) byEnum += n.integerValue;         // NSEnumerator
[nums enumerateObjectsUsingBlock:^(NSNumber *n, NSUInteger idx, BOOL *stop) { ... }];
[nums enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(...)];
[nums enumerateObjectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 2)] options:0 usingBlock:^(...)];
```

实测：

```
  ok   索引 / for-in / objectEnumerator / reverseObjectEnumerator 四种走法加出同一个 10：NSEnumerator 只有 nextObject 和 allObjects 两个方法，for-in 就是它的语法糖（批次大小见 04 章 §控制语句（二））
  ok   reverseObjectEnumerator 是真逆序：想倒着拼串不用自己写反向循环
  ok   enumerateObjectsUsingBlock: 的 block 固定收三个参数：元素、下标、**stop 指针**（*stop = YES 才中止）
  ok   下标到 2 就 *stop = YES：回调停在第 3 个元素（idx 是**进 block 就给的 0/1/2**，不是自己数的次数）
  ok   NSEnumerationReverse 倒着走，但**下标仍是原数组的下标**：倒序里 idx 也跟着倒数，这是最容易记错的一条
  ok   enumerateObjectsAtIndexes:options:usingBlock: 只跑指定的下标集合：中间那一段不用自己判区间
  ok   makeObjectsPerformSelector: 给每个元素发同一条消息：它把「遍历 + 调用」压成一行，代价是编译期不查这个方法存不存在
  ok   NSArray 的 valueForKey: 有**广播**语义：对每个元素取 name，返回一个数组 —— 这是 KVC 集合操作的第一半
  ok   集合运算符（@sum/@avg/@min/@max）必须走 **valueForKeyPath:**（不是 valueForKey:，后者会抛 NSUnknownKeyException）：@sum.self 得 6（类名 NSDecimalNumber，注意是 NSDecimalNumber 不是 NSNumber）、@avg 得 2、@max 还是普通 3
  ok   @count 是唯一在 valueForKey: 下也能用的运算符（28 章 §3 的 KVC 键名规则在这里生效）
```

书上的遍历一节到 `for-in` 就停了。这里补三条 iOS 上天天用的：

- **`enumerateObjectsUsingBlock:` 的三个参数**（元素、下标、`stop` 指针）。想「找到第一个就停」
  不用写 `break` + 手写索引；倒序用 `NSEnumerationReverse`（**注意下标仍是原数组的**，见上面
  `3:4,2:3,1:2,0:1`）。
- **`makeObjectsPerformSelector:`** 把「遍历 + 调用同一条消息」压成一行。示例用一个计数属性
  证明了它**真的对三个元素各调了一次**。代价：编译期不检查选择器存在，`@selector` 写错就是
  `unrecognized selector` 崩溃；而且**它不能带参数**（带参数用 `…withObject:`，只能一个）。
- **`valueForKey:` 在数组上有广播语义**：`[greeters valueForKey:@"name"]` 返回**名字数组**。
  再往上就是 KVC 的**集合运算符**：`@sum` / `@avg` / `@min` / `@max` / `@count`，
  但它们**只能走 `valueForKeyPath:`**（`valueForKey:` 会抛 `NSUnknownKeyException`，
  原文见 §16 第 6 条），而 `@count` 是唯一一个两边都能用的例外。
  还有一条实测细节：`@sum.self` 返回的是 **`NSDecimalNumber`**，不是普通 `NSNumber` ——
  拿它去和 `NSNumber` 比 `==` 会踩坑，取值一律走 `integerValue`/`doubleValue`。

## 9) 排序家族：selector / 函数 / 代码块 / 描述符

```objc
[arr sortedArrayUsingSelector:@selector(compare:)];
[arr sortedArrayUsingFunction:MXCompareString context:NULL];
[arr sortedArrayUsingComparator:^(NSString *x, NSString *y) { return [y compare:x]; }];
[mutable sortUsingSelector:@selector(compare:)];                 // 就地
[arr sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                        ascending:YES selector:@selector(caseInsensitiveCompare:)]]];
```

实测：

```
  ok   sortedArrayUsingSelector: 让元素**自己**比（元素必须实现这个方法）：NSString 有 compare:，所以能这么排
  ok   sortedArrayUsingFunction:context: 收一个 C 函数指针：三个参数（两个对象 + 一个 void* 上下文），返回三个 NSOrdered* 之一
  ok   sortedArrayUsingComparator: 就是 block 版比较器，反过来比就倒序 —— 后两种本质是一回事，只是 C 函数在 ARC 下要自己管上下文
  ok   sortUsingSelector:/sortUsingComparator: 是**可变数组就地排**（没有返回新数组的 sorted… 版本）：书上的命名对称在这里
  按长度排 = a,bb,ccc
  ok   比较器随你定规则（这里按长度，完全不看字母序）：**元素本身可不可比都无所谓**，只要规则说得出 -1/0/1
  描述符排序 = alice,Carol
  ok   sortedArrayUsingDescriptors: 按 **keypath** 排（内部就是 KVC + 指定 selector）：caseInsensitiveCompare: 让 alice 排在 Carol 前面，而 compare: 会把大写 C 排前面（ASCII 序）。表格视图/集合视图的多字段排序靠它，ascending:NO 就是倒序
  ok   同一个数组换 selector 就换结果：compare: 排出来 Carol 在前（大写码位 67 < 小写 97）—— 用户看到的「字母序」几乎总是需要 caseInsensitiveCompare:
  ok   排好的数组还能再排一次，Foundation 不保证「稳定排序」：**同键元素**的相对次序别依赖（这一条只能记，量不出来 —— 相同键的顺序要稳，就自己在比较器里加下标兜底）
```

`sorted…` 返回新数组、`sortUsing…` 就地排 —— 这对命名对称是 Foundation 的**通用规矩**
（`sortedArrayUsing…` vs `sortUsing…`、`setByAdding…` vs `unionSet:`、
`stringByReplacing…` vs `replaceOccurrences…`），第 04 章讲属性时已经埋过，这里正式收口。

`sortedArrayUsingFunction:context:` 是**唯一一个收 C 函数指针**的排序：三个参数
（两个对象 + 一个 `void *` 上下文），返回 `NSComparisonResult`。ARC 下那个 `context`
要自己管内存，实际项目里几乎都换成了 block 版；示例还是把三条都跑了一遍，因为它出现在
书上、而且读旧代码会遇到。

`NSSortDescriptor` 那两行值得单看：**`alice,Carol`（caseInsensitiveCompare:）vs
`Carol,alice`（compare:）**。大写字母的码位（`C` = 67）小于小写（`a` = 97），所以「按字母排」
在只有 `compare:` 时是**错的** —— `UITableView`/`UICollectionView` 的索引列表、
`UISearchController` 的结果分组，全部要用 `caseInsensitiveCompare:` 或 `localizedStandardCompare:`。

## 10) 多维数组，以及集合的三种异常

```objc
NSArray<NSArray<NSString *> *> *grid = @[ @[@"(0,0)", @"(0,1)", @"(0,2)"], ... ];
grid[1][2];                                  // 两层 objectAtIndexedSubscript:
@try { id oob = langs[5]; } @catch (NSException *e) { /* 打印 e.name / e.reason */ }
```

实测（**这三条 `@try` 是本章唯一进示例的崩溃现场**，接住之后进程正常退出）：

```
  ok   数组的数组 = 二维：grid[i][j] 就是两层 objectAtIndexedSubscript:；三维同理，只是每层类型换成 NSArray
  ok   NSMutableArray 装 NSMutableArray = 书上的「学生表」写法：每行还能各自增删，代价是**没有任何类型保护**
  越界：NSRangeException —— *** -[NSConstantArray objectAtIndexedSubscript:]: index 5 beyond bounds [0 .. 2]
  ok   下标越界抛 NSRangeException，**不是返回 nil**：reason 里带 [0 .. 2] 这种合法区间（这条比 04 章的 nil 消息更危险，因为它会崩）
  ok   for-in 遍历途中改集合抛 NSGenericException：reason 里带那个集合的地址，所以这里只断言、不打印（要删就倒序删或先收集再删）
  塞 nil：NSInvalidArgumentException —— *** -[__NSArrayM insertObject:atIndex:]: object cannot be nil
  ok   往集合里塞 nil 抛 NSInvalidArgumentException（reason 原文 object cannot be nil）：04 章说「集合不收 nil」，崩的现场就在这儿。注意它和 §7 那条 initWithObjects: 的 reason（attempt to insert nil object from objects[1]）不是同一句话 —— 同一个约束，两个入口各有各的措辞
```

三条异常、三种 `reason`，逐条对比才有意义：

| 触发 | `e.name` | `reason` 能不能打印 |
|---|---|---|
| `langs[5]` 越界 | `NSRangeException` | 能，且 `[0 .. 2] 这种合法区间`极有用 |
| for-in 途中 `removeObject:` | `NSGenericException` | **不能**：原文是 `…0x… mutated while being enumerated`，带**地址** |
| `[mArr addObject:nil]` | `NSInvalidArgumentException` | 能，`object cannot be nil` |

`addObject:` 那条尤其要记：它的 `reason` **和 `initWithObjects:count:` 那条不一样**
（后者是 `attempt to insert nil object from objects[1]`，带槽位号）。同一个约束、两个入口，
两种话术 —— 搜崩溃日志时不能只搜一句话。

> **怎么删才对**：倒序 `for (NSInteger i = arr.count - 1; i >= 0; i--)`，或者先把要删的收集到
> 另一个数组、遍历结束后统一 `removeObjectsInArray:`。`removeObjectsInArray:` 是**批量删**，
> 不抛（它内部自己处理）。

## 11) `NSDictionary`：键值对与三个字典专属坑

```objc
NSDictionary *byPairs = [NSDictionary dictionaryWithObjectsAndKeys:@36, @"Ada", nil]; // 先值后键
NSDictionary *ages = @{@"Ada": @36, @"Grace": @45};                                   // 字面量：键在前
settings[@"autoSave"] = @YES;      // 新键 → 新增
settings[@"temp"] = nil;           // 已有键 → **删除**
NSSet *hit = [ages keysOfEntriesPassingTest:^(NSString *k, NSNumber *v, BOOL *stop) { return v.integerValue > 40; }];
NSArray *byValue = [ages keysSortedByValueUsingSelector:@selector(compare:)];
```

实测：

```
  ok   dictionaryWithObjectsAndKeys: 是**先值后键**，和字面量 @{key: value} 的顺序正好相反：这是 OC 最经典的笔误（编译器一个字都不提醒）
  ok   字面量字典：下标取值
  ok   不存在的 key 取到 nil（**不是异常**）：和数组越界正好相反
  ok   obj[key] 就是 objectForKeyedSubscript:，和 objectForKey: 同一个方法
  ok   拿错类型的 key（这里用 NSNumber 查字符串键）只是查不到，不会崩：字典不检查 key 的类型，只检查 hash/isEqual:
  ages = Ada=36 Alan=41 Grace=45
  ok   allKeys / allValues / for-in 的顺序**未定义**：想要稳定输出必须自己排序（本教程反复出现的那条规则）
  ok   dictionaryWithObjects:forKeys: 两个平行数组（**对象在前、键在后**）：批量造字典比一个个 setObject: 快，也更不容易写反
  数量不匹配：NSInvalidArgumentException —— *** -[NSDictionary initWithObjects:forKeys:]: count of objects (1) differs from count of keys (2)
  ok   objects/forKeys 数量不等抛异常，reason 把两个数都写出来了：这是平行数组写反之后的现场
  ok   nil 不能当 key（value 也不能是 nil，要放空位用 NSNull）：reason 短且稳定，可以直接断言
  ok   可变字典：同一个下标语法既能改也能加；removeObjectForKey: 对不存在的键**静默无副作用**
  ok   给已有键赋 nil 是**删除**（setObject:forKeyedSubscript: 的 nil 分支就是 removeObjectForKey:）：想放个「空值」得用 NSNull，不然这条赋值悄悄删了整条记录
  ok   enumerateKeysAndObjectsUsingBlock: 一次拿到键和值：比 keyEnumerator + objectForKey: 少一半消息
  ok   keysOfEntriesPassingTest: 返回的是 **__NSSetI**（不是数组）：过滤出来的是集合，要稳定顺序还得自己 sortedArrayUsingSelector:
  ok   keysSortedByValueUsingSelector: **按值排、返回键**：图例、排行榜全靠它（还有 Comparator 版）
  ok   键排序可以按任意规则（这里按值的字符串长度）：书里「值越长算越大」的那个例子
  ok   字典**把 key 拷贝一份**再存：存进去的是那个串的不可变副本（类名 NSTaggedPointerString，见 04 章），不是手里这个可变对象 —— 所以「可变对象当 key 一定失效」这句书上常见说法其实是错的
  ok   改原始那个可变串，查表一切照旧（因为存的是副本）：**真正的坑在浅拷贝** —— key 换成 NSMutableArray，里面再装一个 NSMutableString，改里面的对象会改变外层副本的 hash，查不查得到就成运气了（探针记录见 §16）
  ok   key 必须能响应 NSCopying：塞一个不遵守协议的进去，运行时就是一句 doesNotConformToSelector @"copyWithZone:"（这条留在 §16 的探针记录里，这里只把规则写全）
```

三个专属坑，其中**第二个是本章要纠正的第二条流传说法**：

1. **`dictionaryWithObjectsAndKeys:` 先值后键**，和字面量 `@{key: value}` 的顺序**正好相反**。
   这是 OC 最经典的笔误，编译器一个字都不提醒（它只看到两个 id）。示例把两种造法都跑了一遍，
   `isEqual:` 相等才敢断言顺序记对了。
2. **字典会拷贝 key，所以「可变对象当 key 一定失效」是错的。** 实测：
   拿一个 `NSMutableString @"k"` 当 key 存进去，再 `[mutableKey appendString:@"X"]`，
   `copiedKey[@"k"]` **照样查得到**、`copiedKey[@"kX"]` 是 nil —— 因为存的是**不可变副本**
   （类名 `NSTaggedPointerString`）。真正的坑是**浅拷贝**：如果 key 是一个
   `NSMutableArray`（里面套一个 `NSMutableString`），字典拷的是**外层**，内层那个对象还是
   共享的；改内层会改变**外层副本的 `hash`**，于是桶位对不上，查不查得到就成了运气。
   探针实测（§16 第 8 条）三种查法都命中，但那不代表行为被承诺 ——
   **规则只有一条：key 用不可变对象。**
3. **`settings[key] = nil` 是删除，不是「存了个空值」**，而且编译器**不报** `-Wnonnull`；
   同一语义的 `setObject:nil forKey:` 却会被拦（§16 第 5 条）。想放「空位」必须显式用
   `[NSNull null]`。

顺带把 `dictionaryWithObjects:forKeys:` 的数量不匹配现场也打了出来 ——
`reason` 直接把两个数都写出来了（`count of objects (1) differs from count of keys (2)`），
这是「平行数组写反/漏一个」之后的最好证据。

## 12) 集合族：`NSSet` / `NSCountedSet` / `NSOrderedSet`

```objc
NSSet *tags = [NSSet setWithObjects:@"iOS", @"UIKit", @"iOS", nil];   // 2 个
NSSet *bigger = [tags setByAddingObject:@"SF"];                       // 新集合，tags 不变
NSMutableSet *u = [ms mutableCopy]; [u unionSet:other];               // 就地
NSCountedSet *counter = [NSCountedSet setWithArray:@[@"iOS", @"iOS", @"iOS", @"x"]];
NSOrderedSet *ordered = [NSOrderedSet orderedSetWithObjects:@"x", @"y", @"x", nil];
```

实测：

```
  ok   NSSet 自动去重：两个 iOS 只留一个 —— 去重靠 hash + isEqual:，两个都要对
  ok   setByAddingObject: 返回**新集合**（不可变版的老规矩），原件还是 2 个
  ok   MXUser 重写了 isEqual: 但**没重写 hash**：两个对象内容相等，hash 却还是各一个（NSObject 默认按身份给）
  ok   于是集合里留下了两个「相等」的元素：**isEqual: 说相等但 hash 不同 = 去重失效**，这是自定义对象进 NSSet/字典 key 的头号 bug
  ok   补上 hash（和 isEqual: 用同一批字段）之后，同一个内容只留一个：契约是「isEqual: 相等 ⇒ hash 必须相等」，反过来不要求
  ok   setWithArray: 是「数组去重」的标准写法；anyObject 保证返回**某个**元素，但不保证哪个、也不保证随机（所以只能判空、不能打值）
  ok   三个集合关系：isSubsetOfSet: / intersectsSet: / isEqualToSet: 都是按 isEqual: 比元素
  ok   setByAddingObjectsFromSet: / …FromArray: 也都是返回新集合：集合的并集在不可变版只能这么算
  ok   objectsPassingTest: 过滤出新集合（还有 objectsWithOptions:passingTest: 可以倒着走）
  ok   unionSet: / minusSet: / intersectSet: 就地改：三个集合运算都是「把自己变成结果」，没有返回值
  ok   removeObject: 对不在集合里的元素同样静默无副作用（和字典的 removeObjectForKey: 一致）
  ok   NSCountedSet 是「集合 + 每个元素的次数」：count 数的是**不同元素**的个数，不是总次数
  ok   removeObject: 只把次数减 1，元素还在：书上「删除一次后次数变 2」这条是真的，容易记成「删了就没了」
  ok   减到 0 才真的离开集合：三次加、三次减之后只剩 x —— 计数语义和引用计数（04 章 ARC）没关系，只是同一套「加减到零」的直觉
  ok   NSOrderedSet = 集合的去重 + 数组的下标：三个元素里那个重复的 x 被吃掉，剩下 x、y 还能按 index 取
  ok   可变版把 NSArray/NSMutableSet 的动作合在一起：insert/remove/replace/exchange 都有，还能 unionSet: 之类做集合运算
```

**`MXUser` 那两条是本章最重要的实验**：自定义类**只重写 `isEqual:`、忘了重写 `hash`**，
于是两个「内容相等」的对象在 `NSSet` 里**同时存在**（`count == 2`）。补上
`hash`（用同一批字段）之后立刻变成 `count == 1`。契约只有一句话：

> **`isEqual:` 判相等的两个对象，`hash` 必须相等。** 反过来（hash 相同、内容不同）是允许的
> —— 那只是哈希冲突。**这条是 `NSSet` 去重和字典 key 查找的共同地基。**

`anyObject` 书上被当成「随便取一个」用。实测只能断言它非 nil：**不保证哪个、也不保证随机**，
所以打它的值会让输出随机器变（这条也进了 §16 第 9 条）。

`NSCountedSet` 那三条（加三次 → 删一次次数变 2 → 删三次才离开集合）是书上的一处细节，
实测全部为真。**注意 `counter.count` 数的是「不同元素」的个数（3 个 iOS + 1 个 x → `count == 2`），
不是总次数。**

## 13) `NSData`：字节、base64 与落盘

```objc
NSData *data = [@"Cocoa" dataUsingEncoding:NSUTF8StringEncoding];
NSString *b64 = [data base64EncodedStringWithOptions:0];
NSData *rt = [[NSData alloc] initWithBase64EncodedString:b64 options:0];
[@"中文\nsecond" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err];
NSString *back = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
NSDictionary *plistBack = [NSDictionary dictionaryWithContentsOfFile:plistPath];
NSData *xml = [NSPropertyListSerialization dataWithPropertyList:config
                                format:NSPropertyListXMLFormat_v1_0 options:0 error:NULL];
```

实测：

```
  ok   NSData 按**字节**计长度：Cocoa 是 5 个字节
  ok   base64 往返一致（写用 base64EncodedStringWithOptions:，读用 initWithBase64EncodedString:options:）：这是把二进制塞进 JSON / URL / 邮件头的唯一常用手段
  ok   解不出来的 base64 返回 **nil**（不崩、不返回半成品）：和 §3 的非法 UTF-8 同一个脾气
  ok   NSMutableData：appendData: 追加对象、appendBytes:length: 追加裸字节；.bytes 是 const void*，要 memcmp 或强转才能看内容
  ok   subdataWithRange: 切的是**字节**区间：切在多字节字符中间就会得到解不开的半截（和 §3 的码元陷阱同源）
  ok   字符串直接 writeToFile:atomically:encoding:error: 落盘、stringWithContentsOfFile: 读回：往返无损（路径不外打）
  ok   读回来还能按行切：这是最土的配置文件读写，第 18 章展开
  ok   文件不存在：返回 nil 并填 error（domain=NSCocoaErrorDomain code=260 = NSFileReadNoSuchFileError）—— **不抛异常**，所以每一条都得判返回值
  ok   字典/数组可以直接 writeToFile: 成 plist（默认二进制），dictionaryWithContentsOfFile: 读回来整块相等：这就是第 18 章「设置文件」的原型
  ok   NSPropertyListSerialization 能指定格式：XML 版就是书上贴出来的那个 <dict>/<key>/<true/> 形状（人可读、能进版本库）
  ok   能查「这个图能不能写成 plist」：propertyList:isValidForFormat: —— 只有字符串/数字/日期/数据/数组/字典（以及它们套它们）算合法，塞一个自定义对象进去就是 NO
  ok   写不出去时 writeToFile:atomically: 返回 **NO**（不抛异常、也不打印任何东西）：不判返回值的话，你会以为文件写好了
  ok   序列化版同样返回 nil + error（domain=NSCocoaErrorDomain code=3851）：错误码 3851 在头文件里没有名字，只能靠 code 认
```

这一段是第 18 章（持久化）的前置：`writeToFile:` / `dictionaryWithContentsOfFile:` 是
**plist 时代的原型**（`UserDefaults` 底下就是它）。三条新信息：

- **base64 的读写不对称**：写在 `NSData` 上（`base64EncodedStringWithOptions:`），
  读要用 **`initWithBase64EncodedString:options:`**（`dataWithBase64EncodedString:`
  在 iOS SDK 上**根本没有这个方法**，编译期就报错）。解不出来返回 **nil**。
- **`writeToFile:atomically:` 写不出合法 plist 时返回 `NO`，而且不抛异常、不打印任何东西** ——
  不判返回值你就是发现不了文件根本没写成。
- **`propertyList:isValidForFormat:` 可以事先查「这个图能不能写成 plist」**：
  只有 `NSString`/`NSNumber`/`NSDate`/`NSData`/`NSArray`/`NSDictionary`（以及它们互相嵌套）
  算合法，塞一个自定义对象进去就是 `NO`。序列化成 `NSData` 那条路则是 `nil` + `error`
  （`NSCocoaErrorDomain` **code 3851**，头文件里没有名字，只能靠 code 认）。
- **文件读写的错误永远走 `NSError **`，不走异常**：读不存在的文件是 `nil` + `code 260`
  （`NSFileReadNoSuchFileError`）。这条规则在本教程从第 05 章一直用到第 26 章。

> `subdataWithRange:` 切的是**字节**：切在「中文」两个字的 3 字节中间，解回来就是 nil。
> 和 §3 的码元陷阱同源，只是这次踩的是字节。

## 14) `NSDate` / `NSCalendar` / `NSDateFormatter`

**`NSDate` 就是一个时间点**（不含时区、不含日历），要拿「年月日」必须过 `NSCalendar` +
`NSTimeZone`：

```objc
NSDate *epoch = [NSDate dateWithTimeIntervalSince1970:1700000000];
NSCalendar *utc = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
utc.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
NSDateComponents *c = [utc components:NSCalendarUnitYear | ... | NSCalendarUnitWeekday fromDate:epoch];
NSDate *afterMonth = [utc dateByAddingComponents:plusMonth toDate:jan31 options:0];
```

实测：

```
  ok   NSDate 就是一个时间点：给个 1970 纪元的秒数就能造出来（内部其实按 2001 参考日期存，见下面 description）
  ok   timeIntervalSinceReferenceDate 是相对 2001-01-01 的秒数：两套纪元差 978307200 秒，写死它不如直接用 1970 那套 API
  ok   比较用 compare:/earlierDate:/laterDate:/isEqualToDate:：后两个返回的是**参数里的那个对象**，不是布尔
  description = 2023-11-14 22:13:20 +0000（hasPrefix 2023-11-14 22:13 = 1）
  ok   NSDate 的 description **永远是 UTC**（尾巴上的 +0000 就是它）：和设备时区无关，这是「NSDate 不含时区」最直观的证据
  UTC 分解 = 2023-11-14 22:13 weekday=3
  ok   同一个时间戳，UTC 下是 11 月 14 日 22:13：components 出来的年月日**取决于你给哪个日历哪个时区**
  ok   weekday 是 1..7 且 **1 = 星期日**（不是 0，也不是「1 = 星期一」）：2023-11-14 是周二，所以是 3 —— 这档事最常记错
  ok   东八区同一个戳跨到 15 号早上 6 点：**日历差一天不是 bug，是没指定时区**
  ok   dateFromComponents: 是 components:fromDate: 的反向：没指定的字段按 0 处理（时、分、秒全 0 就是当地零点）
  ok   2024-01-31 加 1 个月 = 2024-02-29：**夹紧**到 2 月最后一天（2024 是闰年，所以 29），不是滚到 3 月 2 日
  ok   加 1 **天**就是 2 月 1 日：dateByAddingComponents: 走日历（会跨月、会尊重月末），dateByAddingTimeInterval: 走秒（不管这些）
  1/31 中午 → 3/15 零点：日历口径 1 个月 14 天 / 物理口径 43.5 天
  ok   jan31 是**中午 12 点**造的（上面 dateFromComponents: 那条），所以到 3/15 零点只有 43.5 天：日历口径给 1 个月 **14 天**，不足一天的那半天直接被丢掉 —— 时间差算「几天」之前先把两边对齐到零点，否则 43.5 和 44 会给你两个不同的答案
  ok   同一对日期，起点是零点还是中午直接影响结果：零点起算给 1 个月 15 天，中午起算给 1 个月 14 天（**整月的判定是「加上去不能超过终点」**，1/31 加一整月要落到 2/29）
  ok   1/31 → 2/15 算得出 **0 个月** 15 天（不是「差半个月」）：months 只数**完整的月**，凑不满一个月就是 0 —— 写「注册了 N 个月」这类文案时，用 month 单独取还是 month+day 一起看，差别就在这
  ok   rangeOfUnit:startDate:interval:forDate: 反推「这一周从哪天开始」：firstWeekday=1 时 1/31 那周从 1 月 28 号（星期1）起，算周报表头就靠它
  ok   rangeOfUnit:inUnit:forDate: 量的是「一天在这个月里排第几到第几」：1..31 —— 拿 length 就是该月天数，写日期选择器要用
  ok   命名时区 timeZoneWithName:@"America/New_York"（名字来自系统的 tz database，拼错就是 nil），secondsFromGMT = -14400
  ok   同一个命名时区，夏天和冬天差整整 3600 秒：**夏令时**就在这一格里 —— 算「两个时刻差多久」要用 NSDate 的秒，算「当地人看到几点」必须给日期问时区
  ok   固定模板 + en_US_POSIX + 固定时区 = 输出可写死进断言：这是「机器读写」的日期格式三件套
  ok   HH 是 0-23（22 点），hh 是 1-12 配 a（10:13 PM）：**只写 hh 不写 a 就丢了半天**，这是日期解析失败的头号原因
  ok   dateFromString: 是反向解析：模板对不上就返回 **nil**（不抛、不猜）
  ok   越界的日期串同样返回 nil：它不做「智能纠正」，所以脏数据安静变 nil，判空不能省
  ok   同一个 2024-12-30：小写 yyyy 给 2024-12-30，大写 **YYYY 是「周所属的年」**（那一周归 2025），给 2025-12-30 —— 跨年的那一周日志/报表日期会整条错一年，这是 OC/Swift 共同的坑
  ok   EEE 是星期缩写（配 locale 才可变中英文）：模板里的字母全是「同一个字母不同大小写 = 不同字段」，所以只能背 + 只能测
  ok   大写 DDD 是**当年第几天**（12-30 是第 365 天），小写 dd 才是当月第几天：两个字母差一个大小写，查日历表时最容易写错
  五档 style： | 11/14/23, 10:13 PM | Nov 14, 2023 at 10:13:20 PM | November 14, 2023 at 10:13:20 PM GMT | Tuesday, November 14, 2023 at 10:13:20 PM Greenwich Mean Time
  ok   dateStyle/timeStyle 五档（No/Short/Medium/Long/Full）就是书上那张枚举表：NoStyle 两个都给的话输出**空串**，Full 会给完整历法名（ICU 数据变了字符串就会变，所以这里只断言相对长度和那一条空串）
  ok   NSISO8601DateFormatter 默认 UTC + 秒，产出 RFC3339/ISO8601 串：跨语言交换日期就该用它，不用自己拼模板
```

书上日期那节的四个坑本章全部实测（时区跨天、`en_US_POSIX`、`HH` vs `hh`、模板不匹配返回
nil），另外补了**五条它没讲的**：

1. **`weekday` 是 1..7 且 1 = 星期日。** 这是全书最容易记错的一格，示例专门断言了它。
2. **月末夹紧**：`2024-01-31` 加 1 个月是 `2024-02-29`（**不是** 3 月 2 日）；加 1 天才是
   `2024-02-01`。`dateByAddingComponents:` 走日历、`dateByAddingTimeInterval:` 走秒。
3. **`components:fromDate:toDate:` 和 `timeIntervalSinceDate:` 两个都对、答案不同**：
   日历口径给「1 个月 14 天」，物理口径给「43.5 天」。**而且起点是零点还是中午会直接改结果**
   —— 示例里那个 `jan31` 是用 `hour = 12` 造的，于是这一对日期只算得出 14 天而不是 15 天。
   算「隔了多久」之前**先把两边对齐到零点**。
4. **`YYYY` 是「周所属的年」**，`2024-12-30` 用 `YYYY-MM-dd` 打出来是 **`2025-12-30`**。
   跨年的那一周日志、报表、缓存 key 会整条错一年。OC/Swift 共同的坑。
5. **`NSDateFormatter` 的五档 `dateStyle/timeStyle` 输出不能写死**：本机打出来是
   `November 14, 2023 at 10:13:20 PM GMT` 这种形状（iOS 16 之后 ICU 换过一次，之前是
   `November 14, 2023, 10:13:20 PM GMT`）。示例只对**两条稳的**下断言：
   `NoStyle` 两档都给时输出**空串**、以及 `Full > Short` 的相对长度。
   这是本章要纠正的**第三条流传说法**：老书里贴的 style 输出字符串今天逐字对不上。

> **`NSDateFormatter` 创建很慢，要复用**；凡是机器读写的固定格式，钉死
> `en_US_POSIX` + `timeZone` + 模板三件；只有「给用户看」的日期才用系统 locale 和 style。
> 跨语言交换日期直接用 `NSISO8601DateFormatter`（示例实测输出
> `2023-11-14T22:13:20Z`，可写死）。

## 15) `NSJSONSerialization`

```objc
NSData *json = [NSJSONSerialization dataWithJSONObject:payload
                                              options:NSJSONWritingSortedKeys error:&err];
id parsed = [NSJSONSerialization JSONObjectWithData:json options:0 error:&err];
id mutableJson = [NSJSONSerialization JSONObjectWithData:json
                                               options:NSJSONReadingMutableContainers error:NULL];
id fragment = [NSJSONSerialization JSONObjectWithData:bare
                                             options:NSJSONReadingAllowFragments error:NULL];
```

实测：

```
  json = {"name":"iOS","tags":["ui","mobile"],"version":18}
  ok   序列化没出错（写不出去时它其实是**抛异常**，见下面）
  ok   NSJSONWritingSortedKeys 让键按字典序输出：不加它键序随机，diff/缓存/断言全废（这条在 debug 和 release 两份输出里也必须逐字节一致）
  ok   解析回来是 id：必须先 isKindOfClass: 再当字典用（JSON 顶层也可能是数组）
  ok   取出来逐个再判类型：JSON 的字符串/数字/布尔在 OC 里分别是 NSString/NSNumber/NSNumber
  ok   JSON 的 null 解析成 **[NSNull null]（类名 NSNull）**、数字成 __NSCFNumber、数组成 __NSArrayI：**没有一个 JSON 数字是「不知道类型的」**，全按 NSNumber 装箱
  ok   true 也是 NSNumber（__NSCFBoolean），取 boolValue 才对：直接当 NSNumber 拿去写进 UILabel 会打出 1
  ok   NSJSONReadingMutableContainers 把**每一层**都做成可变容器（外层 __NSDictionaryM、里层 __NSArrayM）：想改完再写回去就加它，否则改字典里那个数组要先整块取出来改再塞回去
  ok   一个裸串不是合法 JSON（顶层只收对象/数组）：加 NSJSONReadingAllowFragments 才解得出来（类名 NSTaggedPointerString）
  ok   读坏数据：返回 nil + 填 error（domain=NSCocoaErrorDomain code=3840），**不抛**：网络层永远要判 nil
  写坏 JSON：NSInvalidArgumentException —— *** +[NSJSONSerialization dataWithJSONObject:options:error:]: Invalid top-level type in JSON write
  ok   **写**不出去时是抛异常（reason 固定一句 Invalid top-level type in JSON write），**读**坏数据才返回 nil：读写两边的错处理不对称，这是本章最后一条坑
```

这一节把书上的 JSON 小节的三条规矩全部实测，再补一条**它说错了的**：

- **`NSJSONWritingSortedKeys` 必须有**，否则键序随机，diff / 缓存 / 断言全废。
  示例写死整个 JSON 串当断言，debug 与 release 两份输出也必须逐字节一致（这一条同时被
  本教程的「双配置比对」这张安全网验了一遍）。
- JSON 的 `null` → `NSNull`、`true` → `NSNumber`（`__NSCFBoolean`）、数字 → `NSNumber`。
  **JSON 没有 int/double 之分**，取出来一律靠 `intValue`/`doubleValue` 自己选。
- **顶层必须是 array 或 dictionary**（裸串要 `NSJSONReadingAllowFragments`）。
- **本章纠正的第四条流传说法**：老书和很多教程写「`dataWithJSONObject:` 失败时返回 nil
  并填 error」。**错**：示例用 `@try` 接住了真实的崩溃 ——
  `NSInvalidArgumentException: Invalid top-level type in JSON write`。
  **读**坏数据才是「返回 nil + 填 error（code 3840）」。读写两边的错处理不对称，
  这是本章最后一条坑，也是网络层与本地缓存层要分开写错误处理的原因。

> iOS 新代码更常用 Swift 的 `Codable`（第 06、18 章），类型安全得多；
> `NSJSONSerialization` 主要用于 OC 代码、或需要动态字典结构的场景。

## 16) 本章的边界：只能靠探针量、或者根本不能进示例的

示例必须跑在六条判定里（编译日志为空、退出码 0、stderr 为空、stdout 非空、无控制字符、
有结束标记，外加 debug/release 逐字节一致）。所以**会崩的、会乱的、随机器变的**一律
先用独立探针量出来，再把原文抄到这里 —— 这也是你读本章时最该看的一段：这些是**你自己在
真实项目里会撞上的编译器和运行时消息**。

1. **`-Wformat` 拦 `NSUInteger`**（判定 1 要求日志全空，所以这条只能记在这里）：

   ```
   warning: values of type 'NSUInteger' should not be used as format arguments;
   add an explicit cast to 'unsigned long' instead [-Wformat]
   ```

   这正是 §2 里那两个 `(unsigned long)` 强转存在的原因。

2. **`%f` 配 `int` / `%d` 配 `double`**：

   ```
   warning: format specifies type 'double' but the argument has type 'int' [-Wformat]
   ```

   跑出来 `%f` 给 `nan`；反过来 `%d` 配 `double` 给一个和原值无关的大数
   （本次探针 `1390411937`，换机器/换优化等级会变）。**整数走通用寄存器、浮点走 SSE 寄存器，
   两边根本不在同一条流水线上。**

3. **`%@` 打 `char *`**：

   ```
   warning: format specifies type 'id' but the argument has type 'const char *' [-Wformat]
   ```

   探针**直接 signal 11 段错误退出（exit 139）**，连之前那句 `printf` 都没来得及落盘
   （stdout 全在缓冲区里）。`%@` 会对参数发 `description` 消息，`char *` 收到就是垃圾指针。

4. **`valueWithCGPoint:` 不在 Foundation**：

   ```
   error: no known class method for selector 'valueWithCGPoint:'
   ```

   只 `#import <Foundation/Foundation.h>` + CoreGraphics 就没有这个方法，它在 UIKit 的
   `NSValue` 几何分类里。更阴的是：光链接 Foundation 的裸可执行文件里这个方法
   **编得过、跑起来抛 `unrecognized selector`**，因为那个分类是 UIKit 镜像加载时才注册进
   `NSValue` 的。§6 因此 `#import <UIKit/UIKit.h>`。

5. **`-Wnonnull` 只拦一条路**：

   ```
   warning: null passed to a callee that requires a non-null argument [-Wnonnull]
   ```

   `setObject:nil forKey:`、`addObject:nil`、`insertObject:nil atIndex:` 在
   `NS_ASSUME_NONNULL` 的头文件前会被编译器**当场拦住**；而 §11 的下标写法
   `settings[@"temp"] = nil` **却不报**（它走 `setObject:forKeyedSubscript:`，
   那里 `nil` 是合法的「删除」）。同语义两条路，一条有诊断一条没有。

6. **KVC 集合运算符不能走 `valueForKey:`**，抛出的原文：

   ```
   NSUnknownKeyException: this class is not key value coding-compliant for the key sum.self.
   ```

   运算符只在 **`valueForKeyPath:`** 里解析（§8 已按这个写法实测），`@count` 是唯一例外。

7. **拿不遵守 `NSCopying` 的对象当字典 key**，运行时的话术是
   `attempt to insert an object of class X with id Y as a key ... but it does not respond to
   copyWithZone:` —— `reason` 里带**对象地址**，所以 §11 只把规则写全、不在这条上打印原文。

8. **浅拷贝那个坑，探针实测是「还能查到」**：8 个垫料键 + `@[NSMutableString]` 当 key，
   改完里面的那个可变串之后，用同一 key、用新建的同内容 key，**三种查法都命中**。
   但命中是**运气**：外层副本的 `hash` 已经和桶位不一致，Foundation 不承诺任何行为。
   所以 §11 的规则只有一条：**key 用不可变对象。**

9. **三处刻意不打值**：字典/集合的 `description`（顺序与内容随实现变）、`NSSet` 的
   `anyObject`（不保证哪个）、`NSDateFormatter` 的 style 全文（随 ICU 数据版本变，见 §14
   第 5 条）。本章能写死的断言，只有钉死 locale + 时区 + 模板那几条。

10. **换机器会变的东西**（所以别写进你自己的断言里）：`NSString`/`NSNumber` 的私有类名、
    tagged pointer 的指针巧合（04 章 §运算符（三））、plist 字节数、tz database 的时区名、
    ICU 的日期 style 全文、任何渲染相关的量。

## 坑清单

| 现象 | 原因 / 结论 |
|---|---|
| 中文字符串长度不对 | `length` 是 UTF-16 码元数；字节数用 `lengthOfBytesUsingEncoding:` |
| 一个 emoji 被切成两个 | `characterAtIndex:` 拿到半个代理对；按用户字符要走 `enumerateSubstrings:ByComposedCharacterSequences` |
| 两个「看起来一样」的串不相等 | Unicode 组合/分解写法不同，先 `precomposedStringWithCanonicalMapping` |
| `range.location == -1` 判断失败 | `NSNotFound` 是 `NSUIntegerMax`，不是 -1 |
| `%d` 打 `.count` 出来的值不对 | 只取低 32 位（静默截断）；用 `%lu`+`(unsigned long)`，同时会消掉那条 `-Wformat` |
| `%f` 打出 `nan` | 格式符与参数**类别**错配（整数/浮点两条寄存器流水线） |
| `%@` 打成段错误 | `%@` 是给对象的，`char *` 要用 `%s` |
| 拿 `NSNumber` 的 `objCType` 想分 `long`/`long long` | 64 位上都是 `"q"`，分不出；`BOOL` 也是 `"c"` |
| `@3.5` 用 `intValue` 取值变 3 | 转换是**向零截断**；装箱类型不替你保精度 |
| 中文/字母排序结果和预期不符 | `compare:` 按码位排（大写在前、`section10` 在 `section2` 前）；要 Finder 序用 `localizedStandardCompare:` |
| 两个「相等」的对象都在 `NSSet` 里 | 重写了 `isEqual:` 没重写 `hash` |
| 数组越界崩溃 | 下标越界抛 `NSRangeException`（不是返回 nil） |
| for-in 里删元素崩溃 | 遍历中修改集合抛 `NSGenericException`；倒序删或先收集再 `removeObjectsInArray:` |
| `addObject:nil` 崩溃 | 集合不收 nil（`object cannot be nil`），空位用 `NSNull` |
| JSON 每次 key 顺序不同 | 没加 `NSJSONWritingSortedKeys` |
| 改了一个可变对象当 key 的字典后查不到 | 字典**会拷贝 key**（不可变串安全）；真正危险的是**浅拷贝嵌套可变对象** |
| `dict[key] = nil` 少了一条记录 | 下标赋 nil 是**删除**，且编译器不报 |
| 日期差一天/差 8 小时 | `NSCalendar` 没指定 `timeZone` |
| 「隔了一个月」算成 14 天 | 起点没对齐零点；`components:fromDate:toDate:` 只数**完整**的月 |
| 月末加一个月跑到 3 月 | `dateByAddingComponents:` 会**夹紧**到该月最后一天 |
| 跨年那一周日期错一年 | 用了 `YYYY`（周所属年）而不是 `yyyy` |
| 日期串写出去读不回来 | `NSDateFormatter` 没钉 `en_US_POSIX`；或只写 `hh` 没写 `a` |
| style 输出的字符串换系统就变 | ICU 数据版本相关，**不能写死**；只对空串和相对长度下断言 |
| 自定义对象 `writeToFile:` 成 plist 却没报错 | 它返回 `NO`（不抛不印），必须判返回值 |
| `dataWithJSONObject:` 崩了 | **写**失败是抛异常；**读**失败才是 `nil` + `error` |

## 本章的六条通则

把 178 条断言压成六句，下一课（第 06 章的 Swift 面孔）会原样复用：

1. **不可变版返回新对象、可变版就地改。** `stringByReplacing…`/`sortedArrayUsing…`/
   `arrayByAddingObject:`/`setByAddingObject:` 返回新的；`replaceOccurrences…`/`sortUsing…`/
   `addObject:`/`unionSet:` 改自己。命名就是契约。
2. **`nil` 在集合里有三种命运，全都不能靠它表达「空」。** 数组越界 → 异常；
   `addObject:nil` → 异常；`dict[key] = nil` → **删除**。空位只有 `NSNull` 一种写法。
3. **等价的判断只有一套：`isEqual:` + `hash`。** `==` 比的是身份（04 章），
   `NSNumber` 比数值、`NSDate` 比时间点、`isEqualToArray:`/`isEqualToSet:` 逐元素比 `isEqual:`。
4. **顺序未定义的东西要稳定输出必须自己排。** 字典 `allKeys`、`NSSet` 遍历、
   `description`、JSON 键序 —— 四处在同一件事上。
5. **错误处理不对称，逐 API 记。** 字符串/数据解码返回 `nil`；文件读写返回 `nil`/`NO` +
   `NSError`；集合越界/塞 nil/JSON 写非法顶层类型**抛异常**。
6. **一切「看起来一样」的字符串、日期、数字，都要问它到底是哪种编码、哪个时区、哪个类。**
   本章每一个「坑」的底层都是这句话：`length` 是码元、`NSDate` 无时区、`NSNumber` 无类型区分、
   类的真身是私有实现。

---

上一章：[04 Objective-C 语言基础](04-objc-language.md) · 下一章：[06 Foundation（Swift 篇）](06-swift-foundation.md)
