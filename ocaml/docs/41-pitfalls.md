# 41 · 坑清单与最佳实践

本章按层次收集本教程全程（包括 2026 年 Windows 全量复验）
踩过的坑。前面各章的“实测坑”在这里汇总成速查表。

### 41.1 语法层的坑

**坑 1：int 和 float 运算符不同**

OCaml 的整数和浮点数有完全不同的运算符：
- 整数：`+`、`-`、`*`、`/`、`mod`
- 浮点数：`+.`、`-.`、`*.`、`/.`、`**`

```ocaml
1 + 2          (* 正确：整数加法 *)
1.0 +. 2.0     (* 正确：浮点数加法 *)
1 +. 2         (* 错误：整数和浮点数不能混加 *)
```

这是 OCaml 最常被吐槽的点之一，但它是有意为之的设计。OCaml 不做隐式类型转换，避免了很多因隐式转换导致的 bug。你需要什么类型，就显式地用什么类型。

**坑 2：注释不能嵌套？不，OCaml 的注释可以嵌套**

```ocaml
(* 外层注释
   (* 内层注释 —— 完全合法！ *)
   外层继续
*)
```

OCaml 的注释可以嵌套，这和 C、Java 等语言不同。临时注释掉一大段代码时很方便，不用担心里面的注释导致提前结束。

但要注意：很多其他 ML 语言（比如 Standard ML）的注释是不能嵌套的。如果你同时写多种 ML 方言，容易搞混。

**坑 3：if 表达式的两个分支类型必须一致**

```ocaml
if x > 0 then 1 else "negative"   (* 错误：分支类型不一致 *)
```

`if` 是表达式，它有返回值。两个分支必须返回同类型的值，否则类型不一致。

如果你确实需要返回不同类型的东西，用变体类型把它们包起来：

```ocaml
type result = Int of int | Str of string
let answer = if x > 0 then Int 1 else Str "negative"
```

**坑 4：match 的穷尽性警告不要忽视**

```ocaml
let head = function
  | x :: _ -> x
  (* 警告：这个 pattern-matching 不是穷尽的 *)
```

编译器会警告你没有覆盖所有情况（漏掉了 `[]`）。不要忽视这个警告——它通常意味着你的代码有 bug。

如果某个情况真的不可能发生，用 `assert false` 或 `failwith` 显式标记：

```ocaml
let head = function
  | x :: _ -> x
  | [] -> failwith "head: empty list"
```

**坑 5：函数参数之间不要加逗号**

```ocaml
f (x, y)     (* 这不是两个参数！这是一个元组参数 *)
f x y        (* 这才是两个参数 *)
```

很多初学者会写成 `f(x, y)`，这在 OCaml 中是合法的，但意思是「调用 f，参数是一个元组 (x, y)」，而不是「调用 f，两个参数 x 和 y」。

OCaml 的函数调用语法就是空格分隔参数，没有括号也没有逗号。

### 41.2 类型系统的坑

**坑 6：值限制（Value Restriction）**

```ocaml
let cache = ref None
(* 警告：此表达式的类型是 '_weak1 option ref，不是多态的 *)
```

值限制说的是：只有「语法上的值」（比如常量、函数、构造子）才能拥有多态类型。表达式（比如函数调用的结果）不能是多态的。

`ref None` 是一个表达式（`ref` 函数的调用结果），所以它不能是多态的——类型变量会被弱化成 `'_weak1`，意思是「这个类型还没确定，但一旦确定了就不能变了」。

解决方法：
- 如果知道具体类型，加上类型标注：`let cache : int option ref = ref None`
- 如果想要多态，改成函数：`let make_cache () = ref None`

**坑 7：弱化的多态类型变量（_weak1）**

`'_weak1` 这种类型变量叫做「弱多态变量」。它的特点是：第一次使用时会被实例化为具体类型，之后就固定了，不能再变。

