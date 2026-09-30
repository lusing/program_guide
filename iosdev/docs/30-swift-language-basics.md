# 30 · Swift 语言基础与面向对象：把「编译器会报错」逐条量成一行证据

> 示例：`examples/30_swift_language_basics/main.swift`（同级 `probes/` 55 个探针 + `run.sh`、`w01_whitespace.sh`）
> 实测输出见 `build/30_swift_language_basics/stdout.debug.txt`

前二十九章全部在 API 一侧：布局、控件、滚动、动画、音频、传感器、数据库、Objective-C 运行时、
C 语言层、Quartz 2D。这一章回到语言本身。《跟着项目学iOS应用开发：基于Swift 4》里属于这一层的
内容是：**第 5 章**（Swift 程序设计基础：5.1 备注与打印、5.2 无参无返回值函数、5.3 带参函数、
5.4 返回值、5.5 条件语句与随机数、5.6 三元、5.7 for-in 与数组、5.8 啤酒歌与区间、5.9 斐波那契）、
**第 6 章的 6.4**（do/catch/try 与 AVAudioPlayer 的错误码）、**6.6/6.7**（计算属性与作用域）、
**第 9 章整章**（9.1 类是蓝图、9.2 建第一个类、9.3 枚举、9.4 类与枚举的组合、9.5 自定义初始化、
9.6 Designated/Convenience、9.7 方法与属性、9.8 继承、9.9 重写、9.10 可选）、
**第 11 章的 11.3/11.4**（闭包五步简化、完成处理与回调）。

那一版的判据有两样：**Playground 右侧结果栏显示什么**，和**Xcode 报了什么红**。书里到处都是
「编译器将会报错」「发生致命错误」这类句子，配上截图。这两样判据在 2018 年成立，在今天这套
工具链上不能直接用：结果栏要 Playground，报错截图要 IDE，而本教程的所有示例都在命令行里
`swiftc` + 模拟器 headless 跑（六条判定写在 `run-all.sh` 头部与 `README.md`：编译日志为空、退出码 0、
stderr 为空、stdout 非空、无多余控制字符、结尾标记 `==== NN 结束 ====`，外加 debug(-Onone) 与
release(-O) 两份 stdout 逐字节一致）。

所以本章做三处替换：

1. **判据换成 stdout 上的一行行断言**：书里「跑一下看看」的每个结论，这里都写成 `expect(...)`，
   文档里逐字引用运行结果；
2. **「编译器会报错」全部改成独立探针现跑**：主线示例里**不出现**一行故意写错的代码——凡是不合规
   的写法都编译不过，一编译不过六条判定全崩。55 个探针各自开一个进程去量，编译器原话和崩溃现场
   抄在本文末尾的「探针记录」；
3. **Swift 4 的行为按本机 Swift 6.0.3（语言模式默认 5）重新量一遍**：对不上的地方不以「勘误表」的
   形式列，而是按它现在的面目呈现。

## 本章的换法（全部有实测支撑，逐节展开）

- 书 5.1「操作符两边必须有空格，否则报错」：完整规则是「不对称才报错，两边都不留空格也行」，
  而且**只有 `=` 走这条专门的诊断**；`+` 少一边报的是另一件事，措辞完全不是「空格不合规」（§2）；
- 书 5.1「注释删掉两个斜线，编译器就会报错」：报的不是「注释符错了」，而是那行中文被当成代码去
  解析，`cannot find '…' in scope`（§1，探针 e32）；
- 书 5.4「丢失了函数预期的 Int 类型的返回值（missing return in a function expected to return 'Int'）」：
  这条诊断文本在 6.0.3 已经换成 `cannot convert return expression of type '()' to return type 'Int'`（§6，探针 e03）；
- 单表达式函数可以省 `return` 是 Swift 5.1 才有的，书写 Swift 4 时每个分支都得写（§6）；
- 书 5.5 的 `nameScore > 40 && nameScore <= 80`：第二个条件恒真（能走到 `else if` 说明第一条已不成立），
  本章把三条分支的边界逐个量出来给这件事看（§7）；
- 书 5.8「99...1 这种方式……编译器会报错」：**编译期一声不响**，是运行期 fatal error 加信号 4，
  而且和书里说的一样「不会有任何的输出」（§8，探针 e08 编译零诊断 / r01 崩溃现场）；
- 书 5.8 说 `(1...99)` 「类型为 Range」：`1...99` 是 `ClosedRange<Int>`，`..<` 才是 `Range<Int>`（§8）；
- 书 5.9 的 bug 被书自己修对了（`0...n-3` 让项数等于参数），但它把 `n < 3` 留成了一个反向区间：
  编译期无声、运行期 fatal（§9，探针 r09）；同节那条「iteration 从来没有使用过」的警告，
  六年间文本几乎一字未改（§9，探针 e06）；
- 书 9.3 的 `case Coupe` 首字母大写：今天也编译得过，只是风格指南要小写（§13，探针 e23）；
- 书 9.5「回到 main.swift，此时编译器会报错：初始化方法丢失参数 customerChosenColour」：
  6.0.3 原话仍在，只是英文措辞（§14，探针 e12）；
- 书 9.6 的 convenience 两行顺序（先 `self.init()` 再改属性）是**硬规则**，调换顺序或干脆不写
  各有专门的诊断（§15，探针 e21、e14、e27）；
- 书 9.8「Car 中的任何事情在 SelfDrivingCar 类中都可以有」：对初始化方法只有一半成立——
  子类不写自己的 designated 时父类的全继承（含 convenience，间接可用），一写就全消失（§15/§17，探针 r10 与 e22 对照）；
- 书 9.9「用了 override 就会先执行父类的方法」：只在**写了 `super.` 的时候**成立。不写 super 的
  override 完全不跑父类那份（§17，Fish 只留一条「用腮呼吸」）；
- 书 9.10 的强制拆包崩溃：原话是 `Fatal error: Unexpectedly found nil while unwrapping an Optional value`，
  和书里的中文译法逐字对得上（§18，探针 r02）；
- 书 11.3「calculator(n1:n2:operation:) 代码一定要放到两个函数定义的后面，否则会出现找不到函数的错误」：
  这条在 6.0.3 **对 `func` 名字不成立**（函数声明整个文件都可见，探针 e04），
  但对「存在 `let` 里的闭包」成立——提前调用读的是没填过的存储，直接 signal 11（§19，探针 r13）；
- 书 11.3「最后一个参数是闭包才能挪出括号」：Swift 5.3 之后放宽成**多重尾随闭包**（第一个不带标签、
  后面的写成 `label: { }`），但「挪出去的闭包后面再补普通参数」今天依然不行（§19，探针 e31）；
- 书 5.x 时代的 `string.characters.count`：`characters` 在 Swift 5.0 被标成 obsoleted，
  今天直接写 `string.count`（§21，探针 e30）；
- 切到 `-swift-version 6` 之后本章新增的硬错误只有一条：**全局可变状态被非隔离函数改**
  （§21，探针 s06 的两模式对照；s01~s05 两个模式给出逐字相同的诊断）。

```
地基   §1  注释、print(_:terminator:)、多行字符串与转义
排版   §2  操作符两侧的空格：不对称的只有 =，其它是「两条语句」
数据   §3  let/var、类型推断、Int/Float/Double 的字节账、UInt32 → Int
函数上  §4  最小形态：空函数体、定义不执行、声明提前可见
函数上  §5  输入：外部名/内部名、_、默认值、可变参数、inout
函数上  §6  输出：return、隐式 return、Void 的三种写法、元组标签
控制   §7  条件：边界逐个量、冗余条件、优先级与短路、switch 的穷尽
控制   §8  区间与循环：ClosedRange vs Range、stride、repeat-while、标签 break
控制   §9  斐波那契的 off-by-one：书的原版、书的修补、修补留下的坑
组织   §10 作用域：三层围墙、跨方法共享、参数化的解法、同名遮蔽
组织   §11 do/catch/try：三种接法、OSStatus 的 FourCC 形状、defer、rethrows
OOP   §12 类与对象：蓝图与真车、let 锁引用、=== vs ==、struct 值语义
OOP   §13 枚举：case 名、原始值、关联值、CaseIterable、打印形状
OOP   §14 初始化：生产线还是返厂喷漆、self. 与同名、默认参数、init?
OOP   §15 Designated 与 Convenience：顺序是硬规则、继承全有或全无
OOP   §16 方法与 self：函数类型可量、观察器、计算属性
OOP   §17 继承与重写：override、super 的两面、多态、is/as?、两阶段初始化
OOP   §18 可选：盒子、if let/guard/??/!、可选链、IUO
闭包   §19 六步简化逐项等价、多重尾随闭包、集合上收闭包的方法
闭包   §20 逃逸与捕获：入队≠执行、weak 斩环、for 与 while 的每轮变量
版本   §21 #if swift vs #if compiler、characters 的断代、-swift-version 6 对照
容器   §22 数组/字典/Set：三种「取不到」、顺序、Any 与 as?
边界   §23 量到了什么、什么必须回 IDE、换 arm64 会变什么
```

## 本章的方法：为什么要有 probes/ 目录

一条 `expect` 只能断言「程序活着跑完时看到的值」。而本章有一半的论点是关于**程序不允许活着跑完**的
写法：不合规的空格、缺 `override`、convenience 没委托、强制拆包拆到 nil、`99...1`。这些写法要么
编译不过（判定 1 立刻失败），要么当场崩溃（判定 2、3 一起失败），要么在 stdout 里留下不可复现的
值（随机数、字典遍历顺序）。所以本章分成两处放：

- `main.swift`：只放**能安全跑完**的写法，22 节 209 条断言，六条判定全绿；
- `probes/`：55 个一次性小文件，编号约定写在 `probes/run.sh` 头部——
  `eNN` 编译期诊断（只看 swiftc 输出，不运行）、`rNN` 运行期现场（抄 stdout/stderr/退出码）、
  `sNN` 语言模式对照（同一份源码分别 `-swift-version 5` 与 `6`）、`tNN` 纯输出表。

一个必须知道的实现细节：**探针都得复制成 `main.swift` 再编**。顶层语句只有文件名叫 `main.swift`
时才允许存在，否则报的是 `expressions are not allowed at the top level`——那已经不是被测的那件事了。

---

## 1) 注释、print 与控制台（本书 5.1）

书 5.1 的原文给了两层信息：注释「总是以两个斜线开始」，多行用 `/*` 开头 `*/` 结尾；
以及一句后面会被本章打折扣的话——绿色的代码是注释，「Xcode 编译器会忽略它，不会将它作为代码来处理」。

```swift
/// 一行文档注释
/// - Parameter n: 文档注释可以带参数说明
func documented(_ n: Int) -> Int { return n }

/*
 这是一个多行的注释语句 —— 本书 5.1 的原文例子逐字照抄。
 里面写什么都不会执行：var neverRuns = "编译器看不见这一行"
*/
```

`//` 双斜线只保一行；`///` 三斜线是文档注释，编译器同样无视，但 **Xcode 的 Quick Help 面板会捡走
它们**——这是 IDE 功能，headless 环境下量不到，本章只能证明「它不影响编译」。书里那条
「如果删除两个斜线，Xcode 编译器就会报错」是本章第一个被量的说法：报错的内容不是「注释符不对」，
而是那行汉字被交给了语法解析器（探针 e32 抄了原话）。

`print` 在书 5.1 里出现时是个「往控制台写一行」的黑盒。它其实有两个形参：

```swift
print("terminator 传空串就不换行 → ", terminator: "")
print("同一条逻辑行的后半段")
```

第二条判定要求 stdout 可复现，所以本章**用断言而不是靠 print 的顺序**来说明事情；`print` 本身
的输出照样在 stdout 里，被逐字引用：

```
  ok   文档注释不影响编译：documented(3) = 3
print 默认换行；下一次调用从新行开始
terminator 传空串就不换行 → 同一条逻辑行的后半段
  ok   print(_:terminator:) 用 terminator: "" 可以把两条 print 接在同一行
  ok   多行字符串行数: Int = 3
  ok   第二行确实带 4 个空格：    第二行前面有 4 个空格（相对三引号的缩进基准）
  ok   字符串里有一个真换行 → 切成 2 段
  ok   反斜杠本身要写两条才落一条
  ok   插值 \(...) 在编译期就被换成描述
  ok   把 // 去掉是「语义变化」，加回来才又是一行普通字符串
```

要点三条：

- `terminator:` 默认是 `"\n"`，传空串就能把两次 `print` 接在同一行——这是本章「一行行输出」骨架里
  `line()` 与 `section()` 之间不换行的做法；
- 多行字符串（`"""` … `"""`）里的换行是**真实换行**，而每行的缩进基准是**收尾那三引号所在的列**，
  比它更靠右的部分才算内容，所以 §1 那段里只有「第二行」带着 4 个空格；
- 转义：`\n` 换行、`\\` 一个反斜杠、`\"` 引号、`\t` 制表符，`\( )` 是插值——插值在**编译期**就被换成
  表达式求值结果，所以 `"\(1 + 1)"` 里没有「2」这个字符，只有算出来的 2。

## 2) 操作符两侧的空格：书 5.1 的「报错」到底报什么

本书 5.1 在 `var monsterHealth = 19` 旁边写了这段规则（原文完整引在这里，因为断章会把它说对的部分
也抹掉）：

> 当我们使用操作符的时候，例如 =、+、-、/ 或 * 号的时候，你必须让它两边都有一个空格的间隔。
> 等号左边有空格，等号的右边就必须要有空格，如果少了一边，Swift 就会对这种非对称格式报错。因此，
> 要不就两边都有空格，要不就两边都不留空格。

三条可以拆开的 claim：① 少一边会报错；② 两边都不留空格也行；③ 这条规则适用于 `= + - / *`。
`probes/w01_whitespace.sh` 把十一条写法逐个现编现跑（每次拼进一个临时 `main.swift`，只抄 swiftc 的
原话），结论是：**① 对 `=` 成立，② 对 `=` 和 `+` 都成立，③ 只对 `=` 成立。**

```
== 赋值号 = 的四种空格组合 ==
h = 20                   通过（零诊断）
h=20                     通过（零诊断）
h =20                    有诊断：
      main.swift:3:3: error: '=' must have consistent whitespace on both sides
h= 20                    有诊断：
      main.swift:3:2: error: '=' must have consistent whitespace on both sides

== 中缀 + 的四种写法 ==
h = h + 1                通过（零诊断）
h = h+1                  通过（零诊断）
h = h +1                 有诊断：
      main.swift:3:5: error: consecutive statements on a line must be separated by ';'
      main.swift:3:3: error: assigning a variable to itself
      main.swift:3:7: warning: result of operator '+' is unused
h = h+ 1                 有诊断：
      main.swift:3:6: error: consecutive statements on a line must be separated by ';'
      main.swift:3:6: error: '+' is not a postfix unary operator
      main.swift:3:8: warning: integer literal is unused
h = h+1+2                通过（零诊断）
```

（上表把 swiftc 输出里的绝对路径与前缀省略号去掉了，`error:`/`warning:` 文本逐字照抄；
带完整上下文的原始输出在 `probes/w01_whitespace.sh` 现跑可见。）

差别不是细节，是两件不同的事：

- `=` 有一条**专门的排版诊断**：`'=' must have consistent whitespace on both sides`。它是编译器替
  初学者挡「`h =20` 是不是想写 `h ==(x)` 之类」的坑，只在两侧不对称时出现。
