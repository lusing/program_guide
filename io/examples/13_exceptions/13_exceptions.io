// ============================================================
// 13_exceptions.io —— 第 13 章：异常与错误处理
// 运行：io examples/13_exceptions/13_exceptions.io
//
// Io 只有一套错误机制：**异常**。没有错误码、没有返回值哨兵（nil 只是 nil）。
// 捕获入口只有一个 Object try(...)，异常本身就是普通对象，可以 clone 出新类型。
//
// 本章有一个**观察文件**：observe_13_uncaught.io，专门把「未捕获异常会中断
// 脚本、退出码却仍是 0」这个行为做成可验证的观察项。13.3 节做的是同一件事，
// 只是为了让本章自己也能跑出证据。
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

writeln("==== 13 开始 ====")

sec("13.1 try 是唯一的捕获入口")
show("try(1 + 1) 正常返回", try(1 + 1))
e := try(1 + nil)
show("try(1 + nil) 的 type", e type)
show("e error", e error)
// try 最反直觉的一点：**成功时也不把值还给你**，它只回「异常或 nil」
show("try(42) 的值", try(42))
show("try(正常但值就是 nil) 也一样", try(nil))
// 原因就在它自己的实现里：参数消息被丢进一个新建的协程跑，最后只问那个协程有没有异常
tryCode := Object getSlot("try") code
show("Object try 的类型", Object getSlot("try") type)
show("实现代码行数", tryCode split("\n") size)
show("实现里新建了协程", tryCode containsSeq("Coroutine clone"))
show("实现里只回「异常或 nil」", tryCode containsSeq("if(coro exception, coro exception, nil)"))
chk("正常路径 try 给 nil", try(1 + 1), nil)
chk("算出来的普通值也拿不到", try(42), nil)
chk("异常路径 try 给异常对象", e type asString, "Exception")
chk("异常里有完整的错误消息", e error, "argument 0 to method '+' must be a Number, not a 'nil'")
chk("try 自己就是个 Block", Object getSlot("try") type asString, "Block")
chk("try 靠协程实现", tryCode containsSeq("Coroutine clone"), true)

sec("13.2 异常是个普通对象，槽位就是它的全部信息")
show("e coroutine type", e coroutine type)
show("e nestedException", e nestedException)
show("e originalCall", e originalCall)
// 异常的**全部能力**就是它的槽位清单，没有隐藏的私有状态。
// 注意这里打的是排序后的结果，不然顺序取决于哈希表布局，不是确定性输出。
show("Exception slotNames sort", Exception slotNames sort)
show("e hasSlot(\"showStack\")", e hasSlot("showStack"))
show("e hasSlot(\"pass\")", e hasSlot("pass"))
show("e hasSlot(\"catch\")", e hasSlot("catch"))
chk("异常挂在协程上", e coroutine type asString, "Coroutine")
chk("没有嵌套时 nestedException 是 nil", e nestedException, nil)
chk("普通运算错误不带 originalCall", e originalCall, nil)

