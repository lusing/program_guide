# 01 · 全景与工具链

## 1. Pascal 家族简史（五分钟版）

| 年代 | 事件 | 意义 |
|---|---|---|
| 1970 | Niklaus Wirth 发布 Pascal | 教学语言出身：强类型、结构化、"让编译器替你查错" |
| 1983 | Borland Turbo Pascal | 传奇开始：编译速度快到像解释器，Pascal 从教室走向工业 |
| 1995 | Delphi 1.0（Object Pascal + VCL） | 语言进化出类/接口/属性；RAD 三件套（拖控件/属性面板/事件）定型 |
| 2005 | Lazarus 项目成型 | 开源复刻 Delphi 体验：**LCL** 类库 + IDE + 跨平台控件集 |
| 今天 | FPC 3.2.2 / Lazarus 4.8 | 一份代码编 Win/macOS/Linux；语法稳如磐石，老代码三十年能编 |

**FPC（Free Pascal Compiler）** 是编译器，**Lazarus** 是 IDE + LCL 类库——关系如同
clang 与 Qt Creator（但 Lazarus 的 LCL 与 IDE 是一家人）。语言叫 **Object Pascal**
（Delphi 时代定名的面向对象 Pascal）。

## 2. 2026 年还该学它吗

该用的场合：

- **桌面小工具的性价比之王**：无运行时依赖的原生 exe（几百 KB～几 MB），启动即达，
  Windows/macOS/Linux 三平台一份代码。
- 维护存量：工业软件、医疗、测试工装里 Delphi/Lazarus 程序存量巨大。
- 教学：强类型 + 先声明后用 + 明确的内存模型，是理解"编译器在帮你什么"的好样本。

不该用的场合：Web 后端、移动端、需要丰富生态（AI/大数据）的领域——那里 Pascal
只是客人。

**与 Delphi 的关系**：FPC 高度兼容 Delphi 7～10 语法（方言开关 `-MDelphi`），LCL
复刻 VCL 的 API；商业差异（FireMonkey、官方支持）之外，会 FPC≈会半个 Delphi。

## 3. 方言模式：一份编译器，四种脾气

FPC 用 `-M` 开关切换语言方言（本教程全线 **objfpc**）：

| 模式 | 特征 | 适用 |
|---|---|---|
| `-MObjFPC`（本教程） | 泛型要 `generic/specialize`；事件赋值带 `@`；**地址运算符显式** | FPC 生态原生写法 |
| `-MDelphi` | 泛型内联不写 specialize；`@` 可省 | 移植 Delphi 代码 |
| `-MFPC` | 纯过程式（无类） | 复古教学 |
| `-MTP` | Turbo Pascal 兼容 | 守护 1990 年的代码 |

同一个程序换模式重编，行为差异点（本教程实测过的）：`@` 的必要性、泛型语法、
`Result` 可用性。单元内还可用 `{$MODE}` 指令逐单元指定。

## 4. 编译模型：先声明后用 + 单元两段式

- **单遍编译**：标识符必须先声明后使用——所以 var 在过程头、过程在 main 之前。
  好处：编译器全程序类型检查、错误信息直白；代价：互递归要 `forward`（05 章）。
- **单元编译**：`interface`（目录）+ `implementation`（实现），首次编译产出 `.ppu`
  （接口缓存）+ `.o`；单元没改就复用——增量编译的根基（09 章）。
- **无链接器仪式**：fpc 一条命令完成编译+链接；`-B` 强制全量重建（验证脚本用它
  保证干净）。

## 5. 工具链安装（Windows 本机布局）

本教程实测机器的布局（scoop 安装）：

| 组件 | 路径 | 说明 |
|---|---|---|
| Lazarus 4.8 | `G:\scoop\apps\lazarus\current\` | IDE + LCL + **自带完整 FPC** |
| FPC 3.2.2（主线） | `...\lazarus\current\fpc\3.2.2\bin\x86_64-win64\fpc.exe` | 与 lazbuild 同套 RTL/LCL——**本教程用它** |
| FPC 3.2.2（独立包） | `G:\scoop\apps\freepascal\current\bin\i386-win32\` | 只有 32 位目标（后备） |
| lazbuild | `...\lazarus\current\lazbuild.exe` | 命令行构建 .lpi 工程 |

新机器三选一：官方安装包（Lazarus 一体）、scoop（`scoop install lazarus`）、
fpcupdeluxe（自定义组件）。**装 Lazarus 就够了**——语言篇的 fpc 和 GUI 篇的
lazbuild 它全带。

> 实测坑（本仓库验证脚本踩过）：scoop 的独立 `freepascal` 包只有 i386 目标，
> PATH 里若它排在前面会**静默编出 32 位 exe**——工具链解析要"固定路径优先于 PATH"
> （`build.ps1`/`run-all.sh` 都按 环境变量 → 固定路径 → PATH 的顺序找）。

## 6. fpc 常用开关总览

```text
方言与语法
  -MObjFPC / -MDelphi / -MTP    方言模式（本教程全线 ObjFPC）
  -Sc                            支持 C 风格运算符赋值（+= *=，本教程默认开）
