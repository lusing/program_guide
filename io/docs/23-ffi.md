# 23 · 外部函数接口

> 对应示例：[`examples/23_ffi/23_ffi.io`](../examples/23_ffi/23_ffi.io)
>
> 本章部分是**实测的能力边界**。Io 的 FFI（`DynLib`）在本机构建里只有**整数**这一档：
> libm 的 `pow(2, 10)` 拿回来的不是 `1024`（23.4），`Pointer` / `CString` / `Buffer`
> 和 `CFunction setArgumentTypes` / `setReturnType` **一个都不存在**（23.7），
> `Sandbox` 的两个限额是空设（23.8）。
> 23.4 / 23.8 里有两段标了「离线实测原文」的输出——它们**不在示例 stdout 里**
> （会挂住，或含不确定内容），是为文档单独抓的。
> 想要 `2^10 == 1024` 只有一条路：自己写整数签名的 C 函数、`cc -dynamiclib` 编出来，
> 那就是 23.5，而且它是**示例里真的跑通了**的。

## 23.1 DynLib 的四个动作：setPath / open / isOpen / close

一句话：`DynLib` 就是 `dlopen` / `dlsym` 的一层薄壳，生命周期是 `setPath → open → call… → close`，而**克隆不继承句柄**。

实测输出：

```text
-- 23.1 DynLib 的四个动作：setPath / open / isOpen / close
DynLib 的槽 = call, callPluginInit, close, freeFuncName, init, initFuncName, isOpen, open, path, setFreeFuncName, setInitFuncName, setPath, voidCall
setPath 返回 self，path 能原样读回来 = /usr/lib/libSystem.B.dylib
open 之前的 isOpen = false
open 之后的 isOpen = true
新克隆的 isOpen = false
close 之后的 isOpen = false
File 看得到 /usr/lib/libSystem.B.dylib 吗 = false
但它能被 dlopen = true
```

标准库那边只有 7 行（`libs/iovm/io/DynLib.io`），做的事只是给每个克隆挂一个 `forward`：

```io
DynLib do(
	init := method(
		self forward := method(
			self performWithArgList("call", list(call message name, call message arguments map(x, self doMessage(x))) flatten)
		)
	)
)
```

真正的实现在 C 里（`libs/iovm/source/IoDynLib.c`），方法表就是上面那 13 个槽。日常只要四个：

```io
d := DynLib clone setPath("/usr/lib/libSystem.B.dylib")
d path          // 只是记下路径，不加载
d isOpen        // false
d open          // 真的 dlopen；失败会 raise
d isOpen        // true
d close         // dlclose
```

两个容易忽略的细节，示例里都断言了：

```io
chk("setPath 只是记路径，不加载", d path, "/usr/lib/libSystem.B.dylib")
chk("clone 不继承已打开的句柄", (DynLib clone) isOpen, false)
```

`IoDynLib_rawClone` 的注释把第二条写死了：*"a clone will NOT inherit its parent's dynamically loaded object"*——`DynLib clone` 拿到的是一把**新钥匙**，得自己 `open`。

> **为什么重要**：`File with("/usr/lib/libSystem.B.dylib") exists` 在现代 macOS 上是
> **`false`**——系统库被收进了 dyld 共享缓存，文件系统里根本没有这个文件，但
> `dlopen` 照样成功。**别用 `exists` 去预判 dlopen 能不能行**，唯一可靠的判据是
> `try(... open)` 有没有抛。

## 23.2 能过的：整数签名的 C 函数

一句话：只要 C 函数的参数和返回值都是整数（或 `char*` 进不出），`DynLib call` 就可靠且确定。

实测输出：

```text
-- 23.2 能过的：整数签名的 C 函数
abs(-5) = 5
labs(-7) = 7
strlen("hello") = 5
toupper(97) = 65
atoi("42") = 42
atoi("-13") = -13
```

```io
d := DynLib clone setPath("/usr/lib/libSystem.B.dylib")
d open
d call("abs", -5)          // 5
d call("labs", -7)         // 7
d call("strlen", "hello")  // 5，Io 字符串直接当 char* 传
d call("toupper", 97)      // 65
d call("atoi", "42")       // 42
chk("能配合算数：atoi(\"42\") + atoi(\"8\")", d call("atoi", "42") + d call("atoi", "8"), 50)
```