```ocaml
let cache = ref None
!cache            (* 类型是 '_weak1 option *)
cache := Some 1;  (* 现在 '_weak1 被确定为 int *)
!cache            (* 类型是 int option *)
cache := Some "x" (* 错误：类型不匹配，已经是 int 了 *)
```

弱多态是值限制的产物。如果你看到 `'_weak1`，通常意味着你的代码某处多态性不够，需要检查一下。

**坑 8：记录字段名冲突**

```ocaml
type point2d = { x : float; y : float }
type point3d = { x : float; y : float; z : float }

let p = { x = 1.0; y = 2.0 }   (* 这是 point2d 还是 point3d？ *)
```

OCaml 中，记录字段名是全局的（在同一个模块内）。如果两个记录类型有相同的字段名，后定义的会遮蔽先定义的。

上面的代码中，`p` 的类型是 `point3d`，因为 `point3d` 后定义，它的字段名遮蔽了 `point2d` 的。

解决方法：
- 把不同的记录类型放在不同的模块里
- 使用变体类型代替
- 字段名加前缀（比如 `p2d_x`、`p3d_x`）

**坑 9：变体构造子的作用域**

```ocaml
type color = Red | Green | Blue
type traffic_light = Red | Yellow | Green

let x = Red   (* 这是哪个 Red？ *)
```

和记录字段一样，变体构造子的名字也是全局的。后定义的 `traffic_light` 的 `Red` 和 `Green` 会遮蔽 `color` 的。

如果需要同时使用两种类型，用模块命名空间来区分：

```ocaml
module Color = struct
  type t = Red | Green | Blue
end

module TrafficLight = struct
  type t = Red | Yellow | Green
end

let x = Color.Red
let y = TrafficLight.Red
```

### 41.3 模块系统的坑

**坑 10：透明约束会暴露内部类型**

```ocaml
module type S = sig
  type t
  val make : int -> t
end

module M : S = struct
  type t = int
  let make x = x
end

let _ = M.make 42 + 1   (* 能编译吗？ *)
```

答案是：不能。因为签名中 `type t` 是抽象的，透明约束下它仍然是抽象的。外部不知道 `M.t` 是 `int`，所以不能直接当 `int` 用。

但如果签名中写了 `type t = int`，透明约束下外部就知道了：

```ocaml
module type S = sig
  type t = int
  val make : int -> t
end

module M : S = struct
  type t = int
  let make x = x
end

let _ = M.make 42 + 1   (* 可以！透明约束下 t = int 可见 *)
```

**坑 11：Functor 是 applicative 还是 generative？**

OCaml 的 functor 是 applicative 的——用相同的参数调用同一个 functor，得到的模块的类型是相同的。

```ocaml
module S1 = Set.Make(String)
module S2 = Set.Make(String)

let s1 = S1.singleton "hello"
let s2 = S2.singleton "world"
let _ = S1.union s1 s2   (* 能编译吗？ *)
```

答案是：可以。因为 OCaml 的 functor 是 applicative 的，`Set.Make(String)` 两次应用得到的类型相同。

但如果参数是匿名模块（结构），情况就不一样了：

```ocaml
module S1 = Set.Make(struct type t = string let compare = compare end)
module S2 = Set.Make(struct type t = string let compare = compare end)
```

这两个 `S1.t` 和 `S2.t` 是不同的类型——因为两个 `struct ... end` 是不同的模块，即使它们的内容完全一样。

**坑 12：include 的使用时机**

`include` 看起来很方便，但要谨慎使用。过度使用 `include` 会让模块的内容来源变得不清晰——你不知道某个函数是模块自己定义的，还是从哪个地方 include 来的。

经验法则：
- 模块之间是「扩展」关系时，用 `include`（比如 `IntSetExtended` 扩展 `IntSet`）
- 模块之间是「使用」关系时，用普通的模块调用（`M.f x`）
- 不要为了少写几个前缀就 `include` 一个大模块

### 41.4 可变状态的坑

**坑 13：= 和 == 的区别**

