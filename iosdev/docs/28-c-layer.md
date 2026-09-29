# 28 · C 语言层：Swift/ObjC 看见的 C 到底是什么

> 示例：`examples/28_c_layer/main.swift`（C 侧的证据在 `CLBasic.c`、`CLMemory.c`、`CLLayout.c`、`CLBridge.c`，ObjC 侧在 `CLCollect.m`）
> 实测输出见 `build/28_c_layer/stdout.debug.txt`

前面二十七章里，C 一直躲在旁边当「底层方言」：第 26 章调 `sqlite3_prepare_v2`，第 24 章填
`AudioBufferList`，第 21 章起把 `CGContextRef` 传来传去，第 27 章读 `objc_copyClassList(&count)`。
每一处都不难，难的是它们**共用一套和第 4~6 章完全不同的规则**，而这套规则今天没人系统讲了：

- `sizeof(arr)` 传进函数之后从 20 变成 8，长度彻底没了（§3）；
- C 的 `int` 进 Swift 是 `Int32`，Swift 的 `Int` 对应的是 C 的 `long`（§18）；
- `malloc` 之后不判空是 UB 的反面教材，但本章实测：把「分配 + 判空」写在同一个函数里，
  `-O2` 会把判空连同那次分配一起删掉，你量到的是编译器不是分配器（§15）；
- 结构体字段换个书写顺序，`sizeof` 从 12 掉到 8（§7）；
- C 的枚举进 Swift 不是 `enum`，而是个 `RawRepresentable` 结构体，`switch` 穷尽不了（§18）；
- `char *` 交给 `%s` 打中文会变乱码，交给 `%@` 不会——同一个字节流的两种解释（§17）；
- `va_arg`、函数指针、`NSError **`、`@convention(c)`、宏的可见性，全是跨界时要付的账（§12/§13/§17/§20/§22）。

这本书的第 4 章（外加第 2、3 章的语言基础）就是讲 C 的，但它是十多年前写的：里面把 `int`
当「机器字长」、用 `char *` 存中文并拿 `strlen` 数「字数」、把 `malloc` 返回值直接赋给对象指针、
用宏定义所有常量。今天这四样都要改写。所以本章把同一批知识点按今天的规则重讲一遍，
并且把**每一处「C 和 Swift 说法不一样」的地方并排量一次**——这是 Swift 开发者读 SDK 头文件、
读崩溃栈、读开源 C 库时真正需要的那层底子。

```
底子   §1  数据类型：尺寸、范围、char 有没有符号、除法取整方向、浮点的两个上限
运算   §2  自增、优先级、位运算与移位、短路、四种循环、switch 掉 break、goto 清理段
内存   §3  数组就是连续内存：退化、指针相减的单位、行主序、二维数组
字节   §4  字符数组与 C 字符串：sizeof 与 strlen 差那个 0、插一个 0 就截断、同一个字节的两种解释
指针   §5  指针加一 = sizeof(指向的类型)；void* + 1 的「标准没定义、clang 照收」
出参   §6  二级指针与 out 参数：C 只有一个返回值，NULL 要函数自己挡
布局   §7  结构体对齐与 padding：字段顺序真的能省 4 个字节
位模式 §8  联合体看浮点：IEEE 754 三段、正零与负零是两块不同的内存
枚举   §9  C 枚举的尺寸与**底类型符号性**（一个能测出来的冷知识）
句柄   §10 手写 Create/Retain/Release：CoreFoundation 全系列的形状
函数   §11 值传递换不动任何东西、递归的代价
变参   §12 va_list 的 count 是唯一的护栏；Swift 连这类函数都调不了
回调   §13 函数指针表、qsort/bsearch、越界就是 NULL
搬内存 §14 memcpy 与 memmove：重叠区交给 memcpy 是 UB（两种优化级别两个答案）
分配   §15 malloc/calloc/realloc：分配器真说的话只有跨编译单元才听得到
宏     §16 括号、参数展开两次、do{...}while(0)、# 与 ##、条件编译
边界   §17 C 与 ObjC：@encode、结构体属性、NSError **、block 与函数指针
映射   §18 Swift 看见的 C 类型：int->Int32、long->Int、枚举不是 enum、溢出的三种语言规则
借用   §19 withUnsafeBufferPointer / withUnsafeBytes：padding 会被一起搬走
函数   §20 @convention(c)、qsort 的两条路、带捕获的闭包为什么交不出去
字符串 §21 字节与字符是两套计数：17 个字节、7 个字符、6 个 strlen
可见性 §22 宏哪些进得了 Swift，NSError ** 怎么变成 throws
边界   §23 哪些是量出来的、哪些只能记编译器原文、换 arm64 会变什么
```

## 本章的方法：三处证据各干一件事

本章是全教程第一个**三方混编**示例：同一份 C 代码分别被当作 C 编译、被 ObjC 引用、被 Swift 桥接。
`run-all.sh` 见到目录里有 `Bridging.h` 就走混编路径，实际执行的命令是：

```
1) clang -c -O2 -std=gnu11 -fmodules -Wall -Wextra -Wno-unused-parameter \
         -isysroot $SDK -target x86_64-apple-ios15.0-simulator -I <示例目录> \
         CLBasic.c -o build/28_c_layer/CLBasic.<cfg>.o      # 每个 .c 单独一遍，注意没有 -fobjc-arc
2) (cd build/28_c_layer && swiftc -c -Onone|-O -sdk $SDK \
         -target x86_64-apple-ios15.0-simulator -module-name c_layer \
         -import-objc-header Bridging.h main.swift)          # 再编 Swift，.o 落在 build 目录里
3) clang -c -O2 -std=gnu11 -fobjc-arc -fmodules -Wall -Wextra -Wno-unused-parameter \
         -isysroot $SDK -target x86_64-apple-ios15.0-simulator -I <示例目录> -I <build目录> \
         CLCollect.m -o build/28_c_layer/CLCollect.<cfg>.o   # 最后编 .m
4) swiftc -Onone|-O -sdk $SDK -target … main.swift.o CLCollect.<cfg>.o CLBasic.<cfg>.o … \
         -o build/28_c_layer/28_c_layer.<cfg> \
         -framework Foundation -framework UIKit -framework SwiftUI   # 链接由 swiftc 驱动
5) xcrun simctl spawn <模拟器> build/28_c_layer/28_c_layer.<cfg> --selftest
```

步骤 1 和 3 分开是必须的：`-fobjc-arc` 传给 `.c` 会立刻冒出一条「argument unused during
compilation」告警，而判定 1 要求编译日志一个字节都没有。这条坑写在 `run-all.sh` 的注释里，
本章是第一次真的踩到它（27 章只有 `.m`，没有纯 C 文件）。

三处证据的分工是这一章的写法本身：

- **`*.c` 只负责「量」**。`CLBasic.c` / `CLMemory.c` / `CLLayout.c` / `CLBridge.c` 里没有一行
  `printf`（六条判定里 stderr 必须为空，而 C 的 `printf` 混进 ObjC 运行时的 stdout 缓冲会打乱顺序）。
  每个函数回答一个可以断言的小问题，答案全是整型：`size_t CLSizeofInt(void)`、
  `int CLCharIsSigned(void)`、`size_t CLOffsetIInA(void)`。
- **`CLCollect.m` 负责「说」**。它把数字排成中文行，一节一个 `CLLines*` 函数，
  统一走一根全局数组黑板（`CLLBegin` / `CLLAdd` / `CLLResult`），一节开始前清空、动作过程里
  谁执行谁追加一行、最后整块交出。这样「断言里出现的顺序」就是真实执行顺序。
  它同时是 §17 的主角：只有 ObjC 侧能讲 `@encode`、结构体属性、`NSError **`、block。
- **`main.swift` 负责「印」，并且是本章的另一半主角**。§18~§22 问的是
  「Swift 看见的 C 是什么」，这些问题在 C 侧根本不存在（Swift 没有 `sizeof`，也没有裸指针运算），
  只能在 Swift 里断言；而 §1~§17 由 Swift 逐条 `expect` 复核 C/ObjC 交上来的每一行。

另有六条硬约束，和 27 章同一套：`.c` 不 `printf`、`.m` 不 `NSLog`；不打印任何指针值、地址、
耗时、进程内总量（「是不是同一个函数」「字面量有没有合并」一律只打「是/否」）；会崩、会 UB 的调用
只在独立探针里跑，正文以「探针记录」引用原文；§10 的不透明句柄每造一个就还一个，§17、§22 收尾
各打一次「本章造的还活着几个」，必须是 0；所有数值都是这台 `x86_64-apple-ios15.0-simulator` 上的
实测值，换 arm64 会变的那批列在 §23；中文只走 `%@`，`%s` 打 UTF-8 是 §17 的反面教材。

一个必须提前说明的细节：**`.c` 与 `.m` 两种配置下都是 `-O2`**，只有 Swift 跟着配置变
（debug 是 `-Onone`，release 是 `-O`）。这不是疏忽，是本章 §15 能成立的前提——
「优化器把 `malloc` 删了」这条结论必须在两种配置下给出同一份输出，否则六条判定的
「debug/release 输出逐字节一致」就过不了。副作用是好事：`-O2` 才有的折叠在两个配置里都稳定复现。

最后一节 `main.swift` 自己会打印一份「哪些量到了、哪些只能记」的清单，那份清单也在下面的
实测输出里，本章所有不能进示例的部分（UB、崩溃、编译器诊断）都收在那里。

## 1) 数据类型：尺寸是量出来的，范围是实现定义的

第 4 章开头那张「`int` 是 4 个字节、`long` 看机器」的表，今天仍然要背，但要背得准确：
只有 `char`、`long long` 和指针族是**到哪都一样**的，`long` 和 `char` 的符号性是实现定义。
示例把这些全量了一遍（C 侧 `CLBasic.c` 出数，ObjC 侧排版，Swift 侧逐条断言）：

```
== §1 数据类型：尺寸、范围与转换 ==
sizeof（单位是字节，目标 x86_64-apple-ios15.0-simulator）：char=1, short=2, int=4, long=8, long long=8, float=4, double=8
指针家族：int *=8, size_t=8, ptrdiff_t=8 —— size_t 是「sizeof 的类型」，ptrdiff_t 是「两指针相减的类型」，宽度都跟指针一致
对齐：_Alignof(int)=4, _Alignof(double)=8（结构体的对齐由最宽成员决定，见 §7）
long 在这台机器上是 8 而不是 4：这是 LP64（Apple 全线）；Windows 的 LLP64 上 long 是 4、long long 才是 8。所以「要固定宽度」的地方该写 int32_t / int64_t，别赌 long
裸 char 有没有符号：是（SCHAR_MIN=-128, SCHAR_MAX=127）。「char」的符号是实现定义、不是标准规定的，要当数值用就必须显式写 unsigned char —— §4 那两个字节就是后果
范围与溢出：INT_MAX=2147483647；无符号 +1 = 2147483648。无符号回绕是**有定义**的（模 2^n），有符号溢出是**未定义**的，所以本章一次都不量后者
整型除法向 0 取整：7/2=3，-7/2=-3（不是 -4）；余数符号跟被除数：7%2=1，-7%2=-1
这条是 C99 明确保证的恒等式：(a/b)*b + a%b == a。取整方向定了，余数就得跟着变 —— 「向下取整 + 余数非负」是另一套规则，Python 走那一套（-7//2 = -4、-7%2 = 1）；Swift 和 C 这套完全一致，§1 末尾两边各算一遍。跨语言写取模哈希时最容易翻车的就是这一点
整型提升：两个 char 相加，结果类型是 int（sizeof=4，不是 1）—— C 里小整型的运算其实都在 int 上做，只有存回去那一刻才截断
浮点转整数一律向 0 截断：(int)3.9=3，(int)-3.9=-3（不是 -4）
0.1 + 0.2 == 0.3 ？ 否。两条 double 的位模式：4599075939470750516 和 4599075939470750515，差 1 —— 正好 1 个 ULP（最后一位）。浮点比较要么留容差，要么换整数/十进制
float 只有 24 位有效尾数：(float)16777217 == (float)16777216 ？ 是 —— 超过 2^24 的整数别塞进 float
  ok   sizeof(char) == 1 是**标准规定**的，不是实测出来的：C 用「字节」定义 sizeof，而一个 char 就是一个字节
  ok   int=4, long long=8：只有 long long 到哪都是 8，long 不能赌
  ok   本机 sizeof(long) == sizeof(int *) == 8（LP64）—— 所以 C 里 long 能装下指针，int 装不下
  ok   size_t 与 ptrdiff_t 也和指针同宽（8 / 8）
  ok   无符号回绕有定义：INT_MAX+1 = 2147483648；有符号溢出是 UB，本章一次都没量
  ok   -7/2=-3、-7%2=-1：向 0 取整，余数跟着被除数
  ok   同一条表达式 Swift 自己算一遍：-7/2=-3、-7%2=-1，和 C 逐字一致 —— 「向 0 取整 + 余数跟被除数」这一套 Swift 原样继承了 C。另一套「向下取整 + 余数非负」是 Python 的规则（-7//2 = -4、-7%2 = 1），跨语言写取模哈希才是真会翻车的地方
  ok   恒等式 (a/b)*b + a%b == a 在 C99 之后成立：3*2+1=7
  ok   整型提升：两个 char 相加的结果类型是 int（sizeof=4，不是 1）
  ok   (int)-3.9 = -3：浮点转整数也是向 0 截断，不是向下取整
  ok   0.1+0.2 != 0.3，位模式差 1（1 个 ULP）：这就是「浮点别用 ==」的物证
  ok   float 装不下 2^24+1：被吸成了同一个数
```