`call(名字, 参数…)` 的编组规则（`IoDynLib.c`）：

| Io 侧 | C 侧 |
|---|---|
| `Number` | `intptr_t`（`IoNumber_asInt`，会截断成整数） |
| `Symbol` / 字符串 | `char *`（`CSTRING`） |
| `List` | `intptr_t *`（逐个递归编组） |
| `Buffer` | 原始字节指针 |
| `Block` | 一段小小的蹦床代码（`bouncer`），只在 x86-64 上写好了 |

回来的时候：`Number` → `IONUMBER(intptr_t)`，`Symbol` → `IOSYMBOL((char *)n)`，`List` 就地原地改。

> **为什么重要**：`Number` 在 Io 里**只有一种**（第 03 章），内部是 C 的 `double`。
> 一旦跨过 FFI 边界，它就被压成 `intptr_t` 了 —— 这是本章所有怪现象的同一个根因。

## 23.3 forward：把 DynLib 当函数库用

一句话：`forward` 让 `d abs(-9)` 等价于 `d call("abs", -9)`，代价是**拼错名字不再报「不响应消息」**。

实测输出：

```text
-- 23.3 forward：把 DynLib 当函数库用
方法式写法 d abs(-9) = 9
和 d call("abs", -9) 等价 = 9
d strlen("hi") = 2
方法式调用打错名字 = Error resolving call 'no_such_fn_qq'.
```

```io
d abs(-9)          // 9
d strlen("hi")     // 2
try(d no_such_fn_qq(1)) error   // "Error resolving call 'no_such_fn_qq'."
```

`forward` 的改写规则就是 `DynLib.io` 里那一行：

```io
self performWithArgList("call", list(call message name, call message arguments map(x, self doMessage(x))) flatten)
```

即：把消息名当成符号名，把消息实参求值后原样交给 `call`。

> **为什么重要**：`forward` 把 Io 的静态拼写错误变成了**运行期符号解析**。
> 写库调用时优先用显式的 `d call("名字", …)`：名字是字符串常量，一眼能看出
> 它是外部符号，而不是某个记错的本地槽。

## 23.4 过不去的：浮点签名 —— libm 的 pow(2, 10) 不是 1024

一句话：**浮点返回值的 C 函数，用 `DynLib` 调不出来**；`pow(2, 10)` 拿到的不是 `1024`。

实测输出：

```text
-- 23.4 过不去的：浮点签名 —— libm 的 pow(2, 10) 不是 1024
libm 打开了 = true
pow(2, 10) 等于 1024 吗 = false
sqrt(4.0) 等于 2 吗 = false
返回对象仍然是 Number（所以类型系统看不出来） = Number
同一个库里 labs(-7) 照样对 = 7
```

```io
m := DynLib clone setPath("/usr/lib/libm.dylib")
m open
m call("pow", 2, 10) == 1024   // false
m call("sqrt", 4.0) == 2       // false
(m call("pow", 2, 10)) type    // "Number" —— 类型系统一声不吭
m call("labs", -7)             // 7    —— 同一个库里的整数函数照常
```

**离线实测原文**（同一个脚本连跑三次，`gtimeout 10`）：

```text
=== 第 1 次
strlen(hello) = 5
pow(2,10)     = 128
sqrt(4.0)     = 619958784
=== 第 2 次
strlen(hello) = 5
pow(2,10)     = -1878456768
sqrt(4.0)     = 619958784
=== 第 3 次
strlen(hello) = 5
pow(2,10)     = -1869594008
sqrt(4.0)     = 619958784
```

注意 `pow` 那三个值**每次都不一样**：它是整数寄存器里前一次运算的残留，
取决于在它之前跑过什么。所以示例里**只打布尔结论，绝不打这个数**。

原因在源码里，三行看完：