- `+` 这类中缀**没有**这条诊断。`h = h +1` 会被解析成「一条语句 `h = h`」后面紧跟「`+1`」，
  所以报的是 `consecutive statements on a line must be separated by ';'`，附带 `assigning a variable
  to itself` 和一条 `result of operator '+' is unused` 的警告。`h = h+ 1` 同理，只是这次 `+` 被当成
  前缀待在后缀位，于是多出一条 `'+' is not a postfix unary operator`。

也就是说：把书里那句话当成「排版规范」念是对的，当成「编译器会拦你」念，只有 `=` 那一份拦得住。

主线这边把整除那件事一并量了（书 5.1 的 `19 + 31 = 50`、`50 / 2` 之所以顺，是因为它恰好整除）：

```
  ok   先加 31 再除以 2: Int = 25
  ok   两侧一起挤（h+1）照样算：26
  ok   复合赋值 +1 也一样：27
  ok   四则运算本身不受空格影响，受影响的只有排版：26
  ok   整数除法是截断：51/2=25，51%2=1
  ok   负数也朝零截断：-7/2=-3，-7%2=-1
```

- `51 / 2 == 25`：两侧都是 `Int` 时 `/` **截断**而非四舍五入；`51 % 2 == 1` 留下被砍掉的那份。
- `-7 / 2 == -3`、`-7 % 2 == -1`：截断方向是**朝零**，不是朝负无穷——这条账在 Swift 4 之后没有变过，
  但它和「`%` 结果的符号跟左边一致」是同一件事的两面。

## 3) 常量、变量与类型（本书 4.5 / 5.1）

书 4.5 给的是 `let` 与 `var` 的定义，书 5.1 在 `monsterHealth` 上演示类型推断，而书 9.2 的 `Car`
用 `var colour = "Black"` 和 `var numberOfSeats: Int = 5` 两种写法并排——本章把这两种写法的差别
直接打在类型上：

```
  ok   字面量 19 默认推断成 Int
  ok   标了类型的 19 才是 Double：Double
  ok   x86_64 模拟器上 Int 是 8 字节（第 28 章的 LP64 账）
  ok   Int=8 Float=4 Double=8 字节
  ok   布尔落字符串是 true，19 落到 Double 上打印成 19.0：true / 19.0
  ok   书 9.2 里 Car 的默认颜色就是这条字符串：Black 的类型是 String
  ok   var 可以重新赋值
  ok   let 数组能读：letArray[0] = 1
  ok   Int(arc4random_uniform(101)) 的类型与取值范围：Int，必落在 0...100
  ok   抽 2000 次全部落在 0...100 之内：2000 次命中
  ok   字符串转数字返回可选：Int("42")=Optional(42)，Int("abc")=nil
```

逐条拆开：

- **字面量默认 `Int`**。`19` 推断成 `Int` 而不是 `Double`；要 `Double` 必须显式标注
  （`let explicitDouble: Double = 19`），标注之后打印出来才是 `19.0`。书 5.1 那个「=19 会报错」的
  例子里，`monsterHealth` 从第一次赋值起就被钉成了 `Int`，这也是它后面能做整数除法的前提。
- **`Int` 是 8 字节（本机 x86_64 模拟器）**。这一条与第 28 章的 LP64 数据模型接上：C 侧 `long`/`size_t`
  同样是 8 字节，而 `Float` 4 字节、`Double` 8 字节。换 arm64 真机这个数不变（同为 LP64），但
  本章仍把它写成断言，因为它是**这台机器量出来的**。
- **`UInt32` 与 `Int` 之间没有隐式转换**。书 5.5 的原话是 `arc4random_uniform` 的返回值
  「是 UInt32 类型，所以需要使用 Int() 将其转换」，不转就是硬错：探针 e07 抄的是
  `error: cannot convert value of type 'UInt32' to specified type 'Int'`。这是 Swift 的类型系统里
  最不宽容也最省心的一条：数值类型之间**永远**要显式走。
- **随机数只能问范围，不能打印值**。`arc4random_uniform` 每次进程都换种子，一旦把本次值写进
  断言文本，debug 与 release 两份 stdout 就对不齐（六条判定的最后一条）。所以 §3 写成
  「必落在 0...100」+「抽 2000 次全部命中」，一个具体值都不印。
- **`Int("42")` 返回的是 `Int?`**。字符串转数字是**可失败**的，这条为 §18 的可选埋好了线：
  它不是「失败给 0」，而是「失败给 nil」，编译器逼你处理第二种可能。
- `let` 数组能读能改内容吗？能读；`let a = [1,2,3]` 之后 `a.append(4)` 是编译错误
  （`cannot use mutating member on immutable value: 'a' is a 'let' constant`，探针 s05）。
  数组是值类型，`let` 锁的是整个值——这件事和 §12 的 class 正好相反。

## 4) 函数的最小形态（本书 5.2）

书 5.2 的 `getMilk()` 是「无参数、无返回值」：

```swift
func getMilk() {
    print("去门口的小卖店")
    print("买2瓶牛奶")
    print("支付13.20元")
    print("回家")
}
```

本章照抄这四行 `print`，为的是把「定义不产生输出，只有调用才产生」这件事打成可看的：

```
  ok   空函数体也能调用：func 名字() {} 之后 名字()
定义 getMilk() 本身不产生任何输出，只有调用它才打印：
去门口的小卖店
买2瓶牛奶
支付13.20元
回家
先看答案再定义：调用在前的函数与在后的函数声明 ——
calcBefore() = 42（calcBefore 的 func 写在下一行之后）
```

这一节还顺手改掉书 11.3 的一条叮嘱。书里写：

> calculator（n1：4，n2：7，operation：add）代码一定要放到两个函数定义的后面，否则会出现找不到函数的错误。

在 Swift 6.0.3 的顶层代码里，**函数声明在整个文件范围内都可见**，写在调用之后照样跑：上面
`calcBefore()` 的 `func` 就写在 `print` 的下一行，输出 42 正常。探针 e04 单独证了这件事（编译零诊断、
运行输出 9）。这条叮嘱大概是 Xcode 早期或从别的语言带过来的习惯，也可能是 Playground 逐行求值留下的
印象——Playground 是从上往下执行的，那里「在后面定义」确实来不及。

真正有顺序问题的是顶层的 `let`/`var`，而它的表现比「报错」更值得记住：**不报错也不崩，读到的是
没填过的存储**。探针 t01 在定义之前读顶层的 `x` 和 `box`，两次都读到 `0`，定义之后才是 41 和 99。
§19 会看到这条在「闭包存在 let 里」的时候升级成 signal 11（探针 r13）。

## 5) 函数的输入：外部名、内部名、下划线、默认值、可变参数（本书 5.3 / 5.8）

书 5.3 的 `getMilk(howManyMilkCartons:)` 第一次让读者撞上「调用时也必须写参数名」：

```swift
func getMilk(howManyMilkCartons: Int) { print("买 \(howManyMilkCartons) 瓶牛奶") }
getMilk(howManyMilkCartons: 4)
```

少写这个标签不是风格问题，是硬错（探针 e02：`missing argument for parameter 'howManyMilkCartons' in call`，
编译器还会用 `note:` 把声明处指给你）。Swift 的每个参数其实有**两个名字**：外部名给调用者看，
内部名给函数体用。书 5.8 的啤酒歌用的就是这个：

```swift
func beerSong(withThisManyBottles totalNumberOfBottles: Int) -> String { ... }
```

调用点写 `beerSong(withThisManyBottles: 3)`，函数体里用 `totalNumberOfBottles`。本章把它改成返回
歌词字符串而不是打印，于是「3 瓶给几行」「最后一瓶用单数」都能断言：

```
买 4 瓶牛奶
  ok   函数体内用的是内部名：第一段起于 3 bottles
  ok   最后一瓶改用单数 bottle（书 5.8 的 if 分支）
  ok   最后一段说 no more，不出现 0 bottles
  ok   3 瓶 → 3 行，行数 = 传入的参数：3
  ok   func f(_ x: Int) 让调用点写成 f(23)：46
  ok   默认参数：4×7=28，指定单价后 4×5=20
  ok   Int... 收 7 个数得 75，一个不给也得 0
  ok   inout + & 让调用方的值真的变了：bill = 110
```

- 段落数 = 参数值：`for number in (1...totalNumberOfBottles).reversed()` 从大往小走，
  这正是书 5.8 拒绝 `99...1` 之后采用的写法（§8 会把 `99...1` 的真实行为量出来）。
- 书 5.8 反复修改的「1 bottle」单数分支和「no more bottles」收尾，本章用 `contains` 断言：
  最后一行确实是单数，且整个字符串里不出现 `0 bottles`。
- `func f(_ x: Int)` 的下划线是把外部名**删掉**：调用点写成 `beerSongUntagged(23)`。
  这是 Swift 的一个不对称设计——想省标签要显式写下划线，而不是像很多语言那样默认没有标签。
- **默认参数**保留外部名，调用时可省：`priceOf(milkCartons: 4)` 走默认单价，
  `priceOf(milkCartons: 4, unitPrice: 5)` 覆盖它。
- **可变参数** `Int...` 在函数体内就是一个数组（`total()` 一个都不给也合法，`reduce(0, +)` 得 0）。
- `inout` 是唯一能让函数改动调用方存储的普通写法：`addTax(&bill)` 之后 `bill` 自己变成 110。
  注意 `&` 只出现在**调用点**，声明处写 `inout`——两边都做了标记，读代码时不用翻定义就知道这个
  参数会被改。这是「值语义语言里唯一的引用逃生舱口」，也是本章后面 §20 捕获语义的对照组。

## 6) 函数的输出（本书 5.4）

书 5.4 的 `getMilk(howManyMilkCartons:howMuchMoneyRobotWasGiven:) -> Int` 用 `->` 标出返回值类型，
然后 `return change`：

```
你好主人，这里是找回的 2 元钱。
  ok   30 - 4×7 = 2：2
  ok   换参数不换签名：3 瓶找 9 元
  ok   省略 return 的单表达式函数：42
  ok   三种写法的返回值类型都是 Void：()
  ok   元组带标签：min=1 max=32
  ok   拆包成两个常量：1/32
  ok   缺 return 的诊断文本已换：见 probes/e03_missing_return.swift
```

- 30 − 4×7 = 2，换参数不换签名（3 瓶找 9 元）。**函数签名只看类型与标签，不看参数值**，
  这句听上去是废话，但它正是 §7 里「三条分支必须覆盖全部输入」的另一面：签名不保证值域。
- `-> Int` 声明了却忘写 `return`，书 5.4 记的报错是「丢失了函数预期的 Int 类型的返回值
  （missing return in a function expected to return 'Int'）」。那是 Xcode 8/9 时代的措辞，
  6.0.3 给的是另一条：`cannot convert return expression of type '()' to return type 'Int'`
  （探针 e03）。同一个病，从「你漏了 return」改成「你回来的东西类型不对」，
  读法变了但结果一样——都是编译不过。
- 单表达式函数可以省掉 `return`（`func implicitDouble(_ n: Int) -> Int { n * 2 }`）。
  这条是 **Swift 5.1** 才有的（SE-0255），书写 Swift 4 的时候每个分支都得写 `return`。
  也就是说：今天照书的代码多写 `return` 完全没错，只是可以省。
- 「没有返回值」有三种写法，它们是同一个类型：什么都不写、`-> Void`、`-> ()`。
  断言直接问 `type(of:)`，三者都是 `()`。
- 想要多个返回值只能靠**元组**（`-> (min: Int, max: Int)`），而且带标签的元组可以直接 `.min`/`.max`
  取，或者 `let (lo2, hi2) = mm` 拆开。这是 Swift 里「一个 return 值」的唯一扩容方式。

## 7) 条件语句与「覆盖全部情况」（本书 5.5 / 5.6）

书 5.5 用名字评分举例：`if nameScore > 80 { … } else if nameScore > 40 && nameScore <= 80 { … }
else { … }`，收尾的忠告是「检测机制一定要覆盖全部的情况」。这句话值得逐条量。

```
  ok   81 → 完美：你的名字评分是 81，很完美！
  ok   80 不在第一条分支（> 80），落到第二条：你的名字评分是 80，还不错！
  ok   41 → 还不错：你的名字评分是 41，还不错！
  ok   40 也不在第二条（> 40），落到最后：你的名字评分是 40，比较一般。
  ok   0...100 里满足 >40 && <=80 的是 41...80，共 40 个
  ok   && 比 || 紧密：t || f && f = true，加括号变 false
  ok   && 左边为 false，右边函数没被调用：sideEffect = 0
|| 命中左边
  ok   || 左边为 true 也一样短路：sideEffect = 0
  ok   嵌套三元当表达式用：75 → B
  ok   区间 case / where 附加条件 / 绑定 case 各跑一遍：低、中偶、异常大 300
```

- **边界落在哪一边**：81 → 完美、80 → 还不错、41 → 还不错、40 → 一般。书里的第一条件写的是
  `> 80` 而不是 `>= 80`，所以 80 归第二档；第二条件写 `> 40`，所以 40 归最后一档。
  这类「评分程序差一分」的 bug 靠读代码很难看出来，靠把边界打出来一眼就完。
- **第二条里的 `<= 80` 是冗余的**：能走到 `else if` 说明第一条已经不成立，即 `nameScore <= 80`
  必然为真。本章把 `0...100` 全扫一遍数出满足 `> 40 && <= 80` 的整数正好 40 个（41...80），
  把「冗余但无害」说清楚——它是防御性写法，读的人不用推理就能看懂范围，代价是多一个条件。
- **`&&` 比 `||` 结合得紧**：`t || f && f` 是 `true`，加括号成 `(t || f) && f` 才是 `false`。
- **短路是真实发生的**，不是「优化」。用一个会自增的 `bump()` 当右操作数，跑完之后 `sideEffect`
  还是 0——`false && bump()` 与 `true || bump()` 都**根本没调用**那个函数。
  这条在生产代码里的形式是「不要在 `&&`/`||` 右边放有副作用的调用」。
- **`if` 是语句，三元是表达式**：`s > 80 ? "A" : (s > 40 ? "B" : "C")` 能直接当值赋给 `let`。
  书 5.6 用三元改写了 `if`，本章同意它「能当表达式用」这一点，但要提醒：嵌套三元可读性差，
  多层之后 `switch` 更省事。
- **`switch` 比 `if` 链强的地方是「编译器逼你穷尽」**。§13 的枚举 switch 少写一个 case 就是编译错误
  （探针 e20：`switch must be exhaustive`，而且 `note:` 直接把缺的两个 case 名列出来）。
  这是本章「书里说要靠自觉覆盖全部情况 → 编译器可以替你保证」的最典型一处。
  整数 switch 还能用区间 case（`case 1...40`）、`where` 附加条件（`case 41...80 where s % 2 == 0`）、
  绑定 case（`case let x where x > 200`），本节三种都跑了一遍。

## 8) 区间与循环（本书 5.7 / 5.8）

书 5.7 的 `for number in arrayOfNumbers { sum += number }` 与书 5.8 的啤酒歌循环，本章都改写成
可断言的形式（把「每一步的部分和」也记下来，这样 off-by-one 藏不住）：

