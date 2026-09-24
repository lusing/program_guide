# 23 · 脚本工程

> 对应示例：[`examples/23_engineering/23_engineering.sml`](../examples/23_engineering/23_engineering.sml)

前 22 章讲的是"怎么证"，这一章讲"**怎么保证别人跑你的脚本会得到同样的结果**"。
本教程的每条示例都过 `run-all.sh` 的七条判据，这一章把那七条拆开讲清楚，
并给出脚本骨架 —— 顺带把写这章时**验证脚本自己被坑了两次**的经过记下来。

## 23.1 脚本骨架

```text
每个示例文件都是同一个形状：

  val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
  val _ = Feedback.set_trace "Definition.storage_message" 0
  open HolKernel boolLib bossLib Parse     (* + 需要的理论 *)
  val _ = new_theory "TutNN"
  fun sec s = print ("\n" ^ s ^ "\n")   (* 分节 *)
  fun out s = print (s ^ "\n")           (* 整行 *)
  val _ = print "\n==== NN 开始 ====\n"
  ... 若干 sec/out ...
  val _ = print "\n==== NN 结束 ====\n"
  val _ = export_theory ()

`sec`/`out` 只有两个：分节用 sec，其它一律整行 out。
不写 `print` 的变体，是为了让输出**可以逐字节比对**。
```

本教程 24 个示例文件**全部**是这一个形状。三条约定：

1. 开头两行关掉两条 trace（23.2 节）；
2. 输出只有 `sec` 和 `out` 两个函数，不写 `print` 的变体 ——
   这样"这一行是怎么打印出来的"只有两种可能，比对时不会出歧义；
3. 头尾各打一个标记，比对只取标记之间（23.4 节）。

## 23.2 两条必须关的 trace

```text
Theory.save_thm_reporting —— 关掉后 save_thm / store_thm 不打印
                             "Saved theorem ..."。
Definition.storage_message —— 关掉后 Definition 不打印
                             "Definition has been stored under ..."。
为什么非关不可：这两条消息只出现在**其中一条入口**里。
不关掉，两条入口的输出就永远不可能逐字节一致，
第 7 条判据会一直红。

trace 名字不能猜，猜错会直接抛异常：
  <
Exception raised at Feedback.set_trace: No trace "Datatype.storage_message" is registered
>
```

```sml
val _ = Feedback.set_trace "Theory.save_thm_reporting" 0
val _ = Feedback.set_trace "Definition.storage_message" 0
```

这两行出现在每个示例文件的**最开头**（甚至在 `open` 之前）。

为什么非关不可:两条系统提示**只出现在其中一条入口**里：

- `"Saved theorem ___"` —— 只在 Holmake 通道出现；
- `"Definition has been stored under ___"` —— 只在 `hol run` 通道出现。

不关掉，两条入口的输出就**永远不可能**逐字节一致，第 7 条判据会一直红。

> **trace 名字不能猜。** 上面那段输出是真实的：本教程写作时以为存在
> `Datatype.storage_message`（对称地照抄 `Definition.storage_message`），
> 结果它**没有注册**，`set_trace` 直接抛异常。
> 想知道有哪些 trace 就去查源码，不要靠对称性猜。

## 23.3 输出纪律

```text
正常输出 → stdout（print / out / sec）
诊断信息 → stderr（HOL 自己的报错走这里）
run-all.sh 把两者分开接：stdout 用来比对，stderr 必须为空。

推论：脚本里**不要**往 stderr 写东西，也**不要**依赖
任何会随环境变化的东西（时间戳、PID、绝对路径、耗时）。
本章第一句打印的 Globals.version 是「版本号」，是常量，可以用；
而 `Theory "X" took 0.32s to build` 这种就不能进比对区间。
```

判据第 2 条要求 **stderr 为空**，所以脚本里不能往 stderr 写任何东西。

判据第 6 条要求"两次运行逐字节一致"，所以脚本输出里**不能**有：

- 时间戳、耗时（`Theory "X" took 0.32s to build`）；
- PID、临时目录、绝对路径；
- 任何跟机器/负载相关的东西。

`Globals.version`（版本号）是常量，可以放心打印。

## 23.4 标记与区间

```text
`==== 23 开始 ====` 之前有引擎自己的寒暄：
  `<<HOL message: Created theory "Tut23">>`
`==== 23 结束 ====` 之后有构建系统的话：
  `Exporting theory "Tut23" ... done.`
  `Theory "Tut23" took 0.3s to build`
比对只取两个标记**之间**的部分，这样两边的噪声都被滤掉，
留下的全是脚本自己写的。

抽取时匹配必须是**整行严格相等**，不能写子串匹配。
本章就是活的反例：上面两行把标记原样印在了正文里，
子串匹配会把第 46 行当成真的结束标记，区间当场被截断 ——
而「区间非空」「两条通道一致」这些判据照样全绿，
丢掉的半章没人发现。所以判据里还加了
「两个标记各**恰好出现一次**」这一条兜底。
```