```c
/* marshal（参数出去） */
if (ISNUMBER(arg)) { n = IoNumber_asInt(arg); }          // double → intptr_t，截断

/* demarshal（返回值回来） */
if (ISNUMBER(arg)) { return IONUMBER(n); }               // n 就是 intptr_t

/* IoDynLib_justCall（真的调用） */
rc = ((intptr_t(*)(intptr_t,...))f)(params[0], ...);     // 返回值只从整数寄存器取
```

`pow` 把 `1024.0` 放在 `xmm0` 里返回，而 Io 按 `intptr_t (*)(...)` 去取**整数寄存器**——
两边根本不在同一个寄存器上，取到的只是一段垃圾。`sqrt(2.0)` 那三次都返回 `619958784`，
看起来"稳定"，但那是同一个脚本里同一段残留，换个上下文就变。

顺带一个旁证：`IoDynLib_proto` 的方法表里 `{"returnsString", IoDynLib_returnsString}` 是**被注释掉的**——
字符串返回值这条路在这一版里也没接。

> **为什么重要**：这是一条"宁可不支持，也不要静默给错值"的反面教材。Io 既没有
> 报错，也没有把类型标成别的什么，而是**安静地返回一个 `Number`**。跨语言边界时，
> "类型对不上"远比"值算错"好排查——这也是 23.5 选择"自己封一层整数接口"的理由。

## 23.5 真能拿到 1024 的路子：自己编一个整数签名的 C 库

一句话：FFI 的契约既然只认整数，就让 C 侧配合——自己写整数签名的函数、`cc -dynamiclib` 编出来、`DynLib` 再调。

实测输出：

```text
-- 23.5 真能拿到 1024 的路子：自己编一个整数签名的 C 库
cc 的退出码 = 0
源文件字节数 = 227
自建库 isOpen = true
ch23_ipow(2, 10) = 1024
ch23_ipow(3, 4) = 81
ch23_ipow(-2, 3) = -8
ch23_checksum("abc") = 96354
收工后 isOpen = false
```

示例**在运行期真的把 C 代码写出来、真的编译、真的加载**：

```io
shimLines := list(
    "long ch23_ipow(long base, long exp) {",
    "    long r = 1;",
    "    while (exp-- > 0) r *= base;",
    "    return r;",
    "}",
    "long ch23_checksum(const char *s) {",
    "    long h = 0;",
    "    while (*s) { h = h * 31 + (unsigned char)*s; s++; }",
    "    return h;",
    "}",
    ""
)
srcPath := Path with(System getEnvironmentVariable("TMPDIR"), "io_ch23_shim.c")
libPath := Path with(System getEnvironmentVariable("TMPDIR"), "io_ch23_shim.dylib")
srcFile := File with(srcPath)
srcFile remove
srcFile setContents(shimLines join("\n") asUTF8)   // asUTF8：内部表示 ≠ 文件字节
build := System runCommand("/usr/bin/cc -dynamiclib -o " .. libPath .. " " .. srcPath)
buildOk := (build exitStatus == 0) and (File with(libPath) exists)
```

装载和调用，跟调系统库一模一样：

```io
lib := DynLib clone setPath(libPath)
lib open
chk("自建整数函数：2^10 就是 1024", lib call("ch23_ipow", 2, 10), 1024)
chk("负数也准（说明是完整 64 位在传）", lib call("ch23_ipow", -2, 3), -8)
chk("char* 参数也能传", lib call("ch23_checksum", "abc"), 96354)
lib close
```

三个要点：

- **签名用 `long` 而不是 `int`**：macOS 64 位下 `long` 就是 `intptr_t`，和 Io 的编组宽度对齐；用 `int` 会在高 32 位上留下垃圾。
- **整个流程要能降级**：`cc` 不存在或沙箱禁写时，`buildOk` 为假，示例打印一行跳过说明而不是抛异常。这样在没有编译器的机器上，示例仍然退出 0、两遍输出仍然逐字节一致。
- **收工清理**：`lib close` 之后 `File with(libPath) remove` + `srcFile remove`，不留垃圾在 `TMPDIR`。

> **为什么重要**：这正是现实中给 Io 接 C 库的方式——**不要指望 FFI 帮你转换类型，
> 而是让 C 侧暴露一个 Io 用得起的窄接口**（整数进、整数出、`char*` 当字符串）。
> 需要浮点时，让 C 侧返回"放大过的整数"（比如乘 1e6），回来再除。