sec("13.3 未捕获异常：横幅打到 stdout、脚本中断、退出码却是 0")
// 本示例自己必须活到最后（要打印结束标记），所以把「会死的脚本」写进临时文件
// 交给子进程跑，再把它的退出码和 stdout 搬回来做布尔断言。
// 子脚本内容刻意保持纯 ASCII：中文针在字节串上做 containsSeq 容易踩编码问题。
//
// 解释器路径按「环境变量 → 安装前缀 → PATH」三级回落，且**不打印路径本身**
// （路径因机器而异，打出来会破坏逐字节比对）。
resolveIo := method(
    hit := nil
    list(System getEnvironmentVariable("IO_BIN"),
         System installPrefix .. "/bin/io_static",
         System installPrefix .. "/bin/io",
         "io_static",
         "io") foreach(c,
        if(hit == nil and c != nil,
            if(c containsSeq("/"),
                if(File with(c) exists, hit = c)
                ,
                hit = c
            )
        )
    )
    hit
)
ioBin := resolveIo
show("找到可用解释器", ioBin != nil)
childLines := list(
    "writeln(\"child: before\")",
    "Object clone boom",
    "writeln(\"AFTER-MARKER\")"
)
childPath := Path with(System getEnvironmentVariable("TMPDIR"), "io_ch13_child.io")
childFile := File with(childPath)
childFile remove
// asUTF8 不是多余的：Io 的 setContents 倒的是字符串的内部表示（含非 ASCII 会变 UCS4）
childFile setContents(childLines join("\n") asUTF8)
cr := System runCommand(ioBin .. " " .. childPath)
childOut := cr stdout
childErrSize := if(cr stderr == nil, -1, cr stderr size)
show("子进程退出码", cr exitStatus)
show("子进程 stderr 长度", childErrSize)
show("stdout 里有未捕获异常横幅", childOut containsSeq("Object does not respond to 'boom'"))
show("异常之后那一行没被执行", childOut containsSeq("AFTER-MARKER") not)
childFile remove
chk("未捕获异常不改变退出码，仍是 0", cr exitStatus, 0)
chk("横幅走 stdout 而不是 stderr", childErrSize, 0)
chk("异常之后的行被丢弃", childOut containsSeq("AFTER-MARKER"), false)

sec("13.4 自定义异常类型：Exception clone，类型就是身份")
MyErr := Exception clone
SubErr := MyErr clone
sub := try(SubErr raise("子类型出事"))
show("SubErr raise 出来的是什么类型", sub type)
show("isKindOf(SubErr)", sub isKindOf(SubErr))
show("isKindOf(MyErr)", sub isKindOf(MyErr))
show("isKindOf(Exception)", sub isKindOf(Exception))
show("raise 可以直接带消息", (try(MyErr raise("自定义消息"))) error)
chk("raise 出来的实例其 type 就是那个原型", sub type asString, "SubErr")
chk("子类型满足父类型的 isKindOf", sub isKindOf(MyErr), true)
chk("自定义类型仍然 isKindOf(Exception)", sub isKindOf(Exception), true)

sec("13.5 catch：在异常对象上调用，handler 是副作用，返回的是「没接住的异常」")
// 语法是 e catch(类型, 处理表达式)，不是 try(...) catch(...) 的返回值链
caught := try(Exception raise("要接住的"))
matched := caught catch(Exception, "这一行只是被求值，不是返回值")
show("catch 命中时返回", matched)
unmatched := try(Exception raise("要接住的")) catch(Error, "这一行不会跑")
show("catch 没命中时返回的类型", unmatched type)
sideEffect := 0
probe := try(Exception raise("副作用探测"))
probe catch(MyErr, sideEffect = 99)
afterMismatch := sideEffect
probe2 := try(Exception raise("副作用探测"))
probe2 catch(Exception, sideEffect = 123)
afterMatch := sideEffect
show("类型不匹配，handler 没跑（sideEffect）", afterMismatch)
show("类型匹配，handler 跑了（sideEffect）", afterMatch)
chk("catch 命中返回 nil", matched, nil)
chk("catch 没命中就把异常原样还回来", unmatched type asString, "Exception")
chk("类型不匹配时 handler 不执行", afterMismatch, 0)
chk("handler 的返回值不是结果，它按副作用求值", afterMatch, 123)
// 父类型能接住子类型，反之不行
parentCatch := try(SubErr raise("子类型")) catch(MyErr, "父类型接住了")
childCatch := try(MyErr raise("父类型")) catch(SubErr, "子类型接不住父类型")
chk("父类型接得住子类型", parentCatch, nil)
chk("子类型接不住父类型", childCatch type asString, "MyErr")

sec("13.6 pass：接不住就往上扔")
// pass 把当前异常重新抛出，交给更外层
inner := try(Exception raise("往上扔") pass)
show("pass 之后再 try 一次拿到的消息", inner error)
outer := try(try(Exception raise("两层") pass) pass)
show("连扔两层之后拿到的消息", outer error)
// 不 pass 的话异常对象就只是「一个值」，外层 try 不会再接它——因为 try 不读值
swallowed := try(try(MyErr raise("内层炸了")) catch(Error, "类型不对，没接住"))
show("没接住又不 pass，异常就变成普通值了", swallowed)
chk("pass 让异常继续往上走", inner error, "往上扔")
chk("任意层数的 pass 都保留原始消息", outer error, "两层")
chk("异常对象当成值传出去就不再是异常", swallowed, nil)