```
  ok   for-in 累加整数组：sum = 75
  ok   每一步的部分和都能对上：[1, 6, 8, 11, 21, 43, 75]
  ok   还能按索引取：[0]=1 [6]=32
  ok   1...10 跑 10 次，1..<10 跑 9 次：10/9
  ok   for ... where 过滤出 5 个偶数：[2, 4, 6, 8, 10]
  ok   1...99 的类型是 ClosedRange<Int>，不是 Range<Int>
  ok   1..<99 才是 Range<Int>
  ok   ClosedRange 的 upperBound 包含在内：1...99，contains(99)=true
  ok   Range 的 upperBound 不包含：(1..<99).contains(99) = false
  ok   (1...5).reversed() 给出 5→1：[5, 4, 3, 2, 1]
  ok   reversed() 返回的不是数组而是 ReversedCollection<ClosedRange<Int>>
  ok   倒着走用 stride：99 项，99 → 1
  ok   stride(from:through:by:) 含 through 端点：[10, 8, 6, 4, 2, 0]
  ok   换成 to: 就不含端点：[10, 8, 6, 4, 2]
  ok   while 跑了 3 圈
  ok   条件一开始就假的 repeat-while 仍然跑了一整圈：1
  ok   内层 break 只退出内层：外层 3 圈 × 每圈 1 次 = 3
  ok   break outer 一次就跳出两层：1
```

四条要记住的事实：

- **`1...10` 跑 10 圈，`1..<10` 跑 9 圈**，`...` 含右端点、`..<` 不含。
  探针 r08 把这条也跑成了纯输出表。
- **书 5.8 说「（1...99）实际上是一个对象，它的类型为 Range」，类型名不对**：`1...99` 是
  `ClosedRange<Int>`，`1..<99` 才是 `Range<Int>`。两者的 `upperBound` 数值可以相同（`1..<99` 的
  `upperBound` 也是 99），区别在 `contains(99)`：前者 `true`、后者 `false`。
  「对象」这半句是对的——区间确实是能存进常量的值，可以 `contains`、`~=`、取 `lowerBound`。
- **`99...1` 在编译期一声不响，是运行期 fatal**。书 5.8 的原文是：
  > 有人可能会想到能不能通过 99...1 的方式来解决呢？如果你在 Playground 中尝试使用这种方法，
  > 则不会有任何的输出，因为前面的数字大于后面的数字，编译器会报错。

  「不会有任何的输出」这句**完全对**——探针 r01 的 stdout 就是空的（崩溃时缓冲都丢了）；
  但「编译器会报错」不成立：探针 e08（`99...1` 编译）零诊断、退出码 0。真实的现场是
  运行到那一行才 fatal：

  ```
  运行退出码 = 132
  stdout:
  （空）
  stderr:
  Swift/x86_64-apple-ios-simulator.swiftinterface:6167: Fatal error: Range requires lowerBound <= upperBound
  Child process terminated with signal 4: Illegal instruction
  ```

  这比「编译不过」危险得多：一个反向区间可以安静地活到线上。倒着走的合法写法有两种——
  `(1...5).reversed()`（本章主线用）和 `stride(from:through:by:)` / `stride(from:to:by:)`，
  后者含不含 `through`/`to` 端点的差别也被量了出来（`[10,8,6,4,2,0]` vs `[10,8,6,4,2]`）。
- **`reversed()` 返回的不是数组**，是 `ReversedCollection<ClosedRange<Int>>`——一个惰性视图。
  要当数组用得 `Array(...)`。同理 `prefix(2)`/`suffix(2)` 给的是切片（§22）。

`while` 与 `repeat-while` 的差别只有一句：后者**至少跑一圈**，即使条件一开始就假。
嵌套循环里的 `break` 只退最近一层，要一次退两层得给外层加标签（`outer: for … { … break outer }`）。

## 9) 斐波那契与 off-by-one（本书 5.9）

书 5.9 是全章最有教学价值的一段：函数先 `print(0)`、`print(1)`，再用
`for iteration in 0...n` 生成后续项，注释里说参数 `n` 代表「元素个数」。书自己发现了不对，
并给出修补：

> 因为在函数的开始就已经打印出了 0 和 1 两个元素，所以在循环体中我们一共要生成 n-2 个元素，
> 所以将 for 语句修改为 for iteration in 0...n-3 即可。注意 n-3 是因为循环从 0 开始。

本章把 `print` 换成返回数组，于是能直接数项数：

```
  ok   书 5.9 原版 until:5 实际给了 8 项（参数说的是 5 项）：[0, 1, 1, 2, 3, 5, 8, 13]
  ok   项数 = 开头 2 项 + 循环 (n+1) 圈 = n+3；数列本身没错，多的那三项照样是斐波那契数
  ok   until:20 出 23 项，最后三项：[6765, 10946, 17711]
  ok   修补成 0...n-3 之后 n 才真的等于项数：[0, 1, 1, 2, 3, 5, 8, 13]
  ok   修补版与「n 就是项数」的现代写法逐项相等：[0, 1, 1, 2, 3, 5, 8, 13]
  ok   修补版只在 n >= 3 时成立：n=4 出 4 项、n=3 出 3 项
  ok   把没用上的循环变量写成 _ 之后，圈数照样可查：20
```

- 原版的错**不是数列错**（多出来的三项仍然是正确的斐波那契数），是**项数**：开头 2 项 +
  循环 `n+1` 圈 = `n+3` 项。`until:5` 给 8 项、`until:20` 给 23 项，两条都量了。
- 书的修补算得对：`0...(n-3)` 跑 `n-2` 圈，加开头两项正好 `n`。本章把它写成
  `fibonacciBookPatched`，并逐项和现代写法（`for _ in 0..<n`，`n` 就是项数）比对，**完全相等**。
- 但修补留下了一个新坑：`0...(n-3)` 在 `n < 3` 时是**反向区间**，也就是 §8 那条 `99...1` 的病——
  编译期无声，运行期 fatal。探针 r09 的现场与 r01 逐字相同。所以「n=2 要两项」这个再正常不过的
  调用会把 App 当场打崩。这就是为什么现代写法要用**半开区间 + 每轮先 append**：它的边界是
  「圈数 = 项数」，不需要 `n-3` 这种心算。
- 书 5.9 还记了另一条警告：

  > 当前的 Swift 编译器还有一个警告：常量 iteration 从来没有使用过，可以考虑将其替换为下划线
  > 或者移除它（Immutable value 'iteration' was never used；consider replacing with '_' or removing it）

  六年过去，这条文本几乎没变（探针 e06 的原话：`warning: immutable value 'iteration' was never used;
  consider replacing with '_' or removing it`）。它不属于本章的六条判定（`warning` 不是 `error`），
  但主线示例的编译日志必须为空，所以这类警告同样只能进探针。
- 把没用上的循环变量写成 `_`，圈数照样可查——这是「我关心跑了几次，不关心是第几次」的标准写法，
  §3 的 2000 次抽样用的就是它。

## 10) 作用域：三层围墙（本书 6.7）

书 6.7 用苹果园打比：「如果把 `selectedSoundFileName` 的声明放在方法内部，那就等于在你自己家的
围墙里种了一棵苹果树，只有你能摘；放在方法外部（类内）则是围墙外，谁都能摘」。它讲的是
Xylophone 项目里那个「按哪个键都播同一个声音」的 bug。本章把比喻换成可断言的类：

```
  ok   先读到旧值：notePressed 返回 note7
  ok   任何方法都能改这个类属性：改完 = note7
  ok   playSound 开头强行赋值 → 按哪个键都是同一声音（书 6.7 的病）
  ok   参数版调用两次结果不同、外部无从篡改：播放 note1 / 播放 note3
  ok   内层同名常量不影响外层捕获：["outer-a", "outer-b", "outer-c"]
  ok   if 大括号内的常量出去就没了：见 probes/e16_scope_if.swift
```

三层作用域，逐层看清：

1. **函数体内**（局部）：`let localCopy = selectedSoundFileName` 只在 `notePressed` 里活着。
   书 6.7 演示的正是「把一个 `let` 声明在某个方法里，另一个方法看不见」——
   探针 e17 抄的就是那个下场：`error: cannot find 'selectedSoundFileName' in scope`。
2. **类内、方法外**（属性）：所有方法都能读、也能改。这就是 bug 的来源——`playSound()` 开头
   强行赋值一次，之后每次按键听到的都是同一个声音。书给的修法不是「大家别乱改」，而是
   **把值当参数传进去**（`playSound(soundFileName:)` + 一个不可变的 `soundFileNames` 数组）：
   调用两次结果不同，外部无从篡改。这一条是本章第一个「架构味」的结论，第 31 章的 MVC/MVVM 讨论
   会回到它。
3. **文件顶层**（全局）：整个文件都能碰。§21 的探针 s06 会看到 Swift 6 语言模式对这一层的
   可变全局状态动了手。

另外两条实测：

- **同名遮蔽只在内层有效**：`do { let shared = "inner" }` 那个常量出了大括号就不存在了，
  闭包捕获的仍是外层的 `shared`——所以 `nestedScopeDemo()` 三次都返回 `outer-*`。
- 书 5.8 末尾「在一个大括号中声明的常量或者变量，其生存的范围也就在这个大括号之内」这条，
  配合「想在分支外用它」的正确写法是**先声明、不赋初值**（`let newLine: String`，然后两个分支各
  赋值一次）——§5 的啤酒歌就是这么写的。反过来，在分支里 `let`、分支外读，报的是
  `cannot find 'newLine' in scope`（探针 e16），而且同一个文件里还会先收到一条
  `initialization of immutable value 'newLine' was never used` 的警告：编译器已经知道它活不出那对
  大括号了。

## 11) 错误捕获：do / catch / try（本书 6.4）

书 6.4 的核心实验是把音频文件名从 `note1.wav` 改成 `note1.mp3`，然后在 Xcode 的控制台读那条错误，
并告诉你「可以上 osstatus.com 查这个错误代码」。本章用同一个题材（AVAudioPlayer），把「三种接法」
一次跑齐：

```
catch-all: 文件格式不是 CoreAudio 认识的音频
按 case 抓: url 是 nil
  ok   两条 catch 都落进了预期的分支：2 条
  ok   try? 的结果是可选：nil
  ok   try! 的代价由探针承担：probes/r03_try_bang.swift 跑出来是 signal 4
  ok   AVFoundation 把 OSStatus 包进 NSError：domain = NSOSStatusErrorDomain
  ok   本机对不存在的文件给的 OSStatus = 2003334207
  ok   把 OSStatus 按大端拆成四个字符 = wht?，倒过来读是 ?thw（0x7768743f）
  ok   defer 跑在 return 之后：改局部变量留不进返回值 = ["body"]
  ok   多个 defer 是后写的先执行（栈不是队列），函数外的记录才看得见：["body", "defer-2", "defer-1"]
  ok   rethrows 把闭包抛的错误原样递出来：-1
```

- `do { try … } catch { … }` 是兜底 catch；`catch PlayerError.fileMissing(let name)` 是**按 case 抓并绑定**；
  `catch let e as PlayerError` 是按类型抓。三条分支都在，才能确定错误真的落进了预期的那一条。
- 自定义错误实现 `LocalizedError` 给出 `errorDescription` 之后，`error.localizedDescription`
  打出来的才是人话（「文件格式不是 CoreAudio 认识的音频」），否则就是一串带域和编号的 `NSError`。
- **`try?` 是第三条路**：不抛、把失败压成 `nil`，结果类型变成可选。书里只讲了 `try` 与 `try!`。
- **`try!` 的代价**由探针承担：`Fatal error: 'try!' expression unexpectedly raised an error: probe.E.bad`
  加信号 4（r03）。它等价于「我保证不抛」这句话，一旦不成立就是崩溃。
- 忘了写 `try` 的报错（探针 e15）值得记：`call can throw but is not marked with 'try'`，
  后面还跟三条 `note:` 提示你选哪条路（`try` / `try?` / 关掉传播）。
- **本机能给的错误信息只有 domain 与 code**。AVFoundation 把系统的 `OSStatus` 包进 `NSError`：
  domain 是 `NSOSStatusErrorDomain`，本机对「文件不存在」给的是 `2003334207`。
  把这数按大端拆成四个字节是 `w` `h` `t` `?`（`0x7768743f`，即 AudioToolbox 的 `'wht?'`）。
  本章不猜它的含义——「同一个整数换个字节序读出来是 `?thw`」这个形状本身就是想说的全部：
  所谓「查错误代码」，查的是这个 FourCC。
- **`defer` 跑在 `return` 之后**。所以「defer 里改局部变量」留不进返回值（第一条断言只看到
  `["body"]`）；要观察 defer 的效果，得改函数外面能看见的东西。多个 `defer` 是**后写的先执行**
  （栈，不是队列）：`["body", "defer-2", "defer-1"]`。它是 §24/§26 里配对的 `open`/`close`、
  `lock`/`unlock` 的惯用写法。
- **`rethrows`**：函数自己不抛，只在参数闭包抛的时候跟着抛。这样
  `withGuardedFile { 1 }` 不需要 `try`，而 `withGuardedFile { try something() }` 才需要。

## 12) 类与对象：蓝图与真车（本书 9.1、9.2、9.4）

书 9.1 的比喻：类是**蓝图**，按蓝图造出来的那辆真车是**对象**；蓝图里写三样东西——
属性（变量/常量）、动作（方法）、事件（特定时机自动执行的东西）。书 9.2 建了第一个 `Car`：

```swift
class Car {
    var colour = "Black"                 // 带默认值的属性，类型靠推断
    var numberOfSeats: Int = 5           // 显式写类型
    var typeOfCar: CarType = .coupe      // 自定义类型的属性
    var events: [String] = []            // 本章加的：让「动作」可断言
    static func wheelsPerCar() -> Int { return 4 }
    func drive() { events.append("汽车已经开动") }
}
```

（本章把书里的 `print` 换成往 `events` 里记账，因为「先跑父类再跑自己」这种顺序关系靠 print 顺序
断言不了——`print` 的输出要跨进程比，而记账可以在同一个数组上直接比较。）

```
  ok   不写任何 init，实例拿到的就是蓝图里的默认值：Black/5/coupe
  ok   static 方法挂在类上（Car.wheelsPerCar()），实例方法挂在对象上（myCar.drive()）
  ok   书 9.7 的 myCar.drive()：点操作符调用方法，方法里不需要传参数也没法不传 self
  ok   let myCar 之后仍能 myCar.colour = "Red"：现在读回 Red —— class 的 let 锁的是引用，不是内容
  ok   let secondCar = myCar 之后改 secondCar，myCar 一起变成 Blue
  ok   === 问的是「是不是同一辆车」：true（== 对 class 根本不存在，见探针 e24）
  ok   struct 赋值即拷贝：改 planB 之后 planA 还是 5、planB 是 7
  ok   struct 换成 let 常量之后连属性都改不了（探针 e25：cannot assign to property: 'p' is a 'let' constant），只能整体重新赋值：5
  ok   没有一行代码调用过 init，但它跑了：["init 被自动调用"] —— 这就是书 9.1 说的「事件」
```

这一节里最重要的一条是 **`let` 在 class 与 struct 上含义不同**：

- `let myCar = Car()` 之后 `myCar.colour = "Red"` 完全合法（书 9.5 就靠这个「返厂喷漆」写法），
  因为 `let` 锁的是**引用**——「指向哪辆车」不能换，「车里坐着谁」随便改。
- `let secondCar = myCar` 之后改 `secondCar.colour`，`myCar.colour` 一起变。赋的不是车，是遥控器。
- 判断「是不是同一辆车」只能问 `===`；`==` 对 class **根本不存在**（探针 e24：
  `binary operator '==' cannot be applied to two 'CarC' operands`）。同一行写法换成 struct 也一样报错，
  除非显式 `: Equatable` —— struct 不自动有 `==`，这是很多人对 Swift 的第一处意外。
