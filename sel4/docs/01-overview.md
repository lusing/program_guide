# 01 · 开场：seL4 是"被证明过的内核"

对应示例：`../examples/S01_overview.thy`

## 1.1 seL4 是"被证明过的内核"

seL4 是这个教程里唯一一个"结论不由作者宣布、而由机器检查出来"的对象。
真实代码分两个仓库（本教程所有引用都指向它们，`run-all.sh` 第 5 关会逐个校验路径存在）：

| 仓库 | 内容 |
|---|---|
| `l4v/` | Isabelle/HOL 写的规范与证明：抽象规范、设计规范、C 规范、安全定理 |
| `seL4/` | 真正跑在机器上的 C 内核、`libsel4` 头文件、manual |

它们的关系是**精化**：抽象规范说"内核该做什么"，设计规范是可执行原型，
C 规范由 `seL4/` 的 C 源码翻译而来，最后还有汇编层。
每一层都要证明"我这一层的每一步，都对应上一层的某一步"。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
l4v/spec/abstract/   ← 抽象规范（Structures_A.thy、CSpace_A.thy …）
l4v/spec/cspec/      ← 由 seL4/ 的 C 翻译出的规范
l4v/proof/           ← 不变式、精化、访问控制、信息流、汇编精化
seL4/src/            ← C 内核实现（object/、api/、kernel/）
seL4/libsel4/include/sel4/  ← 用户可见的 API 与错误码
```

## 1.2 环境自检

示例先确认自己在哪个 Isabelle 里跑（实测输出）：

```text
Isabelle 版本标识: Isabelle2025-2
```

| 项 | 值 |
|---|---|
| 发行版 | Isabelle2025-2 |
| 可执行文件（macOS） | `/Applications/Isabelle2025-2.app/bin/isabelle` |
| 会话 | `SeL4Tut`（见 `../examples/ROOT`，父会话 **`HOL-Library`**） |
| 真实代码根 | `/Volumes/mac004/lang/seL4`（`SE4SRC=…` 可覆盖） |

父会话为什么是 `HOL-Library` 而不是 `HOL`：第 07、08 章要用 do 记号，
得 import `HOL-Library.Monad_Syntax`。这一处改动会一路影响到验证脚本（见坑位 6）。

## 1.3 最小的能力模型：权利的集合

seL4 的全部访问控制归结到一个动作：**取交集**。
给能力派生出去时，新能力的权利 = 老权利 ∩ 请求的权利。
所以"越权"在数学上不可能——交集不会比两边大。

真实定义见 `l4v/spec/abstract/CapRights_A.thy` 的 `mask_cap`
与 `l4v/spec/abstract/Structures_A.thy` 的 `all_rights`。

## 1.4 第一条定理：掩码不会让权利变多

```text
theorem mask_subset: S01_overview.mask ?R ?R' \<subseteq> ?R
```

```text
theorem mask_all_rights: S01_overview.mask ?R all_rights = ?R
```

两条分别是：掩码只会缩小；拿"全部权利"去掩码等于没掩码。
这条"只减不增"的性质，会在第 03 章（掩码）、第 05 章（派生）、
第 21 章（完整性）以不同抽象层次被重复证明三次。

求值器还会把结果与类型一起打印（实测）：

```text
"4"
  :: "nat"
```

注意类型总是跟着结果一起出现——seL4 的证明里大量使用机器字，
"这个数字是什么类型"几乎每次都要明确。

## 1.5 本教程的验证方式

根目录 `run-all.sh` 做五件事：

1. `isabelle build -D examples` 全量构建，退出码 0 且日志无溃逃痕迹；
2. `isabelle process_theories -O` 捕获每个示例的标记区间（示例里用 `ML` 打印 `==== NN 开始 ====` / `==== NN 结束 ====`）；
3. 同一命令连跑两遍；
4. 逐字节比对两遍输出；
5. 检查文档里出现的每个 `seL4/…` 与 `l4v/…` 路径在真实代码根下存在。

第 4 步的理由：Isabelle 只有一个引擎，没有"跨通道一致性"可比，
于是用"运行间确定性"替代。如果两遍输出不一样，说明示例偷偷依赖了并行调度或环境状态——那本身就是 bug。

---

## 本章坑位清单（实测）

1. **字面写 Unicode**：源文件里出现 `‹ › ∀ ∧ →`，报 `Malformed command syntax` 或 `Inner lexical error`。一律写 `\<open>` `\<close>` `\<forall>` `\<and>` `\<longrightarrow>`。
2. **`@{verbatim xxx}` 忘了加引号**：报 `Bad arguments for document antiquotation`。必须写 `@{verbatim "xxx"}`。
3. **常量名不能用 `ALL EX SUM PROD INT UN INF SUP`**：这 8 个全大写词会被整词替换成符号。
4. **build 报 `[SQLITE_ERROR] cannot commit` / `[SQLITE_IOERR_DELETE]`**：构建库是 SQLite，macOS 上对 `~/` 下未签名二进制的 `unlink` 返回 EPERM，删不掉 `-journal` 就崩。脚本把 `USER_HOME` 指到 `/tmp` 下绕开。
5. **直接改 `ISABELLE_HOME_USER` / `ISABELLE_HEAPS` 无效**：`etc/settings` 里是无条件赋值；唯一能改的是 `USER_HOME`（只在为空时才被赋值）。
6. **`process_theories -l HOL` 会因 import `HOL-Library` 失败**：报 `Bad import … need to include sessions "HOL-Library" in ROOT`，而且 **run.log 是空的、错误只进 stderr**——表现为"每个示例的区间都为空"，很容易误判成示例没输出。基线会话必须写 `-l HOL-Library`。
7. **两遍比对必须关并行**：`parallel_print=false`、`parallel_proofs=0`、`threads=1` 三个 `-o` 缺一个，消息就会在两遍里落到不同位置。
8. **控制字符检查要用 `[[:cntrl:]]`**：写成 `[^[:print:][:space:]]` 时，`LC_ALL=C` 下中文标记的 UTF-8 字节（≥0x80）不在 `[:print:]` 里，24/24 全误报。
9. **溃逃判据裸搜 `Error` 会误报**：seL4 的词汇里 `throwError` / `DError` / `seL4_Error` 是正常标识符，S08 与 S10 会被恒判为"含溃逃痕迹"。必须锚定横幅形状。
10. **引用真实代码不能凭记忆**：文档里的每个路径都要 `test -e` 校验（第 5 关自动做）。

---

下一章：[02 · 内核对象与能力](02-kernel-objects.md) ｜ 返回：[README](../README.md)