运行期检查（本教程"检查通道"全开）
  -Cr    范围检查（数组/子界/类型转换越界即崩）
  -Co    整数溢出检查
  -Ci    IO 检查（IOResult 之外再兜一层）
  -Sa    断言（{$C+}）—— Assert 真正编进代码
  -gh    heaptrc：泄漏/越界报告（走 stderr，零泄漏也打印——排查时手动加，不进验证通道）
优化与产物
  -O2   优化（发布通道）
  -B    全量重建（忽略 .ppu 缓存）
  -XX / -Xs    智能链接/去符号（减小 exe）
路径
  -FE<dir>   exe/单元产物目录（给绝对路径！相对路径按【源文件目录】解析——实测坑）
  -FU<dir>   .ppu/.o 输出目录
  -Fu<dir>   单元搜索路径（多文件工程让兄弟单元可寻）
  -o<file>   指定输出文件名
  -d<name>   定义条件符号（等价 {$DEFINE}）
```

本教程的验证通道组合（02 章起每个 CLI 示例都吃这套）：

```text
检查通道：-MObjFPC -Sc -Cr -Co -Ci -Sa -B    （全检查 + 断言 + 强制重建）
发布通道：-MObjFPC -Sc -O2                   （真实出货形态）
两通道输出必须逐字节一致，任何差异 = 程序有未定义行为的味道
```

## 7. 本教程的验证方法论（贯穿 23 个示例）

| 层 | 手段 | 覆盖 |
|---|---|---|
| 编译 | fpc 双通道 / lazbuild | 语法 + 警告零容忍 |
| 运行 | exit 0 + stderr 空 + 无控制字符 + 结束标记 | 程序真跑通了 |
| 断言 | 检查通道 `-Sa` 下的 Assert / GUI 的 uchecks | 关键路径数值正确 |
| 一致性 | 双通道输出 SHA256 对比 / GUI selftest 日志 | 检查开关不影响语义 |
| 无头 GUI | `--selftest` 分支：建窗体不显示 → 跑逻辑 → 写日志 | GUI 程序也能 CI |

这套方法论本身就是教程内容——把 `build.ps1 -All`（一条命令回归全部 23 个示例）
搬走，你的下一个项目就有 CI 了。

## 8. 学习路线

- **语言篇（02–14）**：顺序读。每章"读讲解 → 跑示例 → 改代码再跑"。
- **GUI 篇（15–23）**：15 是地基（工程三件套/事件模型），16–23 每章一组控件/主题。
- **实战（24）**：记事本+ 串起全部——建议跟着源码逐节读，selftest 的 29 条断言
  就是功能清单。
- **速查**：`CHEATSheet.md`——语法速查 + 全部实测坑位索引（每章"坑位清单"的汇总）。

## 9. 坑位清单（工具链实测）

1. 两个 FPC 并存（i386 独立包 / Lazarus 自带 x86_64）——解析顺序错了静默编 32 位。
2. `-FE/-FU/-o` 相对路径按**源文件目录**解析，不是当前目录——一律给绝对路径。
3. `%FPVERSION%` 不存在（正确 `%FPCVERSION%`），展开为空还不报错；平台串是驼峰
   `Win64`（`-iTO` 打印小写 `win64`）。
4. Git Bash 传参给 fpc/lazbuild：`cygpath -m` + `MSYS2_ARG_CONV_EXCL='*'`，
   否则 `-FEG:/...` 内嵌路径被 MSYS 改写成 Git 安装目录下的路径。
5. `-gh` 报告走 stderr 且零泄漏也打印——别混进"stderr 必须为空"的判定。

---
下一章：[02 第一个程序](02-hello.md) ｜ 返回：[README](../README.md)
