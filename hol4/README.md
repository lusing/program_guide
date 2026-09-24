# HOL4 教程

> 基于 `/Volumes/mac004/lang/hol`（HOL4 源码与手册）写的一套 24 章教程，
> 全部示例在 macOS 上跑通，输出**逐字节可复现**。

HOL4 是一个**LCF 风格的定理证明器**：证明不是文本，而是由一小撮内核规则
构造出来的 ML 值。这意味着两件事 —— 你写的每个"证明步骤"都要经过内核检查，
而你能写的东西又完全取决于手边有哪些 ML 函数。本教程就是围绕这两件事展开的。

- 定位：从"环境能不能跑"到"一个编译器正确性证明"，24 章一条线。
- 纪律：**正文里引用的每一段输出都来自 `build/` 里的实测产物**，不写想象中的输出。
- 规模：24 章正文 / 24 个示例 / **240 条坑位** / 每章 5 项验证判据共 **120 项**。

## 目录结构

```text
hol4/
  docs/          24 章正文（01-overview … 24-capstone）
  examples/      NN_topic/NN_topic.sml（章号 = 目录号）
  run-all.sh     验证入口（bash）
  build.ps1      验证入口（PowerShell，判定与 shell 版逐项一致）
  check-quotes.py  源码卫生：SML 字符串里的 ASCII 双引号
  check-docs.py    文档机器核查：节号 / 引用输出 / 导航链 / 坑位数
  CHEATSheet.md  语法速查 + 坑位索引 + 安全子集 + 刻意回避清单
  README.md      本文件
  build/         验证产物（可删，./run-all.sh clean 只清自己写的子目录）
```

## 工具链

| 项目 | 值 |
|---|---|
| HOL4 版本 | **Trindemossen 2**（`Globals.version = 2`，是个 `int`） |
| Poly/ML | 5.9.2（MacPorts） |
| `hol` 位置 | `/Volumes/mac004/lang/hol4-build/bin/hol`（脚本自动探测，不硬编码） |
| 上游源码 | `/Volumes/mac004/lang/hol`（用户仓库，CRLF） |

**为什么是 `hol4-build` 而不是直接用 `/Volumes/mac004/lang/hol`**：上游工作副本
整棵树是 CRLF（7533 个文件），`ml-yacc`（`.grm`）和 mlton 会在上面翻车。
`hol4-build` 是转过 LF 的一份克隆，构建方式：

```bash
# 1. LF 克隆
# 2. tools-poly/poly-includes.ML 里写上  val MLTON = NONE;
# 3. poly < tools/smart-configure.sml
# 4. bin/build -F
```

脚本用 `HOLBIN=/path/to/hol` 可以覆盖探测结果。

## 验证

两条入口，判定逐项一致：

```bash
./run-all.sh                 # 全量：24 章 × 5 项 = 120 项
./run-all.sh 13              # 只跑一章
TMO=60 ./run-all.sh          # 看门狗秒数（默认 120）
./run-all.sh clean           # 清 build/ 下各章子目录

pwsh -NoProfile -Command '& ./build.ps1 -All'
pwsh -NoProfile -Command '& ./build.ps1 -Only 13'
pwsh -NoProfile -Command '& ./build.ps1 -Clean'
```

三条通道：`run1` / `run2`（两条独立的 `hol run`）、`hm`（`Holmake`）。
每条通道过 1–5，跨通道再过 6–7：

1. 退出码 0
2. stderr 为空
3. 开始 / 结束两个标记各**恰好出现一次**（整行严格相等）
4. 标记区间非空，且不含 `[[:cntrl:]]` 控制字符
5. 区间无溃逃痕迹（组合判据，见下）
6. `run1` 与 `run2` 的区间逐字节一致（运行间确定性）
7. `run1` 与 `hm` 的区间逐字节一致（两条独立入口一致）

三个设计点值得单独说：

- **为什么必须有看门狗**：`metis_tac` / `rw` 被喂进方向不对称的定理时可能
  **不终止**（本教程写作时实测踩到）。进程还在跑、只是永远跑不完，
  退出码判据完全失效。看门狗把它变成可诊断的失败。
- **为什么标记要"各恰好出现一次"**：第 23 章正文为了讲解，把
  `==== 23 结束 ====` 原样印进了输出；区间抽取当时是子串匹配，
  于是把"讲解"当成了真的结束标记，98 行的区间被截成 45 行 ——
  而"区间非空""两条通道一致"**照样全绿**，丢掉的半章没人发现。
- **为什么溃逃判据要锚定行首**：同一章正文还印了 `Static Errors` /
  `Uncaught exception` / `: error:`，裸的子串匹配把"讲解"当成了"痕迹"，
  三条通道全红而脚本其实没毛病。改完必须**反向验证**还能抓真错
  （`bad.sml:4: error: …` 那种）。