四条值得单独说：

**「`sizeof(char) == 1`」不是实测。** C 用字节定义 `sizeof`，而一个字节就是一个 `char`，
这句话在任何一台机器上都真，所以它是本章唯一一条**先验**断言。反过来说，
`sizeof(char) == 1` 完全不告诉你 `char` 有几个 bit（`CHAR_BIT` 才是这个信息，标准只保证 ≥8）。

**`long` 是本章第一个「别赌」的类型。** Apple 全线是 LP64（`long` 和指针都是 64 位），
Windows 是 LLP64（`long` 仍是 32 位）。同一段 `long` 代码换平台就换个宽度，
所以今天要写 `int32_t` / `int64_t`。SDK 里那些 `long` 返回值（比如 `objc_copyClassList` 的 count）
桥到 Swift 会变成什么，§18 有对照。

**除法的取整方向决定了余数的符号。** C99 之前连这一条都没定死，C99 之后定为「向 0 取整」，
于是恒等式 `(a/b)*b + a%b == a` 成立、余数符号跟着被除数。这一条经常被写成
「Swift 和 Python 都是另一套」，**实测下来只有 Python 是另一套**：Swift 的 `/` 与 `%` 和 C 完全一致
（示例里 Swift 侧自己算了一遍 `-7/2 = -3`、`-7%2 = -1`，和 C 逐字相同）。
真正会在跨语言实现里翻车的是 Python 的「向下取整 + 余数非负」——写哈希分片、
写取模配色，Python 侧和 C/Swift 侧给出的余数符号能差一个。

**浮点的两个上限各管一件事。** `0.1 + 0.2 != 0.3` 是**十进制小数在二进制里没有精确表示**，
示例把两条 `double` 的位模式取成整数相减，差正好 1（最后一个 bit），这就是「1 个 ULP」的物证；
`2^24 + 1` 装不进 `float` 是**尾数只有 24 位**，超过就是丢，不报错、不 trap。
前者告诉你浮点别用 `==`，后者告诉你「用 float 存自增 ID / 存像素坐标整数」什么时候开始出错。

## 2) 运算符与控制语句：少一个 break 不报错，短路是省时间的正规手段

这一节是第 2、3 章的内容，但示例把每一条例成可断言的计数（`CLBasic.c` 里每个函数返回一个整数）：

```
== §2 运算符与控制语句 ==
自增：i=5 时 a=i++ 让 a=5，紧接着 b=++i 让 b=7 —— 后缀先交旧值再自增，前缀先自增再交新值
优先级：2 + 3 * 4 = 14；三目那条 a>b ? a : b+1（a=3,b=4）= 5 —— ?: 的优先级比 + 低，所以加的是 b 那一支
位运算（12=1100, 10=1010）：&=8, |=14, ^=6, ~0=-1（取反连符号位一起翻，所以是 -1）
移位：1u<<31 = 2147483648，转成 int 就是 -2147483648；-8>>1 = -4（有符号右移补符号位）；(unsigned)-8 右移一位再转回 int = 2147483644（高位补 0，得到一个很大的正数）
注意 1<<31 直接对有符号 int 写是未定义行为（结果超出 int 范围），所以这里从无符号出发再显式转回来。位标志一律用无符号类型
短路：0 && f() 让 f 跑了 0 次，1 || f() 跑了 0 次，1 && f() 跑了 1 次 —— 右边执行与否只看左边够不够定结论，这就是把昂贵判断放在 && 右边的理由
循环：for 0..9 求和 = 45；while 计到 10；条件一开始就为假的 do-while 仍跑 1 次（它先执行再判断）；for 里 continue 计到 5 个奇数
break 只出最内层：5x5 双层、靠 done 标志停外层的那段走了 13 步 —— C 没有「跳出外层」的语法，只能标志位或者 goto
switch 少写一个 break：case 0 会连着执行 case 1，循环 0..2 累加出来 = 121（1+10，再 10，再 100）。少写 break 不报错，只会静默地把下一支也跑了；clang 有 -Wimplicit-fallthrough 专管这件事，但本机量下来和教科书说法不一样：
  这条警告不在 -Wall -Wextra 里（本章的编译参数就是这个组合，少写 break 的那个版本一个诊断都没有），必须显式点名才响；点名之后，「// fall through」一类的注释在这台 Apple clang 16 上一种都压不住警告，只有 __attribute__((fallthrough))（以及 C23 的 [[fallthrough]];）行 —— 五种注释写法的原文见 §23 探针记录。所以本节这段用的是属性而不是注释
default 写在最前面也一样是兜底：case 2 命中 -> 22（位置不影响匹配，只看有没有别的 case 对上）
C 没有异常，出错就一路 goto 到清理段：顺利那条返回 11。顺带一条：free(NULL) 是合法的，所以清理段里的 free 可以无条件写
  ok   i++ 交旧值（5）、++i 交新值（7）：差的就是那一次自增的时机
  ok   2 + 3 * 4 = 14：乘除优先于加减，这条背不住就全部加括号
  ok   a>b ? a : b+1（a=3,b=4）= 5 —— ?: 优先级低于 +，所以 b+1 整个是第三支；写括号才是正解
  ok   12&10=8, 12|10=14, 12^10=6：位标志、开关状态全靠这三个
  ok   ~0 = -1：取反连符号位一起翻，所以「0 变 -1」不是 bug
  ok   1u<<31 = 2147483648，转成 int 变 -2147483648：同一串位的两种解释，所以位标志必须一路用无符号
  ok   -8>>1 = -4：有符号右移补符号位（实现定义，本机是算数右移），所以 >> 不能当「除以 2」用在负数上
  ok   短路实测：0&&f() 跑 0 次、1||f() 跑 0 次、1&&f() 跑 1 次
  ok   do-while 条件一开始就是假，仍跑了 1 次：它先执行再判断
  ok   少一个 break 的 switch 累加出来是 121（1+10, 再 10, 再 100）：静默往下跑。本章的编译组合就是 -Wall -Wextra，一个诊断都没有 —— 这条警告不在里面，得显式点名（探针记录见 §23）
  ok   default 写在最前面也还是兜底：case 2 命中拿到 22
  ok   goto 清理段那条顺利路径返回 11：C 没有异常，出错就一路 goto —— iOS 底层代码全是这个形状，读得懂它才算读得懂 SDK
```

**`~0 == -1` 与 `1u<<31` 转成 `int` 是同一个知识点：位没变，解释变了。** 补码里 `~0` 全 1，
那就是 -1；`1u<<31` 是无符号的 2147483648，同一串位按 `int` 解释就是 -2147483648。
所以位标志必须**一路用无符号类型**：中间只要有一次被塞进 `int`，最高位那个标志位就变成负数，
后面所有比较全错。这也是 SDK 里 `CFCalendarUnit`、`UIViewAutoresizing` 这类
`NS_OPTIONS` 底类型写成 `NSUInteger`（无符号）的原因。

**有符号右移是实现定义的。** 本机是算术右移（补符号位），于是 `-8>>1 == -4`，
看着像「除以 2」；但同一行代码在别的实现上可能高位补 0，得到 2147483644。
所以「对负数用 `>>` 当除法」是不可移植的写法，无符号才可以用 `>>`。

**短路是语言保证，不是编译器优化。** 示例真的数了 `f()` 被执行几次（0/0/1），
这是把昂贵判断放在 `&&` 右边的正规理由；也是 §6 里「先判 NULL 再解引用」能写成一句 `if (p && *p > 0)` 的前提。

**这一节最实用的一条是 `switch` 掉 `break`，而它的「常识版本」在这台工具链上是错的。**
教科书说「写一句 `// fall through` 注释就不会被警告」。示例为此专门跑了一组编译参数矩阵
（源码在独立探针里，正文以「探针记录」引用原文）：

```
    10) -Wimplicit-fallthrough 的真实开关条件（§2 用它替代了教科书说法）。同一段 case 0 少写 break 的代码：
         -Wall -Wextra                        -> 一个诊断都没有（本章编译用的就是这个组合）
         -Wall -Wextra -Wimplicit-fallthrough -> warning: unannotated fall-through between switch labels [-Wimplicit-fallthrough]
             外加两条 note：insert '__attribute__((fallthrough));' to silence this warning / insert 'break;' to avoid fall-through
       开着这条警告，逐个试教科书里那些「写句注释就行」的写法，每个都仍然警告（各 1 条）：
         // fall through、/* fall through */、/* fallthrough */、/* FALLTHRU */、/* falls through */、/* -FALL-THROUGH- */
       换成 __attribute__((fallthrough)); 或 -std=c2x 下的 [[fallthrough]]; 才是 0 条。
       另外 -Wimplicit-fallthrough=1..5 这种带级别的写法在这台 Apple clang 16 上直接是
         warning: unknown warning option（它只收不带 =N 的形式），所以级别调不了。
       结论：本章那段 fallthrough 演示用的是属性写法；「注释里写 fall through 就行」在这台工具链上量不出来。
```

于是示例里那段故意掉 `break` 的代码用了属性而不是注释（`CLBasic.c`）：

```c
            case 0:
                total += 1;
                __attribute__((fallthrough));   // 少写这一行，case 1 也会被跑一遍
            case 1:
                total += 10;
                break;
```

结果是 121（1+10、再 10、再 100），并且两种配置逐字节一致。**工程结论**：`-Wall -Wextra`
拦不住掉 `break`，真要靠编译器兜底就得显式开 `-Wimplicit-fallthrough`，
而开了之后能压住它的只有 `__attribute__((fallthrough))` / C23 的 `[[fallthrough]]`。

**`goto` 清理段是 iOS 底层代码的常态，不是落后写法。** C 没有异常，
「一路 `goto fail;` 再统一 `free`」就是它的错误处理协议。`free(NULL)` 合法这条在这里格外重要：
清理段里的 `free` 可以无条件写，不需要判断这个指针有没有被赋过值。
读 `sqlite3`、`libdispatch`、任何 Apple 的 C 层实现，看到的全是这个形状。

## 3) 数组就是连续内存：传进函数那一刻，长度信息彻底没了

```
== §3 数组就是连续内存 ==
5 个 int 的数组：sizeof = 20 字节；元素数 = sizeof(a)/sizeof(a[0]) = 5 —— 这个除法是 C 里数组长度的唯一算法，而且只在数组还没退化的地方成立
&a[3] - &a[0] = 3（单位是「元素」）；先转成 char * 再相减 = 12 字节。指针相减的结果永远是元素数，这是最容易记错的一条
二维数组 int m[2][3] 是行主序连续存放：换行的字节跨度 = 12（正好一行 3 个 int），m[1][2] = 6（值没被搬走）
数组名还没退化时，&a 的类型是「指向整个数组的指针」int(*)[5]，它加一跳过整块 = 20 字节，不是 4
纯指针算术求和 *(a+i) = 150 —— 和 a[0]+…+a[4] 是同一个数，a[i] 本来就是 *(a+i) 的语法糖
退化实测：本地数组 sizeof = 20；同一个数组传进函数之后 sizeof = 8。传进去的已经不是数组，只是一个地址，长度信息彻底没了
所以 C 的数组参数必须另外带一个 count：memcpy(dst, src, n)、objc_copyClassList(&count)、sqlite3_prepare_v2(..., nByte) 里那个「多出来的长度参数」全是同一个原因
  ok   sizeof(int[5]) = 20、元素数 = 5：这个除法只在数组没退化的地方有效
  ok   &a[3]-&a[0] = 3 个元素，转成 char* 再减 = 12 字节 —— 指针相减的单位永远是元素
  ok   行主序：换行跨 12 字节，m[1][2] 仍是 6
  ok   int(*)[5] 加一跳过整块 20 字节：&a 和 a 差的是类型，不是值
  ok   同一个数组：本地 sizeof = 20，传进函数之后 = 8 —— 退化掉了长度
```