- `=` 是结构相等：比较内容
- `==` 是物理相等：比较内存地址

```ocaml
let a = [1; 2; 3]
let b = [1; 2; 3]

a = b     (* true：内容相同 *)
a == b    (* false：不同的内存对象 *)
```

对于不可变值，你几乎总是应该用 `=`。`==` 主要用于可变值（ref、数组），判断两个引用是不是同一个。

**坑 14：ref 的比较**

```ocaml
let r1 = ref 0
let r2 = ref 0

r1 = r2     (* true 还是 false？ *)
r1 == r2    (* true 还是 false？ *)
```

答案：
- `r1 = r2` 是 `true`——结构相等，比较的是 ref 指向的内容
- `r1 == r2` 是 `false`——物理相等，比较的是引用本身是不是同一个

如果你想比较两个引用的内容，用 `=`。如果你想判断两个引用是不是同一个对象（修改 r1 会不会影响 r2），用 `==`。

**坑 15：Hashtbl 的键比较**

标准库的 `Hashtbl` 默认使用结构相等（`=`）和 `Hashtbl.hash`。也就是说，两个内容相同的字符串会被认为是同一个键。

但 `Hashtbl` 有一个参数化版本 `Hashtbl.Make`，你可以自定义相等函数和哈希函数。如果你用物理相等（`==`）作为键的比较方式，那行为就完全不同了——两个内容相同的对象可能被当作不同的键。

使用第三方库的哈希表时，一定要看清楚它的相等语义。

### 41.5 I/O 的坑

**坑 16：input_line 保留换行符吗？**

不保留。`input_line` 返回的字符串**不包含**末尾的换行符。

```ocaml
(* 假设文件内容是 "hello\nworld\n" *)
let line = input_line ic
(* line = "hello"，不是 "hello\n" *)
```

这意味着，如果你逐行读取再逐行写入，原始文件的换行符格式可能会改变（比如 Windows 的 `\r\n` 会变成 `\n`）。

如果需要保留原始格式，用 `really_input_string` 或 `input_char` 自己处理。

**坑 17：缓冲区刷新问题**

输出是带缓冲的。如果你调用了 `print_string` 但没看到输出，可能是因为缓冲区还没满，内容还没真正输出。

```ocaml
print_string "Thinking...";
(* 做一些耗时操作 *)
print_endline "done"
```

你可能期望先看到 "Thinking..."，然后过一会儿看到 "done"。但实际上，"Thinking..." 可能一直缓冲着，直到 "done" 才一起输出。

解决方法：在需要立即显示的输出后调用 `flush stdout`。

**坑 18：文件描述符泄漏**

如果打开了文件但忘记关闭，就会泄漏文件描述符。泄漏多了，程序会达到系统的文件描述符上限，无法再打开新文件。

最容易出问题的场景是异常：正常路径下有关闭文件的代码，但异常路径下漏掉了。

解决方法：用 `Fun.protect ~finally` 或 `with_file` 模式（见第 22 章），确保无论正常返回还是抛出异常，文件都会被关闭。

### 41.6 顶层结构与短语终结的坑（本教程实测重灾区）

本教程 12–22 号示例初版全部编译失败，病根就是这一节的内容——
这些坑**与平台无关**，macOS 上同样编译不过：

- **顶层不允许 `let ... in`**。`let x = e in ...` 是表达式，
  只能出现在函数体/`let () = ...` 块内部。顶层的语句链要包一层
  `let () = ...`。
- **定义后面紧跟“裸调用”必须补 `;;`**。反例：

  ```ocaml
  let section n title =
    Printf.printf "\n---- %d) %s ----\n" n title;
    print_endline (String.make 50 '-')     (* <- 少了 ;; *)
  (* 注释 *)
  section 1 "..."                          (* 被吞进应用链！ *)
  ```

  症状极具迷惑性：报错不在病灶处，而是 `The function
  print_endline has type string -> unit`（应用了过多参数）、
  `CamlinternalFormatBasics.End_of_format`（printf 吞了后面的
  原子）或某个孤儿的 `;;` 语法错。看到这三类错，优先往回找
  缺 `;;` 的定义。