标记之前有引擎的寒暄（`Created theory`），之后有构建系统的话
（`Exporting theory` / `took 0.12377s to build`）。
比对只取**两个标记之间**的部分，两边的噪声就都被滤掉了。

> **这一节记录了一个真实的验证脚本 bug。** 本章正文需要讲解"标记长什么样"，
> 于是把 `` `==== 23 结束 ====` 之后有构建系统的话：`` 原样印在了输出里。
> 而 `run-all.sh` 的区间抽取当时写的是子串匹配（`index($0, e)`），
> 于是**把讲解当成了真的结束标记**，区间从 98 行被截断成 45 行。
>
> 可怕的地方在于：**五项判据全绿。** 截断后的区间依然非空、无控制字符、
> 两条通道也依然逐字节一致 —— 丢掉的半章没有任何人发现。
>
> 修法是两条：① 抽取改成整行严格相等（`$0 == e`）；
> ② 判据里加一条"两个标记各**恰好出现一次**"兜底。
> 光修 ① 不够 —— 下次谁再把标记印进正文，① 也救不了。

## 23.5 七条判据

```text
每条通道各自过 1–5：
  1. 退出码 0
  2. stderr 为空
  3. 开始 / 结束两个标记各**恰好出现一次**（整行严格相等）
  4. 标记区间非空，且不含 [[:cntrl:]] 控制字符
  5. 区间无溃逃痕迹
跨通道再过 6–7：
  6. run1 与 run2 的区间逐字节一致（运行间确定性）
  7. run1 与 hm 的区间逐字节一致（两条独立入口一致）

第 4 条为什么写 POSIX 字符类而不是 [^[:print:]]：
  在 LC_ALL=C 下，后者的补集会把 CJK 的 UTF-8 高字节
  全判成「非可打印」，本章这一行就会被误杀。
```

每条通道（`run1` / `run2` / `hm`）各自过 1–5，跨通道再过 6–7，
**每章 5 项**，24 章共 **120 项**。

第 4 条有个 macOS 上必踩的坑：控制字符检测要写 POSIX 字符类
`[[:cntrl:]]`，不能写 `[^[:print:]]`。
后者在 `LC_ALL=C` 下的补集会把 **CJK 的 UTF-8 高字节**全判成"非可打印"
—— 本章这种满屏中文的输出会被整章误杀。

## 23.6 溃逃痕迹

```text
`prove` 失败时会往 stdout 打印
    Proof of ... failed. First unsolved sub-goal is ...
然后抛异常。如果只用关键字列表去匹配 `failed.`，
任何一句「这一条失败了」的中文说明都会被误判。
所以判据写成**组合**：横幅行 `Proof of` 后面必须紧跟着
单独一行的 `failed.`，两者同时出现才算数。
同样的道理，**所有单行判据都必须锚定行首**。`Static Errors`
`Uncaught exception` 这几个词本章就印在上面两行里（在引号中、
行中间），裸的子串匹配会把「讲解」当成「痕迹」，三条通道全红 ——
而脚本其实一点毛病都没有。真实错误行的形状是
    bad.sml:4: error: Pattern and expression have ...
    Uncaught exception at ./basis/FinalPolyML.sml:492: ...
所以 `: error:` 那条要连带「源文件名 + 行号」一起匹配。
反过来，`Exception raised at ...` **不算**痕迹：
19.3 / 22.4 / 23.2 这几节是故意 handle 住异常打印出来做演示的，
它们是预期输出，退出码也还是 0。
```

这一节是"溃逃痕迹"判据的设计说明，也是这一章第二次踩坑的记录。

**第一次（已知）：** `prove` 失败会打印

```
Proof of ... failed. First unsolved sub-goal is ...
```

然后抛异常。如果拿关键字列表匹配 `failed.`，
任何一句"这一条失败了"的中文说明都会被误判。
所以判据写成**组合**：`Proof of` 单独一行，且紧跟着单独一行的 `failed.`。

**第二次（本章新踩）：** 修完第一条之后，本章正文为了讲解这些横幅长什么样，
把 `Static Errors` / `Uncaught exception` / `: error:` 原样印进了输出。
结果**裸的子串匹配把"讲解"当成了"痕迹"，三条通道全红** —— 而脚本一点毛病没有。

修法同样是两条：

1. **所有单行判据锚定行首**（`^Static Errors`、`^Uncaught exception`）；
2. `: error:` 那条**连带源文件名和行号一起匹配**
   （真实形状是 `bad.sml:4: error: ...`）。

改完之后必须**反向验证**：拿一段真的错误输出喂给判据，确认它仍然抓得住
（本章写作时确实这么验了一遍，`escape_trace` 对真实错误仍返回"有痕迹"）。
只去掉误报、不确认还能抓真错，等于把判据废掉。