**`sizeof(a)/sizeof(a[0])` 只在数组还没退化的地方成立。** 这一条是 C 数组的全部真相：
函数签名里写 `int arr[5]`，编译器收下之后按 `int *arr` 处理，`sizeof(arr)` 给出的是指针宽度 8。
探针记录里那条编译器原文值得背下来：

```
    5) 数组退化。源码：long f(int arr[5]) { return (long)sizeof(arr); } 的编译器原文：
         warning: sizeof on array function parameter will return size of 'int *' instead of 'int[5]' [-Wsizeof-array-argument]
       本章的函数刻意写成 int *arr（§3），所以这条警告不会自己冒出来 —— 它是你「以为长度还在」时唯一的哨兵。
```

于是 SDK 里每一个「数组参数」旁边都跟着一个长度参数：`memcpy(dst, src, n)`、
`objc_copyClassList(&count)`、`sqlite3_prepare_v2(db, sql, nByte, ...)`、
`CGContextFillRects(ctx, rects, count)`。看到「指针 + 一个整数」这对组合，条件反射就该是
**那个整数是元素个数还是字节数**——这两种写法在 C 里都存在，混了就是一次越界。

**指针相减的单位永远是元素。** `&a[3] - &a[0]` 得 3，不是 12；想要字节数就 `(char *)&a[3] - (char *)&a[0]`。
`sizeof(*p)` 与元素数同理跟着类型走。这一条在遍历（`for (int *p = a; p < a + n; p++)`）里最容易写歪。

**`&a` 和 `a` 是同一个地址、两种类型。** `int(*)[5]` 加一跳过整块 20 字节，`int *` 加一跳 4 字节。
值相同、类型不同，所以「两个指针长得一样不代表算术一样」在 C 里是字面意义上的。

## 4) 字符数组与 C 字符串：长度不是存的，是数到 0 数出来的

```
== §4 字符数组与 C 字符串 ==
字面量 "中文"：sizeof = 7 字节，strlen = 6 字节 —— 差的 1 是结尾的 '\0'。C 字符串没有长度字段，长度是「数到 0」
源文件是 UTF-8，一个中文字占 3 个字节，所以 "中文" 的 strlen = 6；ASCII 的 "iOS" 才是 3。C 层根本没有「字符」这个概念，只有字节
char s[] = "abc" 的 sizeof = 4（把字面量连结尾 0 一起复制进栈）；而 const char *s = "abc" 的 sizeof 是指针宽度 —— 同一个名字，两种东西
手动把 s[2] 写成 '\0'，strlen 立刻变 2 —— 「长度」完全由第一个 0 决定，写坏一个字节就当场截断
同一个字节（"中" 的首字节 0xE4）：按 char 取到 -28，按 unsigned char 取到 228。字节没变，是「char 有没有符号」把它解释成了两个数 —— 拿 char 存像素、存二进制就会出这种事
同一个 .c 里两处 "merged-check"：编译器把相同字面量合并成同一份了吗？是 （只打布尔；地址每次运行都不同，绝不进输出）
strcmp 比的是内容不是地址：字面量 "iOS" 和一份 memcpy 出来的副本（两块不同的内存）strcmp 返回 0 吗？是（0 才是相等）；"abc" 对 "abd" 的返回值归一化之后是 -1（前小后大）。只有符号是可靠的，别断言它等于 -1
  ok   "中文"：sizeof=7（含结尾 0），strlen=6（两个汉字 × 3 字节）
  ok   "iOS" 的 strlen=3，而 char s[]="abc" 的 sizeof=4：C 字符串的长度里永远含那个 0
  ok   插一个 '\0' 之后 strlen 变 2：写坏一个字节就等于截断
  ok   同一个 0xE4 字节：char 读出 -28，unsigned char 读出 228 —— 存二进制/像素就必须写 unsigned
  ok   strcmp 比内容：字面量和它的 memcpy 副本返回 0 吗 = 是（相等）；"abc" vs "abd" 的符号归一成 -1 —— 只取符号，不认具体数值
```

**「`sizeof` 比 `strlen` 大 1」不是巧合，是「结尾那个 0 占一格」。** 由此推出 C 字符串的三个实操纪律：
拷贝时长度要 `+1`（`memcpy(dst, src, strlen(src) + 1)`）；`strncpy` 补不满时**不保证**有结尾 0，
所以要自己补；任何一个字节被写坏成 0，字符串就当场变短——示例真的演示了这一手（`s[2] = '\0'`
之后 `strlen` 立刻从 5 掉到 2），这就是缓冲区溢出最常见的可见症状：不是崩，是**内容莫名其妙短了**。

**C 层没有「字符」，只有字节。** 源文件是 UTF-8，所以 `"中文"` 的 `strlen` 是 6，
`"iOS"` 才是 3。这一条直接推掉书里那句「用 `char *` 存中文、用 `strlen` 数长度」的写法：
`strlen` 给你的是字节数，不是「几个字」。§21 会把这三套计数（字节 / UTF-8 码元 / 用户可见字符）并排量一遍。

**同一个字节两种读法，是 §1「`char` 有没有符号是实现定义」的后果。** `0xE4` 按 `char` 读是 -28，
按 `unsigned char` 读是 228。存像素、存二进制、做哈希时误用 `char`，负数会被符号扩展进
`int`，于是同一张图在 arm64（`char` 无符号）和 x86_64（本机 `char` 有符号）上算出不同的值。
要存字节就写 `unsigned char` 或 `uint8_t`，这是唯一的正规写法。

**`strcmp` 的返回值只有符号可靠。** 标准说的是「小于 0 / 等于 0 / 大于 0」，具体数值是实现定义的。
示例把返回值归一成 -1/0/1 再断言，并在文字里明确「别断言它等于 -1」——
断言了具体数值的代码换一个 libc 就挂。字面量合并那条（两处相同的 `"merged-check"` 是不是同一份内存）
只打「是/否」，地址绝不进输出，因为每次运行都不同。

## 5) 指针加一：一步走多远由类型决定，void 没有大小所以这步没有定义

```
== §5 指针运算 ==
指针加一前进多少字节 = sizeof(指向的类型)：char*=1, int*=4, long*=8, double*=8
对照 sizeof：int* 那一步 4 == sizeof(int)=4；double* 那一步 8 == sizeof(double)=8 —— 一条规则同时解释了两件事
void* 加一：1 字节。void 没有大小，所以标准 C 根本没有定义这条运算（C 规范把它列为约束违规）—— 但 clang 默许它，按 GNU 扩展当成 1 字节：换成 -std=c11 照样编过，只有加 -pedantic 才出一句 warning（原文见 §23 探针记录）。编译器不拦不等于标准允许：这一行没有任何标准保证它可用
所以跨平台的 C 代码别写 void* + 1：先转成 char */uint8_t *，或者用下标
  ok   加一步的字节数：char*=1, int*=4, long*=8, double*=8
  ok   指针加一 = sizeof(指向的类型)：int* 的 4 步 == sizeof(int)=4，一条规则解释全部
  ok   void* + 1 在 clang 这儿给 1 字节：标准 C 没定义这条运算，可它连 -std=c11 都能编过，只有 -pedantic 会警告（探针记录见 §23）—— 「编译器不拦」和「标准允许」是两件事
```

四种指针各量一遍，和 `sizeof` 并排打出来，这条规则就不需要背了：**`p + 1` 前进
`sizeof(*p)` 个字节**。`a[i]` 就是 `*(a + i)` 的语法糖（§3 用纯指针算术求和得到同一个 150 来证明）。

`void * + 1` 是本章第一次遇到「教科书说它是编译错误，实测不是」。探针原文：

```
    6) void* + 1 的标准化程度。同一行代码：
         -std=c11 -Wall -Wextra            -> 编译通过，一个诊断都没有
         -std=c11 -Wall -Wextra -pedantic  -> warning: arithmetic on a pointer to void is a GNU extension [-Wgnu-pointer-arith]
       「标准 C 里这是编译错误」这句话在这台机器上量不出来：clang 连 -std=c11 都不拦，
       只在 -pedantic 下提醒一句。约束违规是规范层面的措辞，编译器有权宽容。
```

结论不是「可以放心用」，而是**反过来用**：标准没定义 = 没有任何保证，编译器宽容只是它今天的宽容。
工程写法是先转成 `char *` / `uint8_t *` 再做算术，或者干脆用下标。
这条也在 Swift 侧再出现一次——`UnsafeRawPointer` 的 `advanced(by:)` 参数单位是**字节**，
而 `UnsafePointer<T>` 的是**元素**（§19），同样是「类型决定步长」。

## 6) 出参与二级指针：C 只有一个返回值，多出来的结果只能靠地址带出去

```
== §6 出参与二级指针 ==
三个出参一次填满：11, 22, 33 —— C 函数只有一个返回值，要往外带多个结果就靠指针
二级指针取值 **pp = 42（pp 指向「那个指针」，p 指向那个 int）
传地址进去：返回码 = 0、出参被写成 7；传 NULL 进去：返回码 = -1，函数没崩 —— C 不会替你检查 NULL，检查是函数自己该做的事
这就是 CoreFoundation 的签名形状（OSStatus/返回码 + 出参），也正是 ObjC 把它包成「返回 BOOL + NSError ** 出参」的原因 —— §17 有并排对照
顺带一条：OC 属性/参数上那个 `out` 关键字是给 Swift 的所有权提示（决定桥接成 inout 还是只读），对 C 本身没有任何作用
  ok   三个出参填满：11, 22, 33 —— C 只有一个返回值，多结果只能靠指针
  ok   二级指针 **pp 读到 42：先取那个指针，再取它指向的值
  ok   传地址 -> 返回 0 且出参被写成 7；传 NULL -> 返回 -1 且没崩：C 函数必须自己挡 NULL
```

`int CLRead(int *out)` 这种签名是 CoreFoundation 的呼吸：返回码说明成没成，出参装结果。
示例同时喂了两条路：给地址（返回 0，出参被写成 7）和给 `NULL`（返回 -1，不崩）。
**「传 NULL 不崩」不是运气，是函数自己写了 `if (out == NULL) return -1;`** ——
C 里没有任何机制替你检查地址，这是库作者的义务，也是读别人 C 代码时第一个要看的地方。

「出参」这个概念在 ObjC/Swift 桥接里长成了三个不同的东西，本章分别在 §17、§22 演示：
ObjC 的 `NSError **`、Swift 的 `autoreleasing` 与 `inout`、以及 Swift 的 `throws`（编译器把
「返回码 + 出参」自动接成 `try` 的成败两条路径）。OC 属性修饰符里那个 `out`
（`@property (out)`）在这里顺手澄清：它是给 Swift importer 的所有权提示，对 C 语义零影响。

## 7) 结构体布局：字段顺序真的能省 4 个字节

```
== §7 结构体布局与对齐 ==
同样三个字段、三种书写顺序：{char,int,char}=12 字节，{int,char,char}=8 字节，{char,char,int}=8 字节 —— 最大最小差 4
差在哪：A 里 i 前面挤了两个 1 字节，而 int 要按 4 对齐，于是中间填了 3 个、尾部又补了 3 个：offsetof(i)=4, offsetof(d)=8；B 把同类挤一起：offsetof(i)=0（就在开头）
B 和 C 一样大（8 vs 8）：字节排好之后，c/d 谁在前不影响尺寸
嵌套：struct{ CLPackB origin; int extra; } 的 sizeof = 12，offsetof(extra) = 8 —— 内层结构体的对齐会向外传染
_Alignof(struct CLPackA) = 4：结构体的对齐等于它最宽成员的对齐，不是它自己的尺寸
这条规则在工程里是真能省内存的：字段按宽度从大到小排，结构体就可能小一档；交错着写就白填一堆 padding。反过来「靠 padding 对齐到 2 的幂」也是故意做的 —— 看 offsetof 就能分清哪种是哪种
  ok   {char,int,char}=12 字节，{int,char,char}=8 字节：同样的字段，光改顺序就省 4 个字节
  ok   A 里 i 的偏移是 4（前面补了 3 字节才对齐），d 在 8 —— 尾部还要补到 12
  ok   B 与 C 一样大（8 == 8）：同类挤一起之后，谁先谁后无所谓
  ok   _Alignof(struct CLPackA) = 4 == sizeof(int)：结构体的对齐等于最宽成员
```