- **定义后跟定义（`let`/`type`/`module`/`exception`）不需要 `;;`**：
  解析器能自行分辨。反过来，`;` 结尾的裸语句后面也不能直接跟
  新定义（要么 `;;`，要么并入同一个 `let () =` 块）。
- **跨块引用**：`let a = ... in ...;;` 里的 `a` 不进入后续短语
  的作用域。裸语句要用前面的变量，就合并进同一个 `let () =`。
- **用异常跳出多重循环**：`try` 必须包住整个 `while`，写在循环
  **后面**的 `(try () with Exit -> ())` 永远接不住（本教程
  优快排里真实修过的一个潜在运行时崩溃）。

### 41.7 绑定运算符、GADT 与 Effect 的坑（5.4.1 实测）

- `let*` / `and*` / `let+` 是**算子值**，Stdlib 没有自带，
  `let open Result in let* ...` 直接 `Unbound value ( let* )`——
  要自己接线（第 27 章）。
- `( let+ )` 参数序是值在前；`Option.map` / `Result.map` 是函数
  在前，不能直接赋给它。
- 负数字面量作实参加括号：`validate_user "bob" (-1) "x"`，
  否则 `-1` 按二元减号解析成部分应用。
- match 臂里的 GADT 类型标注**必须带括号**：
  `| (Get : a Effect.t) -> ...`；不带括号是语法错。
- 存在类型（GADT 打包值、效应构造子）参与的 match，函数边界
  要显式标注类型，否则 `int is ambiguous: it would escape the
  scope of its equation`。
- 记录式 `Effect.Deep.match_with` 的 `effc` 要补返回类型标注
  （`((a, 'b) continuation -> 'b) option`）；effect 模式里的续延
  变量 `k` 不允许标注。
- 一次性续延：同一个 `k` 恢复两次抛
  `Effect.Continuation_already_resumed`；多解回溯不能靠 resume
  两次。
- 首类模块的 package type 不支持参数化类型方程：
  `(module S : SET with type 'a t = 'a S.t)` 非法；把元素类型拆成
  独立的 `elt` 再 `with type elt = ...`（第 14 章示例 12 的修法）。
- class 方法里用开放对象类型 `< ...; .. >` 报 unbound type
  variables：值绑定会自动泛化而 class 不会，要写显式多态方法
  `method m : 'a. (< ...; .. > as 'a) -> ...`（第 24 章）。
- `Domain.cpu_count` 不存在（用 `recommended_domain_count`）；
  `Atomic.fetch_and_add` 只支持 int。
- `Stream` 模块不在 5.4 标准库发行里；`Seq.nth` / `Seq.sort` /
  `print_bool` 不存在（速查见第 2.8 节）。

### 41.8 标签参数、lazy、首类模块与对象的坑（2026-09 扩充实测）

- **可选参数不能是最后一个参数**：`let g ?(a = 1) = ...` 直接
  Syntax error；后面必须跟非可选参数钉住调用时机。
- **带缺省值的可选参数在函数体内已是普通值**：递归里转发
  `?sep` 报 `string` vs `string option`——转发只能在「还是 option
  的那一层」做，递归改用内部辅助函数（第 31 章）。
- **高阶函数的标签顺序必须一致**：形参 `g` 以 `~x ~y` 顺序被应用，
  实参函数也必须按 `~x ~y` 定义；且带标签的形参不能喂无标签函数
  （`h1 (+) 1 2` 编译不过）。
- **顶层拆包用 `module P = (val m : S)`**：写 `let module P = e`
  而不接 `in` 直接 `;;` 是 Syntax error——`let module` 是表达式
  绑定（第 33 章）。
- **首类模块按签名名判等**：结构一模一样的两个签名，打包出的
  `(module S1)` 与 `(module S2)` 是不同类型，不能进同一个 list。