sec("13.7 嵌套异常：一个原因套一个原因")
nested := try(Exception raise("外层原因", Exception clone setError("内层原因")))
show("nested error", nested error)
show("nested nestedException error", nested nestedException error)
show("nestedException 也有自己的 type", nested nestedException type)
chk("两层原因都能取到", nested nestedException error, "内层原因")
chk("外层错误消息不被覆盖", nested error, "外层原因")

sec("13.8 Error 与 Exception 是两家人")
show("Lobby 有 Error", Lobby hasSlot("Error"))
show("Error 有 raise", Error hasSlot("raise"))
show("Error isKindOf(Exception)", Error isKindOf(Exception))
show("Exception 有 raise", Exception hasSlot("raise"))
// Error 只是给 VM 内部留的另一个空壳原型，不参与 raise/catch 体系
err := try(Error raise("想用它当异常"))
show("拿 Error 当异常用会得到", err error)
chk("Error 没有 raise", Error hasSlot("raise"), false)
chk("Error 不在 Exception 家族里", Error isKindOf(Exception), false)
chk("自定义异常只能从 Exception 出发", err type asString, "Exception")

sec("13.9 signal + withHandler：可恢复异常")
// raise 是「一去不回」，signal 是「问一句还能不能继续」。
// withHandler(类型, 处理器, 主体)：主体里 signal 出来的异常交给处理器，
// 处理器返回什么，signal 那个表达式就得到什么。
seen := List clone
v := withHandler(MyErr,
    block(exc, resume,
        seen append(exc error)
        42
    ),
    MyErr signal("轻微问题")
)
show("主体里 signal 表达式的值", v)
show("处理器看到了什么", seen)
fallback := try(MyErr signal("没人接的就退化成 raise"))
show("没有处理器时 signal 的归宿", fallback type)
show("退化后的消息", fallback error)
quiet := List clone
normal := withHandler(MyErr, block(exc, resume, quiet append("不该跑")), "主体正常结束")
show("主体没出事时的返回值", normal)
show("处理器有没有被误触发", quiet)
chk("处理器返回的值成为 signal 的结果", v, 42)
chk("处理器收到了原始异常消息", seen at(0), "轻微问题")
chk("无处理器时 signal 退化成 raise", fallback error, "没人接的就退化成 raise")
chk("主体没出事时处理器不触发", quiet size, 0)

// ⚠️ 处理器必须用 block(...) 造，不能用 method(...)。
// 原因在 11.3.1：method 造的块 isActivatable 是 true，一进形参（形参就是槽）
// 就被零参调用，异常对象压根传不进去。
probeLog := List clone
okHandler := withHandler(MyErr, block(exc, resume, probeLog append(exc error); 42),
                         MyErr signal("轻微问题"))
show("block  造的处理器：结果", okHandler)
show("block  造的处理器：看到的消息", probeLog)
// 取快照：下面那次 method 版还会往 probeLog 里塞东西
logAfterBlock := probeLog clone

badErr := try(withHandler(MyErr,
    method(exc, resume, probeLog append("method 处理器被提前跑了"); 42),
    MyErr signal("轻微问题")))
show("method 造的处理器：报错", badErr error)
show("method 造的处理器：让 probeLog 长到了几条", probeLog size)
chk("block 造的处理器拿得到异常", logAfterBlock at(0), "轻微问题")
chk("block 造的处理器返回的值就是 signal 的值", okHandler, 42)
chk("block 时只留下一条痕迹（处理器只跑了一次）", logAfterBlock size, 1)
chk("method 造的处理器进形参时就被调用了一次", probeLog size, 2)
chk("被提前跑掉的处理器再也不能当处理器", badErr error, "Number does not respond to 'call'")

sec("13.10 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 13 结束 ====")
if(fails != 0, System exit(1))