- `struct SeatPlan` 赋值即拷贝：改 `planB` 不影响 `planA`。而 `let` 一个 struct 常量之后连它的属性
  都改不动（探针 e25：`cannot assign to property: 'p' is a 'let' constant`，
  而且 `note:` 直接给出修法 `change 'let' to 'var' to make it mutable`）。
  **class 的 `let` 能改属性、struct 的 `let` 不能**——同一行写法，两种命运，这就是值类型与引用类型的
  分界线。
- 「事件」在哪？在 `init`。`AutoEvent()` 没有任何一行代码调用过 `init`，它自己跑了
  （`eventLog == ["init 被自动调用"]`）。书 9.1 说「实例化时自动执行的就是事件」，到 9.5 才点破这件事，
  本章把它提前到 §12 并跑出来。

## 13) 枚举：给自己造一个数据类型（本书 9.3）

书 9.3 的问题是：`carType` 该用什么类型？写 `Int` 的 0/1/2 就得再配一份说明书，而「说明书」不会
被编译器检查。枚举给的是**一个新的数据类型 + 它全部合法的取值**：

```
  ok   type(of:) 报的就是自定义的类型名：CarType
  ok   同 case 才相等：.coupe == .coupe 为 true、.coupe == .sedan 为 false
  ok   switch 分派枚举：三个 case 全写出来才编译得过（漏一个的原话见探针 e20）：两厢轿车
  ok   书 9.4 那行 print(typeOfCar) 打的是 case 名本身：coupe
  ok   原始值：WindDirection.north.rawValue = N
  ok   用原始值反查会得到可选："S" → Optional(swift_language_basics.WindDirection.south)、"X" → nil
  ok   关联值在 case 里被解出来：rect(3×4) 面积 = 12.0
  ok   circle(diameter: 2) 面积 ≈ 3.1416（π 本身没法逐字节，用「与 π 相差不到 1e-4」来断言）
  ok   加了 : CaseIterable 之后 allCases 自动给全：[swift_language_basics.CarType.sedan, swift_language_basics.CarType.coupe, swift_language_basics.CarType.hatchback]
  ok   Int 的 0 和 1 能相加 —— 这就是「0 代表轿车」的代价：加出来的 1 谁也说不清是什么
  ok   无关联值的枚举直接进字符串插值就是 case 名（探针 r05 抄了原话）："coupe"
```

- `type(of:)` 报回来的是你自己造的类型名：`CarType`。这是「枚举是一个类型」最直白的证据。
- 枚举自动可比较（`==` 有，`===` 没有——它不是引用类型）。
- `switch` 分派枚举必须写全，少一个 case 编译不过（探针 e20 的 `switch must be exhaustive`
  加两条 `note: add missing case: '.coupe'` / `'.hatchback'`）。
  **新增一个 case 会让所有漏掉它的 switch 当场编译失败**——这正是书 9.3 说的「减少 Bug」的真实机制：
  不是编译器更聪明，是它逼着每个使用点都表态。
- 书 9.4 里 `print(myCar.typeOfCar)` 打的是 case 名本身（`coupe`）。这个行为今天仍然成立，
  探针 r05 抄了完整形状：无关联值的枚举打出来就是 case 名；带关联值的打成 `circle(3.0)`、
  `rect(w: 1.0, h: 2.0)`；而 `String(describing:)` 之外还有个细节——**直接进字符串插值和
  `print` 是一样的**，不会变成 `Optional(...)`。
- 书 9.3 的代码写的是 `case Coupe`（首字母大写），本章按风格指南用 `case coupe`。
  两者都编译得过（探针 e23 零诊断），但大小写是**真的当两回事**：`CarType.Coupe` 与 `CarType.coupe`
  不是同一个符号。书里那种写法不会报错，只是和 Swift 官方风格（case 小写开头）不一致。
- **原始值**（`enum WindDirection: String`）给每个 case 挂一个对外可见的值：`.north.rawValue == "N"`，
  反查 `WindDirection(rawValue: "X")` 给 `nil`——**外部数据进枚举必须走这条可失败的路**，
  这是 §10.7/§10.9 那种解析 JSON 的地方唯一安全的收口。
- **关联值**才是枚举和「一组常量」的真正区别：`case rect(width:height:)` 自己带数据，
  `switch` 里 `case .rect(let w, let h)` 就地解出来。
- `CaseIterable` 是 **Swift 4.1** 才有的（书出版时刚要赶上），加了它 `allCases` 自动给全，
  不用手写数组。注意打印出来带模块名前缀（`swift_language_basics.CarType.sedan`）——
  那前缀就是 `swiftc` 的 `-module-name`，第 27 章的运行时类名前缀是同一件事的另一面。
- 「Int 那套写法的代价」这条断言很朴素但值得留着：`0 + 1 == 1` 完全合法，
  而加出来的那个 `1` 是「轿车 + 双门」还是「数字 1」，谁也说不清。枚举不让它相加。

## 14) 类的初始化：生产线喷漆还是返厂喷漆（本书 9.5）

书 9.5 的比喻非常准：§12 那种 `Car()` 之后再 `myCar.colour = "Red"`，等于新车造好再返厂喷漆；
要的是「在生产线上装配的时候就是红色」——那就是自定义 `init`。

```
  ok   init 里只改了 colour：Red/5/coupe —— 没提到的属性仍然是默认值
  ok   属性不给默认值，就必须有一个 init 把它填满；填了就能用：Green
  ok   init(colour:) 里写 self.colour = colour 才是在改属性：Gray
  ok   带默认值的 init 参数 = 一个 init 顶三个：Black/Red/2
  ok   init? 成功时给可选：Optional("note1")
  ok   init? 里 return nil 就等于「这个对象造不出来」：nil
```

- `init(customerChosenColour:)` 里只改了一个属性，其余属性**仍然是默认值**：
  init 不要求你把所有属性都写一遍，只要求每个属性最终有值。
- 书 9.5 接下来说「回到 main.swift，此时编译器会报错：初始化方法丢失参数 customerChosenColour」。
  这条在 6.0.3 照样成立，原话（探针 e12）：
  `error: missing argument for parameter 'customerChosenColour' in call`，
  外加 `note: 'init(customerChosenColour:)' declared here` 把声明处指出来。
  **一旦类里写了 init，编译器就不再送你那个无参 init。**
- 再往回一步：属性既不给默认值、类里又没有 init，得到的是一个「造不出来」的类（探针 e13）：
  `error: class 'Car' has no initializers`，note 说的是真正的原因
  ——`stored property 'colour' without initial value prevents synthesized initializers`。
  这两条合起来是 Swift 初始化第一铁律的两种破法：**每个存储属性必须有初值，
  要么写在声明上，要么在 init 里填满。**
- `self.` 什么时候必须：参数与属性**同名**时。`init(colour: String) { self.colour = colour }`
  里不带 `self` 的是参数。书 9.6 的代码注释正是在说这件事。忘了写不静默（见 §16 的探针 e26）。
- **init 也可以有默认参数值**，于是「无参 / 只给颜色 / 颜色+座位」三种调用一个 init 就够。
  书 9.5 那会儿的写法要写两三个 init。
- **可失败构造器 `init?`**：`SoundFile(name: "")` 里 `return nil`，调用方拿到的是可选。
  书里没讲，但 iOS 上到处都是——`UIImage(named:)` 就是它，这也是为什么它返回 `UIImage?`。

## 15) Designated 与 Convenience（本书 9.6）

书 9.6 的动机：9.5 把 init 写成「必须给颜色」之后，连想实例化一辆标准车都得写颜色，太麻烦。
它给的解法是两类初始化方法，原文：

> 当我们使用 convenience 初始化方法的时候，首先要调用 Designated 初始化方法来实例化一个对象，
> 然后再去设置这个对象的 colour 属性。

下面就是书里的代码原样（`init()` 空体 + `convenience init(customerChosenColour:)`）：

```
  ok   书 9.6 的 console 输出（Black 5 Coupe / Gold 5 Coupe）在 6.0.3 一字不差：Black/Gold/coupe
  ok   convenience 只能「先委托、后改」：改的是已经造好的那辆车（两条原话见探针 e21、e14）
  ok   初始化方法的继承是「全有或全无」，不是逐个可用：结论见探针 r10 与 e22 的对照
```

- 书 9.6 声称控制台会打印 `Black 5 Coupe` 和 `Gold 5 Coupe`。在 6.0.3 上这段代码
  **一字不差地照样跑**（`Black/Gold/coupe`）——本章的第三条「书的代码仍然有效」的证据。
- 「先委托、后改」不是风格建议，是硬规则。两条破法各有专门的诊断：
  调换顺序（探针 e21）和干脆不写 `self.init()`（探针 e14）都报
  `'self' used before 'self.init' call or assignment to 'self'`，
  e14 还多一条 `'self.init' isn't called on all paths before returning from initializer`。
  读法：convenience 改的是**已经造好的那辆车**，所以在它存在之前你碰不了它。
- 反方向也拦：`designated` 里不许 `self.init()`（探针 e27：
  `designated initializer for 'Car2' cannot delegate (with 'self.init'); did you mean this to be
  a convenience initializer?`，note 直接把委托那一行指出来）。
  **能写 `self.init()` 的只有 convenience。**
- 书 9.8 说「Car 中的任何事情在 SelfDrivingCar 类中都可以有」，对初始化方法**只有一半成立**：
  探针 r10 量的是「子类不写任何 designated」→ 父类的无参 init、designated init、convenience init
  全都能用（`无参 = Black / 父类 designated = Red / 父类 convenience = Gold`）；
  探针 e22 量的是「子类一写自己的 designated」→ 父类的**全部消失**：
  `SelfDrivingCar()` 报 `missing argument for parameter 'where' in call`，
  `SelfDrivingCar(customerChosenColour: "Red")` 报
  `incorrect argument label in call (have 'customerChosenColour:', expected 'where:')`。
  一句话：**初始化方法的继承是全有或全无，不是逐个可用。** 想两者都有就显式写 `override init`。

## 16) 方法、方法里的 self 与属性观察器（本书 9.7）

书 9.7 的分辨法是一句提示：

> 在类外面定义的叫作函数，在类内部定义的函数则叫作方法。之前用于生成随机数的
> arc4random_uniform（）就是函数，因为它没有定义在任何的类中，因此不需要用点操作符来调用它。

这个区别在本章不是靠读，而是靠 `type(of:)` **量**出来：

```
  ok   同样的加法：函数不带点（topLevelAdd(2, 3)）、方法带点（calc.add(2, 3)）—— 都是 5 和 5
  ok   方法取出来就是普通函数：type(of: calc.add) = (Int, Int) -> Int
  ok   取出来的方法仍然绑在 calc 上：methodValue(4, 5) = 9
  ok   没绑定实例的方法类型是「先收一个 Calc」：(Calc) -> (Int, Int) -> Int —— 这就是「方法是绑了 self 的函数」的实证
  ok   方法可以直接改属性（class 里不用写 mutating）：memory = 9
  ok   static 方法挂在类上：Calc.className() = Calc
  ok   参数与属性同名时必须 self.colour：paintSelf("Red") 之后 = Red
  ok   名字不撞时不带 self 也一样改的是属性：paintOther("Green") 之后 = Green
  ok   init 里的第一次赋值不触发观察器：observeLog = []
  ok   willSet 读到的还是旧值、didSet 里的 oldValue 也是旧值：["willSet：3 → 4", "didSet：3 → 4"]
  ok   书 6.6 的「循环换声音」算的是余数：noteCount=10 → 第 4 个声音
  ok   改完 noteCount 立刻读到新的 7：计算属性不存在「忘了刷新」
```

- 函数不带点（`topLevelAdd(2, 3)`）、方法带点（`calc.add(2, 3)`）。
- **方法取出来就是一个普通函数**：`let methodValue = calc.add`，`type(of: methodValue)` 是
  `(Int, Int) -> Int`，而且它仍然绑在 `calc` 上（`methodValue(4, 5) == 9`）。
- 没绑定实例的方法（`Calc.add`）类型是 `(Calc) -> (Int, Int) -> Int`——**先收一个实例**。
  这就是「方法是绑了 self 的函数」的实证，也是第 15 章 target-action、第 27 章 ObjC 消息发送
  在 Swift 侧的类型学底子。
- `static` 方法挂在类上（`Calc.className()`），不接触实例；class 的方法里改自己的属性
  不需要写 `mutating`（struct 才需要——第 28 章已经量过那一条）。
- **`self.` 什么时候必须**：参数名与属性名撞了的时候。忘了写并不静默（探针 e26）：
  `error: cannot assign to value: 'colour' is a 'let' constant`，
  而且 note 直接给出修法：`add explicit 'self.' to refer to mutable property of 'ShadowedCar'`。
  注意它报的是「你正在改的那个参数是 let」——`colour = colour` 被解析成「参数赋值给自己」，
  连「assigning a variable to itself」这层意思都在这里。名字不撞时（`paintOther`）不带 `self`
  也一样改的是属性。
- **属性观察器**（`willSet`/`didSet`）书里没讲，但书 6.6「每次播放不同的声音」就是它的典型用途。
  三条实测：`init` 里的第一次赋值**不触发**观察器（那时对象还没造好）；`willSet` 里读到的还是
  旧值（新值在 `newValue`），`didSet` 里的旧值在 `oldValue`；所以 `["willSet：3 → 4", "didSet：3 → 4"]`
  这两条记录里，箭头两边一个是旧一个是新，位置不同含义也不同。
- **计算属性**（`var nextSound: Int { return noteCount % 7 + 1 }`）不占存储，每次读现算，
  所以永远和依赖的属性同步——这就是书 6.6 用「余数」换声音的写法在今天的形态。
  它和 `didSet` 的分工：需要「值变了顺手做件事」用 didSet；需要「永远和别的值保持一致」用计算属性。

## 17) 继承与重写（本书 9.8、9.9）

书 9.8 的继承用 `SelfDrivingCar : Car`，接着用动物族谱（Animal → Birds/Mammals → Humans）说明
「继承是 is-a 关系」。书 9.9 讲重写，原文：

> 如果只是使用 func 关键字，编译器则会报错……这意味着在父类 Car 中已经定义了 drive（）方法，
> 子类中要重写 drive（）方法则必须使用 override 关键字。
>
> 这样当我们调用 Fish 类的 breathe（）时，会先执行父类（Animals）的 breathe（）方法，
> 接着再执行自己在水中呼吸的代码。

两段话，第一段完全成立（探针 e11：`overriding declaration requires an 'override' keyword`），
第二段**有条件**——它成立的前提是那段代码里写了 `super.breathe()`。

```
  ok   子类一行属性都没写就有父类的三个属性：Black/5/coupe
  ok   destination 还是 nil → 可选绑定跳过第二行（书 9.10 的解法）：["汽车已经开动"]
  ok   这一次 drive() 加了两行（先 super.drive() 再自己的）：["汽车已经开动", "驾驶的目的地为：幸福巷4号"]
  ok   events 是存在对象上的，第二次 drive() 只追加不重置 → 攒成三行：["汽车已经开动", "汽车已经开动", "驾驶的目的地为：幸福巷4号"]
  ok   Humans 一路继承 Mammals 的属性、Animal 的方法，再在外面加自己的一份：["用肺呼吸", "人类还会说话"]
  ok   Birds 没重写 breathe，继承来的那份照用：["飞", "用肺呼吸"]
  ok   override 不等于「自动先跑父类」：不写 super 就完全没有父类那一行（书 9.9 的说法只适用于写了 super 的场合）：["用腮呼吸"]
  ok   参数写父类类型、实参给子类对象 → 调用落在子类的那份实现上（第 15 章 delegate 的机制根子就在这里）
  ok   is 问的是「是不是这个类型（或它的子类）」：zoo[0] is Birds = true、zoo[0] is Fish = false
  ok   子类对象必然是父类类型：zoo[2]（一个 Humans）is Mammals = true。静态类型已经保证的事不用运行时再问：zoo[2] is Animal 会收到一条 warning（探针 e29）
  ok   as? 给的是可选：转型失败就是 nil，不会崩（对比 §18 的强制拆包）
  ok   as? 失手时走 else，什么都不发生：拿到了 Fish（acts 还空着）
  ok   super.init() 之后才允许读继承来的 acts：从 幸福巷4号 出发，acts 还是 0 条
  ok   NeedsDest2 只有 init(to:)：无参 NeedsDest2() 已经是编译错误（见探针 e22）
```

