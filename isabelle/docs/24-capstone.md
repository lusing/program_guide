# 24 · 综合案例：一个被证明过的编译器

对应示例：`../examples/T24_capstone.thy`

## 24.1 这一章做什么

把前面二十三章串成一件完整的事：

1. 定义一门**源语言**（算术表达式）；
2. 定义一台**目标机器**（栈机）；
3. 写一个**编译器**；
4. 证明**编译器正确**——编译出的指令序列，执行效果等于源语言的语义；
5. 再证明一个**常量折叠优化**不改变机器行为；
6. 最后 `export_code` 导出成真能跑的 ML 程序。

用到的东西：数据类型（第 4 章）、递归函数（第 5 章）、结构化归纳（第 6 章）、`simp` 与 `auto` 的配合（第 7、8 章）、`arbitrary:`（第 6 章）、代码生成（第 19 章）。

## 24.2 源语言

```isabelle
type_synonym vname = string
type_synonym state = "vname \<Rightarrow> int"

datatype aexp = N int | V vname | Plus aexp aexp

fun aval :: "aexp \<Rightarrow> state \<Rightarrow> int" where
  "aval (N n) s = n"
| "aval (V x) s = s x"
| "aval (Plus a1 a2) s = aval a1 s + aval a2 s"

value "aval (Plus (V ''x'') (N 5)) ((\<lambda>x. 0) (''x'' := 3))"
```

```text
"8"
  :: "int"
```

`x` 取 3，加 5 得 8。

## 24.3 目标机器：栈机

```isabelle
datatype instr = LOADI int | LOAD vname | ADD

type_synonym stack = "int list"

fun exec :: "instr list \<Rightarrow> state \<Rightarrow> stack \<Rightarrow> stack" where
  "exec [] s stk = stk"
| "exec (i # is) s stk = (case i of
     LOADI n \<Rightarrow> exec is s (n # stk)
   | LOAD x  \<Rightarrow> exec is s (s x # stk)
   | ADD     \<Rightarrow> exec is s ((hd (tl stk) + hd stk) # tl (tl stk)))"
```

指令序列从左到右执行，栈按"**栈顶在左**"的惯例写。`ADD` 弹出栈顶两个元素，压回它们的和。

**这里刻意用 `hd` / `tl` 而不是模式匹配**，原因值得讲：模式匹配会逼你给"栈深度不足"这种畸形状态一个返回值，而那本来就是不该发生的事。凭空引入一个 `undefined` 分支只会污染后续证明——每次 `simp` 都会多一个"这个分支可能吗"的残骸。

```text
consts
  exec :: "instr list \<Rightarrow> (char list \<Rightarrow> int) \<Rightarrow> int list \<Rightarrow> int list"

Found termination order: "(\<lambda>p. size_list size (fst p)) <*mlex*> {}"

"[7]"
  :: "int list"
```

`exec [LOADI 3, LOADI 4, ADD] (λx. 0) []` 得 `[7]`。

## 24.4 编译器

```isabelle
fun compile :: "aexp \<Rightarrow> instr list" where
  "compile (N n) = [LOADI n]"
| "compile (V x) = [LOAD x]"
| "compile (Plus a1 a2) = compile a2 @ compile a1 @ [ADD]"
```

```text
consts
  compile :: "aexp \<Rightarrow> instr list"

Found termination order: "size <*mlex*> {}"

"[LOAD ''x'', LOADI 3, ADD]"
  :: "instr list"
```

注意 `compile (Plus a1 a2)` 里的顺序：**先 `compile a2` 再 `compile a1`**。因为栈顶在左，`ADD` 会算 `hd(tl stk) + hd stk` = 第一个压入的 + 第二个压入的 = `a1 + a2`。所以 `a1` 要后压（更靠栈顶）。

实测输出印证了：`compile (Plus (N 3) (V ''x''))` 得到 `[LOAD ''x'', LOADI 3, ADD]`——先加载 x，再压 3，然后相加。

## 24.5 关键引理：执行是可拼接的

```isabelle
lemma exec_append: "exec (is1 @ is2) s stk = exec is2 s (exec is1 s stk)"
  apply (induction is1 arbitrary: stk s)
    apply simp
   apply (auto split: instr.split)
  done
```

```text
theorem
  exec_append:
    exec (?is1.0 @ ?is2.0) ?s ?stk = exec ?is2.0 ?s (exec ?is1.0 ?s ?stk)
```

这条是**整章的关键**。没有它，归纳步骤里会出现一长串无法化简的 `@`。

两点值得学：

1. **`arbitrary: stk s`**：归纳时栈和状态在每一步都不同。不设为任意，归纳假设会被特化到某一个栈上，用不上。（第 6 章的 `itrev` 就是这个道理。）
2. **`split: instr.split`**：`exec` 的函数体里有个 `case i of …`，`simp` 不会自动拆它。要让 `auto` 对 `i` 的三种构造器分别处理，必须显式给 split 规则。

## 24.6 编译正确性

```isabelle
theorem exec_compile: "exec (compile a) s stk = aval a s # stk"
proof (induction a arbitrary: stk)
  case (N n)
  then show ?case by simp
next
  case (V x)
  then show ?case by simp
next
  case (Plus a1 a2)
  then show ?case by (simp add: exec_append add.commute)
qed
```

