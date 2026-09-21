// ============================================================
// 23_ffi.io —— 第 23 章：外部函数接口
// 运行：io examples/23_ffi/23_ffi.io
//
// Io 的 FFI 叫 DynLib：dlopen + dlsym，参数和返回值都按 intptr_t 传。
// 于是本章有一条很硬的、必须先说清楚的边界：
//   · 整数签名的 C 函数能调：abs / labs / strlen / toupper / atoi 都能过
//   · **浮点签名的 C 函数调不了**：libm 的 pow(2, 10) 拿回来的不是 1024。
//     证据在源码里 —— marshal 用 IoNumber_asInt 把参数截成整数，demarshal 用
//     IONUMBER(intptr_t) 造返回对象，而调用本身是 ((intptr_t(*)(intptr_t,...))f)()，
//     返回值只从整数寄存器取；double 走 xmm0，取到的是一段残留值。
//   · Pointer / CString / Buffer 这三个编组原型在本机构建里**不存在**，
//     CFunction 上也没有 setArgumentTypes / setReturnType（本机实测均为 false）。
// 所以「调 libm 的 pow 算 2^10 断言得到 1024」这件事在本机做不到。
// 本章把这个失败实测出来，再给出真正跑得通的路子：自己写整数签名的 C 函数、
// 用 cc 编成动态库（macOS -dynamiclib / Linux -shared -fPIC）、再让 DynLib
// 调 —— 那条路上 2^10 就是 1024。
//
// 平台分支：示例带 Darwin / Linux 两套实测。macOS 用 libSystem.B.dylib /
// libm.dylib 的绝对路径；Linux 用 ld.so 认得的 soname（"libc.so.6" /
// "libm.so.6"）。两条路的教学点一致：文件系统里都「看不到」这个库文件
// （macOS 收进了 dyld 共享缓存；Linux 的 soname 由 ld.so 缓存解析），
// dlopen 却都能开。其余平台直接跳过本章（给出标记、干净退出）。
//
// 安全红线（本章 23.8 再展开）：DynLib 能把任意动态库的任意符号拉进本进程，
// 绝不要把用户可控的路径或符号名喂给它。
// ============================================================

fails := 0
chk := method(tag, got, want,
    if(got asString != want asString,
        fails = fails + 1
        writeln("  [FAIL] ", tag, " 得到 ", got asString, "，期望 ", want asString)
    )
)
sec := method(title, writeln(""); writeln("-- ", title))
show := method(label, value, writeln(label, " = ", value asString))

writeln("==== 23 开始 ====")

isDarwin := System platform == "Darwin"
isLinux := System platform == "Linux"
if(isDarwin not and isLinux not,
    writeln("本章只带 Darwin / Linux 两套实测分支（当前平台：", System platform, "），跳过。")
    writeln("==== 23 结束 ====")
    System exit(0)
)
sysPath := if(isLinux, "libc.so.6", "/usr/lib/libSystem.B.dylib")
mathPath := if(isLinux, "libm.so.6", "/usr/lib/libm.dylib")
shimExt := if(isLinux, "so", "dylib")
ccArgs := if(isLinux, "-shared -fPIC", "-dynamiclib")

sec("23.1 DynLib 的四个动作：setPath / open / isOpen / close")
// 标准库 io/DynLib.io 只有 7 行：给每个克隆挂一个 forward（下一节讲）。
// 真东西在 C 里（libs/iovm/source/IoDynLib.c），对外就这 13 个槽：
show("DynLib 的槽", DynLib slotNames sort join(", "))
d := DynLib clone setPath(sysPath)
show("setPath 返回 self，path 能原样读回来", d path)
show("open 之前的 isOpen", d isOpen)
d open
show("open 之后的 isOpen", d isOpen)
// clone 不继承句柄：IoDynLib_rawClone 的注释专门写了这一点
show("新克隆的 isOpen", (DynLib clone) isOpen)
d close
show("close 之后的 isOpen", d isOpen)
chk("setPath 只是记路径，不加载", d path, sysPath)
chk("clone 不继承已打开的句柄", (DynLib clone) isOpen, false)
// 「文件系统里看不到、dlopen 却能开」：macOS 把系统库收进了 dyld 共享缓存；
// Linux 的 "libc.so.6" 是 soname，由 ld.so 缓存/默认路径解析，stat 不到这个名字
show("File 看得到 " .. sysPath .. " 吗", File with(sysPath) exists)
sysLib := DynLib clone setPath(sysPath)
sysLib open
show("但它能被 dlopen", sysLib isOpen)
sysLib close
chk("文件存在性判断不了系统库能否 dlopen", File with(sysPath) exists, false)

