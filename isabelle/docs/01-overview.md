# 01 · 开场：机器当裁判

对应示例：`../examples/T01_overview.thy`

## 1.1 这是一本"机器当裁判"的教程

其他语言的教程里，示例"跑出正确输出"就算过。Isabelle/HOL 不一样：示例里的**每一条 `lemma` 都必须被内核逐条认可**，整个会话构建通过，示例才算活着。你写的不是"能跑的程序"，而是"被检查过的数学文本"。

这带来一个本教程坚持的纪律：**正文里出现的每一段输出，都是从 `build/` 产物里抽出来的实测字节**，不是想象中的样子。你在自己机器上重跑 `./run-all.sh`，得到的东西应当逐字节一致。

两个命令要记住：

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
isabelle build -D examples              # 全量构建：证明/类型错误在此暴露
isabelle process_theories -O ...        # 捕获每个示例的输出消息
```

至于交互开发，标准答案是 **Isabelle/jEdit**（随发行版自带，`isabelle jedit`）。它逐命令高亮、侧栏实时显示证明状态，是唯一能"边写边看目标"的官方前端。VSCode 也有官方扩展，但教程类文本以 jEdit 为准。

## 1.2 环境自检

先确认自己在哪个 Isabelle 里跑。下面这段输出直接来自 ML 端的 `getenv`（实测）：

```text
Isabelle 版本标识: Isabelle2025-2
```

本机工具链（写在 `run-all.sh` 顶部，换了环境要重新确认）：

| 项 | 值 |
|---|---|
| 发行版 | Isabelle2025-2 |
| 可执行文件 | `/Applications/Isabelle2025-2.app/bin/isabelle` |
| ML 系统 | polyml-5.9.2，`x86_64_32-darwin` |
| 会话 | `IsaTut`（见 `../examples/ROOT`） |

发行版自带预编译好的 `Pure` 与 `HOL` 堆镜像，所以第一次 `build` 不需要从源码重建 HOL——这也是为什么全量验证能在 1 分钟内跑完。

## 1.3 计算：先看看求值器长什么样

`value` 用代码生成器求值，打印**结果与类型**：

```text
"7"
  :: "nat"
```

```text
"[3, 2, 1]"
  :: "nat list"
```

```text
"[1, 4, 9]"
  :: "int list"
```

三条分别对应 `(1::nat) + 2 * 3`、`rev [1::nat, 2, 3]`、`map (λn. n * n) [1::int, 2, 3]`。注意三点：

1. 结果外面有**引号**——打印的是该项的源码形式，不是"值"；
2. `::` 后面一定跟着**类型**，因为同一个写法在不同类型下结果不同；
3. 每个数字字面量都写了标注（`1::nat`）。这不是啰嗦，见 1.4。

## 1.4 证明：第一条被机器认可的定理

```isabelle
lemma first_proof: "1 + 1 = (2::nat)"
  by simp
```

`by simp` 的意思是"交给化简器，证完为止"。证完之后它进了理论的事实库，可以按名字取用（实测）：

```text
theorem first_proof: 1 + 1 = 2
```

第二条用 `blast`（一阶自动推理）：

```isabelle
lemma and_swap: "A \<and> B \<longleftrightarrow> B \<and> A"
  by blast