- **lazy 的异常不记忆化**：成功才缓存，失败每次 force 都重新执行
  并重抛；`Lazy.force` 多线程不安全（第 32 章）。
- **方法调用做实参必须加括号**：`f obj#m x` 解析成 `(f obj#m) x`，
  printf 的格式串会错位报 `End_of_format` 系错误；要写
  `f (obj#m x)`。
- **二元方法要 `object(self : 'a)`**：裸 `object(self)` 加
  `method eq (a : 'a)` 报 "type variables are unbound"；正确写法
  下子类会**失去**对父类的子类型关系（`(b : e4 :> e3)` 编译不过，
  函数子类型的逆变成环）——子类未必是子类型（第 35 章）。
- **方法不能重载**：一个类里两个 `method f` 报 "multiple
  definitions"；多重继承同名同类型后者生效、同名不同类型直接类型错。
- **开放类型 `#cl` 不能写在方法参数里**：`let` 与类初始化参数可以；
  方法参数里报类型错，改用行多态 `< m : t; .. >`。
- **`Hashtbl.replace` / `remove` 一次只动最近一个绑定**：`add` 出的
  更早重复键原样保留（实测 `find_all = [3; 1]`）；清光要循环
  `while Hashtbl.mem h k do Hashtbl.remove h k done`（第 34 章）。
- **value restriction 的真实边界**（5.4.1 REPL 实测）：`let g = f 1`
  是 `'_weak -> int`（`'b` 在逆变位置不放行）；`id id` 同样不泛化
  （别信传言）；`List.map (fun x -> x) []` 反而泛化（协变位置，
  relaxed value restriction 放行）；偏应用要多态就 eta 展开。
- **`class` 不自动泛化方法**：要 `class ['a] c = ...`；`new` 多态类
  的结果是 `'_a c`（value restriction 作用于对象），首次使用后固化。

### 41.9 手册扩充轮实测坑（2026-09-27，Format 与语言扩展）

- **顶层裸断点恒换行**：Format 的 `@ ` 断点只有包在 `@[<hov>` 盒
  里才有「能塞就不换」的语义；写在任何盒外的裸断点总是换行，
  哪怕整行只有 13 个字符（第 36 章）。
- **`Format.set_margin` 收紧会连带压低 `max_indent`**（78/68 ->
  20/10），只恢复 margin 不恢复 max_indent，之后超过第 10 列的
  断点全被误触发。恢复要成对：`set_margin 78; set_max_indent 68`
  （默认几何是 78/68，不是 78/76）。
- **连续 `Format.printf` 不 flush 会跨调用累积列计数**：3 行 26
  字符的输出后第 4 次调用的盒子被误判放不下而竖排。修法：每次
  `Format.print_flush ()`，或用 kfprintf helper 在 continuation 里
  flush（第 36 章）。
- **Printf 与 Format 两家族缓冲独立**：混用时输出顺序会乱；
  `%a` 打印机类型也不通用（`out_channel` vs `formatter` 域）。
- **自制 printf helper 必须显式多态标注 + kfprintf**：
  `ksprintf` 的 `%a` 只吃 `unit -> 'a -> string` 打印器（第 36 章）。
- **`let` 位置的多态变体模式把 row 闭口**：直接匹配 `int vlist`
  报 "does not allow tag `Nil"；补标注后穷尽检查又要求 `Nil`
  分支——访问器用完整 match 写（第 37 章）。
- **同一编译单元同名类型出现两次**：interp 逐句执行能过，
  byte/native 直接 "Multiple definition"（`type nonrec` 的演示必须
  包在嵌套模块里，第 38 章）。
- **`module A = G () and B = G ()` 语法非法**：generative functor
  应用分两行写（第 39 章）。
- **refutation 臂必须用通配模式**：`| Bool _ -> .` 的模式自己先
  类型错误，要写 `| _ -> .`（第 39 章）。
- **extensible variant 的 match 必须带通配臂**（Warning 8 提示
  `*extension*`，第 38 章）。