sec("23.2 能过的：整数签名的 C 函数")
// 系统库里这几个函数的签名全是整数，编组不丢信息，结果确定。
// （macOS 在 libSystem.B.dylib、Linux 在 libc.so.6 —— 都能 dlopen 到。）
d open
show("abs(-5)", d call("abs", -5))
show("labs(-7)", d call("labs", -7))
show("strlen(\"hello\")", d call("strlen", "hello"))
show("toupper(97)", d call("toupper", 97))
show("atoi(\"42\")", d call("atoi", "42"))
show("atoi(\"-13\")", d call("atoi", "-13"))
chk("abs(-5) == 5", d call("abs", -5), 5)
chk("labs(-7) == 7（64 位整数版）", d call("labs", -7), 7)
chk("Io 字符串直接当 char* 传进去", d call("strlen", "hello"), 5)
chk("toupper 就是 ASCII 大小写换算", d call("toupper", 97), 65)
chk("能配合算数：atoi(\"42\") + atoi(\"8\")", d call("atoi", "42") + d call("atoi", "8"), 50)
d close

sec("23.3 forward：把 DynLib 当函数库用")
// DynLib.io 里的 forward 把 d foo(a, b) 改写成 d call("foo", a, b)。
// 方便，但也把「函数不存在」这件事从「不响应消息」变成了运行期解析失败。
d open
show("方法式写法 d abs(-9)", d abs(-9))
show("和 d call(\"abs\", -9) 等价", d call("abs", -9))
show("d strlen(\"hi\")", d strlen("hi"))
// 打错名字不会报「不响应消息」，而是走到 dlsym 才失败 —— 注意消息原文
show("方法式调用打错名字", (try(d no_such_fn_qq(1))) error)
chk("forward 和 call 是同一件事", d abs(-9), d call("abs", -9))
chk("forward 让拼写错误延后到 dlsym 才暴露",
    (try(d no_such_fn_qq(1))) error, "Error resolving call 'no_such_fn_qq'.")
d close

sec("23.4 过不去的：浮点签名 —— libm 的 pow(2, 10) 不是 1024")
// 关键：**不要**把 pow 的返回值打出来。它是从整数寄存器里捞的残留值，
// 取决于在它之前跑过什么，连跑三次能给出 128 / -1878456768 / -1869594008
// 三个完全不同的数（docs 23.4 里有这段离线实测原文，macOS；Linux 上同样
// 只断言布尔结论，两条通道一致）。
// 能打出来而且确定的，只有「它和 1024 不相等」这个布尔结论。
m := DynLib clone setPath(mathPath)
m open
show("libm 打开了", m isOpen)
show("pow(2, 10) 等于 1024 吗", m call("pow", 2, 10) == 1024)
show("sqrt(4.0) 等于 2 吗", m call("sqrt", 4.0) == 2)
show("返回对象仍然是 Number（所以类型系统看不出来）", (m call("pow", 2, 10)) type)
// macOS 的 libm.dylib 自己导出 labs；Linux 的 libm.so.6 不导出，但 glibc 的
// dlsym 会沿着 libm→libc 的依赖链把 labs 找出来 —— 两边都能调，值一样。
show("同一个库里 labs(-7) 照样对", m call("labs", -7))
chk("浮点返回值拿不回来", m call("pow", 2, 10) == 1024, false)
chk("sqrt 也一样", m call("sqrt", 4.0) == 2, false)
chk("类型系统不报警，只有值不对", (m call("pow", 2, 10)) type, "Number")
chk("同一个库里整数签名照常", m call("labs", -7), 7)
m close
// 源码依据（IoDynLib.c）：
//   marshal:   if (ISNUMBER(arg)) n = IoNumber_asInt(arg);   // 参数被截成整数
//   demarshal: if (ISNUMBER(arg)) return IONUMBER(n);         // n 是 intptr_t
//   IoDynLib_justCall: ((intptr_t(*)(intptr_t,...))f)(...)    // 返回值只从整数寄存器取
// 顺带一提，IoDynLib_proto 的方法表里 "returnsString" 是被注释掉的 ——
// 字符串返回值也没接上（传进去可以，取出来不行）。