```

```text
theorem and_swap: (?A \<and> ?B) = (?B \<and> ?A)
```

这里必须立刻说清一件会让所有新手卡住的事：**输出里的 `\<and>` 不是笔误，是 ASCII 转义**。Isabelle 的词法层自己做符号替换，源码保 ASCII 才能让任何编码环境下的字节完全一致——这也是本教程能"逐字节比对两次运行"的前提。

实测把边界画清楚（这三条是本教程自己踩出来的，不是抄文档）：

| 写法 | 位置 | 结果 |
|---|---|---|
| `text ‹…›`、`lemma ‹…›` | 字面 cartouche **分隔符** | ✗ `Malformed command syntax` |
| `lemma "∀x. x ∈ A ⟶ x ∈ B"` | 字面符号在**项**里 | ✗ `Inner lexical error … Failed to parse prop` |
| `text \<open>… ∀ …\<close>` | 字面符号在**散文**里 | ✓ 能过（纯文本，不进内语法） |

所以硬规则只有两条：**分隔符一律写 `\<open>` `\<close>`；项里一律写 `\<forall>` `\<in>` `\<longrightarrow>`**。散文里写字面符号虽能过，但整个发行版的 1467 个 `.thy` 里一个字面符号都没有（实测扫描），跟着写转义最省心。

用 ML 把定理拿出来打印，是后续章节观察规则的通用手段（实测）：

```text
"(?A \<and> ?B) = (?B \<and> ?A)"
```

注意 `?A` `?B`：它们是**元变量**（scheme 变量），表示"这条定理对任意命题 A、B 都成立"。

## 1.5 本教程的验证方式

根目录的 `run-all.sh` 做四件事：

1. `isabelle build -D examples` 全量构建，退出码 0 且日志无溃逃痕迹；
2. `isabelle process_theories -O` 捕获每个示例的标记区间（示例里用 `ML` 打印 `==== NN 开始 ====` / `==== NN 结束 ====`）；
3. 同一命令连跑两遍；
4. 逐字节比对两遍输出。

第 4 步值得解释：其他语言项目可以拿两个引擎（或两种二进制）互相比对，**Isabelle 只有一个引擎**，没有"跨通道一致性"可比。于是用"运行间确定性"替代——如果两次运行的输出不一样，说明示例偷偷依赖了并行调度、随机源或环境状态，那本身就是 bug。

实测这一步抓到过真问题：默认开启 `parallel_print` 时，24 个示例里有 12 个两次运行的消息顺序不同。关掉并行打印（`run-all.sh` 里那三个 `-o`）之后，唯一剩下的差异是末尾那行 `Finished Draft (... cpu time, factor 0.51)` 的耗时数字，而它在标记区间之外。

---

## 本章坑位清单（实测）

1. **字面写 Unicode**：源文件里出现 `‹ › ∀ ∧ →`，报 `Malformed command syntax` 或 `Inner lexical error`。一律写 `\<open>` `\<close>` `\<forall>` `\<and>` `\<longrightarrow>`。
2. **`@{verbatim xxx}` 忘了加引号**：报 `Bad arguments for document antiquotation`。必须写 `@{verbatim "xxx"}`。
3. **`isabelle process` 不是命令**：Isabelle2025 里叫 `process_theories`；`isabelle help` 也不存在，直接裸跑 `isabelle` 看工具列表。
4. **build 报 `[SQLITE_ERROR] cannot commit` / `[SQLITE_IOERR_DELETE]`**：构建库是 SQLite，写库时要 `unlink` 掉 `-journal` 文件。本机在 `~/` 下对未签名二进制的 `unlink` 会返回 EPERM（macOS 实测），所以脚本把 `ISABELLE_HOME_USER` 指到 `/tmp` 下绕开，并在开跑前清掉上次留下的半截 journal。
5. **改 `ISABELLE_HEAPS` 没用**：`etc/settings` 里写的是 `ISABELLE_HEAPS="$ISABELLE_HOME_USER/heaps"`，直接设会被覆盖。要改就改 `ISABELLE_HOME_USER`。
6. **数字字面量不写类型标注**：报 `Wellsortedness error`，不是语法错误而是"不知道放哪个类型"。算术表达式永远写 `(1::nat)`。
7. **`real` 不在 `Main` 里**：要用实数得 `imports Complex_Main`。很多教程直接写 `imports Main` 然后奇怪类型找不到。
8. **`@{const length}` 报 `Not a logical constant`**：`length` 只是 `Nat.size_class.size` 的缩写记号，不是独立常量。用 `@{term "length"}`。
9. **把量化命题交给 `value`**：`value` 只会算，枚举不了无穷域（集合概括还会报 `Type nat not of sort enum`）。量化公式是 `blast` 的领地。
10. **`\<open>` `\<close>` 不配对**：多写一个 `\<close>` 会让后面所有命令失认，报错地点却在几十行之后。看到 `At command "<malformed>"` 就往上找没配对的引号。

---

下一章：[02 · 第一个理论](02-first-theory.md) ｜ 返回：[README](../README.md)