- **`Warning 10` 系列**：`for` 循环体里的非 unit 表达式
  （`Atomic.fetch_and_add`、`CA.bump ()`）要 `ignore (...)`
  包住，否则零告警判定失败。
- **非原子竞争是静默算错**：两域各 30 万次 `r := !r + 1` 实测丢
  5-6 万次更新，不崩溃；Atomic / Mutex / `[@atomic]` 字段三修法
  实测全部精确（第 40 章）。

### 41.10 Windows 平台的坑（MSYS2 UCRT64 实测）

详见第 2.8 节，速查：

- 从原生 shell 调用编译器要设 `OCAMLLIB`（否则
  `Unbound module Stdlib`）；
- `ocamlopt` 需要单独安装 `flexdll` 包（`flexlink` 不在 ocaml
  包的依赖里）；
- `ocamlc -o x` 生成**无后缀 PE**，PowerShell `&` 不肯执行——
  显式 `.exe`；字节码运行还要 PATH 上有 `ocamlrun`、链接了
  unix 的还要 `OCAMLLIB` 找 stublibs 的 DLL；
- `Unix` 模块要手工 `-I ... unix.cma` 链接（macOS 同样）；
- 数字开头文件名触发 Warning 24；多文件项目的模块名必须合法；
- 临时目录：`Filename.get_temp_dir_name ()` 取的是 `TMP` 而
  不是 `TEMP`（两者可能不同，检查残留时两个都要看）。

### 41.11 macOS 平台的坑（MacPorts + OCaml 5.5.0，2026-09-20 实测）

- **工具链不在 `/usr/bin`**：MacPorts 装在 `/opt/local/bin/ocamlc`
  （Homebrew 是 `/opt/homebrew/bin`），`ocamlc -where` 给出
  `/opt/local/lib/ocaml`。脚本按「环境变量 → PATH → 常见目录」三级探测。
- **`Unix` 模块必须显式 `-I +unix`**（不写也能编过，但会吐
  `Alert ocaml_deprecated_auto_include`，那是**告警**）：

  ```bash
  ocamlc -w -24 -I +unix unix.cma  -o build/15_algorithms     examples/15_algorithms.ml
  ocamlopt -w -24 -I +unix unix.cmxa -o build/15_algorithms_opt examples/15_algorithms.ml
  ```

  写 `-I "$(ocamlc -where)/unix"` 效果相同。
- **`ocamlopt` 开箱可用**，不需要 Windows 上那套 `flexdll`；代价是原生
  编译比字节码慢一个量级（全量 31 个示例 byte+native 约 4 分钟）。
- **中间产物会掉在源文件旁边**：`ocamlc x.ml` 把 `x.cmi` / `x.cmo`
  写在 `x.ml` 同一个目录里，直接编译 `examples/*.ml` 会污染源码目录。
  本教程的两个入口都先把源码复制一份到 `build/` 再编译，产物留在 `build/`。
- **「零告警」这条在 macOS 上真会咬人**。本机 5.5.0 实测报出两类：
  `Warning 26 [unused-var]`（`let x = ... in` 定义了却没人用）和
  `Warning 23 [useless-record-with]`（`{ r with ... }` 把字段列全了，
  `with` 是多余的）。教学代码里「定义完看都不看一眼」的写法最容易踩前者——
  要么把它打印出来（教程里更合适），要么写成 `let _ = ...`。

### 41.12 最佳实践

**实践 1：优先使用不可变数据**

默认用不可变数据结构（列表、元组、不可变记录），只有在有充分理由时才用可变数据。

不可变数据的好处：
- 更容易推理——值不会被别人修改
- 没有副作用——函数是纯的，测试简单
- 天然线程安全——不需要锁
- 可以安全共享——不用担心别名问题

**实践 2：用模式匹配代替 if**

```ocaml
(* 不推荐 *)
if l = [] then ... else ...

(* 推荐 *)
match l with
| [] -> ...
| x :: xs -> ...
```