sec("23.5 真能拿到 1024 的路子：自己编一个整数签名的 C 库")
// FFI 的契约既然只认整数，那就让 C 侧配合：自己写整数签名的函数、
// 用 cc 编成动态库（macOS：-dynamiclib 出 .dylib；Linux：-shared -fPIC 出 .so），
// DynLib 再调。这不是绕过问题，而是把「Io 的 FFI 只有整数这一档」摊开给读者看。
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
libPath := Path with(System getEnvironmentVariable("TMPDIR"), "io_ch23_shim." .. shimExt)
srcFile := File with(srcPath)
srcFile remove
// 必须 asUTF8：Io 字符串的内部表示不等于文件字节（第 14 章的坑）
srcFile setContents(shimLines join("\n") asUTF8)
build := System runCommand("/usr/bin/cc " .. ccArgs .. " -o " .. libPath .. " " .. srcPath)
show("cc 的退出码", build exitStatus)
show("源文件字节数", srcFile size)
// 编译失败（没有 cc / 沙箱禁写）时降级成跳过，不能抛出去
buildOk := (build exitStatus == 0) and (File with(libPath) exists)
if(buildOk,
    lib := DynLib clone setPath(libPath)
    lib open
    show("自建库 isOpen", lib isOpen)
    show("ch23_ipow(2, 10)", lib call("ch23_ipow", 2, 10))
    show("ch23_ipow(3, 4)", lib call("ch23_ipow", 3, 4))
    show("ch23_ipow(-2, 3)", lib call("ch23_ipow", -2, 3))
    show("ch23_checksum(\"abc\")", lib call("ch23_checksum", "abc"))
    // 上面对 libm 的那条断言，在这里换个库就成立了
    chk("自建整数函数：2^10 就是 1024", lib call("ch23_ipow", 2, 10), 1024)
    chk("负数也准（说明是完整 64 位在传）", lib call("ch23_ipow", -2, 3), -8)
    chk("char* 参数也能传", lib call("ch23_checksum", "abc"), 96354)
    lib close
    show("收工后 isOpen", lib isOpen)
,
    writeln("cc 不可用或编译失败，跳过自建库实测（本机两遍输出仍一致）")
)
File with(libPath) remove
srcFile remove

sec("23.6 错误路径：把异常消息原文抄下来")
// 只说异常的 error 槽。异常对象自己的 asString 带对象地址，绝不能打。
u := DynLib clone setPath(sysPath)
// 「没 open 就 call」两个平台给出**相反**的答案：
//   macOS：dlsym 解析不到符号，报 Error resolving call 'abs'.（异常）；
//   Linux：handle 还是 NULL，glibc 的 dlsym(NULL, …) 按**全局符号表**解析 ——
//   不但不报错，还把全局已加载的 libc 里的 abs 调出了 5。这比报错更值得
//   警惕：一行 call 都不用 open，就能摸到进程里任意全局符号（23.8 红线加码）。
if(isLinux,
    show("没 open 就 call（dlsym(NULL) 走全局符号表，居然通了）", u call("abs", -5))
,
    show("没 open 就 call", (try(u call("abs", -5))) error)
)
u open
show("符号不存在", (try(u call("no_such_symbol_xyz", 1))) error)
show("参数超过 8 个", (try(u call("abs", 1, 2, 3, 4, 5, 6, 7, 8, 9))) error)
show("库文件不存在", (try(DynLib clone setPath("/no/such/libch23_nope." .. shimExt) open)) error)
show("dlopen 一个文本文件", (try(DynLib clone setPath("/etc/hosts") open)) error)
// 四条断言用 containsSeq，免得把整段 dlopen 长文塞进 chk 里。
// 注意顺序：符号解析在参数个数检查**之前**，所以 u 必须还开着。
if(isLinux,
    // Linux 上「没 open 的克隆」同样能全局解析出 abs —— 那条「解析不到符号」
    // 的保护在 glibc 上根本不存在，实测断言它的**反面**。
    chk("没 open 也能调：dlsym(NULL) 从全局符号表解析出 libc 的 abs",
        (DynLib clone) call("abs", -5), 5)
,
    chk("没 open 报的是「解析不到符号」而不是「库没打开」",
        ((try(DynLib clone call("abs", -5))) error) containsSeq("Error resolving call 'abs'."), true)
)
chk("参数上限是 8 个（第 9 个就拒）",
    ((try(u call("abs", 1, 2, 3, 4, 5, 6, 7, 8, 9))) error) containsSeq("too many arguments (9)"), true)
// dlopen 失败的诊断原文由动态链接器给，两边措辞不同：
//   macOS dlerror：带 mach-o 措辞 + 「dlopen(路径, 0x000A)」调用原文；
//   glibc  dlerror：只有简短原因（invalid ELF header），不带调用原文，
//                   路径由 Io 的包装层（Error loading object '…'）带上。
if(isLinux,
    chk("dlopen 失败会把动态链接器自己的诊断原样带出来",
        ((try(DynLib clone setPath("/etc/hosts") open)) error) containsSeq("invalid ELF header"), true)
    chk("glibc 的 dlerror 不带调用原文，路径由 Io 包装层补上",
        ((try(DynLib clone setPath("/etc/hosts") open)) error) containsSeq("Error loading object '/etc/hosts'"), true)
,
    chk("dlopen 失败会把动态链接器自己的诊断原样带出来",
        ((try(DynLib clone setPath("/etc/hosts") open)) error) containsSeq("not a mach-o file"), true)
    chk("错误消息里带 dlopen(...) 的调用原文",
        ((try(DynLib clone setPath("/etc/hosts") open)) error) containsSeq("dlopen(/etc/hosts, 0x000A)"), true)
)
u close