## 23.6 错误路径：把异常消息原文抄下来

一句话：`DynLib` 的四种失败都有确定的错误文本，抄下来就能当断言目标。

实测输出：

```text
-- 23.6 错误路径：把异常消息原文抄下来
没 open 就 call = Error resolving call 'abs'.
符号不存在 = Error resolving call 'no_such_symbol_xyz'.
参数超过 8 个 = Error, too many arguments (9) to call 'abs'.
库文件不存在 = Error loading object '/no/such/libch23_nope.dylib': 'dlopen(/no/such/libch23_nope.dylib, 0x000A): tried: '/no/such/libch23_nope.dylib' (no such file), '/System/Volumes/Preboot/Cryptexes/OS/no/such/libch23_nope.dylib' (no such file), '/no/such/libch23_nope.dylib' (no such file)'
dlopen 一个文本文件 = Error loading object '/etc/hosts': 'dlopen(/etc/hosts, 0x000A): tried: '/etc/hosts' (not a mach-o file), '/System/Volumes/Preboot/Cryptexes/OS/etc/hosts' (no such file), '/etc/hosts' (not a mach-o file), '/private/etc/hosts' (not a mach-o file), '/System/Volumes/Preboot/Cryptexes/OS/private/etc/hosts' (no such file), '/private/etc/hosts' (not a mach-o file)'
```

```io
u := DynLib clone setPath("/usr/lib/libSystem.B.dylib")
(try(u call("abs", -5))) error                     // 还没 open
u open
(try(u call("no_such_symbol_xyz", 1))) error       // 符号不存在
(try(u call("abs", 1,2,3,4,5,6,7,8,9))) error      // 9 个参数，超限
(try(DynLib clone setPath("/no/such/libch23_nope.dylib") open)) error
(try(DynLib clone setPath("/etc/hosts") open)) error
```

三条从源码里读出来的顺序/上限：

```c
/* IoDynLib_justCall：先解析符号，再查参数个数 */
void *f = DynLib_pointerForSymbolName_(DATA(self), CSTRING(callName));
if (f == NULL)      IoState_error_(IOSTATE, m, "Error resolving call '%s'.", ...);
if (IoMessage_argCount(m) > 9)   IoState_error_(IOSTATE, m,
                        "Error, too many arguments (%i) to call '%s'.", ...);

/* IoDynLib_open：dlopen 失败就把动态链接器自己的诊断原样带出来 */
IoState_error_(IOSTATE, m, "Error loading object '%s': '%s'",
               DynLib_path(DATA(self)), DynLib_error(DATA(self)));
```

- 参数硬上限是 **8 个**（`argCount > 9` 判的是"消息名 + 8 个参数"）。
- **符号解析排在参数个数检查之前**——所以库已 `close` 之后再传 9 个参数，报的仍然是"解析不到符号"。
- `DynLib_error` 就是 `dlerror()` 的原文，包含 `dlopen(path, 0x000A)` 和它试过的每一个路径，因此在同一台机器上是**逐字节确定**的。

> **为什么重要**：错误消息是 `dlopen` 唯一诚实的"能力清单"。写平台相关的 FFI 代码时，
> 先把这个平台的失败原文抄进测试，比读文档靠谱——文档会过时，`dlerror()` 不会。

## 23.7 CFunction 与缺失的编组设施

一句话：C 实现的槽是 `CFunction`（带接收者类型，**不能脱离原接收者保存**），而这一版构建里没有 `Pointer` / `CString` / `Buffer`，也没有 `setArgumentTypes` / `setReturnType`。

实测输出：

```text
-- 23.7 CFunction 与缺失的编组设施
用户方法的 type = Block
原始槽 size 的 type = CFunction
原始槽 size 的 name = List_size()
原始槽 size 的 uniqueName = size
原始槽 size 的 typeName = List
CFunction 自己一个槽都没有 = list()
typeName 只有 CFunction 有，Number 上没有 = false
CFunction 上有 setArgumentTypes = false
CFunction 上有 setReturnType = false
DynLib 上有 setArgumentTypes = false
Lobby 上有 Pointer / CString / Buffer = list(false, false, false)
把 List_size() 存进槽再引用 = CFunction defined for type List but called on type Object
```