- 子类一行属性都没写，就有父类的三个属性：继承是真的，不是需要转发的假继承。
- `super.drive()` 先跑父类那一份，然后接着跑自己写的部分。所以 `auto.events` 里
  「汽车已经开动」在前、「驾驶的目的地为：幸福巷4号」在后——**这正是书 9.10 结尾控制台上的那两行**
  （书里的原文输出是「汽车已经开动 / 驾驶的目的地为：幸福巷4号」）。
  一个容易漏的点：`events` 是存在对象上的，第二次 `drive()` **只追加不重置**，
  于是攒成三行。书里那种「看 print 输出」的判据不会告诉你这件事，因为它只看这一次运行。
- **不写 super 就没有父类那一份**：`Fish.breathe()` 只 append「用腮呼吸」，Animal 那条完全不出现。
  所以「override 会先执行父类」这句要修正成「**override + super 才会**」。这一条在 iOS 上很实际：
  `viewDidLoad` 忘了 `super.viewDidLoad()` 就是这个形状（书 9.9 恰好举了这个例子）。
- **多态**：参数写父类类型（`func makeItBreathe(_ a: Animal)`），实参给子类对象，调用落在
  子类的那份实现上。第 15 章 delegate 的机制根子就在这里——delegate 方法都是这么找到的。
- `is` 问「是不是这个类型（或它的子类）」，`as?` 给可选、失手不崩。两个反直觉点：
  `zoo[2] is Mammals` 合法且为真（子类对象必然是父类类型），但 `zoo[2] is Animal` 会收到
  一条警告 `'is' test is always true`（探针 e29）——**静态类型已经保证的事，运行时再问就是冗余**，
  而在本教程的判定下「有警告」等同失败，所以主线里不写它。
- **两阶段初始化**（书 9.5/9.6 没点名，但代码一直在遵守）：先填满自己的存储属性，再 `super.init()`，
  之后才允许碰继承来的属性。顺序颠倒的现场（探针 e28）：
  `error: property 'self.destination' not initialized at super.init call`。
  这条规则解释了为什么 iOS 代码里 `super.init` 总是站在 init 的中段而不是开头或末尾。

## 18) 可选：盒子、摇一摇，以及什么时候必须拆（本书 9.10）

书 9.10 是全书讲可选最清楚的一节，它的三步走是：`String` 不能直接收 nil（「编译器将会报错」）→
声明改成 `String?` → 想当 `String` 用就得拆包。它还给了崩溃现场的中文描述：

> 构建并运行项目，编译器会报错——发生致命错误：在拆包一个可选值的时候，意外发现 nil

以及一句要紧的判断：「编译器并不会检测它是否为 nil」。本章把这三步和两种安全写法全跑了一遍，
崩溃现场交给探针：

```
  ok   空字符串不是「没有值」："" 的 count = 0，它照样是一个 String（要收 nil 必须写 String?，探针 e09 就是硬闯的下场）
  ok   声明成 String? 之后可以不赋值：destination = nil
  ok   书 9.10 的 if destination != nil 写法：没有目的地，不出发
  ok   书 9.10 推荐的 if let 可选绑定：没有目的地，不出发
  ok   guard let 是同一件事的「早退出」写法：守卫：先返回，不带 nil 往下走
  ok   ?? 给的是「nil 时的替代值」，结果不再是可选：驾驶的目的地为：家
  ok   有值时 destination! 拿到的就是普通 String：驾驶的目的地为：幸福巷4号
  ok   判空 / if let / ?? 三种写法在有值时给出同一个结果：驾驶的目的地为：幸福巷4号
  ok   guard let 有值时走的是守卫之后的正常分支：守卫通过：幸福巷4号
  ok   「幸福巷4号」是 5 个字符：绑定成功走 if、失败走 else，两个出口都存在：5 / -1
  ok   可选链 a?.count 的结果本身又是可选：Optional(3)
  ok   在 nil 上调用方法不是崩溃，是整条链直接不执行：nil
  ok   String? 的真实类型是 Optional<String>：Optional<String>
  ok   IUO 当 String 用，不用写 !：直接读 .count = 15
  ok   但它仍然是可选，赋 nil 之后再用就是崩溃（探针 r02 的 fatal 原文）
```

- 探针 e09（`var destination: String = nil`）的原话值得背下来：
  `'nil' cannot initialize specified type 'String'`，note 是 `add '?' to form the optional type 'String?'`
  ——**编译器直接告诉你该改成什么**。
- 探针 r02（拆 nil 的 `destination!`）：`Fatal error: Unexpectedly found nil while unwrapping an
  Optional value` + 信号 4。与书中译法逐字对应，六年未变。
- **「没有值」和「空的值」是两件事**：`""` 的 `count` 是 0，它照样是一个 String；要能收 nil，
  类型必须写 `String?`。
- `String?` 的真实类型是 `Optional<String>`（`type(of:)` 直接给），`?` 只是语法糖。
- 四种拆法各有分工，本章全跑：`if destination != nil` 然后 `!`（书 9.10 的第一种，判空与取值分两步、
  编译器不帮你连着看）、`if let userSet = destination`（**可选绑定**，书 9.10 推荐的写法，
  绑定出来的常量只在 `if` 的大括号里活着——回指 §10）、`guard let … else { return }`
  （同件事的「早退出」写法，过了守卫之后变量在**整个函数剩余部分**有效）、
  `destination ?? "家"`（nil 时的替代值，结果不再是可选）。
  在有值的时候前三种给同一个结果；`guard` 那条走的是「守卫通过」分支。
- **可选链**：`maybeArray?.count` 的结果本身又是可选（`Optional(3)`），因为整条链可能断。
  而 `maybeArray?.append(9)` 在 nil 上调用**什么都不发生**，不崩、不报错——这条能解释很多
  「代码明明执行了却没效果」的现场。
- **IUO（`String!`）**：声明上是可选，用时自动拆。Interface Builder 拖出来的 `@IBOutlet` 就是这个
  类型，理由是真机上线前它一定被装配好；但它是**承诺不是保证**，赋 nil 之后再用 == 拆 nil 一样崩。
  这也是本项目第 21 章起反复说「outlet 尽量用 `weak` + 明确可选」的原因。

## 19) 闭包：把代码当值传来传去（本书 11.3）

书 11.3 的定义：「闭包实际上是一个匿名的函数……我们可以直接使用它的功能，并且将它作为参数或
返回值进行传递」。主线例子就是 `calculator(n1:n2:operation:)`，书里给了**五步简化**
（去参数类型 → 去返回值类型 → 去 `return` → 换 `$0/$1` → 把闭包挪出括号）。本章把六步
（多一步「去 `func` 和函数名」）逐项跑出来，并断言**六个结果全等于同一个 28**：

```
  ok   把函数当参数：calculator(n1: 3, n2: 6, operation: add) = 9
  ok   换一份实现就换一种算法：28
  ok   六步简化（去 func/名字、去 return、去参数类型、去返回值类型、换 $0/$1、闭包挪到括号外）逐项等价：28 28 28 28 28 28
  ok   $0 是第一个参数、$1 是第二个：4-7 = -3、7-4 = 3
  ok   两个闭包参数都写在括号里：42
  ok   同一次调用写成多重尾随闭包（书 4 的时代还没有这个语法）：42
  ok   map 生成新数组、不动原数组：[3, 6, 4, 8, 24, 55]，原数组还是 [2, 5, 3, 7, 23, 54]
  ok   链式：先筛 >5（[7, 23, 54]）、各乘 2、再求和 = 168
  ok   sorted 收的是「比较闭包」，返回新数组：[54, 23, 7, 5, 3, 2]
  ok   不传闭包的 sorted() 走 <：[2, 3, 5, 7, 23, 54]（原数组 array 仍然是 [2, 5, 3, 7, 23, 54]）
  ok   contains(where:) 收闭包、contains(_:) 收元素：找 7 → true、找 99 → false
  ok   compactMap 会把 nil 剔掉：[2, 54]
  ok   reduce(into:_:) 边走边改同一个累加器：<2><5><3><7><23><54>
  ok   写在初始化之后的两次调用都正常：applyTwice(5) = 10、doublerLater(9) = 18
  ok   闭包存进 let 之后它的类型就是函数类型：(Int) -> Int —— 与 §16 取出来的方法同一种东西
```

- `$0`/`$1` 不是「省字数的糖」，它是**按位置命名的参数**：`{ $0 - $1 }` 得 −3，
  `{ $1 - $0 }` 得 3。参数一多就用具名闭包，别数 `$2`。
- 书 11.3 那条「最后一个参数是闭包才能挪出括号」，在 **Swift 5.3**（书出版之后）放宽成
  **多重尾随闭包**：`withTwoClosures { 40 } then: { 2 }`——第一个闭包不带标签，后面的写成
  `label: { … }`。同一个调用的两种写法结果一样（42）。
- 但**「挪出去的闭包后面再补一个普通参数」今天依然不行**（探针 e31，一次报三条）：
  `expected ',' separator` / `extra argument 'then' in call` / `missing argument for parameter 'then' in call`。
  所以今天的准确说法还是「要挪出括号的必须是**收尾的那几个闭包参数**」。
- 书 11.3 结尾的 map 三连（`addOne` 函数 / 带名字的闭包 / `$0`）本章照跑，三份结果相等，
  并且**原数组不动**——`map` 生成新数组。这是 §12 值语义在容器上的复现。
- 集合上「收闭包」的方法，书里只讲了 `map`，本书后面几章（表格视图取数据、Core Data 转换）
  天天用到的是这一批：`filter`/`sorted(by:)`/`contains(where:)`/`compactMap`/`reduce`/`reduce(into:)`。
  两个细节：不传闭包的 `sorted()` 走 `<`；`reduce(into:_:)` 边走边改同一个累加器（拼字符串时
  比 `reduce` 少一堆中间副本）。
- **书 11.3 那条「一定要放到两个函数定义的后面」的叮嘱**，在 §4 已经证伪（对 `func` 名字不必要）。
  但换成「存在 `let` 里的闭包」它就是对的：`let doublerLater = { … }` 是**运行到那一行才初始化**的，
  函数名是编译期就存在的符号。提前调用会读到没填过的存储——探针 r13 的量法是直接 signal 11
  （退出码 139），连 `Fatal error` 都没有。主线里只留「先定义后调用」的正常路径
  （`applyTwice(5) == 10`、`doublerLater(9) == 18`）。
- 闭包存进 `let` 之后它的类型就是函数类型（`(Int) -> Int`）——与 §16 从实例上取下来的方法同一种东西。

## 20) 逃逸闭包、捕获，以及「完成后做什么」（本书 11.3 延伸 / 11.4.3）

书 11.4.3 问「什么是完成处理？」，它给的答案是 Bmob 的 `signUpInBackground { (isSuccessful, error) in … }`：
把「注册成功之后要做的事」当参数交出去，网络回来时再被调用。iOS 上到处都是这个形状
（`UIView.animate`、`URLSession` 的 completion、`CLLocationManager` 的异步回调）。这个形状在语言层
的名字就叫**逃逸闭包**：闭包要在函数返回**之后**才被调用，于是它「逃出」了这次调用。

```
  ok   入队不等于执行：此时 closureLog = []
  ok   闭包捕获的是变量本身，不是写下那一刻的值（两个闭包都跑在 step 已经变成 7 之后）：["入队时读的是变量当前的值：step=7", "第二个闭包：step=7"]
  ok   对象持有闭包、闭包又捕获对象 → 计数回不到 0，deinit 不跑：[] —— 这就是「循环引用」的直接后果
  ok   [weak self] 斩断环之后 deinit 正常跑：["释放 修复测试"]
  ok   for 的循环变量每轮独立：["i=0", "i=1", "i=2"]
  ok   while 的变量被三轮共享，跑的时候它已经是 3：["i=0", "i=1", "i=2", "j=3", "j=3", "j=3"]（同一件事的探针版记录在 t04）
```

- **入队 ≠ 执行**：`enqueue` 返回之后 `closureLog` 还是空数组。这就是「完成处理」和「直接调用」的区别。
- **闭包捕获的是变量本身，不是写下那一刻的值**：两个闭包都在 `step = 7` 之后才跑，
  所以连第一个闭包（写于 `step == 0` 时）读到的也是 7。这一条是很多异步 bug 的正解
  ——「我明明记得传进去的是旧值」：传进去的是**那个变量**。
- 非逃逸参数想存起来，编译期就拦（探针 e19：`assigning non-escaping parameter 'completion'
  to an @escaping closure`，note：`parameter 'completion' is implicitly non-escaping`）。
  默认值是**不逃逸**，这是安全的一侧：能少想一层生命周期。
- 逃逸闭包里引用成员**必须显式写 `self.`**（探针 r11：`reference to property 'tag' in closure
  requires explicit use of 'self' to make capture semantics explicit`，两条 note 分别给修法）。
  这不是洁癖：它逼着你在读代码时看见「这个闭包把宿主对象抓住了」。
- 抓住了会怎样？`KeyHolder` 持有闭包、闭包捕获 `self` → 计数回不到 0 → `deinit` 不跑，
  `holderLog` 是空数组；换成 `[weak self]` 之后同一份代码打印出 `["释放 修复测试"]`。
  这是全章最短的**循环引用**实验，也是第 24/25 章那些 delegate/Timer 章节反复回到的那个坑。
- **`for` 的循环变量每轮一个新变量，`while` 的是同一个**：三个闭包分别在 `for` 与 `while` 里造，
  跑完之后前者给出 `i=0/i=1/i=2`，后者给出三个 `j=3`。这条在 Swift 3 就修好了（书的时代刚好赶上），
  但它在今天的面试题库里仍然是「看谁背过」。

## 21) 编译器版本与语言模式：这本 Swift 4 的书在今天

本章开头说过「本机是 Swift 6.0.3」。这句话其实压缩了两件事，而它们各自有独立的宏：

```
  ok   #if compiler(>=6.0) 为 true、#if swift(>=6.0) 落在 5 分支：编译器是 6.0.3，语言模式默认还是 5 —— 两个宏问的不是同一件事
  ok   书里的 Swift 4 代码在 6.0.3 仍能按 swift(>=4.0) 的分支编译：true
  ok   今天写 bookString.count；书 5.x 时代的 bookString.characters.count 已经不可用：error: 'characters' is unavailable: Please use String directly（探针 e30 抄了全原文）
  ok   把语言模式切到 6 的唯一新增硬错误出现在「全局可变状态被非隔离函数改」这一条（探针 s06 的两模式对照）
```