sec("23.7 CFunction 与缺失的编组设施")
// 原始槽（C 实现的槽）的值是 CFunction，用户写的 method 是 Block。
show("用户方法的 type", (Object clone do(a := method(1)) getSlot("a")) type)
show("原始槽 size 的 type", (list(1, 2, 3) getSlot("size")) type)
show("原始槽 size 的 name", (list(1, 2, 3) getSlot("size")) name)
show("原始槽 size 的 uniqueName", (list(1, 2, 3) getSlot("size")) uniqueName)
show("原始槽 size 的 typeName", (list(1, 2, 3) getSlot("size")) typeName)
show("CFunction 自己一个槽都没有", (list(1, 2, 3) getSlot("size")) slotNames)
show("typeName 只有 CFunction 有，Number 上没有", 1 hasSlot("typeName"))
// 这三样在别的 Io 分支上是配齐的，本机构建里一个都没有 —— 实测报告形态
show("CFunction 上有 setArgumentTypes", (list(1, 2, 3) getSlot("size")) hasSlot("setArgumentTypes"))
show("CFunction 上有 setReturnType", (list(1, 2, 3) getSlot("size")) hasSlot("setReturnType"))
show("DynLib 上有 setArgumentTypes", DynLib hasSlot("setArgumentTypes"))
hasP := Lobby hasSlot("Pointer")
hasC := Lobby hasSlot("CString")
hasB := Lobby hasSlot("Buffer")
show("Lobby 上有 Pointer / CString / Buffer", list(hasP, hasC, hasB))
// 大坑（第 22 章也记过）：hasSlot(...) 的结果**不能**直接当 list(...) 的实参，
// 这个 VM 会卡死在 C 里、只能靠外部超时打断。先存变量再 list。
argT := (list(1, 2, 3) getSlot("size")) hasSlot("setArgumentTypes")
retT := (list(1, 2, 3) getSlot("size")) hasSlot("setReturnType")
chk("原始槽是 CFunction，用户方法是 Block", (Object clone do(a := method(1)) getSlot("a")) type, "Block")
chk("CFunction 没有 setArgumentTypes / setReturnType", list(argT, retT), list(false, false))
chk("Pointer / CString / Buffer 三个原型都不存在", list(hasP, hasC, hasB), list(false, false, false))
// 大坑：CFunction 是**带接收者类型**的。List_size() 是从 List 上取的，
// 一旦存进 Lobby 槽，引用它的那一刻就按新接收者（Object）去执行，直接炸。
Lobby setSlot("ch23Cf", list(1, 2, 3) getSlot("size"))
show("把 List_size() 存进槽再引用", (try(ch23Cf asString)) error)
chk("CFunction 不能脱离原接收者保存",
    ((try(ch23Cf asString)) error) containsSeq("CFunction defined for type List but called on type Object"), true)

sec("23.8 安全红线与旁路设施")
// 一句话，记住就够：
writeln("警告：DynLib 能把任意 dylib 的任意符号拉进本进程，等于把整个进程")
writeln("      的内存和安全边界交出去。调用方可控的路径与符号名，一律不许进 DynLib。")
// 标准库给了个沙箱（io/Sandbox.io），但它的两个限额在本机是**空设**：
show("Sandbox 的槽", Sandbox slotNames sort join(", "))
show("沙箱里算 2 + 3", Sandbox doSandboxString("2 + 3"))
show("沙箱里拼字符串", Sandbox doSandboxString("\"hi\" .. \"!\""))
Sandbox setMessageCount(3)
show("设了消息上限 3，沙箱里照样把 1..100 累加跑完", Sandbox doSandboxString("a := 0; for(i, 1, 100, a = a + i); a"))
Sandbox setMessageCount(0)
show("限额读回来", Sandbox messageCount)
show("timeLimit 初值", Sandbox timeLimit)
chk("消息上限设得进、读得出，执行却能跑完", Sandbox doSandboxString("a := 0; for(i, 1, 100, a = a + i); a"), 5050)
chk("沙箱返回值本身可用", Sandbox doSandboxString("2 + 3"), 5)
// AddonLoader 管的是另一件事：预编译好的动态库 addon（macOS .dylib / Linux .so，
// 不是临时 dlopen）
show("AddonLoader 的槽", AddonLoader slotNames sort join(", "))
show("已经注册进来的 addon", AddonLoader addons)
show("有 JSON addon 吗", AddonLoader hasAddonNamed("JSON"))
show("addon 搜索路径条数", AddonLoader searchPaths size)
chk("本机没有任何 addon 注册进来", AddonLoader addons, list())

sec("23.9 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 23 结束 ====")
if(fails != 0, System exit(1))