三个结构体定义在 `CLTypes.h`，字段一个不多一个不少，只是换了顺序：

```c
struct CLPackA { char c; int i; char d; };    // 顺序「最差」的那个
struct CLPackB { int i; char c; char d; };    // 同类字段挤在一起
struct CLPackC { char c; char d; int i; };    // 和 B 等价，只是 c/d 在前
```

`sizeof` 分别是 12 / 8 / 8。**这是本章唯一一处「改一下书写顺序就少 4 个字节」的实测**，
而它解释了为什么音频/图像那类结构体（`AudioBufferList`、`CGRect`）要把同宽的字段挤在一起，
也解释了为什么数组一大片时（每元素省 4 字节 × 10 万 = 400KB）这条规则会从「好看」变成「性能」。

`offsetof` 把「为什么」摊开：`CLPackA` 里 `i` 的偏移是 4 而不是 1，因为 `int` 要按 4 对齐，
前面必须填 3 字节；`d` 在 8，尾部再补 3 让总尺寸回到 4 的倍数。**尾部也要补齐**这一条最容易被忽略，
而它正是「数组里下一个元素的起点」所在（Swift 侧对应 `MemoryLayout<T>.stride`，§18 里两者一致）。

嵌套那条也值得记：内层结构体的对齐会向外传染，`_Alignof(struct CLPackA) == sizeof(int) == 4`，
不是它自己的 12。所以判断一个布局对不对，看 `_Alignof` 而不是看大小。

## 8) 联合体与浮点位模式：负零在内存里真的存在，只是 `==` 把它抹平了

```
== §8 联合体与浮点位模式 ==
union { float f; uint32_t bits; } 的 sizeof = 4 —— 所有成员都从同一块内存的 0 偏移开始，谁大谁定总尺寸
位模式：1.0f = 1065353216（0x3F800000），2.0f = 1073741824，-1.0f = 3212836864
拆出来看 1.0f：符号位 0、指数段 127（偏置 127，真指数 0）、尾数段 0；2.0f 的指数段 = 128（正好大一档）；-1.0f 的符号位 = 1
0.0f 的位模式 = 0x00000000，-0.0f = 0x80000000：只差最高那一位；可它们 == 比较的结果是 相等。算术里它会露出来：1.0f / -0.0f 是负无穷吗 是，atan2f 把 -0.0 与 +0.0 分在 -pi / +pi 两侧吗 是 —— 符号位单独占一位，所以「负零」在内存里真的存在，只是 == 把它抹平了
这就是 IEEE 754 单精度：1 位符号 + 8 位指数 + 23 位尾数，§1 那个「24 位有效尾数」的上限就是这么来的。union 是「同一块内存换种解释」的合法手段；Swift 没有 union，对应写法是 Float.bitPattern 或 withUnsafeBytes（§18）
  ok   union{float;uint32_t} 的 sizeof = 4：成员共起点，谁大谁定尺寸
  ok   1.0f 的位模式 = 0x3f800000
  ok   -1.0f 的符号位 = 1，1.0f 是 0：符号单独占一位
  ok   正零 0x00000000、负零 0x80000000：位模式差一位，可 C 在运行时比出来的 0.0f == -0.0f 是 相等；而 1.0f / -0.0f 给出负无穷吗 是、atan2f 分得开这两个零吗 是 —— 「== 相等」不等于「位模式相同」，浮点做键值或哈希时要按位比
  ok   2.0f 的指数段比 1.0f 大 1：值翻倍 = 指数 +1，尾数一个字都不动
  ok   1.0f：指数段 127（偏置 127 -> 真指数 0），尾数段 0
```

书里讲联合体只讲「省内存」，本章用它干的是**看位模式**——这也是工程里最常见的用法
（快速 `sqrt` 那类技巧、序列化、把 `NaN` 当哨兵）。三段拆开之后 §1 的两个浮点结论就有了机制解释：
尾数 23 位 + 1 位隐含位 = 24 位有效，所以 `2^24+1` 装不进 `float`。

**正零与负零这一条是本章新量出来的**，它推掉一个常见误解（「`0.0 == -0.0` 所以它们是同一个数」）：
两块不同的内存，`==` 说相等，但除法和 `atan2` 分得开。工程后果很具体——
把浮点当字典键、算哈希、做位级序列化时，「`==` 相等」不够，得比位模式；
反过来在算角度/斜率时，`atan2(0.0, -1.0)` 与 `atan2(-0.0, -1.0)` 给你一个 +π 一个 -π，
这个差是正常的、可利用的，不是 bug。

Swift 侧没有 union，两条对应写法（§18/§19 演示）：`Float.bitPattern` 取位模式，
`withUnsafeBytes` 直接看那 4 个字节。

## 9) 枚举：尺寸看不出的东西，用「小减大」能量出来

```
== §9 枚举 ==
enum CLColor{RED=1,GREEN=2,BLUE=4,BIG=100000} 的 sizeof = 4 —— 编译器挑了一个和 int 同样宽的整型，不是「按最大值的位数算」；至于它有没有符号，下一段有办法量出来
枚举值就是整数：RED=1, BLUE=4, BIG=100000；把 RED|BLUE 当枚举传进去再打出来 = 5 —— 编译器完全不检查位标志组合是不是一个合法的 case
底类型有没有符号，sizeof 是看不出来的（两个枚举都是 4 字节）。换一种问法：拿小的减大的，再把结果当回枚举本身。enum CLColor{1,2,4,100000} 算 RED-BLUE 得 4294967293 —— 回绕成了一个巨大的正数，所以 clang 给它的底类型是 **unsigned int**；enum CLSigned{-7,7} 算 NEG-POS 得 -14 —— 还是负数，底类型是 **int**。一个枚举有没有负数，就足以让编译器换掉它的底类型
带负数的枚举 {NEG=-7,POS=7} 的 sizeof = 4：尺寸没变，变的是符号性 —— 这一条也正是 §18 里 Swift 那边 CLColor.rawValue 是 UInt32、CLSigned.rawValue 是 Int32 的原因
对照 ObjC：NS_ENUM / NS_OPTIONS 的用处就是把底类型写死，这样 Swift 才敢把它翻成 enum / OptionSet（§22 实测）
  ok   enum CLColor 的 sizeof = 4：编译器给了个和 int 同宽的整型，不是按最大值算位数
  ok   RED=1, BIG=100000：枚举值就是个整数
  ok   RED|BLUE = 5：C 枚举不检查这个组合是不是合法 case
```

「`sizeof(enum)` 是 4」是背得住的结论；「这个枚举的底类型有没有符号」用尺寸看不出来——两个都是 4 字节。
`CLLayout.c` 里那对函数换了个问法，把符号性变成可观测的：

```c
// sizeof 看不出底类型有没有符号，「小减大」才看得出来：
// 无符号底类型会回绕成一个巨大的正数，有符号底类型就老老实实是负数。
long CLColorSubtractWrapped(void) { return (long)(enum CLColor)(CL_RED - CL_BLUE); }
long CLSignedSubtractWrapped(void) { return (long)(enum CLSigned)(CL_NEG - CL_POS); }
```

`1 - 4` 按 `enum CLColor` 算出 4294967293（回绕 = 无符号底），按 `enum CLSigned` 算出 -14（有符号底）。
**一个枚举里有没有负数，就足以让编译器换掉它的底类型**——这条规则直接解释了 §18 里
Swift 那边 `CLColor.rawValue` 是 `UInt32`、`CLSigned.rawValue` 是 `Int32`：importer 跟着 C 的底类型走。
知道这一点的工程价值是：拿一个 C 枚举的 `rawValue` 和 `Int` 比较之前，先确认它是哪一种，
否则 `-7` 会变成 `4294967289` 混进逻辑里。

另一半结论是「C 枚举不做穷尽检查」：`RED|BLUE` 塞进去当枚举，编译器一声不响，得到 5。
位标志在 C 里就得靠约定，而 ObjC 的 `NS_OPTIONS` / Swift 的 `OptionSet`
存在的唯一理由就是把这层约定写进类型。

## 10) 不透明句柄：自己手写一遍 CoreFoundation 的形状

```
== §10 不透明句柄：手写的 Create/Retain/Release ==
Create 之后：引用计数 = 1，getter 读到 seed = 2026，进程内本章造的还活着 1 个 —— 外面拿到的是 CLOpaqueRef（一个指针），字段看不见也构造不出来
Retain 两次 -> 计数 = 3：结构体的定义只在那个 .c 里，所以「计数加一」必须由库自己提供函数
Release 两次 -> 计数 = 1，还活着 1 个
再 Release 一次 -> 计数归零、真 free：还活着 0 个，回到起点的 0 个。此刻那个指针已经是野指针，读它就是 UB —— C 不会替你发现
给 Retain/Release 传 NULL：不崩（函数自己挡），CLOpaqueRefCount(NULL) = -1（用 -1 表示无效句柄，而不是返回 0，好和「已释放」区分）
CoreFoundation 全系列（CFStringRef、CGContextRef、SecKeyRef…）都是这个形状。在 ARC 下用它们就得自己配平 Create/Copy 与 Release —— 这是桥接里最容易漏的一段
  ok   Swift 这边另造一个句柄（seed 传 1，和上面 ObjC 那个 2026 是两块内存）：Create 之后计数 = 1，seed 只能靠 getter 读回 1
  ok   Retain -> 2
  ok   两次 Release 之后本章还活着 0 个，和进节前的 0 一致：计数配平了
  ok   给 getter 传 NULL 拿到 -1：句柄类 API 必须自己挡 NULL
```

`CLTypes.h` 里只有一句 `typedef struct CLOpaque *CLOpaqueRef;`——结构体本体藏在 `CLMemory.c`。
这就是「不透明句柄」的全部机制：**类型名公开、定义私有**，所以外面既看不见字段，
也没法自己造一个，只能走库给的函数。`CFStringRef`、`CGContextRef`、`SecKeyRef`、
`AVAudioBuffer`（部分）全是这个形状。

`CLOpaqueAliveObjects()` 是本章的自检仪表：进一节记一次，出节再记一次，两次必须相等
（§17、§22 收尾各打一次，全 0）。这让「配平」从口号变成断言——ARC 接管不了
手动引用计数的 CF 对象，「谁 Create/Copy 谁 Release」漏一次就是永久泄漏，
而这类泄漏在 instruments 里出现时通常已经晚了。

`CLOpaqueRefCount(NULL) == -1` 而不是 0，是一个值得抄的小设计：0 是「合法对象已释放」，
-1 才是「你给的句柄无效」，两者不能混。

## 11) 值传递：C 没有引用传递，只有拷贝

```
== §11 函数、值传递与递归 ==
值传递：函数里换完再出来，x=1, y=2 —— 一点没变，换的是两份拷贝。想真的换就得给地址（§6），C 没有「引用传递」这个语言特性
递归：Fibonacci(0)=0, (1)=1, (10)=55, (20)=6765 —— fib(20) 展开了两万多次调用；递归的问题从来不是「能不能写」，是「有没有记忆化」
两个同签名的普通函数：CLAddFunc(3,4)=7, CLMulFunc(3,4)=12 —— 它们是 §13 那张回调表的原料
  ok   值传递换不动：函数里换完了，外面还是 x=1, y=2
  ok   fib(10)=55, fib(20)=6765：值不大，但 fib(20) 展开了两万次调用
```

`void CLSwap(int a, int b)` 换完出来还是 1、2——这条看似弱智，却是理解 §6「要改就给地址」、
理解 Swift 的 `inout`（编译器把地址传下去，看起来像引用）、
以及理解「结构体按值传给 ObjC 方法是拷贝，改不动」（§17）的共同地基。

## 12) 可变参数：count 是唯一的护栏，而 Swift 连门都进不来