- `#if compiler(>=6.0)` 问的是**编译器版本**，为真；`#if swift(>=6.0)` 问的是**语言模式**，
  落在 5 的分支。`run-all.sh` 不带 `-swift-version`，所以取 SDK 默认的 5。
  换句话说：6.0.3 的编译器**在用 Swift 5 的规则编译这份代码**。这就是这本书的代码今天还能原样跑的
  制度原因。`#if swift(>=4.0)` 也为真——语言模式是「按哪一版规则」，不是「不低于哪一版」。
- 一条真正的「Swift 4 → 5 断代」：`String.characters` 在 **5.0 被 obsoleted**。
  书 5.x 时代要数字符得写 `s.characters.count`，今天直接 `s.count`。硬用旧写法是编译错误
  （探针 e30 抄全原文，包括 `note: 'characters' was obsoleted in Swift 5.0`）。
- **把语言模式切到 6 会新增什么拦截**？同一份源码、只换 `-swift-version`，逐条对照（探针 s01~s07）：
  s01（不对称空格）、s02（未用的局部常量）、s03（顶层顺序）、s04（用了没初始化的变量）、
  s05（`let` 数组 append）——**两个模式的诊断逐字相同**；
  s07（闭包捕获 `self`）两个模式**都通过**；
  只有 s06 在 5 模式跑得好（打印 2）、6 模式编译不过：
  `error: main actor-isolated var 'counter' can not be mutated from a nonisolated context`，
  note 给出 `add '@MainActor' to make global function 'bump()' part of global actor 'MainActor'`。
  所以本章的结论很具体：**Swift 6 对本章内容唯一的破坏在「并发隔离」这一维**，
  它不管闭包怎么写，只管「这块代码在哪个 actor 上跑」。这句话是第 31 章之后所有
  `@MainActor`/`Task`/actor 讨论的入口。

本章所有「Swift 4 时代 vs 现在」的账，集中在这里：

| 节 | 书里的说法 | 6.0.3 上的实测 |
| --- | --- | --- |
| §2 | `= + - / *` 两侧都必须有空格 | 只有不对称的 `=` 有专门诊断；`+` 是被解析成两条语句 |
| §4/§19 | 调用必须写在函数定义之后 | 对 `func` 不成立（e04）；对 `let` 闭包成立且代价是 signal 11（r13） |
| §6 | 缺 return 报「missing return in a function…」 | 改成 `cannot convert return expression of type '()' to return type 'Int'`（e03） |
| §6 | 每个分支都得写 return | 单表达式函数可省（Swift 5.1） |
| §8 | `99...1` 编译器会报错 | 编译零诊断（e08），运行期 fatal + 信号 4（r01） |
| §8 | `1...99` 的类型是 Range | `ClosedRange<Int>`；`..<` 才是 `Range` |
| §9 | `0...n-3` 即可 | 项数确实等于 n，但 n<3 时是反向区间崩溃（r09） |
| §9 | 未用的 iteration 会警告 | 仍然警告，文本几乎没变（e06） |
| §13 | `case Coupe` | 大写也编译得过（e23），风格指南要小写 |
| §13 | （无） | `CaseIterable` 是 Swift 4.1 才有 |
| §15 | convenience 先委托后改 | 成立，而且违反时是两条专门的诊断（e14/e21/e27） |
| §17 | override 会先执行父类 | 只在写了 `super.` 时成立 |
| §18 | 强制拆 nil 会致命错误 | 原话与书中译法逐字对应（r02） |
| §19 | 五步简化 | 六步全部等价；另加多重尾随闭包（SE-0279，5.3）与 e31 的边界 |
| §21 | `s.characters.count` | 已 obsoleted，写 `s.count`（e30） |

## 22) 数组与字典：容器里的值和「取不到」这件事（本书 4.7 / 6.5 / 10.7.2）

书 4.7 用数组装图片名、6.5 用数组装声音名、10.7.2 用字典装 API 返回的 JSON。三种容器的
「取不到」各不相同：数组越界是**崩溃**，字典缺键是 **nil**，Set 只问在不在。

```
  ok   数组字面量就推出 [String]：count = 3、下标从 0 开始 note1
  ok   type(of:) 给的是 Array<String>（写 [String] 是它的简写）：Array<String>
  ok   append 尾加、insert(at:) 插队：["first", "note1", "note2", "note3", "note4"]
  ok   remove(at:) 按位置删，删完前面的自动补位：["first", "note2", "note3", "note4"]
  ok   切片 prefix/suffix 给出头尾（切片不是数组，要变回去就 Array(...)）：["first", "note2"] / ["note3", "note4"]
  ok   找位置返回可选：note3 在第 Optional(2) 个、nope 是 nil
  ok   第 6 章按下第 8 个键时播哪个声音：["note1", "note2", "note3", "note1", "note2", "note3", "note1"]
  ok   enumerated() 给 (位置, 元素) 一对：第一项是 first
  ok   map 把每个元素过一遍函数：["FIRST", "NOTE2", "NOTE3", "NOTE4"]
  ok   数组赋值即拷贝（§12 的 struct 语义在这儿）：names2 有 4 项、soundNames 还是 3 项
  ok   字典按键取值：weather["temp"] = Optional(21)
  ok   缺键不崩、给 nil（这就是 Int? 而不是 Int 的原因）：nil
  ok   所以读字典要带 ?? 兜底：-1
  ok   把值赋成 nil 是**删除这个键**，不是存一个 nil：现在剩 2 个键
  ok   keys 的顺序每个进程重新随机，所以要印就得先排序：["feelsLike", "humidity", "temp"]
  ok   values 同理：[20, 21, 63]
  ok   字典排序要先把 (key, value) 元组拿出来排：["feelsLike=20", "humidity=63", "temp=21"]
  ok   [Any: ...] 里取出来的值是 Any?，要先 as? 成具体字典再取键：Optional(21)
  ok   as? 收 Any 里的字符串：Optional("Hangzhou")
  ok   Set 自动去重：插两次 ios 之后还是 2 个元素
  ok   [ios, swift] 是它的子集：true
  ok   Set 要打就得先 sorted：["ios", "swift", "uikit"]
  ok   交集直接给出共同的元素：["ios"]
```

- `type(of:)` 给的是 `Array<String>`，`[String]` 是它的简写（同理 `Dictionary<String, Int>` 与
  `[String: Int]`）。这条在 §3 的类型推断之外再钉一次：**写下的类型名和被叫的类型名可以不同**。
- 数组的下标从 0、`append` 尾加、`insert(at:)` 插队、`remove(at:)` 按位置删且**后面自动补位**；
  `firstIndex(of:)` 给可选（找不到是 `nil`，不是 `-1`——和 `NSString` 的 `NSNotFound` 是两套习惯）。
- 书 6.5/6.6「按下第 8 个键播哪个声音」的算术就是**下标 + 余数**：
  `soundNames[$0 % soundNames.count]`。它和 §16 的 `nextSound`（`noteCount % 7 + 1`）是同一个式子，
  一个是数组版、一个是整数版。
- **数组赋值即拷贝**（`names2 += ["note5"]` 之后 `soundNames` 还是 3 项）——§12 的 struct 语义
  在容器上的复现。真机上的实现是「写时才复制」（COW），语义上等价于拷贝。
- **数组的「取不到」不是 nil，是崩溃**：`array[10]` 越界的现场是
  `Swift/ContiguousArrayBuffer.swift:675: Fatal error: Index out of range` + 信号 4（探针 r04）。
  所以「先判 `count` 再取」和「用 `firstIndex` 拿可选」不是防御性啰嗦，是两种崩溃路径的分岔口。
- **字典缺键给 nil，所以返回类型必须是 `Value?`**。三个连着的实测：`weather["pressure"] == nil`；
  读的时候要么 `?? -1` 兜底、要么 `if let`；**把值赋成 `nil` 是删除这个键**，不是「存了一个 nil」。
  最后这条是很多「字典里怎么少了一个键」悬案的答案。
- **`keys`/`values` 的顺序每个进程重新随机**（哈希种子每进程换）。本章所有字典/Set 的输出都先
  `sorted()` 才打印——这不是谨慎，是六条判定里「stdout 可复现」的直接要求。
  要按键排整个字典得先把 `(key, value)` 元组拿出来排（`weather.sorted { $0.key < $1.key }`）。
- **`[String: Any]` 是 JSON 的形状**（书 10.7.2/10.9 处理的就是它）：取出来的值是 `Any?`，
  要一层层 `as?` 才能往下走——`(api["main"] as? [String: Int])?["temp"]`。
  这一行把 §18 的可选链、`as?` 的可选、字典的可选三件事叠在一起，也正是下一章（31）讨论
  「数据怎么进 Model」时会被换成 `Codable` 的那段代码。
- `Set` 自动去重、只问成员关系；`isSubset`/`intersection` 这类集合代数在 iOS 上最常见的用处是
  权限集合与标签匹配。它同样没有稳定顺序，要打就 `Array(...).sorted()`。

## 23) 本章的边界：量到了什么、什么必须回 IDE

**量到了的**：22 节 209 条断言 + 55 个探针，覆盖本书 5.1~5.9、6.4、6.6、6.7、9.1~9.10、11.3、11.4.3
的全部语言层条目。凡是本节写「成立/不成立」的，都指着一行 stdout 或一条编译器原话。

**量不到、必须回 Xcode 或真机的**：

- **IDE 反馈本身**：Quick Help 面板怎么渲染 `///` 文档注释、报错的红色波浪线画在哪一列、
  Fix-It 气泡给哪几个候选修法。本章能给的只有诊断**文本**（`file:line:col: error:` 里其实已经带了
  行列号，画线的位置就是从这来的）。
- **Playground 的结果栏**：这本书的原始判据。它在命令行里没有对应物——这也是本章把判据整体换成
  断言的原因。
- **`@IBDesignable`/`@IBOutlet` 的实际装配**：可选一节讲了 IUO 是 outlet 的类型，但 outlet 什么时候
  被填、故事板里连线断了会怎样，那是第 31 章（故事板）的题，而且是 IDE 侧的题。
- **arm64 真机上的宽度类断言**：`MemoryLayout<Int>.size == 8` 这条在 x86_64 模拟器和 arm64 真机上
  都是 8（同为 LP64），但 `Float`/`Double` 的格式化输出、`String(format:)` 的舍入残差这类东西
  换架构仍可能漂——所以主线里凡是浮点都只用稳定位数或容差（§13 的 π 用「相差不到 1e-4」断言）。
- **Swift 6 的完整并发检查**：本章只测了「全局可变状态被非隔离函数改」这一条（s06）。
  `Sendable`、`actor`、`@MainActor` 的整座山不在本章范围，它们属于「异步与并发」那一章。
- **枚举打印里的模块名前缀**（`swift_language_basics.CarType.sedan`）取决于 `-module-name`，
  换工程名就变；本章把它写死，是因为本项目的所有示例都由 `run-all.sh` 统一给这个参数。
  断言里凡是依赖类型名 `CustomStringConvertible` 默认输出的，都属于这一类「工具链形状」。

---

## 探针记录

以下全部是**现跑现抄**的原文（`./probes/run.sh` 一次跑完 55 个，`./probes/w01_whitespace.sh` 跑 §2
那张表）。每条前面的绝对路径统一写成 `main.swift`（探针都得复制成 `main.swift` 才能带顶层语句），
`error:` / `warning:` / `Fatal error:` 之后的文本一字未改。崩溃类的都记了退出码与信号。

### 编译期诊断（e01~e32）

**`probes/e01_operator_spacing.swift`** — 操作符空格：`var monsterHealth =19`（`=` 左边有空格、右边没有）

实测：

```
--- 编译输出 ---
main.swift:2:19: error: '=' must have consistent whitespace on both sides
1 | import Foundation
2 | var monsterHealth =19
  |                   `- error: '=' must have consistent whitespace on both sides
3 | monsterHealth = monsterHealth+1
4 | print(monsterHealth)
编译退出码 = 1
```

**`probes/e02_missing_arg.swift`** — 调用 `getMilk()` 而声明是 `getMilk(howManyMilkCartons:)`——外部名不能省

实测：

```
--- 编译输出 ---
main.swift:3:9: error: missing argument for parameter 'howManyMilkCartons' in call
1 | import Foundation
2 | func getMilk(howManyMilkCartons: Int) { print(howManyMilkCartons) }
  |      `- note: 'getMilk(howManyMilkCartons:)' declared here
3 | getMilk()
  |         `- error: missing argument for parameter 'howManyMilkCartons' in call
4 | 
编译退出码 = 1
```

**`probes/e03_missing_return.swift`** — 声明了 `-> Int` 却一个 `return` 都没写（书 5.4 记的就是这条报错的旧文本）

实测：

```
--- 编译输出 ---
main.swift:3:5: error: cannot convert return expression of type '()' to return type 'Int'
1 | import Foundation
2 | func f(x: Int) -> Int {
3 |     print(x)
  |     `- error: cannot convert return expression of type '()' to return type 'Int'
4 | }
5 | 
编译退出码 = 1
```

**`probes/e04_use_before_define.swift`** — 在函数定义之前调用它（书 11.3 的叮嘱）。结果：**零诊断**，函数声明整个文件可见

实测：

```
--- 编译输出 ---（空）
（编译类探针：到此为止，不运行）
```

**`probes/e05_unused_let.swift`** — 顶层 `let priceToPay = 4 * 7` 从来没用过。结果：**零诊断**——顶层常量不告警，函数体内才告警（对照 s02）

实测：

```
--- 编译输出 ---（空）
（编译类探针：到此为止，不运行）
```

**`probes/e06_unused_loop_var.swift`** — 未使用的循环变量 `iteration`（书 5.9 记的那条警告）

实测：

```
--- 编译输出 ---
main.swift:3:5: warning: immutable value 'iteration' was never used; consider replacing with '_' or removing it
1 | import Foundation
2 | var acc = 0
3 | for iteration in 0...3 { acc += 1 }
  |     `- warning: immutable value 'iteration' was never used; consider replacing with '_' or removing it
4 | print(acc)
5 | 
（编译类探针：到此为止，不运行）
```

**`probes/e07_uint32_to_int.swift`** — `let nameScore: Int = arc4random_uniform(101)`——UInt32 不隐式转 Int（书 5.5）

实测：

```
--- 编译输出 ---
main.swift:2:22: error: cannot convert value of type 'UInt32' to specified type 'Int'
1 | import Foundation
2 | let nameScore: Int = arc4random_uniform(101)
  |                      `- error: cannot convert value of type 'UInt32' to specified type 'Int'
3 | print(nameScore)
4 | 
编译退出码 = 1
```

**`probes/e08_descending_range.swift`** — `for n in 99...1`（书 5.8 说「编译器会报错」）。结果：**零诊断**，崩溃现场见 r01

实测：

```
--- 编译输出 ---（空）
（编译类探针：到此为止，不运行）
```

**`probes/e09_nil_to_string.swift`** — `var destination: String = nil`——要收 nil 必须加 `?`（书 9.10）

实测：

```
--- 编译输出 ---
main.swift:2:27: error: 'nil' cannot initialize specified type 'String'
1 | import Foundation
2 | var destination: String = nil
  |                  |        `- error: 'nil' cannot initialize specified type 'String'
  |                  `- note: add '?' to form the optional type 'String?'
3 | print(destination)
4 | 
编译退出码 = 1
```

**`probes/e10_force_nil.swift`** — `destination!` 拆一个从没赋过值的可选。结果：**编译期无声**，崩溃现场见 r02

实测：

```
--- 编译输出 ---（空）
（编译类探针：到此为止，不运行）
```

**`probes/e11_missing_override.swift`** — 子类重写父类方法却没写 `override`（书 9.9）

实测：

```
--- 编译输出 ---
main.swift:3:34: error: overriding declaration requires an 'override' keyword
1 | import Foundation
2 | class Car { func drive() { print("开动") } }
  |                  `- note: overridden declaration is here
3 | class SelfDrivingCar: Car { func drive() { print("自动") } }
  |                                  `- error: overriding declaration requires an 'override' keyword
4 | print(SelfDrivingCar())
5 | 
编译退出码 = 1
```

**`probes/e12_designated_no_default.swift`** — 类里写了 `init(customerChosenColour:)` 之后调用 `Car()`（书 9.5 预言的那条）

实测：

```
--- 编译输出 ---
main.swift:6:17: error: missing argument for parameter 'customerChosenColour' in call
2 | class Car {
3 |     var colour = "Black"
4 |     init(customerChosenColour: String) { colour = customerChosenColour }
  |     `- note: 'init(customerChosenColour:)' declared here
5 | }
6 | let myCar = Car()
  |                 `- error: missing argument for parameter 'customerChosenColour' in call
7 | print(myCar.colour)
8 | 
编译退出码 = 1
```