`CFunction` 的元信息很齐，但都是**只读的观测口**，不是配置口：

```io
(list(1, 2, 3) getSlot("size")) type        // "CFunction"
(list(1, 2, 3) getSlot("size")) name        // "List_size()"
(list(1, 2, 3) getSlot("size")) uniqueName  // "size"
(list(1, 2, 3) getSlot("size")) typeName    // "List"
(list(1, 2, 3) getSlot("size")) slotNames   // list()   —— 原始槽自己一个槽都没有
```

`typeName` 是 `CFunction` 独有的：`1 hasSlot("typeName")` 是 `false`，`1 typeName` 直接抛
`Number does not respond to 'typeName'`。

**缺失的那一批**（实测报告形态）：`CFunction setArgumentTypes`、`CFunction setReturnType`、
`DynLib setArgumentTypes`、`Lobby Pointer`、`Lobby CString`、`Lobby Buffer` —— **全是 `false`**。
别的 Io 分支上这几个是用来自定义编组的（比如声明某个参数是 `double`、某个返回值是字符串），
本机构建里没有，因此 23.4 那条浮点边界**没有绕过的余地**。

**大坑**：`CFunction` 是**带接收者类型**的。`List_size()` 是从 `List` 上取下来的；一旦存进
Lobby 槽，引用它的那一刻就按新接收者（`Object`）去执行：

```io
Lobby setSlot("ch23Cf", list(1, 2, 3) getSlot("size"))
try(ch23Cf asString) error
// "CFunction defined for type List but called on type Object"
```

连 `(list(1,2,3) getSlot("size")) isKindOf(CFunction)` 都会炸（错在 `Object.io` 的
`isKindOf` 里），`performOn` 不带参数也是同一句报错。**只能在原接收者上就地用**。

> **为什么重要**：`CFunction` 不是"一个函数值"，而是"**某个类型上的一个原始实现**"。
> 它跟 `Block`（用户写的 `method`，可以随便传递、赋值、当闭包）是两种东西。
> 想传函数值就传 `Block`；原始槽只能就地调用。

## 23.8 安全红线与旁路设施

一句话：`DynLib` 是"把进程内存边界交出去"的能力，而标准库给的 `Sandbox` 在本机**兜不住任何东西**。

实测输出：

```text
-- 23.8 安全红线与旁路设施
警告：DynLib 能把任意 dylib 的任意符号拉进本进程，等于把整个进程
      的内存和安全边界交出去。调用方可控的路径与符号名，一律不许进 DynLib。
Sandbox 的槽 = doSandboxString, messageCount, printCallback, setMessageCount, setTimeLimit, timeLimit
沙箱里算 2 + 3 = 5
沙箱里拼字符串 = hi!
设了消息上限 3，沙箱里照样把 1..100 累加跑完 = 5050
限额读回来 = 0
timeLimit 初值 = 0
AddonLoader 的槽 = addonFor, addons, appendSearchPath, hasAddonNamed, loadAddonNamed, searchPaths, type
已经注册进来的 addon = list()
有 JSON addon 吗 = false
addon 搜索路径条数 = 4
```

**红线**（示例里逐字打出来，就是要它进回归比对）：

```text
警告：DynLib 能把任意 dylib 的任意符号拉进本进程，等于把整个进程
      的内存和安全边界交出去。调用方可控的路径与符号名，一律不许进 DynLib。
```

具体到代码：`setPath` 的参数、`call` 的符号名，**都必须是代码里的常量白名单**，
绝不能来自命令行、配置、网络或用户输入。理由很直白——`DynLib` 能 `dlopen` 任意 dylib、
再 `dlsym` 任意符号并以任意整数参数调用它，等于把整个进程地址空间交出去；
本机构建连 `voidCall` 和 `callPluginInit`（直接调 addon 的 init 函数）都在。

**`Sandbox` 的两个限额是空设**（实测）：

