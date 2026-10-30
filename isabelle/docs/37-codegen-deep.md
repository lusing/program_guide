# 37 · 代码生成进阶

对应示例：`../examples/T37_codegen_deep.thy`

## 37.1 从"能求值"到"能导出"

codegen 手册的工程半边：三种求值引擎的差异、`[code_unfold]`
把逻辑等价与执行等价分离、方程的挑选与撤销、`export_code`
的目标语言导出与 `code_printing` 的翻译针脚。

## 37.2 三种求值引擎同台

```isabelle
value "fib 20"        (* 默认：代码生成 + ML 编译 *)
value [nbe] "fib 20"  (* 规范求值 *)
value [simp] "fib 20" (* 化简求值 *)
```

三者语义不一致时说明方程组不是保守定义——差异本身是诊断手段。
`[simp]` 可能"证出"命题化简（重写器的功劳），`[nbe]` 只把项
正规化到构造子，默认引擎真编译执行。

## 37.3 code_unfold：逻辑态与执行态分离

定义保持数学上的漂亮形态，执行换成高效版：

```isabelle
fun cnt :: "(nat ⇒ bool) ⇒ nat ⇒ nat list ⇒ nat" where
  "cnt p acc [] = acc"
| "cnt p acc (x # xs) = cnt p (if p x then acc + 1 else acc) xs"

lemma cnt_acc: "cnt p acc xs = acc + length (filter p xs)"
  by (induct xs arbitrary: acc) auto

lemma lfilter_len_unfold [code_unfold]:
  "lfilter_len p xs = cnt p 0 xs"
  unfolding lfilter_len_def by (simp add: cnt_acc)
```

注意辅助引理要**累加器泛化**（`arbitrary: acc`）——直接对
`lfilter_len p xs = fold (...) xs 0` 做 `induct xs` 会卡在
fold 的起点参数错位（实测三个子目标对不上）。

## 37.4 方程的挑选与 code drop

Isabelle 2026 取消了旧属性 `[code del]`。现在按常量删除代码方程，使用
`[code drop]` 或 `[code drop: 常量名]`；显式注册普通代码方程既可以写
`[code]`，也可以写更明确的 `[code equation]`。

本章先撤掉 `lfilter_len` 定义方程的默认执行路径：

```isabelle
declare lfilter_len_def [code drop]
declare lfilter_len_unfold [code]
```

这样逻辑定义仍然保持原样，代码生成则使用 37.3 证明的高效版本。
撤销 `[code_unfold]` 重写规则仍然使用 `[code_unfold del]`，不要与按常量
删除代码方程的 `[code drop]` 混为一谈。

## 37.5 export_code：四种目标语言

```isabelle
export_code fib lfilter_len in SML file_prefix "gen37_sml"
export_code fib in Haskell file_prefix "gen37_hs"
```

`export_code` 支持 SML、Haskell、OCaml 和 Scala。带 `file_prefix` 时，
文件进入**会话导出区**，不是当前目录；用 `isabelle export -x` 取出。
预处理器按目标语言独立配置，混目标导出时应逐个检查。

## 37.6 code_printing：翻译层的针脚

`code_printing` 可以调整目标语言侧的类型、常量名和字面量呈现。例如，
把 Haskell 中的 `fib` 映射为 `fibFast`：

```isabelle
code_printing
  constant fib ⇀ (Haskell) "fibFast"

export_code fib in Haskell file_prefix "gen37_hs2"
```

箭头是 `⇀`（`\rightharpoonup`），写成 `⇒` 会解析报错。

## 37.7 坑位清单（实测）

1. 未注册 code 方程的常量：`value` 报 `No code equations`
   （第 35 章 partial_function 同款）。
2. Isabelle 2026 已取消 `[code del]`；按常量删除代码方程用
   `[code drop]`，普通代码方程也可显式写成 `[code equation]`。
3. `file_prefix` 相对于会话导出目录；取文件用 `isabelle export -x`。
4. `code_unfold` 逐目标生效，别假设全局。
5. `value [simp]` 可能借助重写证明命题，与另外两种引擎的执行路径不同。
6. `code_printing` 的箭头是 `⇀`，写成 `⇒` 会解析报错。
7. SML 导出带签名块，Haskell 使用模块，两者的名字折叠规则不同。
8. 求值超时：默认引擎编译大项较慢，教学示例控制在 `fib 20` 量级。

相关章节：第 19 章代码生成基础、第 35 章 partial_function 的 `[code]`
手动注册，以及第 43 章 `isabelle export` 工具。