**`probes/e13_property_no_value.swift`** — 存储属性既无默认值、类里又没有 init，于是没有可用的初始化方法

实测：

```
--- 编译输出 ---
main.swift:2:7: error: class 'Car' has no initializers
1 | import Foundation
2 | class Car {
  |       `- error: class 'Car' has no initializers
3 |     var colour: String
  |         `- note: stored property 'colour' without initial value prevents synthesized initializers
4 | }
5 | print(Car.self)
编译退出码 = 1
```

**`probes/e14_convenience_no_selfinit.swift`** — convenience 里**根本没写** `self.init()` 就去改属性

实测：

```
--- 编译输出 ---
main.swift:6:9: error: 'self' used before 'self.init' call or assignment to 'self'
 4 |     init() {}
 5 |     convenience init(c: String) {
 6 |         colour = c
   |         `- error: 'self' used before 'self.init' call or assignment to 'self'
 7 |     }
 8 | }

main.swift:7:5: error: 'self.init' isn't called on all paths before returning from initializer
 5 |     convenience init(c: String) {
 6 |         colour = c
 7 |     }
   |     `- error: 'self.init' isn't called on all paths before returning from initializer
 8 | }
 9 | print(Car(c: "Red").colour)
编译退出码 = 1
```

**`probes/e15_no_try.swift`** — 会抛的调用没写 `try`

实测：

```
--- 编译输出 ---
main.swift:4:6: error: call can throw but is not marked with 'try'
2 | enum E: Error { case bad }
3 | func risky() throws { throw E.bad }
4 | do { risky() } catch { print(error) }
  |      |- error: call can throw but is not marked with 'try'
  |      |- note: did you mean to use 'try'?
  |      |- note: did you mean to handle error as optional value?
  |      `- note: did you mean to disable error propagation?
5 | 
编译退出码 = 1
```

**`probes/e16_scope_if.swift`** — 在 `if` 的大括号里 `let newLine`，出了括号就读它（书 5.8 末尾那条作用域规则）

实测：

```
--- 编译输出 ---
main.swift:4:9: warning: initialization of immutable value 'newLine' was never used; consider replacing with assignment to '_' or removing it
2 | let n = 1
3 | if n == 1 {
4 |     let newLine = "a"
  |         `- warning: initialization of immutable value 'newLine' was never used; consider replacing with assignment to '_' or removing it
5 | }
6 | print(newLine)

main.swift:6:7: error: cannot find 'newLine' in scope
4 |     let newLine = "a"
5 | }
6 | print(newLine)
  |       `- error: cannot find 'newLine' in scope
7 | 
编译退出码 = 1
```

**`probes/e17_local_across_methods.swift`** — 一个方法里的局部常量，另一个方法想用（书 6.7 的围墙）

实测：

```
--- 编译输出 ---
main.swift:4:30: error: cannot find 'selectedSoundFileName' in scope
2 | class VC {
3 |     func notePressed() { let selectedSoundFileName = "note1"; print(selectedSoundFileName) }
4 |     func playSound() { print(selectedSoundFileName) }
  |                              `- error: cannot find 'selectedSoundFileName' in scope
5 | }
6 | print(VC().notePressed())
编译退出码 = 1
```

**`probes/e18_let_reassign.swift`** — 给 `let` 重新赋值

实测：

```
--- 编译输出 ---
main.swift:3:1: error: cannot assign to value: 'a' is a 'let' constant
1 | import Foundation
2 | let a = 1
  | `- note: change 'let' to 'var' to make it mutable
3 | a = 2
  | `- error: cannot assign to value: 'a' is a 'let' constant
4 | print(a)
5 | 
编译退出码 = 1
```

**`probes/e19_escaping.swift`** — 把非逃逸的闭包参数存进属性（不加 `@escaping`）

实测：

```
--- 编译输出 ---
main.swift:4:49: error: assigning non-escaping parameter 'completion' to an @escaping closure
2 | class Holder {
3 |     var stored: (() -> Void)?
4 |     func set(_ completion: () -> Void) { stored = completion }
  |                |                                `- error: assigning non-escaping parameter 'completion' to an @escaping closure
  |                `- note: parameter 'completion' is implicitly non-escaping
5 | }
6 | print(Holder().set {})
编译退出码 = 1
```

**`probes/e20_switch_not_exhaustive.swift`** — `switch` 枚举时漏写两个 case

实测：

```
--- 编译输出 ---
main.swift:4:1: error: switch must be exhaustive
2 | enum CarType { case sedan, coupe, hatchback }
3 | let t = CarType.coupe
4 | switch t {
  | |- error: switch must be exhaustive
  | |- note: add missing case: '.coupe'
  | `- note: add missing case: '.hatchback'
5 | case .sedan: print("s")
6 | }
编译退出码 = 1
```

**`probes/e21_convenience_before_selfinit.swift`** — convenience 里两行顺序颠倒：先改属性、后 `self.init()`

实测：

```
--- 编译输出 ---
main.swift:9:9: error: 'self' used before 'self.init' call or assignment to 'self'
 7 |     init() {}
 8 |     convenience init(customerChosenColour: String) {
 9 |         colour = customerChosenColour
   |         `- error: 'self' used before 'self.init' call or assignment to 'self'
10 |         self.init()
11 |     }
编译退出码 = 1
```

**`probes/e22_subclass_own_designated.swift`** — 子类写了自己的 designated 之后，去调父类的无参 init 和 convenience init

实测：

```
--- 编译输出 ---
main.swift:16:24: error: missing argument for parameter 'where' in call
12 | class SelfDrivingCar: Car {
13 |     var destination: String?
14 |     init(where: String) { destination = `where` }   // 子类自己的 designated
   |     `- note: 'init(where:)' declared here
15 | }
16 | let a = SelfDrivingCar()
   |                        `- error: missing argument for parameter 'where' in call
17 | let b = SelfDrivingCar(customerChosenColour: "Red")
18 | print(a.colour, b.colour)

main.swift:17:23: error: incorrect argument label in call (have 'customerChosenColour:', expected 'where:')
15 | }
16 | let a = SelfDrivingCar()
17 | let b = SelfDrivingCar(customerChosenColour: "Red")
   |                       `- error: incorrect argument label in call (have 'customerChosenColour:', expected 'where:')
18 | print(a.colour, b.colour)
19 | 
编译退出码 = 1
```

**`probes/e23_uppercase_case.swift`** — `case Coupe` 首字母大写（书 9.3 的写法）。结果：**零诊断**，大写也编译得过

实测：

```
--- 编译输出 ---（空）
（编译类探针：到此为止，不运行）
```

**`probes/e24_eq_on_class.swift`** — 对 class 实例、以及没声明 `Equatable` 的 struct 实例用 `==`

实测：

```
--- 编译输出 ---
main.swift:8:10: error: binary operator '==' cannot be applied to two 'CarC' operands
 6 | struct CarS { var colour = "Black" }
 7 | let c1 = CarC(); let c2 = CarC()
 8 | print(c1 == c2)
   |          `- error: binary operator '==' cannot be applied to two 'CarC' operands
 9 | let s1 = CarS(); let s2 = CarS()
10 | print(s1 == s2)

main.swift:10:10: error: binary operator '==' cannot be applied to two 'CarS' operands
 8 | print(c1 == c2)
 9 | let s1 = CarS(); let s2 = CarS()
10 | print(s1 == s2)
   |          `- error: binary operator '==' cannot be applied to two 'CarS' operands
11 | 
编译退出码 = 1
```

**`probes/e25_struct_let_property.swift`** — `let` 一个 struct 常量之后改它的属性

实测：

```
--- 编译输出 ---
main.swift:6:3: error: cannot assign to property: 'p' is a 'let' constant
3 | // class 的 let 实例可以改属性（§12 实测），struct 的 let 常量不行 —— 同一行写法，两种命运。
4 | struct SeatPlan { var numberOfSeats: Int = 5 }
5 | let p = SeatPlan()
  | `- note: change 'let' to 'var' to make it mutable
6 | p.numberOfSeats = 7
  |   `- error: cannot assign to property: 'p' is a 'let' constant
7 | print(p.numberOfSeats)
8 | 
编译退出码 = 1
```

**`probes/e26_missing_self_shadow.swift`** — 参数与属性同名时忘了 `self.`：`colour = colour`

实测：

```
--- 编译输出 ---
main.swift:7:33: error: cannot assign to value: 'colour' is a 'let' constant
 5 | class ShadowedCar {
 6 |     var colour = "Black"
 7 |     func setA(colour: String) { colour = colour }        // 忘了 self.：改的是参数自己
   |                                 |- error: cannot assign to value: 'colour' is a 'let' constant
   |                                 `- note: add explicit 'self.' to refer to mutable property of 'ShadowedCar'
 8 |     func setB(seats: Int) { var local = 0; local = local + seats; _ = local }
 9 |     func setC(colour2: String) { colour = colour2 }      // 名字不冲突，不带 self 也正确
编译退出码 = 1
```

**`probes/e27_designated_calls_designated.swift`** — designated init 里用 `self.init()` 委托

实测：

```
--- 编译输出 ---
main.swift:6:5: error: designated initializer for 'Car2' cannot delegate (with 'self.init'); did you mean this to be a convenience initializer?
 4 | class Car2 {
 5 |     var colour = "Black"
 6 |     init() {
   |     `- error: designated initializer for 'Car2' cannot delegate (with 'self.init'); did you mean this to be a convenience initializer?
 7 |         self.init(colour: "Red")
   |              `- note: delegation occurs here
 8 |     }
 9 |     init(colour: String) { self.colour = colour }
编译退出码 = 1
```

**`probes/e28_property_after_superinit.swift`** — 自己的存储属性填在 `super.init()` **之后**（两阶段初始化）

实测：

```
--- 编译输出 ---
main.swift:13:15: error: property 'self.destination' not initialized at super.init call
11 |     var destination: String
12 |     init(to: String) {
13 |         super.init()
   |               `- error: property 'self.destination' not initialized at super.init call
14 |         destination = to               // 错 1：自己的属性填在 super.init() 之后
15 |         print(colour)                  // 错 2：这行本身合法，只是用来说明「继承的属性要等到这之后」
编译退出码 = 1
```

**`probes/e29_is_always_true.swift`** — `zoo[0] is Animal`——静态类型已经保证的事又问一遍。结果是**警告**

实测：

```
--- 编译输出 ---
main.swift:7:14: warning: 'is' test is always true
5 | class Birds: Animal {}
6 | let zoo: [Animal] = [Birds()]
7 | print(zoo[0] is Animal)
  |              `- warning: 'is' test is always true
8 | print(zoo[0] is Birds)
9 | 
（编译类探针：到此为止，不运行）
```

**`probes/e30_string_characters.swift`** — `s.characters.count`（书 5.x 时代的写法）

实测：

```
--- 编译输出 ---
main.swift:6:9: error: 'characters' is unavailable: Please use String directly
4 | let s = "幸福巷4号"
5 | print(s.count)
6 | print(s.characters.count)
  |         `- error: 'characters' is unavailable: Please use String directly
7 | 

Swift.String:5:16: note: 'characters' was obsoleted in Swift 5.0
3 |     public typealias CharacterView = String
4 |     @available(swift, deprecated: 3.2, obsoleted: 5.0, message: "Please use String directly")
5 |     public var characters: String { get set }
  |                `- note: 'characters' was obsoleted in Swift 5.0
6 |     @available(swift, deprecated: 3.2, obsoleted: 5.0, message: "Please mutate the String directly")
7 |     public mutating func withMutableCharacters<R>(_ body: (inout String) -> R) -> R
编译退出码 = 1
```

**`probes/e31_argument_after_trailing.swift`** — 把闭包挪出括号之后，再在它后面补一个普通参数

实测：

```
--- 编译输出 ---
main.swift:6:31: error: expected ',' separator
4 | // 反过来问：闭包挪出去之后，还能在它后面补一个普通参数吗？
5 | func withClosureFirst(_ body: () -> Int, then label: String) -> String { return label + String(body()) }
6 | print(withClosureFirst { 42 } then: "答案 = ")
  |                               `- error: expected ',' separator
7 | 

main.swift:6:37: error: extra argument 'then' in call
4 | // 反过来问：闭包挪出去之后，还能在它后面补一个普通参数吗？
5 | func withClosureFirst(_ body: () -> Int, then label: String) -> String { return label + String(body()) }
6 | print(withClosureFirst { 42 } then: "答案 = ")
  |                                     `- error: extra argument 'then' in call
7 | 

main.swift:6:29: error: missing argument for parameter 'then' in call
3 | // 书 11.3：「如果函数的最后一个参数是闭包，则可以先删除参数名称，再把闭包移到括号外面」。
4 | // 反过来问：闭包挪出去之后，还能在它后面补一个普通参数吗？
5 | func withClosureFirst(_ body: () -> Int, then label: String) -> String { return label + String(body()) }
  |      `- note: 'withClosureFirst(_:then:)' declared here
6 | print(withClosureFirst { 42 } then: "答案 = ")
  |                             `- error: missing argument for parameter 'then' in call
7 | 
编译退出码 = 1
```

**`probes/e32_uncommented_prose.swift`** — 注释里那行中文去掉 `//`（书 5.1 说「编译器就会报错」）

实测：

```
--- 编译输出 ---
main.swift:6:1: error: cannot find '这是注释里的中文，去掉斜线之后编译器怎么看它' in scope
4 | // 去掉斜线之后并不是「注释符错了」这一条诊断，而是那行文字被当成代码去解析。
5 | // 下面这一行原样来自 §1 那段注释里的中文。
6 | 这是注释里的中文，去掉斜线之后编译器怎么看它
  | `- error: cannot find '这是注释里的中文，去掉斜线之后编译器怎么看它' in scope
7 | 
编译退出码 = 1
```

### 运行期现场（r01~r13）

**`probes/r01_desc_range.swift`** — `for n in 99...1` 的运行现场（对应 e08）：**stdout 完全为空**，与书 5.8 那句「不会有任何的输出」一致

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 132
stdout:

stderr:
Swift/x86_64-apple-ios-simulator.swiftinterface:6167: Fatal error: Range requires lowerBound <= upperBound
Child process terminated with signal 4: Illegal instruction
```

**`probes/r02_force_nil.swift`** — 拆一个从没赋值的 `String?`（书 9.10 的崩溃）

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 132
stdout:

stderr:
probe/main.swift:4: Fatal error: Unexpectedly found nil while unwrapping an Optional value
Child process terminated with signal 4: Illegal instruction
```

**`probes/r03_try_bang.swift`** — `try!` 一个真会抛的调用

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 132
stdout:

stderr:
probe/main.swift:5: Fatal error: 'try!' expression unexpectedly raised an error: probe.E.bad
Child process terminated with signal 4: Illegal instruction
```

**`probes/r04_index_oob.swift`** — 数组下标越界

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 132
stdout:

stderr:
Swift/ContiguousArrayBuffer.swift:675: Fatal error: Index out of range
Child process terminated with signal 4: Illegal instruction
```

**`probes/r05_enum_print.swift`** — 枚举的打印形状：无关联值 / 带关联值 / 进插值

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
coupe
coupe
circle(3.0)
inter=rect(w: 1.0, h: 2.0)
true
stderr:（空）
```

**`probes/r06_avplayer_missing.swift`** — AVAudioPlayer 打不到文件：NSError 的 domain/code、`catch` 与 `try?` 三种接法的输出

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
url = nil
catch: Error Domain=NSOSStatusErrorDomain Code=2003334207 "(null)"
catch: NSOSStatusErrorDomain code=2003334207
try? = nil
stderr:（空）
```

**`probes/r07_optional_interp.swift`** — 可选进字符串插值的形状（`nil` vs `Optional("hi")`）、`??`、可选链

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
s=nil t=Optional("hi")
直接插值 s=nil
?? 默认：无
字典取值：nil
Int("abc") = nil
Int("42") = Optional(42)
可选链 count = Optional(3)
nil 上调用方法之后 = nil
stderr:（空）
```

**`probes/r08_ranges.swift`** — 区间与循环的纯输出表：`1...10`/`1..<10`/`where`/`reversed`/`stride`/`Array(区间)`

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
1...10 =10  1..<10 =9  where 偶数 =[2, 4, 6, 8, 10]
reversed 前三个 =[5, 4, 3]  数组求和 =75
range.contains(50)=true   lower/upper=1/99  类型=ClosedRange<Int>
reversed 类型=ReversedCollection<ClosedRange<Int>>
stride = [10, 8, 6, 4, 2, 0]
Array(1...3) = [1, 2, 3]
stderr:（空）
```

**`probes/r09_fib_reverse_range.swift`** — 书 5.9 修补版 `0...(n-3)` 在 n=2 时的运行现场（与 r01 同一句话）

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 132
stdout:

stderr:
Swift/x86_64-apple-ios-simulator.swiftinterface:6167: Fatal error: Range requires lowerBound <= upperBound
Child process terminated with signal 4: Illegal instruction
```

**`probes/r10_convenience_init_inherited.swift`** — 子类不写任何 designated 时，父类的无参 / designated / convenience init 各能不能调

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
无参 = Black
父类 designated = Red
父类 convenience = Gold
stderr:（空）
```

**`probes/r11_self_in_escaping.swift`** — 逃逸闭包里不带 `self.` 地引用属性（非逃逸那份反而没事）

实测：

```
--- 编译输出 ---
main.swift:11:29: error: reference to property 'tag' in closure requires explicit use of 'self' to make capture semantics explicit
 9 |     func demo() {
10 |         setNonEscaping { print(tag) }
11 |         setEscaping { print(tag) }
   |                     |       |- error: reference to property 'tag' in closure requires explicit use of 'self' to make capture semantics explicit
   |                     |       `- note: reference 'self.' explicitly
   |                     `- note: capture 'self' explicitly to enable implicit 'self' in this closure
12 |     }
13 | }
编译退出码 = 1
```

**`probes/r13_closure_before_init.swift`** — `let` 里的闭包在它初始化之前就被调用——连 `Fatal error` 都没有，直接信号 11

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 139
stdout:

stderr:
Child process terminated with signal 11: Segmentation fault
```

### 语言模式对照（s01~s07：同一份源码，分别 -swift-version 5 与 6）

**`probes/s01_ws.swift`** — `h = h +2`（中缀两侧不对称）——两个模式逐字相同：报的是「两条语句」，不是空格规则

`swift-version 5` 下：

```
--- 编译输出 ---
main.swift:4:5: error: consecutive statements on a line must be separated by ';'
2 | var h = 19
3 | h = h+1
4 | h = h +2
  |     `- error: consecutive statements on a line must be separated by ';'
5 | print(h)
6 | 

main.swift:4:3: error: assigning a variable to itself
2 | var h = 19
3 | h = h+1
4 | h = h +2
  |   `- error: assigning a variable to itself
5 | print(h)
6 | 

main.swift:4:7: warning: result of operator '+' is unused
2 | var h = 19
3 | h = h+1
4 | h = h +2
  |       `- warning: result of operator '+' is unused
5 | print(h)
6 | 
编译退出码 = 1
```

`swift-version 6` 下：

```
--- 编译输出 ---
main.swift:4:5: error: consecutive statements on a line must be separated by ';'
2 | var h = 19
3 | h = h+1
4 | h = h +2
  |     `- error: consecutive statements on a line must be separated by ';'
5 | print(h)
6 | 

main.swift:4:3: error: assigning a variable to itself
2 | var h = 19
3 | h = h+1
4 | h = h +2
  |   `- error: assigning a variable to itself
5 | print(h)
6 | 

main.swift:4:7: warning: result of operator '+' is unused
2 | var h = 19
3 | h = h+1
4 | h = h +2
  |       `- warning: result of operator '+' is unused
5 | print(h)
6 | 
编译退出码 = 1
```

**`probes/s02_unused_local.swift`** — 函数体内未使用的局部常量——两个模式逐字相同

`swift-version 5` 下：

```
--- 编译输出 ---
main.swift:3:9: warning: initialization of immutable value 'priceToPay' was never used; consider replacing with assignment to '_' or removing it
1 | import Foundation
2 | func run() {
3 |     let priceToPay = 4 * 7
  |         `- warning: initialization of immutable value 'priceToPay' was never used; consider replacing with assignment to '_' or removing it
4 | }
5 | run()
--- 运行 ---
运行退出码 = 0
stdout:

stderr:（空）
```

`swift-version 6` 下：

```
--- 编译输出 ---
main.swift:3:9: warning: initialization of immutable value 'priceToPay' was never used; consider replacing with assignment to '_' or removing it
1 | import Foundation
2 | func run() {
3 |     let priceToPay = 4 * 7
  |         `- warning: initialization of immutable value 'priceToPay' was never used; consider replacing with assignment to '_' or removing it
4 | }
5 | run()
--- 运行 ---
运行退出码 = 0
stdout:

stderr:（空）
```

**`probes/s03_toplevel_order.swift`** — 顶层代码的顺序（定义之后再用）——两个模式都通过

`swift-version 5` 下：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
1
stderr:（空）
```

`swift-version 6` 下：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
1
stderr:（空）
```

**`probes/s04_used_before_init.swift`** — 读取还没初始化的 `var destination: String`——两个模式逐字相同

`swift-version 5` 下：

```
--- 编译输出 ---
main.swift:3:7: error: variable 'destination' used before being initialized
1 | import Foundation
2 | var destination: String
  |     `- note: variable defined here
3 | print(destination)
  |       `- error: variable 'destination' used before being initialized
4 | destination = "here"
5 | 
编译退出码 = 1
```

`swift-version 6` 下：

```
--- 编译输出 ---
main.swift:3:7: error: variable 'destination' used before being initialized
1 | import Foundation
2 | var destination: String
  |     `- note: variable defined here
3 | print(destination)
  |       `- error: variable 'destination' used before being initialized
4 | destination = "here"
5 | 
编译退出码 = 1
```

**`probes/s05_let_array_append.swift`** — `let` 数组 `append`——两个模式逐字相同

`swift-version 5` 下：

```
--- 编译输出 ---
main.swift:3:3: error: cannot use mutating member on immutable value: 'a' is a 'let' constant
1 | import Foundation
2 | let a = [1, 2, 3]
  | `- note: change 'let' to 'var' to make it mutable
3 | a.append(4)
  |   `- error: cannot use mutating member on immutable value: 'a' is a 'let' constant
4 | print(a.count)
5 | 
编译退出码 = 1
```

`swift-version 6` 下：

```
--- 编译输出 ---
main.swift:3:3: error: cannot use mutating member on immutable value: 'a' is a 'let' constant
1 | import Foundation
2 | let a = [1, 2, 3]
  | `- note: change 'let' to 'var' to make it mutable
3 | a.append(4)
  |   `- error: cannot use mutating member on immutable value: 'a' is a 'let' constant
4 | print(a.count)
5 | 
编译退出码 = 1
```

**`probes/s06_global_var_v6.swift`** — **全局可变状态被非隔离函数改**：5 模式跑得好（打印 2），6 模式编译不过——本章唯一一条 Swift 6 新增硬错

`swift-version 5` 下：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
2
stderr:（空）
```

`swift-version 6` 下：

```
--- 编译输出 ---
main.swift:3:15: error: main actor-isolated var 'counter' can not be mutated from a nonisolated context
1 | import Foundation
2 | var counter = 0
  |     `- note: mutation of this var is only permitted within the actor
3 | func bump() { counter += 1 }
  |      |        `- error: main actor-isolated var 'counter' can not be mutated from a nonisolated context
  |      `- note: add '@MainActor' to make global function 'bump()' part of global actor 'MainActor'
4 | bump(); bump()
5 | print(counter)
编译退出码 = 1
```

**`probes/s07_self_capture_v6.swift`** — 闭包捕获 `self`：两个模式**都通过**——「捕获」本身不是问题，跨 actor 才是

`swift-version 5` 下：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
captured
stderr:（空）
```

`swift-version 6` 下：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
captured
stderr:（空）
```

### 纯输出表（t01~t04）

**`probes/t01_toplevel_let.swift`** — 顶层 `let`/`var` 在定义之前读：不报错、不崩，读到零初始化；同文件里函数在定义之前调用正常

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
用之前 x=0 box=0
用之后 x=41 box=99
函数在定义之前调用 = 42
stderr:（空）
```

**`probes/t02_closure_shorthand.swift`** — 闭包六步简化的逐项输出（每一步都单独打印，全部 28）

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
9
28
28
28
28
28
28
28
-3
[3, 6, 4, 8, 24, 55]
[3, 6, 4, 8, 24, 55]
[3, 6, 4, 8, 24, 55]
168
[54, 23, 7, 5, 3, 2]
true
[2, 54]
<2><5><3><7><23><54>
stderr:（空）
```

**`probes/t03_semantics.swift`** — 赋值语义总表：class 共享、struct 拷贝、数组/字典拷贝、函数类型变量

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
两个独立实例：c1=Black c2=Red 同一对象=false
class 赋值给另一个常量：alias=Red —— 改 alias2 就是改 alias（同一对象：true）
class 的 let 实例可以改属性：describe=Gold
struct：s1=Black s2=Red 值相等=false
数组：arrA=[1, 2, 3] arrB=[1, 2, 3, 4] —— 赋值即拷贝（写时才复制）
字典：加一键之后 原 count=2 拷贝 count=1
函数类型变量：f1(1)=2，type(of:) = (Int) -> Int
stderr:（空）
```

**`probes/t04_closure_capture.swift`** — 捕获语义表：外部 var（跑的时候才读）/ for 每轮独立 / while 共享同一个

实测：

```
--- 编译输出 ---（空）
--- 运行 ---
运行退出码 = 0
stdout:
外部 var：写完才调 → ["读到 counter=0", "读到 counter=7"]
for 的循环变量：每轮一个独立的 i → ["i=0", "i=1", "i=2"]
while 的变量被三轮共享：三个闭包读同一个 j → ["j=3", "j=3", "j=3"]
stderr:（空）
```

---

## 本章能带走的东西

按「明天就会用到」排序：

1. **别用 `&&`/`||` 的右边做副作用**（§7）：短路不是优化建议，是真的不调用。边界值逐个打出来
   （81/80/41/40）比读代码可靠一个数量级。
2. **倒着走永远写 `.reversed()` 或 `stride(from:to:by:)`，不要写 `99...1`**（§8/§9）：后者编译期
   一声不响，运行期 fatal。书 5.9 的修补 `0...(n-3)` 就是这条的活教材——它在 `n < 3` 时崩。
3. **数值类型之间没有隐式转换**（§3）：`UInt32` → `Int` 必须 `Int(...)`；`Int("abc")` 给 `nil` 不给 0。
4. **`let` + class 能改属性，`let` + struct 连属性都改不动**（§12）：`let` 锁的是引用还是值，
   是选 class/struct 的第一判据。判断同一对象用 `===`；`==` 对 class 不存在，struct 要 `: Equatable`。
5. **新增枚举 case 会让所有漏它的 switch 编译失败**（§13）：这不是限制，是书 9.3 那句「减少 Bug」的
   全部机制。外部数据进枚举走 `init?(rawValue:)`。
6. **每个存储属性必须有初值，要么写在声明上、要么在 init 里填满**（§14）：破了报两条原话之一
   （`has no initializers` / `missing argument for parameter`）。
7. **convenience 必须先 `self.init()` 再改属性；designated 不许委托**（§15）：三条诊断把这条规则
   钉得死死的。想同时保留父类和子类的 init，得显式 `override init`——初始化继承是全有或全无。
8. **`override` 不等于「自动先跑父类」，`super.` 才是**（§17）：`viewDidLoad` 忘写 super 就是这个形状。
   两阶段初始化决定了 `super.init()` 只能站在「自己属性填满之后」的位置。
9. **方法就是绑了 self 的函数**（§16）：`type(of: obj.m)` 是 `(A, B) -> C`，
   `type(of: T.m)` 是 `(T) -> (A, B) -> C`。这句是理解 delegate、target-action、
   以及第 27 章 ObjC 消息转发的钥匙。
10. **可选链断了不崩，是整条链不执行**（§18/§22）：`x?.mutatingCall()` 静悄悄。判空之后要么 `if let`
    要么 `guard let`，`!` 只允许出现在「刚刚已经检查过」的后面。字典读值必带 `??` 或绑定。
11. **闭包捕获变量本身**（§19/§20）：异步回来读的是那一刻的值，不是写下闭包那一刻的值。
    默认不逃逸（要存就得 `@escaping`），逃逸闭包里 `self.` 必须显式——那是提醒你这里有一根引用。
12. **对象持有闭包、闭包捕获对象 = deinit 不跑**（§20）：`[weak self]` 斩环。
    这是 Timer/URLSession/通知中心那三处经典泄漏的同一张病理切片。
13. **字典/Set 要打印必先排序**（§22）：哈希顺序每进程重新随机。数组拷贝是语义、COW 是实现。
14. **`#if swift` 问语言模式，`#if compiler` 问编译器版本**（§21）：本机 6.0.3 编译器 + 默认 5 模式，
    所以这本 Swift 4 的书能原样跑。要迁移看的是 `-swift-version 6` 会新增哪几条诊断，
    本章量到的那一条是全局可变状态的 actor 隔离。

下一章（31）回到本书真正的主题——**界面与架构**：故事板与 XIB 在 headless 下能量到哪一步
（`ibtool` 编译、segue 的触发、`@IBOutlet` 装配时机），以及 MVC/MVVM、单例、依赖注入与回调三种形态
如何在本章这套语言设施上落地。本章那些「类是蓝图」「let 锁引用」「闭包捕获变量」的账，
到那里会变成「视图控制器之间怎么传数据」的全部依据。
