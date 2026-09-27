# 36 · 美化打印：%a 自定义打印机与 Format 盒子

对应示例：`../examples/32_pp_printers.ml`

官方手册「A guided tour」的收尾支柱就是 pretty-printing：结构化数据
要「照优先级打括号」、「按宽度自适应换行」。工具箱有两层——
`%a` 自定义打印机（printf 体系）与 `Format` 盒子（美化打印体系）。

### 36.1 `%a`：把打印函数当参数传

```ocaml
let pr_int oc n = Printf.fprintf oc "%d" n
Printf.printf "int via %a and %a\n" pr_int 42 pr_int (-7)
```

`%a` 消耗两个实参：一个打印机 + 一个待打印值。`%d` 只认 int，
`%a` 能挂任意类型。

### 36.2 pp 组合子：搭积木

Format 家族约定 `pp_xxx : formatter -> xxx -> unit`，打印机本身
成了值，可以互相包装：

```ocaml
let pp_int ppf n = Format.fprintf ppf "%d" n

let pp_option printer ppf = function
  | None -> Format.fprintf ppf "None"
  | Some v -> Format.fprintf ppf "Some(%a)" printer v

let rec pp_list printer ppf = function
  | [] -> Format.fprintf ppf "[]"
  | x :: r -> Format.fprintf ppf "@[<hov>%a;@ %a@]" printer x (pp_list printer) r
```

`pp_option (pp_pair pp_int pp_string)` 这样嵌套组合——这就是
OCaml 生态里遍地 `pp_*` 前缀函数的来历。

**坑（实测）：两家族的 `%a` 打印机类型不通用**。Printf 家族要
`out_channel -> 'a -> unit`，Format 家族要 `formatter -> 'a -> unit`；
拿 pp 组合子喂 `Printf.printf "%a"` 直接类型错。**两家族的输出
缓冲也相互独立**——同一程序里混用，输出顺序会乱（Format 的内容
可能全部迟于 Printf 的内容出现）。

### 36.3 Format 盒子：宽度自适应

```ocaml
let rec pr_list ppf = function
  | [] -> Format.fprintf ppf "[]"
  | x :: r -> Format.fprintf ppf "@[<hov>%d ::@ %a@]" x pr_list r
```

- `@[<hov> ... @]`：水平或垂直盒——整行放得下就横排，放不下
  就在每个断点处换行；
- `@ `：可断点（横排时输出一个空格）；
- `@;`：强制换行；`@[<v n> ... @]`：垂直盒，每层缩进 n 格；
- `Format.asprintf`：打印到字符串（不落盘，几何固定为默认 78 列）。

**坑（实测，5.4.1）一：顶层裸断点恒换行**。断点 `@ ` 只有在
盒子内才有「能塞就不换」的语义；写在任何盒外的裸断点**总是**
换行——哪怕整行只有 13 个字符。所以断点永远要包在 `@[<hov>` 里。

**坑（实测，5.4.1）二：`set_margin` 收紧时会把 `max_indent` 一并
压低**（78/68 → 20/10），只恢复 margin 不恢复 max_indent——之后
所有超过第 10 列的断点全被误触发。恢复必须成对：
`Format.set_margin 78; Format.set_max_indent 68`（默认几何是
margin 78 / max_indent 68，不是 76！）。

**坑（实测，5.4.1）三：连续 `Format.printf` 不 flush，列计数跨调用
累积**——3 行 26 字符的输出后（累计恰超 78）第 4 次调用的盒子被
误判放不下而竖排。修法：每次 `Format.printf` 后 `Format.print_flush ()`，
或统一走下面的 helper。

示例 32 采用的稳定输出 helper（kfprintf + 在 continuation 里 flush）：

```ocaml
let show : 'a. ('a, Format.formatter, unit, unit) format4 -> 'a =
  fun fmt ->
    Format.kfprintf (fun ppf -> Format.pp_print_flush ppf ()) Format.std_formatter fmt
```

显式多态标注不能省（否则格式串被过早固化，传 `%a` 打印器时
"applied to too many arguments"）；且必须 `kfprintf`（formatter 域）——
`ksprintf` 的 `%a` 只吃 `unit -> 'a -> string` 型打印机。

### 36.4 优先级感知的表达式打印机

手册经典案例：打印 `2*x+1` 而不是 `((2*x)+1)`。递归携带「当前
上下文优先级」，仅当子式优先级更低时加括号：

```ocaml
let rec pp_expr prec ppf = function
  | Const c -> Format.fprintf ppf "%F" c
  | Var v -> Format.fprintf ppf "%s" v
  | Sum (f, g) ->
    Format.fprintf ppf "%s@[<hov>%a +@ %a@]%s"
      (if prec > 0 then "(" else "") (pp_expr 0) f (pp_expr 0) g
      (if prec > 0 then ")" else "")
  | Prod (f, g) -> (* 优先级 2，同理 *) ...
```

验证输出：`2. * x + 1.`、`2. * (1. + x)`、`1. / (2. * (1. + x))`——
括号只在必要处出现（乘对加的嵌套、商的右操作数）。配套的求导
函数 `deriv` 直接来自手册，可现场生成测试数据。

### 36.5 本章小结

| 工具 | 用途 |
|---|---|
| `%a` + 打印机 | 任意类型的可组合打印 |
| pp 组合子 | pp_option / pp_list 套娃 |
| `@[<hov>` 盒 + `@ ` 断点 | 宽度自适应换行 |
| `Format.asprintf` | 到字符串（几何固定） |
| `kfprintf` helper | 顺序与断行都稳定的输出 |

示例 32 把两家族、组合子、盒子与优先级打印机全部跑通，三条
Format 实测坑都有现场演示。

---
上一章：[35 · 面向对象进阶：继承、子类型与二元方法](35-objects-deep.md) ｜ 下一章：[37 · 多态变体深水区](37-poly-variants.md) ｜ 返回：[README](../README.md)