模式匹配更具表达力，而且编译器会检查穷尽性——如果你漏掉了某个情况，编译器会警告你。`if l = []` 就没有这种保障。

同样，对于 `option` 和 `result`，优先用模式匹配处理，而不是 `Option.is_some` + `Option.get` 这种不安全的组合。

**实践 3：用 option / result 代替异常**

预期内的错误用 `option` 或 `result` 类型，让类型系统强迫调用者处理。异常留给真正意外的情况。

```ocaml
(* 不推荐：用异常 *)
let find key map =
  if not (mem key map) then raise Not_found
  else ...

(* 推荐：用 option *)
let find key map =
  if not (mem key map) then None
  else Some ...
```

`option` 让错误在类型中可见，调用者无法忽视。异常是隐式的，类型系统不追踪。

**实践 4：合理使用抽象类型保护不变量**

如果你的数据结构有不变量（比如有序列表必须有序、日期必须合法），用不透明约束把内部表示隐藏起来，只暴露能保证不变量的操作。

让类型系统帮你保证「非法状态不可表示」——只要你拿到了这个类型的值，它就一定是合法的。

**实践 5：让类型系统帮你写对代码**

类型系统不是阻碍，而是工具。你可以通过设计好的类型来减少 bug：

- 用变体类型表示「多种情况」，而不是用字符串或整数编码
- 用 `option` 表示可能不存在的值，而不是用特殊值（-1、空字符串等）
- 用 `result` 表示可能失败的操作，而不是用异常
- 用抽象类型保护不变量
- 用私有类型控制构造

**一个好的类型设计胜过 100 个单元测试。** 类型系统在编译时为你保证所有可能的值都是合法的，而测试只能覆盖有限的情况。

### 41.13 本章小结

语法层的坑：
- 整数和浮点数运算符不同，不能混用
- 注释可以嵌套（和 SML 不同）
- if 表达式的分支类型必须一致
- match 的穷尽性警告一定要重视
- 函数参数用空格分隔，不要加逗号

类型系统的坑：
- 值限制导致弱多态类型变量（`'_weak1`）
- 记录字段名在模块内是全局的，会互相遮蔽
- 变体构造子同理

模块系统的坑：
- 透明约束下，签名中抽象的类型仍然抽象
- Functor 是 applicative 的，但匿名结构每次都是新类型
- include 要慎用，避免来源不清

可变状态的坑：
- `=` 是结构相等，`==` 是物理相等
- ref 的 `=` 比较内容，`==` 比较引用本身
- Hashtbl 默认用结构相等，自定义的要看清

I/O 的坑：
- `input_line` 不保留换行符
- 输出是缓冲的，必要时手动 flush
- 用 `Fun.protect` 防止文件描述符泄漏

顶层结构的坑：
- 顶层不允许 `let ... in`，语句链包 `let () =`
- 定义后跟裸调用必须补 `;;`；三类怪错先怀疑它
- 用异常跳多重循环，try 要包住整个循环

绑定运算符/GADT/Effect 的坑：
- `let*` 是算子值，要自己接线；`( let+ )` 值在前
- GADT 标注带括号；存在类型参与时边界要标全
- effect 模式的 k 不可标注；续延一次性
- 5.4 无 `Domain.cpu_count` / `print_bool` / `Stream` 模块

Windows 的坑（MSYS2）：
- 原生 shell 要设 `OCAMLLIB`
- 原生编译要装 flexdll
- 产物加 `.exe` 后缀；字节码运行依赖 ocamlrun 在 PATH

最佳实践：
- 优先使用不可变数据
- 用模式匹配代替 if
- 用 option/result 代替异常
- 用抽象类型保护不变量
- 让类型系统帮你写对代码
- 失败链用绑定运算符直着写，语义随 `( and* )` 实现选

---
上一章：[40 · OCaml 5 内存模型](40-memory-model.md) ｜ 返回：[README](../README.md)
