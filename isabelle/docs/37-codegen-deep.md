# 37 · 代码生成进阶

对应示例：`../examples/T37_codegen_deep.thy`

## 37.1 一句话概括

codegen 手册的工程半边：三种求值引擎的差异、`[code_unfold]`
把逻辑等价与执行等价分离、方程的挑选与撤销、`export_code`
的目标语言导出与 `code_printing` 的翻译针脚。

## 37.2 三种引擎

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

## 37.4 方程挑选

- `[code]` 注册（fun 定义自动全挂）；
- `[code del]` 摘除（`declare lfilter_len_def [code del]`）；
- `[code equation]` **不是合法属性**（实测），等价物是
  `declare foo.simps(2) [code del]`；
- `[code drop: foo]` 在 HOL-Library（`Code_Lazy` 一族），Main 没有。

## 37.5 export_code 与 code_printing

```isabelle
export_code fib lfilter_len in SML file_prefix "gen37_sml"
export_code fib in Haskell file_prefix "gen37_hs"

code_printing
  constant fib ⇀ (Haskell) "fibFast"
```

文件进**会话导出区**（不是当前目录），用 `isabelle export -x` 取。
预处理器按目标语言独立配置——混目标导出时逐个检查。
箭头是 `⇀`（`\rightharpoonup`），写成 `⇒` 解析报错（实测）。

## 37.6 坑位清单（实测）

1. 未注册 code 方程的常量：value 报 `No code equations`
   （第 35 章 partial_function 同款）。
2. `[code equation]` 不存在。
3. `file_prefix` 相对于会话导出目录；取文件用 `isabelle export -x`。
4. code_unfold 逐目标生效，别假设全局。
5. SML 导出带签名块（structure 折叠），Haskell 是模块。
6. 求值超时：默认引擎编译大项慢，教学示例控制在 fib 20 量级。

## 37.7 与其他章的接口

- 第 19 章代码生成基础（三引擎初见）。
- 第 35 章 partial_function 的 `[code]` 手动注册。
- 第 43 章 `isabelle export` 工具。