```
== §12 可变参数 ==
va_arg 靠 count 决定读几次：CLSumVarargs(5, 1,2,3,4,5) = 15，CLSumVarargs(0) = 0，CLSumVarargs(3, 10,20,30) = 60
CLMaxOfVarargs(5, 3,9,2,9,1) = 9；只给 1 个 -> 42
这个 count 是唯一的护栏：说少了漏读，说多了读过头（都是 UB，探针记录见 §23）。所以 C 库里更常见的形态是「以哨兵结尾」（execl("prog", ..., NULL)）或者干脆传数组 + 长度
另一条只有这里讲得下：va_arg(ap, float) 永远是错的 —— 可变参数里 float 已被提升成 double，必须 va_arg(ap, double)。printf 的 %f 背后就是这个提升
  ok   本节的所有调用都在 ObjC 侧：Swift 连 CLSumVarargs 这个名字都拿不到 —— 它是可变参数函数，importer 直接标成 unavailable（编译器原文见 §23）
```

示例只跑了**诚实**的调用（5 个参数就写 5），护栏失效的代价放在探针里：

```
    4) 可变参数 count 撒谎。源码：sum(10, 1, 2, 3) —— 说十个只给三个。
       连跑三次分别打 855015054 / 1039683214 / 1022393998，一次都没崩；换 -O2 又是另一个数。
       读过头不会立刻出事，它只是把栈上的邻居当成你的参数加了起来。
```

**「读过头不崩，只是把栈上的邻居加起来」是这一节真正的警告**：这类 bug 不会当场暴露，
它会带着一份看起来合理的数据往下流。所以标准库里更常见的形态是哨兵结尾（`execl(..., NULL)`）
或者干脆数组 + 长度。

另一条只有这一节讲得下：`va_arg(ap, float)` 永远是错的，因为可变参数里 `float` 已被提升成 `double`。
这是 `printf("%f", x)` 背后那条规则的另一面，也是「自己写日志宏」最常踩的坑。

**Swift 侧完全不能调 C 可变参数函数**，这是硬限制而不是「麻烦」：

```
         调 C 可变参数函数：error: 'CLSumVarargs' is unavailable: Variadic function is unavailable
             （紧跟一条 note：'CLSumVarargs' has been explicitly marked unavailable here）
```

所以桥接头里如果混进一个 `...` 的函数，Swift 那边必须在 ObjC 侧再包一层数组接口——
这是本章对「新写的 API」给出的具体建议：**别在需要跨 Swift 的接口上用可变参数**。

## 13) 函数指针：按名字找实现，代价是名字拼错了没人查

```
== §13 函数指针与回调表 ==
表里有 3 项，按下标取出名字并各调一次（同一个入参 5）：[0] double-it -> 10  [1] square-it -> 25  [2] negate-it -> -5
越界：CLApplyTable(99, 5) = -9999 —— CLMapAt 返回 NULL，调用方必须自己挡；C 里函数指针可以是 NULL，而调用 NULL 就是跳飞
这张表和 27 章的 selector / target-action 是同一件事的低配版：按名字找实现。区别是 C 的表要自己维护，名字拼错了编译器不查
qsort 的比较函数签名必须写成 int(const void *, const void *)：5,3,9,1,7,7 排完是 1, 3, 5, 7, 7, 9（比较函数里第一件事就是转回 int）
bsearch 找到给那个元素、找不到给 NULL：查 9 -> 9，查 4 -> -1
所以「传一个比较函数」在 C 里必然伴随 const void * 和一次强制转换；Swift 的 sorted(by:) 用泛型把这一整套收走了（§20 对照）
  ok   回调表里有 3 项
  ok   按下标取函数各调一次：[0]=10, [1]=25, [2]=-5
  ok   越界下标 -> CLMapAt 给 NULL -> -9999：C 里函数指针可以是 NULL，调用前必须挡
  ok   函数指针比的是实现不是名字：CLSameFunctionPointer(CLDoubleOf, CLDoubleOf) = 1、换个人就是 0（只打 1/0，地址绝不进输出）
```

这一节是 27 章的回环：**C 的函数指针表就是 selector 机制的低配版**——
都是「按名字/下标找实现」，区别是 ObjC 的那张表由 runtime 维护、拼错名字运行时还能查，
而 C 的表自己维护，越界给 `NULL`、调用 `NULL` 就是跳飞。
`CLApplyTable(99, 5)` 返回 -9999 而不是崩，正是「调用方自己挡了一刀」的写法。

`qsort` 的比较函数是很多人第一次被迫读 C 回调的地方，示例把它的三步都跑了：
签名必须是 `int(const void *, const void *)`、比较函数里第一件事是转回 `int`、
`bsearch` 找不到给 `NULL`。§20 会拿 Swift 的 `sorted(by:)` 并排——泛型把
`void *` 与强制转换这一整套收走了，代价是带捕获的比较闭包**交不出**给 C。

## 14) memcpy 与 memmove：重叠区交给 memcpy，两个优化级别给出两个答案

```
== §14 memcpy 与 memmove ==
两块不重叠的内存：目的先是 "-----"，memcpy(dst, src, 5) 之后 = "abcde"
源和目的重叠（把 buf[0..2] 搬到 buf[2..4]）：memmove 之后 = "ababcfg" —— 它自己判断方向，搬过去的是**原来的**那三个字节
探针记录：同一段重叠交给 memcpy，本机 -O0 得到 "ababafg"、-O2 得到 "ababcfg"（memmove 两版都是 "ababcfg"）；开 -fsanitize=address 直接报 "AddressSanitizer: memcpy-param-overlap: memory ranges [0x…] and [0x…] overlap"。同一段代码、两个答案，这就是 UB 的样子：memcpy 只保证不重叠，重叠之后没有「正确结果」可言，所以本章不给它下断言
记一条就够：可能交叠 -> memmove；确认不交叠 -> memcpy（更快，能上 SIMD）
  ok   Swift 自己准备两块缓冲、交给 C 的 memcpy 填：目的先是 "-----"，填完是 "abcde" —— 长度由那个 0 决定而不是由数组的 8 决定，CLCopyNonOverlap 在 dst[5] 补了 0，后面两个 '-' 就不见了
  ok   同一段重叠交给 memmove："ababcfg"。搬之前 buf[2]、buf[3] 正是源区的前两个字节，它仍然给出「搬动前的那三个」—— 方向判断在库里做完了。换 memcpy 就是探针记录里 -O0/-O2 两个答案，本节一次都不跑
```

第一条断言是 Swift 侧的：Swift 自己准备 `src` / `dst` 两个 `[CChar]` 缓冲，
用 `withUnsafeBufferPointer` / `withUnsafeMutableBufferPointer` 把两个地址一起交给 C 的 `memcpy`，
再读回来——这就是 §19 那圈借用 API 的一次实际用途，而且结果里 `dst[5]` 被补了 0，
所以「后面两个 `-` 不见了」把 §4 的「长度由第一个 0 决定」又坐实了一次。

重叠区示例**一次都没跑**，只跑了 `memmove` 那条有保证的路。UB 的证据留在探针里：

```
    1) memcpy 重叠。源码：char buf[8] = "abcdefg"; memcpy(buf + 2, buf, 3);
       -O0 打 ababafg；-O2 打 ababcfg。一个字都没改，只换了优化级别，答案就变了。
       同一行改用 memmove：-O0 与 -O2 都稳定打 ababcfg。
       再加 -fsanitize=address，报的原文是（地址这节略去，本章规定指针不进输出）：
         ERROR: AddressSanitizer: memcpy-param-overlap: memory ranges [0x…] and [0x…] overlap
       它是直接 abort，不是返回错误码 —— sanitizer 也只能事后拦，拦不住「这次结果碰巧对」。
```

这一条的教训比「memmove 处理重叠」大得多：**UB 不是「一定错」，是「没有答案」**。
同一行代码在 `-O0` 下碰巧对，在 `-O2` 下就变了；sanitizer 能报，但它是 abort，不是给你纠正。
所以工程结论只有一条：可能交叠就 `memmove`，别为了「memcpy 快一点」去推断布局。

## 15) malloc 家族：本章最重要的一节——你量到的可能是编译器

书里这一段是「`malloc` 之后要判空」。示例照做，但做出来才发现**这条纪律的量法本身是个坑**：

```
== §15 malloc 家族 ==
calloc 保证全 0：calloc(4, sizeof(int)) 之后第一个元素 = 0（malloc 不保证，拿到的是上一手留下的脏内存）
同一个「大到不可能」的尺寸先问三遍：尺寸写死在源码里的那版答 返回 NULL？否；尺寸换成形参的那版答 返回 NULL？否；第三版还往那块内存写了个数再读回来，它答 返回 NULL？否。三版全说「不是 NULL」
这三版量到的都不是分配器，而是编译器。「分配 + 判空 + 立刻 free」写在同一个函数里就没有可观测的副作用，-O2 于是把 malloc 连同那句判空一起删掉，整个函数编成一句 return 0；连第三版「写进去再读回来」都被折成 「把编译器自己写的那个常数交给出参」（两版的汇编原文见 §23 探针记录）。它依赖的假设是：这次分配要么成功、要么根本不需要真的发生。尺寸是不是常量、内存有没有被写过，都不影响这个结论。
把分配挪到另一个编译单元（CLMemory.c 里一个只 return malloc(n) 的函数），判空写在本文件，第四版终于量到了真答案：malloc((size_t)-1) 返回 NULL？是；malloc(1<<62) 返回 NULL？是；malloc(1<<40) 返回 NULL？否；malloc(64) 返回 NULL？否。四格里前两个是 NULL，后两个不是
同一台机器、同一次运行里，「不可能的大小」确实给 NULL（所以 malloc 之后必须查），而 1TB 的 malloc(1<<40) 居然成功：往里写 12345 读回来还是 12345。差别就在 64 位虚拟地址空间够大 —— malloc 只是在账本上划了一段地址，返回非空并不等于这块内存真的可用，写入才见分晓
所以这一节真正的结论有两条：其一，分配失败是**返回 NULL**，不抛异常、不 abort，每一次 malloc 后面都必须查；其二，「读源码推断优化器会留下什么」是不可靠的 —— 同一个判空写在不同的编译单元里，一个会被删干净、一个不会。涉及分配器、溢出、内存重叠这类边界行为时，只有把反汇编摊开看、或者换编译单元再跑一遍才算数
三件套的分工：malloc 只要一块（内容不定）、calloc 要清零的、realloc 要变大的。realloc 可能原地扩也可能搬家，所以必须把返回值接回同一个变量：写成 realloc(p, n) 而不看返回值，搬家之后就是一枚悬垂指针（探针记录见 §23）
free 之后再读就是 UB。C 没有任何机制帮你发现这件事 —— ARC 换来的正是这一条
  ok   calloc 之后第一个元素 = 0：清零是 calloc 唯一的额外承诺
  Swift 侧再问一遍：CLMallocRaw 的完整类型是 (Int) -> Optional<UnsafeMutableRawPointer> —— size_t 落成了 Int（所以传 -1 编译得过，到 C 那边就是 SIZE_MAX），void * 落成 Optional<UnsafeMutableRawPointer>，也就是 C 的 NULL 在 Swift 里就是一个真的 nil
  ok   Swift 里传 -1：guard let 走进 nil 分支 = true，出参停在自定的记号 -1（-1 = 「没写过」）—— 这是 C 的 malloc 真的返回了 NULL
  ok   Swift 里传 1 << 40：拿到了指针，用 raw 指针 store/load 写进去又读回来 12345 —— 1TB 的额度在虚拟内存上只是记一笔账
  ok   同一个尺寸、两个编译单元、两个答案：分配和判空写在 C 那个函数里的 CLMallocIsNullForSize(-1) 给 0（意思是「不是 NULL」），判空写在 Swift 这边的这版给「是 NULL」。前者是 -O2 折出来的常数（连 malloc 都没调），后者才是分配器说的话 —— 汇编原文见 §15 与 §23
```

`CLMemory.c` 里刻意留了四种写法，从「会被折」到「折不掉」：

```c
int CLMallocHugeIsNull(void) { void *p = malloc((size_t)-1); int isNull = (p == NULL) ? 1 : 0; if (p) { free(p); } return isNull; }
int CLMallocIsNullForSize(size_t n) { void *p = malloc(n); int isNull = (p == NULL) ? 1 : 0; if (p) { free(p); } return isNull; }
int CLMallocUsedIsNull(size_t n, long *readBack) { /* 分配、判空、真写入 *p = 12345、读回出参、free */ }
void *CLMallocRaw(size_t n) { return malloc(n); }   // 唯一把指针交给调用方的那个
```

前三版都回答「不是 NULL」，而它们量的根本不是分配器。反汇编摊开在探针记录里（一字未改，缩进重排）：