实测回显——三个分支各一条：

```text
show exec (compile (N n)) s stk = aval (N n) s # stk

show exec (compile (V x)) s stk = aval (V x) s # stk

show exec (compile (Plus a1 a2)) s stk = aval (Plus a1 a2) s # stk

theorem exec_compile: exec (compile ?a) ?s ?stk = aval ?a ?s # ?stk
```

三个分支各说一件事：常量就是压一个立即数、变量就是加载、加法则"先执行左段的编译结果，再在其上执行右段，最后 ADD"。

`add.commute` 出现在最后一步，是因为**栈是"反的"**：栈顶放着右子表达式的值，`hd (tl stk) + hd stk` 的顺序与 `a1 + a2` 相反，需要一次交换律。

这就是"编译器正确性定理"的完整形态：`exec (compile a) s stk = aval a s # stk`——**执行编译结果，等于把源语义的值压栈**。

## 24.7 一个常量折叠优化

正确性定理一旦立住，就可以拿它验证"改写源程序"是安全的：

```isabelle
fun optm :: "aexp \<Rightarrow> aexp" where
  "optm (N n) = N n"
| "optm (V x) = V x"
| "optm (Plus a1 a2) = (case (optm a1, optm a2) of
     (N m, N n) \<Rightarrow> N (m + n)
   | (b1, b2) \<Rightarrow> Plus b1 b2)"

lemma aval_optm: "aval (optm a) s = aval a s"
  apply (induction a)
    apply simp
   apply simp
  apply (auto split: aexp.split)
  done
```

```text
consts
  optm :: "aexp \<Rightarrow> aexp"

Found termination order: "size <*mlex*> {}"

theorem aval_optm: aval (optm ?a) ?s = aval ?a ?s

"Plus (N 3) (V ''x'')"
  :: "aexp"
```

`optm (Plus (Plus (N 1) (N 2)) (V ''x''))` 得 `Plus (N 3) (V ''x'')`——`1 + 2` 被折叠成 `3`。

注意 `aval_optm` 里又用了 `split: aexp.split`：`optm` 的函数体里 `case (optm a1, optm a2) of …` 需要拆，而且这里的 split 是对**对偶的两个分量**同时做，比 24.5 的单层 split 更重。

把优化和正确性定理串起来：

```isabelle
lemma optm_preserves_machine: "exec (compile (optm a)) s stk = exec (compile a) s stk"
  by (simp add: exec_compile aval_optm)
```

```text
theorem
  optm_preserves_machine:
    exec (compile (optm ?a)) ?s ?stk = exec (compile ?a) ?s ?stk
```

**这条证明只有一行**，因为两条已有定理把两边都化成了同一个东西：

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
exec (compile (optm a)) s stk  = aval (optm a) s # stk   (exec_compile)
                               = aval a s # stk          (aval_optm)
                               = exec (compile a) s stk  (exec_compile 反向)
```

这就是"先证结构引理"的回报：主定理一旦立住，推论几乎免费。

## 24.8 导出一台能跑的机器

```isabelle
export_code aval compile exec optm in SML module_name T24_Machine
```

```text
See theory exports
```

到这一步，这台机器已经不是一个比喻了：它是**可以编出来、可以跑、并且被证明过的东西**。

---

## 本书方法论（五条）

1. 先把对象语言写成 `datatype`，把语义写成 `fun`；
2. 先证**结构性质**（拼接、结合、交换），再证主定理；
3. 主定理用归纳，归纳变量但凡会变都写 `arbitrary:`；
4. 每个 `simp` 步骤问一句"它凭什么知道这个"；
5. 最后 `export_code`，让证明过的东西真的跑起来。

---

## 本章坑位清单（实测）

1. **`compile (Plus a1 a2)` 的顺序写反**：栈顶在左，必须先 `compile a2` 再 `compile a1`。写反了正确性定理证不出。
2. **归纳时忘了 `arbitrary: stk s`**：归纳假设被特化到某一个栈上，用不上。
3. **`case … of` 不拆**：`simp` 不自动拆 `case`，要给 `split: instr.split` / `aexp.split`。
4. **用模式匹配处理畸形栈**：会凭空引入 `undefined` 分支污染后续证明。用 `hd`/`tl` 更干净。
5. **`add.commute` 漏了**：栈是反的，最后一步需要交换律。
6. **先证主定理再证结构引理**：顺序反了会在归纳步里撞上一长串 `@`，卡死。
7. **优化器的正确性忘了串 `exec_compile`**：`aval_optm` 只说源语义不变，机器行为不变要靠 `exec_compile` 桥接。
8. **`export_code` 漏列常量**：要列全（`aval compile exec optm`），依赖自动带、入口不自动带。
9. **以为 `Found termination order` 是错误**：它是终止性自动通过的标志。
10. **把 `hd`/`tl` 当成"不安全"就回避**：在已证明正确的上下文里，它们反而比 `undefined` 分支更好证。

---

上一章：[23 · 工程实践与证明风格](23-engineering.md) ｜ 下一章：[25 · 类型类](25-classes.md) ｜ 返回：[README](../README.md)
