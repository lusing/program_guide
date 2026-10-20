# Emacs 教程

三套互补的 Emacs 教程，都基于 **GNU Emacs 31.1**，内容自包含，所有键位/命令/默认值都经本机实测。

## 教程列表

### [使用 Emacs 教程](docs/using-emacs/README.md)

教你**怎么用** Emacs：从启动、看懂屏幕、基本编辑，到文件/窗口管理、搜索替换、Dired、键盘宏、Shell、定制、安装包……25 章，覆盖日常使用的方方面面。

- 适合：想用 Emacs 做编辑/编程的人
- 不需要会 Elisp
- 内容提炼自 GNU Emacs 官方手册（31.1）

### [CC Mode 教程](docs/cc-mode/README.md)

教你**怎么用和怎么配** Emacs 自带的 CC Mode（编辑 C/C++/Objective-C/Java/IDL/Pike/AWK 的同一套 mode 家族）：缩进引擎与 syntactic context、`c-offsets-alist`、风格系统、日常命令、电键与 auto-newline、注释填充与多行宏、字体化、性能与 FAQ……9 章。

- 适合：用 Emacs 写 C 系语言、想搞懂「为什么这么缩进」并配出自己的风格的人
- 不需要会写扩展（写扩展看下面的扩展开发指南）
- 内容提炼自 GNU《CC Mode Manual》5.35，全部在 Emacs 31.1 + CC Mode 5.35.2 实测；原书与实现的版本漂移点正文当场注明

### [Emacs 扩展开发指南](docs/extending-emacs/README.md)

教你**怎么写** Emacs 扩展（Elisp 编程）：语言基础、buffer/point/keymap/hook 等核心对象、mode 机制、进程/定时器、宏、测试、打包、eintr 精读、参考手册补遗、CL 手册（cl-lib）……49 章 + 2 附录，配套 48 个可运行示例。

- 适合：想给 Emacs 写扩展/插件的人
- 需要一定编程基础
- 每个示例都在 `emacs -Q --batch` 下真跑，输出逐字节核验

## 目录结构

```text
emacs/
├── README.md                     本文件（hub）
├── docs/
│   ├── using-emacs/              《使用 Emacs》教程（25 章）
│   │   ├── README.md
│   │   ├── 00-before-you-start.md
│   │   ├── ...
│   │   └── 24-cheatsheet.md
│   ├── cc-mode/                  《CC Mode》教程（9 章）
│   │   ├── README.md
│   │   ├── 00-overview-and-activation.md
│   │   ├── ...
│   │   └── 08-customization-performance.md
│   └── extending-emacs/          《扩展开发指南》（49 章 + 2 附录）
│       ├── README.md
│       ├── 00-setup.md
│       ├── ...
│       ├── 48-types-structs.md
│       ├── appendix-a-pitfalls.md
│       └── appendix-b-cheatsheet.md
├── examples/                     扩展教程的配套示例（48 个 .el 文件）
│   ├── 01-hello.el
│   ├── ...
│   └── 48-types-structs.el
├── tools/
│   └── check_docs.py             文档结构核查脚本（覆盖三套教程）
├── run-all.sh                    批量验证示例（bash）
└── build.ps1                     批量验证示例（PowerShell）
```

## 工具链

| 项 | 值 |
|---|---|
| Emacs | GNU Emacs 31.1（`/opt/local/bin/emacs`，macOS MacPorts） |
| 依赖的库 | 只用内置库：`seq`、`cl-lib`、`ert`、`package` |
| 本机版本 | `emacs --version` 核对；示例应能在 Emacs 27+ 上运行 |

## 验证示例（扩展教程）

```bash
# bash 入口
./run-all.sh                  # 验证 examples/ 下全部 48 个示例
./run-all.sh 07-lists         # 只验证一个
./run-all.sh -Keep            # 验证并保留 build/ 里的产物
```

```powershell
# PowerShell 入口
.\build.ps1 -All              # 验证全部示例
.\build.ps1 -File 07-lists    # 验证单个
```

## 核查文档结构

```bash
python3 tools/check_docs.py           # 核查三套教程的结构完整性
python3 tools/check_docs.py --mutate  # 自检：故意改坏一个文件，确认能检出
```

## 说明

- 三套教程都只依赖 Emacs 内置功能，不需要任何第三方包。
- 扩展教程的示例不读用户配置（`-Q`），输出可复现。
- 所有键位/命令/默认值都以 Emacs 31.1 为准，遇到版本差异会在正文里注明。