```io
Sandbox doSandboxString("2 + 3")        // 5，沙箱本身能用
Sandbox setMessageCount(3)
Sandbox doSandboxString("a := 0; for(i, 1, 100, a = a + i); a")   // 5050 —— 照样跑完
Sandbox messageCount                     // 0
Sandbox timeLimit                        // 0
```

设得进、读得出，但对沙箱里的执行**没有约束**：消息上限挡不住 100 次迭代的循环。
时间上限同样无效——**离线实测原文**（`gtimeout 6`）：

```text
沙箱前

IOVM:
	Received signal but since multiple Io states are in use
	we don't know which state to send the signal to. Exiting.
rc=124
```

`Sandbox setTimeLimit(1)` 之后跑 `doSandboxString("while(true, nil)")`，脚本照样打不到
下一行，只能靠外部超时打断。**所以别拿 `Sandbox` 当"运行不可信代码"的兜底。**

**`AddonLoader`** 管的是另一件事：预编译好的 `.dylib` addon（不是临时 `dlopen`），
API 有 `addons` / `addonFor` / `hasAddonNamed` / `loadAddonNamed` / `searchPaths` / `appendSearchPath`。
本机上 `addons` 是 `list()`、`hasAddonNamed("JSON")` 是 `false`、搜索路径 4 条——
**一个 addon 都没注册进来**。想加 addon 得自己编（那就是 23.5 的路子：编出 dylib，
再让 C 侧暴露整数接口）。

> **为什么重要**：FFI 的安全账要算在**调用方**头上。语言运行时给的"沙箱"如果是空设，
> 它反而更危险——因为它会让人误以为已经兜住了。真实做法是：
> ① 路径与符号名白名单；② 不可信代码放到**真进程隔离**里（子进程 + `gtimeout`，
> 就是第 13 章观察项那套），而不是同进程的 `Sandbox`。

## 23.9 坑位清单

1. **用 `DynLib` 调 `pow` / `sqrt` 这类浮点签名的 C 函数** → 返回值不是数学结果（实测 `pow(2,10) != 1024`）；让 C 侧封成整数接口，或返回放大后的整数（23.4 / 23.5）。
2. **把浮点调用的返回值打进输出** → 它是整数寄存器的残留值，连跑三次给出 `128` / `-1878456768` / `-1869594008`，逐字节比对必挂；只断言布尔结论（23.4）。
3. **用 `File ... exists` 预判库能不能 `dlopen`** → 现代 macOS 系统库在 dyld 共享缓存里，`exists` 是 `false` 但 `open` 照样成功；唯一判据是 `try(... open)`（23.1）。
4. **`open` 之前就 `call`，或用 `forward` 打错函数名** → 都报 `Error resolving call '名字'.`（是"解析不到符号"而非"库没打开"）；先 `open`、并优先用显式 `d call("名字", …)`（23.3 / 23.6）。
5. **一次给 `call` 传超过 8 个参数** → 硬上限 8 个（`Error, too many arguments (9) to call 'abs'.`），而且符号解析排在这条检查之前（23.6）。
6. **把原始槽（如 `List_size()`）取进变量或槽再引用** → 按新接收者执行，直接抛 `CFunction defined for type List but called on type Object`；只能在原接收者上就地用（23.7）。
7. **指望 `setArgumentTypes` / `setReturnType` / `Pointer` / `CString` / `Buffer`** → 本机构建里实测全是 `false`，没有自定义编组的余地（23.7）。
8. **拿 `Sandbox setMessageCount` / `setTimeLimit` 兜失控代码** → 设得进读得出但对执行无效（上限 3 条消息照样跑完 100 次迭代；时间上限挡不住 `while(true, nil)`，离线实测 `rc=124`）（23.8）。
9. **把 `hasSlot(...)` 直接当 `list(...)` 的实参** → VM 卡死在 C 里、只能靠外部超时打断（第 22 章也踩过），先存变量再 `list`（23.7）。
10. **让用户可控的字符串决定 `setPath` 或符号名** → 等于把进程地址空间交出去；路径与符号名必须是代码里的常量白名单，不可信代码用子进程 + 超时隔离（23.8）。

---

上一章：[22 · 性能陷阱与基准](22-performance.md) · 下一章：[24 · 实战：一个完整的 Io 程序](24-capstone.md)