```
    2) malloc 的判空被折成常数。示例里 CLMallocHugeIsNull 在 -O2 的汇编（缩进是这里重排的，指令一字未改；.cfi_* 略）：
         _CLMallocHugeIsNull:                       ## @CLMallocHugeIsNull
             pushq   %rbp
             movq    %rsp, %rbp
             xorl    %eax, %eax
             popq    %rbp
             retq
       尺寸换成形参的那版（CLMallocIsNullForSize）汇编一字不差也是这六行。第三版（CLMallocUsedIsNull，
       真往那块内存写了 12345 再读回来）被编成：
             testq   %rsi, %rsi / je  LBB34_2 / pushq %rbp / movq %rsp, %rbp
             movq    $12345, (%rsi) / popq %rbp / LBB34_2: xorl %eax, %eax / retq
       —— 连那块假想的内存都不需要了，只剩「往出参写 12345，返回 0」。整份 CLMemory.c 的 -O2 汇编里
       只剩一处 malloc 字样：CLMallocRaw 那句 jmp _malloc（尾调用），也就是唯一那个把指针交出去的函数。
       顺带一条同样被折掉的：CLCallocZeroed 也是六行 return 0。但这两次折叠性质不同 ——
       calloc 本来就承诺全 0，编译器是**知道答案**才折的；malloc 那三版折的是「你的分配一定成功」这个**假设**。
       独立探针（判空之后又真往那块内存写了一个字节再打印）：-O0 打 returned_null=1，
       -O2 打 returned_null=0 外加一行 wrote_ok。前者是分配器说的，后者是编译器折的。
```

只有第四版——分配在 `CLMemory.c`，判空写在 `CLCollect.m`（以及 Swift）——编译器看不穿，
才量到分配器真说的话：`malloc((size_t)-1)` 与 `malloc(1<<62)` 返回 NULL，
而 `malloc(1<<40)`（1TB）**成功**，写进去 12345 还能读回来。这不是分配器大方，是
64 位虚拟地址空间够大：`malloc` 只是在账本上划了一段地址，**非空不等于可用，写入才见分晓**。

顺带三条能直接用在工程上的：

1. `calloc(n, sizeof(T))` 的额外承诺只有「全 0」，尺寸是 `n * sizeof(T)`（乘法溢出就是 §1 那个 UB 的远亲）；
2. `realloc` 可能搬家，所以**必须把返回值接回同一个变量**，探针量到 8 字节扩到 4096 时 `moved=1`，
   旧指针那四个字节已经被分配器的空闲链表元数据盖掉；
3. 拿 `void *` 回 Swift 就是 `Optional<UnsafeMutableRawPointer>`——C 的 NULL 在这里是一个真的 `nil`，
   而 `size_t` 落成 `Int`（所以传 `-1` 编译得过，到 C 那边是 `SIZE_MAX`）。这两条把 §18 的类型映射
   在最要命的地方提前演示了一遍。

最后一句是本章给 ARC 用户的：`free` 之后再读就是 UB，C 没有任何机制帮你发现。
ARC 换来的正是这一条，代价是 §10 那类手动计数句柄得自己配平。

## 16) 宏：它不是函数，本章把「展开两次」量成了两个不同的数

```
== §16 宏 ==
不带括号：#define SQR(x) x*x，传 SQR(3+1) 展开成 3 + 1 * 3 + 1 = 7；全括号的版本 = 16（正确值 16）
参数被展开两次：CL_TWICE(x) 定义为 ((x)+(x))，传一个「每调一次就返回下一个 10 倍」的函数 —— 宏版得到 30（10 + 20），函数版得到 20（10 + 10）；副作用次数分别是 2 和 1
上面这一条就是「宏不是函数」的全部证据：同一个表达式，宏多跑了一次，还多算了一次值。工程里的写法是：复杂逻辑一律写成 inline 函数，只有必须发生在编译期的事（拼名字、字符串化、条件编译）才用宏
多语句宏包进 do{...}while(0)：跑两轮计到 5。不包的话，if (x) MACRO(); else ... 会被拆成「第一条语句归 if，第二条谁都不归」
# 把参数变字符串：CL_STRINGIFY(CL_Paste_Target) = "CL_Paste_Target" —— 日志宏的原料
## 拼标识符：CL_PASTE(CL_, answer) 拼出 CL_answer = 77 —— 拼完才去找宏，所以嵌套一深就容易拼出一个不存在的东西
__func__ 展开成当前函数名（一串字符，不是地址）："CLCurrentFuncName"
条件编译走的哪一支：编号 = 11（个位 1 = __LP64__ 成立；十位 1 = 探到了 <stdint.h>）。#if 在编译期就定死，编进去之后另一支根本不存在，运行时改不了
Swift 能不能看见这些宏？只有对象式的简单常量能（CL_answer = 77 那类），带参数的都看不见 —— 实测见 §22
  ok   SQR(3+1)：不带括号 = 7，带括号 = 16
  ok   同一个表达式：宏版 30，函数版 20 —— 参数被展开两次，值也跟着变
  ok   副作用次数：宏 2 次，函数 1 次
  ok   # 号把宏参数原样变成字符串字面量：Swift 侧读回来也是 "CL_Paste_Target"
```

「宏参数展开两次」在书里是一句警告，示例把它量成了两个不同的返回值：`CL_TWICE(f())` 得 30，
同逻辑的函数得 20；副作用计数分别是 2 和 1。传进去的是一个每调一次返回下一个 10 倍的函数，
所以宏版本真的调了它两次。**这是「宏不是函数」唯一有说服力的证法**，
而它给出的工程规则很干脆：复杂逻辑写 `inline` 函数，宏只留给必须在编译期发生的事
（拼名字、字符串化、条件编译）。

`__func__` 展开成函数名的一串字符（不是地址），所以日志宏可以安全把它打进输出——
这一点在本章的输出纪律下格外重要：`__FILE__`、`__LINE__` 会违反「路径不进输出」，`__func__` 不会。

条件编译那条（编号 11：个位 = `__LP64__` 成立，十位 = 探到 `<stdint.h>`）说明的是
`#if` 的另一支**根本没被编进二进制**，运行时改不了。今天 iOS 工程里唯一常见的用法是
`#if TARGET_OS_IPHONE` / `__LP64__`，而 §22 会看到 Swift 侧的 `#if arch(...)` 是另一套完全独立的东西。

## 17) C 与 ObjC 的边界：`@encode`、结构体属性、`NSError **`，以及 `%s` 打中文

`.m` 只是 include 了同一份 `CLTypes.h`，链接的是同一份实现——先证明这一点：

```
== §17 C 与 Objective-C 的边界 ==
同一个 C 函数从 ObjC 里调：CLIntArrayCount() = 5，和 C 文件自己量的一致 —— .m 只是 include 了同一份 CLTypes.h，链接的是同一份实现，不存在两份代码
@encode 眼里的 C 类型：int="i", double="d", float="f", char="c", int *="^i", 结构体 CLPackA="{CLPackA=cic}", 结构体 CLPackB="{CLPackB=icc}"
结构体的编码把字段名和 padding 都写进去了（'x' 就是补的字节），所以 §7 那个「字段顺序影响尺寸」在 @encode 的字符串上直接看得见。这就是 NSValue 的 valueWithBytes:objCType:、以及 KVC 装箱、归档所使用的类型描述
C 按值返回结构体，ObjC 直接接住：i=7, c=3, d=4；再交回 C 求和 = 14
结构体做 ObjC 属性：写进去再读回来 i=7, c=3, d=4 —— 它是 ivar 里的一段值，没有 retain，也不能直接装进 NSArray（那要包成 NSValue）
C 往调用方的结构体里写：100, 1, 2（out 参数在结构体上的形态）
C 字符串 -> NSString："C 侧的字面量"；再走 UTF8String + stringWithUTF8String 回到 NSString，内容一字不差吗？是；NSString 侧数到 17 个 UTF-8 字节 —— NSString 是对象（自带编码和长度），char * 只是一段还没被解释的字节，两个方向都得显式写转换
同一段字节的两种打印法：先包成 NSString 再交给 %@ 得到 "C 侧的字面量"，直接把 char * 交给 %s 得到 "C ‰æßÁöÑÂ≠óÈù¢Èáè" —— stringWithFormat 里的 %s 只按逐字节取字符，不认 UTF-8，两串相等吗？不等。这就是 27 章那条「中文一律走 %@」在 C 层的另一半原因
失败约定的两套：C 那边是「返回码 + 出参」（§6）；ObjC 把它包成「返回 是 + NSError ** 出参」。有效句柄 -> 是, seed=31415, error=nil；NULL 句柄 -> 否, seed 仍是 0, error 的 domain=CLCStyleAPI code=17 desc="C 侧返回了 -1（句柄无效）"
注意 NSError ** 那条的三步：先把出参清成 nil、再判调用方有没有传地址进来、成功路径绝不写它 —— 这三步在 §6 的 C 函数里同样存在，只是 C 用返回码表达。Swift 的 throws 是同一套约定的自动版（§22）
ObjC 里存一个 C 函数指针：CLMapAt(1) 拿到的是表里的 square-it，调用它算 6 -> 36；和 CLApplyTable(1, 6) = 36 一致。本地定义的 C 函数也能当函数指针用（CLSquareOfSixViaPointer 算 6 = 36）
block 与函数指针的分水岭：block 能捕获上下文 —— 这个 block 算 6 得到 13（captured 后来被改成 7，block 读到的跟着变），而函数指针只能读全局变量。反过来，把一个 block 交给「要函数指针」的 C 接口，必须靠一个不带任何捕获的 trampoline（§20 在 Swift 里演一遍）
同一条对照的另一半：C 表里的 square-it 是纯函数，调两次结果一样（36, 36）；block 那次的结果依赖 captured，换个人再调就可能是另一个数
本节收尾：句柄已经 Release，本章造的还活着 0 个 —— §10 和 §17 各造各还，谁也没给后面的小节留脏计数
  ok   §17 用完的句柄也还干净了：本章造的还活着 0 个
```

`@encode` 是这一节的重点，因为它把 §7 的布局知识接进了 ObjC 的类型系统：

```objc
CLLAdd([NSString stringWithFormat:@"@encode 眼里的 C 类型：int=\"%s\", double=\"%s\", float=\"%s\", char=\"%s\", int *=\"%s\", "
        "结构体 CLPackA=\"%s\", 结构体 CLPackB=\"%s\"",
        @encode(int), @encode(double), @encode(float), @encode(char), @encode(int *),
        @encode(struct CLPackA), @encode(struct CLPackB)]);
```

结构体的编码串 `"{CLPackA=cic}"` 把名字和字段类型都写进去了，`x` 表示补的字节。
这就是 `NSValue valueWithBytes:objCType:`、KVC 装箱、归档所用的类型描述——
27 章 §6 里那个「属性编码」在这里有了底层解释。

**`%s` 与 `%@` 那两行是本章给中文产品的一课。** 同一个 `char *`：

```objc
const char *cs = CLStaticCString();
NSString *oc = [NSString stringWithUTF8String:cs];
// 正确的回程：UTF8String 出来的那串字节再用 stringWithUTF8String 包回去
NSString *roundTrip = [NSString stringWithUTF8String:[oc UTF8String]];
// 反面教材：同一个 char * 直接交给 %s，它不按 UTF-8 解，于是一串乱码
NSString *viaPercentS = [NSString stringWithFormat:@"%s", [oc UTF8String]];
```

`stringWithUTF8String:` 走一圈内容一字不差；`%s` 打出来是「C ‰æßÁöÑÂ≠óÈù¢Èáè」——
它只按逐字节取字符，不认编码。两串不等，这就是示例把 `%s` 全部赶出输出的原因，
也是 27 章那条「中文一律走 `%@`」在 C 层的另一半原因：**跨界拿到 `char *` 时，
必须先显式选定编码再进对象世界**。

`NSError **` 那三行纪律（先清 `nil`、判调用方给了地址没有、成功路径绝不写它）
在 §6 的 C 函数里同样存在，只是那里用返回码表达。**这三步是 throws 的前置条件**：
少一步，Swift 侧 `try` 失败路径就会读到脏值——§22 实测了这一点。

`block` 与函数指针的分界线只有一句：**block 能捕获上下文**。
示例先让 `captured` 是 7，再交给 block 算 6 得 13，然后把 `captured` 改掉——
block 读到的跟着变，而函数指针只能读全局变量。反过来把 block 交给「要函数指针」的 C 接口，
必须靠一个不带任何捕获的 trampoline，§20 在 Swift 侧演同一件事。

## 18) Swift 看见的 C 类型：同名，不同宽