**当前状态：通过 120，失败 0。**

## 机器核查

```bash
python3 check-quotes.py            # SML 字符串里的 ASCII 双引号（--fix 自动改「」）
python3 check-docs.py              # 文档机器核查（--verbose 看每条比对）
```

`check-docs.py` 查四件事：

1. **节号对应** —— `docs/NN-x.md` 的 `## NN.M 标题` 必须与示例里
   `sec "NN.M 标题"` 一一对应（顺序 + 文字）。标题里的反引号在比对前去掉。
2. **引用输出** —— ```text 块里的每一行都要能在 `build/NN_x/run1.sec` 里
   **逐字节**找到。不参与比对的块（示意、离线复现的报错文本）要在紧邻上一行
   写 `<!-- 示意 … -->` **显式标注**。
3. **导航链** —— 首章只有"下一章"、末章只有"上一章"、其余两章都有，
   且指向相邻章、文件真实存在。
4. **坑位数** —— 每章 `## NN.M 坑位清单` 恰好 10 条且是本章最后一节；
   24 章之和（**240**）必须等于 CHEATSheet.md 与 README.md 里引用的数字。

两个脚本都修过"假绿"：`check-quotes.py` 原来传文件列表时一个文件都没扫却报
"检查通过"；`build.ps1` 原来 `-Filter '[0-9]*'` 匹配不到任何目录，
整轮被跳过却报"通过 0，失败 0"。现在两者都在"什么都没收到"时直接报错退出。

## 章节索引

| 章 | 主题 | 一句话 |
|---|---|---|
| [01](docs/01-overview.md) | 概览与环境自检 | 定理是 ML 值；最小闭环长什么样 |
| [02](docs/02-terms.md) | 项与引号 | ``` ``t`` ``` vs `` `p` `` vs `` `:T` `` |
| [03](docs/03-ml.md) | ML 那半边 | 值绑定、模式匹配、异常、组合子 |
| [04](docs/04-kernel.md) | 内核十条规则 | 定理只能由这些规则造出来 |
| [05](docs/05-datatype.md) | 数据类型 | `Datatype` 送的四件赠品 |
| [06](docs/06-recursion.md) | 递归定义 | 结构递归、良基递归、终止性 |
| [07](docs/07-induction.md) | 归纳 | 归纳假设不够强时怎么泛化 |
| [08](docs/08-simp.md) | 化简器 | `simp` / `rw` / `fs` / `gs` / `gvs` 的残余对比 |
| [09](docs/09-tactics.md) | 基本战术与目标栈 | `g` / `e` / `p` / `drop` / `top_thm` |
| [10](docs/10-tacticals.md) | 战术算子 | `THEN` / `THENL` / `ORELSE` / `ALLGOALS` |
| [11](docs/11-conv.md) | 转换 | `conv : term -> thm`，深度与定位 |
| [12](docs/12-arith.md) | 算术 | Peano、`num` 的坑、Presburger 判定 |
| [13](docs/13-lists.md) | 列表 | `listTheory` 常用函数与三个证明 |
| [14](docs/14-quantifiers.md) | 量词与一阶自动化 | `simp` 与 `metis` 的分工 |
| [15](docs/15-sets.md) | 集合与谓词 | `α set` 就是 `α -> bool` |
| [16](docs/16-relations.md) | 关系与闭包 | `RTC` / `TC` / `WF` / 良基递归 |
| [17](docs/17-inddef.md) | 归纳定义 | `Hol_reln` 的四条赠品 |
| [18](docs/18-records.md) | 记录类型 | `with` 不是赋值 |
| [19](docs/19-types.md) | 类型与类型缩写 | 拆类型、参数化、多态记录 |
| [20](docs/20-simpset.md) | 化简器与 simpset | 重写 / cong / 定向三件事 |
| [21](docs/21-automation.md) | 自动化工具箱 | 四台机器各自认哪些符号 |
| [22](docs/22-theories.md) | 理论与数据库 | 四条登记通道、四种查法、Holmake 缓存 |
| [23](docs/23-engineering.md) | 脚本工程 | 七条判据与两个真实的验证脚本 bug |
| [24](docs/24-capstone.md) | 综合练习 | 表达式语言 → 栈机 → 编译器 → 正确性 |

## 免责

- 本教程的示例是**教学用的最小模型**，不是 HOL4 标准库的一部分，
  也不追求工业级强度（比如 24 章的 `IAdd` 在栈下溢时行为未指定）。
- 引用的"定理形状""打印结果"以本机实测为准，随 HOL4 版本可能变化。
- 想看某条结论是怎么跑出来的，去 `build/NN_topic/run1.sec` 找原文。