> `Exception raised at ...` **不算**痕迹：19.3、22.4、23.2 这几节是
> 故意 `handle` 住异常打印出来做演示的，它们是预期输出，退出码也还是 0。

## 23.7 可重入

```text
Holmake 会缓存：脚本没改，它直接加载上次编好的理论文件。
所以脚本**第二次跑的时候环境是干净的**，第一次留下的
ML 绑定、trace 设置、定理都不在。
推论：
  - 不能依赖上一次运行定义的常量；
  - 不能在脚本里假设某个定理「应该还在」；
  - 重名会被拒：<DUP "dup_test">
```

```sml
val _ = out ("  - 重名会被拒：" ^ ((save_thm ("dup_test", TRUTH);
                                    save_thm ("dup_test", TRUTH); "<允许>")
                                   handle e => "<" ^ exn_to_string e ^ ">"))
```

Holmake 按时间戳缓存（22.6 节），脚本没改就加载上次编好的理论文件。
这意味着**脚本必须能从零重建**：

- 不能依赖上一次运行定义的 ML 常量；
- 不能假设某个定理"应该还在"；
- 理论里名字唯一，重复登记抛 `DUP`（上面最后一行是实测输出）。

本教程 24 个脚本全部满足可重入 —— 这也是 `run-all.sh` 敢在每章开头
`rm -rf` 三个通道目录、每次都从干净环境跑的前提。

## 23.8 中文引号

```text
写中文说明时想用引号，别用 ASCII 双引号：
  错：out ("规则生成的是"最小集合"（归纳的）。")
  对：out ("规则生成的是「最小集合」（归纳的）。")
SML 把第一个内部引号当字符串结束，报错点是
`parse error: expected closing parenthesis`，
离真正的原因有十万八千里。本教程写的时候踩了 6 次，
于是有了 check-quotes.py 这个前置检查。
```

写中文教程时最高频的一个错误：在 SML 字符串里用 ASCII 双引号当书名号。

```sml
out ("规则生成的是"最小集合"（归纳的）。")    (* 错 *)
out ("规则生成的是「最小集合」（归纳的）。")  (* 对 *)
```

SML 把第一个内部引号当成字符串结束，后面的中文全变成语法错误，
而**报错点**是 `parse error: expected closing parenthesis` ——
离真正的原因有十万八千里。本教程写作时踩了 6 次，于是有了
`check-quotes.py` 这个前置检查（README 里的"机器核查"之一）。

> `check-quotes.py` 自己也修过一次 bug：它原来只取 `args[0]` 当根目录去 glob，
> 于是传一串文件名进去时**一个文件都没扫**，却照样打印"检查通过"。
> 现在改成：收不到任何 `.sml` 就直接报错退出（拒绝"假绿"）。
> 修完实测：无参数跑和传 24 个文件跑，都是"24 个文件"。

## 23.9 收尾

```text
骨架 + 纪律都到位之后，剩下就是正常的活：
  ⊢ ∀l. LENGTH (MAP (λx. x + 1) l) = LENGTH l
```

```sml
val _ = out ("  " ^ p ``!l : num list. LENGTH (MAP (\x. x + 1) l) = LENGTH l``
                (Induct_on `l` >> rw []))
```

骨架和纪律都到位之后，剩下的就是正常的活。
这一行证明（第 13 章也出现过）既是收尾，也是提醒：
**工程化不是为了把证明变复杂，而是为了让"证明是对的"这件事可以被机器复核。**

## 23.10 坑位清单

1. **两条 trace 必须在 `open` 之前关掉** → 否则两条入口的输出永远不可能一致。
2. **trace 名字不能猜** → 没有 `Datatype.storage_message`，猜错直接抛异常。
3. **输出只用 `sec` / `out`** → 不写 `print` 变体，避免比对歧义。
4. **区间抽取必须整行严格相等** → 子串匹配会被"正文里提到标记"截断（23.4）。
5. **标记必须各恰好出现一次** → 只判"存在"兜不住第 4 条那类截断。
6. **控制字符用 `[[:cntrl:]]` 不是 `[^[:print:]]`** → 后者在 `LC_ALL=C` 下误杀 CJK。
7. **溃逃判据要写成组合，单行判据要锚定行首** → 否则"讲解"被当成"痕迹"（23.6）。
8. **改完判据要反向验证还能抓真错** → 只去误报等于把判据废掉。
9. **脚本必须可重入** → Holmake 缓存意味着第二次跑时环境是干净的。
10. **中文引号用「」不用 `"`** → `check-quotes.py` 是前置检查，但也要确认它真扫到了文件。

---

上一章：[22 · 理论与数据库](22-theories.md) ·
下一章：[24 · 综合练习](24-capstone.md)