从这里开始本章换了主角。§1~§17 是「C 侧量、ObjC 侧说」，§18 起问的是
「Swift 拿到的是什么」。第一条就是最多人搞错的：

```
== §18 Swift 看见的 C 类型：同名，不同宽 ==
  同一批 C 函数，Swift 侧拿到的类型名：sizeof(int) -> Int，数组元素数(long) -> Int，CLColorValue -> Int，CLBitsOf -> UInt32，CLAddFunc -> Int32，void* 步长 -> Int32
  ok   C 的 int 进 Swift 变成 **Int32**，不是 Int：CLAddFunc(1,2) 的结果类型是 Int32
  ok   C 的 long 进 Swift 变成 **Int**：CLIntArrayCount() 的类型是 Int —— C 里两种不同宽的类型，在 Swift 里成了「大整型」和「小整型」
  ok   size_t、ptrdiff_t 进 Swift 都是 Int（Int / Int / Int）—— 连同 long 在内，三个不同的 C 类型塌成了同一个 Swift 类型。这不是精度损失，是 Swift 有意把「长度/计数」统一成 Int；代价是 C 那边「无符号」的语义没了：size_t 做减法在 Swift 侧不再是自动回绕，而是会 trap
  ok   两边各量一遍同一个类型：Swift 的 MemoryLayout<Int32>.size = 4，C 的 sizeof(int) = 4 —— 数值必须相同，否则桥接就是骗人的
  ok   MemoryLayout<Int>.size = 8 == C 的 sizeof(long) = 8：Swift 的 Int 就是 C 的 long，所以它在这台机器上恒为 64 位
  ok   而 Swift 的 Int（8 字节）和 C 的 int（4 字节）不同宽 —— 「Swift 里传个 Int 给要 int 的 C 函数」这句直觉是错的，必须写 Int32；反过来 C 的 long 才对应 Swift 的 Int
  ok   C 结构体进 Swift 还是那个结构体：MemoryLayout<CLPackA>.size = 12，sizeof = 12
  ok   连对齐都一致：alignment = 4 == _Alignof = 4
  ok   CLPackB：size=8、stride=8 —— stride 是「数组里一个元素占几格」，正好等于补齐后的 sizeof
  C 枚举在 Swift 里不是 enum：CL_RED 的类型是 CLColor，rawValue = 1，CL_BLUE.rawValue = 4
  ok   CL_RED == CL_BLUE 给出 false：它被 import 成一个 RawRepresentable 的结构体，能比、能取 rawValue，但**不是** Swift 的 enum —— 没有 case、switch 也穷尽不了，所以从 C 枚举过来的一定要自己补一个 Swift enum（§22 那条「宏与常量要重述」是同一件事）
  ok   位标志得自己拼：CL_RED.rawValue|CL_BLUE.rawValue = 5，塞回 CLColor 再交回 C -> 5。NS_OPTIONS 才能变成 Swift 的 OptionSet，裸 C 枚举不行
  两个枚举的 rawValue 类型不一样：CLColor 的是 UInt32，CLSigned 的是 Int32，后者读到 -7。这不是 importer 随手挑的 —— 它跟着 §9 在 C 侧量出来的底类型符号性走：CLColor 全是非负数，clang 给它 unsigned int，于是 Swift 给 UInt32；CLSigned 里有一个 -7，底类型变成 int，Swift 就给 Int32
  ok   rawValue 的符号性两边一致：C 侧 RED-BLUE 回绕成 4294967293（正数 = 无符号底），NEG-POS 是 -14（负数 = 有符号底）；Swift 侧则分别是 UInt32 和 Int32
  ok   尺寸仍然一致：Swift 的 MemoryLayout<CLColor>.size = 4 == C 的 sizeof = 4，CLSigned 也一样：4 == 4 —— 换的只是符号，不是宽度。拿一个可能是无符号的 rawValue 去和 Int 比较之前，先看清它是哪一种（这也是 §1 那条「char 有没有符号是实现定义」的续集）
  ok   整数溢出的三种语言规则并排：C 的有符号溢出是 UB（§1 只敢用无符号回绕，本机 2147483648）；Swift 的 &+ 是**定义好**的回绕（Int32.max &+ 1 = -2147483648）；Swift 的普通 + 溢出直接 trap（探针记录见 §23）
```

**「Swift 传个 `Int` 给要 `int` 的 C 函数」这句直觉是错的**，这是本章对日常写法影响最大的一条：
C 的 `int` 落成 `Int32`，C 的 `long` 才对应 Swift 的 `Int`。示例用 `typeName` 把每个返回类型打成字符串，
再用 `MemoryLayout<T>.size` 和 C 侧的 `sizeof` 互相验一遍（数值必须相同，否则桥接就是骗人的）。

反过来，`long`、`size_t`、`ptrdiff_t` 三个不同的 C 类型**塌成了同一个 Swift `Int`**。
Swift 有意把「长度/计数」统一成 `Int`，代价是 C 那边「无符号」的语义没了：
`size_t` 做减法在 C 里自动回绕（有定义），在 Swift 侧是 `Int` 减法，**溢出会 trap**。
这就是为什么从 C 桥过来的计数代码要特别注意 `count - 1`（`count` 可能为 0）。

**C 枚举不是 Swift 的 `enum`**，这是第二个高频误解。`CL_RED` 的类型是 `CLColor`——
一个 `RawRepresentable` 结构体，能比、能取 `rawValue`，但没有 case，`switch` 穷尽不了。
所以从 C 枚举过来的值必须自己补一个 Swift `enum` 再映射（§22 那条「宏和常量要在 Swift 重述一遍」是同一件事）。
而 `rawValue` 到底是 `UInt32` 还是 `Int32`，§9 已经量出了机制：跟着 C 的底类型符号性走。

溢出的三条语言规则并排放在这里最直观：C 有符号溢出是 UB（所以 §1 全程只用无符号回绕）、
Swift 的 `&+` 是**定义好**的回绕、Swift 的普通 `+` 溢出直接 trap。探针记录第 9 条量到了 trap 的样子：

```
    9) Swift 的普通 + 溢出。源码：var x = Int32.max; x = x + 1。先打出 start，然后：
         Child process terminated with signal 4: Illegal instruction（退出码 132）
       值得注意的是 stderr 里只有模拟器这一句，Swift 自己的 fatal error 文案一个字都没进 stderr。
       所以「崩是确定会崩」和「崩了能留下可读日志」是两件事。
```

## 19) Swift 的指针：withUnsafe 那一圈借的是同一块内存

```
== §19 Swift 的指针：withUnsafe 那一圈 ==
  ok   把 Swift 数组借给 C 只读扫一遍：CLCountBelow(< 4) = 3（数组是 3,1,4,1,5）—— withUnsafeBufferPointer 给出的 baseAddress 就是那个 const int *
  ok   CLBumpEach 就地改内存：之后变成 4,2,5,2,6 —— C 函数不靠返回值也能改到外面，靠的就是这个地址
  ok   改完再数 <5 的：3 个 —— 借出去的指针指向同一块内存，不是副本
  借用的边界：闭包一返回，那个指针就不许再留用。Swift 用这个作用域替「数组可能搬家」兜底 —— 把 baseAddress 存到外面是崩溃名单上的常客
  一个 CLPackA（c=2, i=1, d=3）的原始字节：02 00 00 00 01 00 00 00 03 00 00 00
  ok   整块 12 字节 == sizeof(struct CLPackA) = 12：Swift 的 withUnsafeBytes 量到的是和 C 同一块内存
  ok   三个字段各落在 0/4/8 号位置（02 01 03）—— 和 §7 的 offsetof 完全对得上，小端把 int 1 写成 01 00 00 00
  ok   非零字节只有 3 个，剩下 9 个是 padding。padding 里的内容 C 不管，所以「整个结构体 memcpy / 拿去当 key / 写进文件」都可能搬走一堆垃圾 —— 要比较或持久化就逐字段比，别 memcmp 整块
  ok   给 C 传 nil：CLSumPackB(nil) = -1。Swift 的 Optional 指针和 C 的 NULL 在这就是同一个值，所以 §6 那句「函数自己挡 NULL」在 Swift 侧同样要成立
```

三条断言跑的是同一个数组：只读扫一遍（得 3）、就地 +1（Swift 侧看到 `4,2,5,2,6`）、
再数一遍。**「改完再数还是 3」证明借出去的是同一块内存，不是副本**——
这就是 `withUnsafeBufferPointer` 的全部承诺，而它的边界同样重要：
闭包一返回那个指针就不许再留用，把 `baseAddress` 存到外面是崩溃名单上的常客。

`withUnsafeBytes` 那 12 个字节把 §7 的对齐知识变成了看得见摸得着的东西：
`02 00 00 00 01 00 00 00 03 00 00 00`——三个字段各在 0/4/8，小端写法，**剩下 9 个字节是 padding**。
于是本章最实用的一条纪律出现了：**别拿整块结构体 `memcmp`、当哈希键、或者直接写文件**。
padding 里的内容 C 不管，你可能搬走一堆垃圾（Swift 侧新建的实例里那 9 个字节还可能是别的值）。
要比就逐字段比，要存就逐字段编码。

`CLSumPackB(nil)` 返回 -1：Swift 的 `Optional` 指针和 C 的 `NULL` 在这里就是同一个值，
所以 §6 那条「函数自己挡 NULL」在 Swift 侧同样必须成立——Swift 的可选类型不会替你检查传出去的指针。

## 20) Swift 的函数指针：`@convention(c)` 只收不带捕获的闭包

```
== §20 Swift 的函数指针：@convention(c) 与 qsort ==
  ok   Swift 闭包直接当 C 的函数指针用：CLCallMap({ $0 * 2 }, 21) = 42。CLIntMap 在 Swift 里就是 @convention(c) (Int32) -> Int32，**不带捕获**的闭包才能这么交出去
  ok   CLApplyTwice 把同一个指针调了两次再相加：22（每次 10+1）。纯函数才敢这么用；带状态的「函数」在 C 里只能靠全局变量，而那一页日志就再也复现不出来了（§17 那句话的另一半）
  ok   表里的函数和 Swift 里写的名字是同一个实现：同一个 -> 1，换另一个 -> 0
  ok   从表里取出的函数指针也能交给 Swift 闭包的位置：CLCallMap(CLMapAt(1), 6) = 36（square-it）
  ok   同一个数组两条路：C 的 qsort（1,2,2,7,9,10）与 Swift 的 sorted(by:)（1,2,2,7,9,10）一致 —— 但 qsort 只认那个不带捕获的 C 函数指针，sorted 的比较闭包什么都能带
  ok   比较闭包里捕获了一个集合（把 2 排到最后）：结果变成 1,7,9,10,2,2 —— 这一次两条路**故意**不一样。同样的逻辑要交给 C 的 qsort，只能把那个集合变成全局变量，或者干脆做不到
  ok   Swift 也能直接 callLibc 的 qsort：把全局函数 clCompareInt32Asc 交出去，排完是 1,2,2,7,9,10 —— 代价就是这个比较函数必须写在全局（或无捕获闭包），签名还要变成 UnsafeRawPointer + load(as:)
  要真的把「带捕获的 Swift 闭包」交给 C，必须再配一个上下文指针 + trampoline —— block 干的正是这件事，只是它把这套藏起来了（§17 有对照）
```

两个方向都跑了：Swift 闭包交给 C 的函数指针位（`CLCallMap({ $0 * 2 }, 21) == 42`），
以及从 C 表里取出的指针交给 Swift 闭包参数位（`CLCallMap(CLMapAt(1), 6) == 36`）。
中间那条「同一个 -> 1、换另一个 -> 0」是把 §13 的实现同一性判断挪到 Swift 侧再验一次。

`qsort` 的两条路是这一节的核心对照：同一个数组，C 的 `qsort` 和 Swift 的 `sorted(by:)`
给出同样的结果；然后示例给 Swift 的比较闭包加了一个**捕获**（把 2 排到最后），
结果变成 `1,7,9,10,2,2`，两条路**故意**不一样。同样的逻辑想交给 C 的 `qsort`，
只能把那个集合变成全局变量——或者干脆做不到。带捕获的闭包直接交出去，编译器的原文是：

```
         带捕获的闭包当 C 函数指针：error: a C function pointer cannot be formed from a closure that captures context
```

一个容易漏的点写在示例注释里：**全局常量不算捕获**。所以 `{ $0 * 2 }`、引用全局函数的闭包
都能交出去，只有真的捕获了局部上下文才报错——探针为了复现这条错误专门把变量改成了函数参数。
「要真的把带捕获的闭包交给 C，必须再配一个上下文指针 + trampoline」正是 `block` 替你做的事。

## 21) Swift 侧的 C 字符串：字节与字符是两套计数

```
== §21 Swift 侧的 C 字符串：字节与字符是两套计数 ==
  同一条字符串三套数法：String(cString: CLStaticCString()) = "C 侧的字面量"，Swift 的 utf8 计数 = 17，Foundation 的 lengthOfBytes(using: .utf8) = 17，Swift 的 characters 计数 = 7
  ok   Swift 数 UTF-8 字节和 Foundation 数的一致（17 == 17）：这两边都懂编码
  ok   而 characters 给出 7 —— 「几个字符」和「几个字节」是两套计数。C 的 strlen（§4 那个 6）只会给你字节，所以按 strlen 去「截断中文」就会切出半个字，这是中文产品最常见的 C 层 bug
  ok   对照 C 侧："中文" 的 sizeof = 7（含结尾 0），strlen = 6（纯字节）
  ok   Swift -> C -> Swift 走一圈内容不变（"C 侧的字面量"）：withCString 借出的那个 char * 只在闭包里有效，出来就收回
  ok   谁负责解释这串字节也要想清楚：C 只能取到第 0 个字节（228），而 Swift 的 String 从一开始就带着 UTF-8 编码 —— 跨界时「传 char *」传的不是字符串，是一段还没解释的字节
```

同一条字符串三个数：17 个 UTF-8 字节、17（Foundation 数的一致）、7 个用户可见字符。
把 §4 的 `strlen` 放进来就是四个数——**「几个字节」和「几个字符」是两套计数**，
按 `strlen` 去截断中文就会切出半个字，这是中文产品最常见的 C 层 bug。

最后一条是概念上的收尾：C 侧只能取到第 0 个字节 `228`，「它是什么意思」由接收方决定；
Swift 的 `String` 从一开始就带着编码。所以「传 `char *`」传的不是字符串，
是一段还没被解释的字节——两个方向的转换都必须显式写（§17 的 `%s` 就是忘了这一条的后果）。
`withCString` 借出的 `char *` 同样只在闭包里有效，出来就收回，和 §19 的指针同一个规则。

## 22) 宏的可见性，与 `NSError **` -> `throws`

```
== §22 宏的可见性，与 NSError ** -> throws ==
  ok   对象式的简单宏能进 Swift：CL_answer = 77（CLMacros.h 里 #define 的那个 77，Swift 直接当常量看见）
  ok   而且和 C 侧算出来的一致（77）—— 但**函数式宏**看不见：CL_SQR_BAD(3)、CL_TWICE(x) 在 Swift 里根本不存在（探针记录有原文）
  ok   条件编译的结果也带过来了：CL_WORD_BRANCH = 1（个位 1 = __LP64__ 那一支）—— 它是编译期就定死的常量，Swift 的 #if arch(...) 同理（下面这一行就是它自己那一支）
  Swift 侧的条件编译：这一行是 arch(x86_64) 那一支印出来的（C 那边 §16 用的是 __LP64__，两边各查各的）
  ok   成功路径：ObjC 那个 BOOL + NSError ** 的接口，在 Swift 里变成 throws —— 返回 YES 就走 do 分支，seed 被写成 98765
  ok   把 NULL 句柄传进去：Swift 侧收到一个 NSError（domain=CLCStyleAPI, code=17），而 out 参数没有被写（还是 0）—— §17 那条「先把出参清成 nil、失败路径绝不写它」的纪律，就是为了让 throws 这一侧读到干净的值
  ok   本节造的句柄也都还了：本章造的还活着 0 个
```

书里那句「`#define` 的东西 Swift 都能看见」只对了一半。实测边界很清楚：
对象式的简单常量能过来（`CL_answer = 77`），**函数式宏一律看不见**，编译器原文：

```
         函数式宏：error: cannot find 'CL_SQR_BAD' in scope（CL_TWICE、CL_STRINGIFY 各一条同样的）
```

所以工程规则是：跨语言的常量要么写 `static const` / `enum`，要么在 Swift 侧用 `let` 重述一遍。
§16 讲「宏不是函数」，§22 补上「宏也不跨界」，两条合起来才是今天该少用宏的完整理由。

`throws` 那两行是本章的闭环。同一个接口
`- (BOOL)readSeedOfHandle:(CLOpaqueRef)h seed:(int *)out error:(NSError **)error`
在 Swift 里变成 `try readSeed(ofHandle:seed:) -> Int32`：方法名被 importer 改写（探针原文
`'readSeedOfHandle(_:seed:)' has been renamed to 'readSeed(ofHandle:seed:)'`），
返回码变成成败两条路径，`NSError **` 变成 `throw`。而它成立的前提就是 §17 那三步纪律——
失败路径没把出参清干净，Swift 侧就读到脏值。示例两边各跑了一次：成功路径 seed 写成 98765；
NULL 句柄走 `catch`，拿到 `domain=CLCStyleAPI, code=17`，出参仍是 0。

顺带一句条件编译：C 用 `__LP64__`，Swift 用 `#if arch(x86_64)`，**两边各查各的**，
不会因为 C 走了某一支就带着 Swift 一起走。

## 23) 本章的边界：哪些是量出来的、哪些只能记、哪些留给真机

示例自己把这份清单打了出来，它是本章的方法论总结：

```
== §23 本章的边界：哪些是量出来的、哪些只能记、哪些留给真机 ==
  量出来并可断言的：整族类型的尺寸与对齐、char 的符号性、无符号回绕、除法与余数的取整方向、整型提升、
            浮点截断与 1 个 ULP 的差异、2^24 上限、前后缀自增、优先级、位运算与移位、短路、
            for/while/do-while/continue/break/switch(含 fallthrough)/goto 的计数、数组连续性与行主序、
            sizeof 与 strlen 的差、UTF-8 字节数、字面量合并、strcmp 的符号、指针步长、退化后的 sizeof、
            出参与 NULL 检查、结构体 padding 与 offsetof、union 位模式与 IEEE 754 三段、正零与负零的位模式和两处算术后果、枚举底类型尺寸、
            引用计数与配平、值传递、递归、可变参数（OC 侧）、回调表与 qsort/bsearch、memcpy/memmove 的结果串、
            calloc 清零、malloc 真失败的那次（跨编译单元才量得到）、编译器对分配的三种折叠、
            宏的展开次数与副作用次数、@encode、结构体属性、NSString <-> char *、
            以及 Swift 侧的类型映射、MemoryLayout、withUnsafe 系列、@convention(c)、throws、宏的可见性。
  只记不跑的（示例一行都没执行，全部来自独立探针，正文以「探针记录」引用编译器/运行时的原文）：
    有符号整数溢出、memcpy 重叠区、realloc 搬家后继续用旧指针、可变参数 count 撒谎、void* + 1 的标准化
    程度、malloc 判空被折之后的汇编长什么样、Swift 把带捕获的闭包当 @convention(c) 传出去、Swift 调 C 可变参数
    函数、Swift 用普通 + 触发溢出 trap、函数式宏在 Swift 里不存在、-Wimplicit-fallthrough 到底什么时候响。
```

有符号溢出那条最有欺骗性，探针原文值得单独抄一遍：

```
    3) 有符号溢出。源码：int x = 2147483647; int y = x + 1; 打印 y 和 x。
       -O0 打 x+1=-2147483648  x=2147483647，-O2 一模一样，看着「挺正常」。
       这正是它最骗人的地方：UB 不保证当场出错，只保证编译器不必为你的假设负责。
       所以本章从头到尾只用无符号回绕做「溢出」的演示。
```

「两个优化级别给出同一个错误答案」看起来像「这条 UB 无害」，其实恰恰相反：
它只是这一次没被利用。同一条 UB 在 memcpy 重叠那节里给了两个**不同**的答案。
UB 的定义不是「一定崩」，而是「标准不承诺任何东西」——这是本章最想在 C 层讲清楚的词。

`realloc` 搬家那条也留在探针里，因为它的后果是悬垂指针，属于「跑一次不一定看得出来」：

```
    7) realloc 搬家。8 字节 realloc 到 4096：moved=1（-O0 与 -O2 都是 1），
       而旧指针 p 那四个字节已经不再是最初的 97 98 99 0 —— 被分配器的空闲链表元数据盖掉了。
       那几个字节每次运行都不同，所以本章一次都没把它们打进输出。
```

**换 arm64 会变什么**，这一条对本章所有数值做了范围限定：

```
  本机才成立的数值：long=8 与 char 有没有符号（有）都随目标变。
    换 arm64（真机）之后至少这几处会变：long 仍是 8 但 char 变成无符号（§4 那个 -28 变成 228）、
    CLCharIsSigned() 反过来、Swift 侧 char 字段从 Int8 变成 UInt8（§19 的字段赋值要跟着改）、
    x86_64 独有的 objc_msgSend_stret 一整套在 arm64 上不存在。结构体的 padding 与对齐规则本身不变，具体字节数会变。
```

所以本章的结论分成两类：**规则**（`p + 1` 走 `sizeof(*p)`、字段按宽度排序能省 padding、
`int -> Int32` 的映射、重叠就 `memmove`、分配要判空且判空要写在看不穿的地方）可以带走；
**数值**（12、8、4294967293、-28）只在这台 `x86_64-apple-ios15.0-simulator` 上成立。

刻意没讲的部分也摊开写了（C++ 名字修饰与 `extern "C"`、原子操作与内存序、`setjmp/longjmp`、
VLA、位域布局、`dlopen` 与符号可见性），并且明确本章不碰任何具体框架的 C API
（`CGContext`、`sqlite3`、`AudioQueue`）——那是第 26 章和本章之后 Quartz 2D 一章的主题，
这里只把「C 层的规则」和「跨界时哪条会变」讲清楚。

最后一行是给这本书第 4 章的批注，也是本章存在的理由：

```
  这本书（第 4 章）里今天需要改写的部分：把 int 当「机器字长」（今天是 fixed-width 类型）、
    用 char* 存中文并靠 strlen 数「字数」、把 malloc 的返回值直接赋给对象指针、
    以及用宏做所有常量（今天该用 enum/static const，Swift 侧再用 let 重述一遍 —— §22 那条可见性差异就是原因）。
```

## 本章能带走的东西

按「明天就会用到」排序：

1. **`int` 进 Swift 是 `Int32`，`long`/`size_t`/`ptrdiff_t` 才是 `Int`**（§18）。跨界时先确认宽度和符号，
   别把「都是整数」当「都是 `Int`」。`size_t` 塌成 `Int` 之后，无符号回绕变成会 trap 的普通减法。
2. **数组参数旁边那个整数是元素数还是字节数**（§3）。C 的数组一进函数就只剩地址，长度信息彻底没了。
3. **结构体字段按宽度从大到小排**（§7），`offsetof`/`stride` 用来分辨「省内存」和「故意对齐」；
   **别整块 `memcmp` / 别把结构体当哈希键**（§19），padding 里的内容 C 不管。
4. **可能交叠就 `memmove`；每次 `malloc` 都判空**（§14/§15）。判空这件事如果要验证，
   得写在编译器看不穿的地方——同一个函数里的「分配 + 判空 + free」在 `-O2` 下会被整体删掉。
5. **中文一律走 `%@`，`char *` 必须先按编码包成 `String`/`NSString`**（§17/§21）。
   `strlen` 给的是字节不是字符，按它截断就会切出半个字。
6. **C 的枚举和宏都不会自动变成 Swift 的 enum 和常量**（§18/§22）：裸枚举过来是个 `RawRepresentable`
   结构体（`switch` 穷尽不了），函数式宏在 Swift 里根本不存在。要 `NS_ENUM` / `NS_OPTIONS` 才有好映射。
7. **带捕获的闭包交不给 C 的函数指针位**（§20）。真要交就自己配上下文指针 + trampoline，
   而 block 就是把这套藏起来的版本（§17）。
8. **UB 不等于「一定崩」**（§23）：有符号溢出两个级别给出同一个「看起来对」的值，
   memcpy 重叠两个级别给出两个不同的值。两者的共同点是标准不承诺任何结果，
   所以这类边界行为只能靠 sanitizer 和反汇编，不能靠读代码推断。

下一章（29）会把这些规则用在真正的框架 API 上：Quartz 2D 的 `CGContextRef`——
一个不透明句柄（§10）、一套返回码式 API、`CGRect` 这类值类型（§7/§17），
以及「画完之后把像素读回来」这种只有 C 层能验的断言。
