# Emacs 扩展开发指南

Emacs Lisp（Elisp）扩展开发教程与可运行示例。26 个示例覆盖从语言基础到写出一个完整扩展的全程，
每个示例都在 `emacs -Q --batch` 下**真跑**，并逐字节核验输出。

## 目录结构

```text
emacs/
├── README.md                  本文件
├── Emacs扩展开发指南.md         教程正文（27 章 + 2 个附录）
├── run-all.sh                 批量验证入口（macOS / Linux / bash）
├── build.ps1                  批量验证入口（Windows / PowerShell，跨平台也能跑）
├── examples/                  NN-topic.el，两位编号 + 主题
│   ├── 01-hello.el
│   ├── 02-types.el
│   ├── ...
│   └── 26-todo-demo.el
└── build/                     验证产物（不入库）
```

## 工具链

| 项 | 值 |
|---|---|
| Emacs | GNU Emacs 31.1（`/opt/local/bin/emacs`，macOS MacPorts） |
| 依赖的库 | 只用内置库：`seq`、`cl-lib`、`ert`、`package` |
| 本机版本 | `emacs --version` 核对；示例应能在 Emacs 27+ 上运行 |

`run-all.sh` 会依次尝试 `/opt/local/bin/emacs`、`/usr/local/bin/emacs`、
`/Applications/Emacs.app/Contents/MacOS/Emacs`、`PATH` 里的 `emacs`。
`build.ps1` 会按平台尝试 scoop / MacPorts / 官方 app bundle 的常见路径，
也可以用 `-Emacs <path>` 或环境变量 `EMACS` 显式指定。

## 编译 / 验证

```bash
# bash 入口
./run-all.sh                  # 验证 examples/ 下全部 26 个示例
./run-all.sh 07-lists         # 只验证一个（可给多个）
./run-all.sh -Keep            # 验证并保留 build/ 里的产物
./run-all.sh -Clean           # 清理 build/
```

```powershell
# PowerShell 入口（Windows 原生；macOS/Linux 装了 pwsh 也能跑）
.\build.ps1 -All              # 验证全部示例
.\build.ps1 -File 07-lists    # 验证单个（可省略 .el）
.\build.ps1 -All -Keep        # 保留产物
.\build.ps1 -Clean            # 清理
```

两个入口的判定标准**完全一致**，输出格式也一致。

## 判定标准（四条，缺一不可）

1. **字节编译退出码为 0**
2. **编译时 stderr 为空** —— 字节编译的警告也走 stderr，所以这条等价于「零警告」
3. **运行退出码为 0，且运行 stderr 为空**
4. **stdout 里没有多余控制字符**（0..31，TAB/LF/CR 除外），
   **且有结束标记** `==== NN 结束 ====`（NN 与文件名前缀一致）

几条标准都是真的会拦住东西的，不是摆设：

- 第 2 条的由来：`byte-compile-file` 遇到 free variable / 未使用参数时**退出码仍是 0**，
  只往 stderr 写警告 —— 不查 stderr 就等于放弃了「干净」这个要求。
- 第 4 条里「控制字符」的由来：`%S` 打印键序列（`(kbd "C-c x")` → 含原始 `0x03`）
  或 advice 对象（`advice-member-p` 返回的对象含字节码）时，会把裸字节写进输出。
- 结束标记的由来：兜住「代码被静默截断」—— 某个 `error` 让 Emacs 提前退出时，
  输出仍然完整，只有标记会缺失。

## Elisp 特有的一条约定：**输出用 `princ`，不用 `message`**

batch 模式下 `princ` 走 stdout，而 `message` 走 **stderr**（交互模式里它是往 echo area 写 UI 文本）。
所以所有示例统一写成：

```elisp
(princ (format "结果 %S\n" 某个对象))
```

`princ` 不加引号不加换行，换行和格式化交给 `format`。

## 各章索引

教程正文每一章对应一个示例文件。

| 章 | 主题 | 示例 |
|---|---|---|
| 0 | 环境、batch 模式、验证标准 | — |
| 1 | 第一个程序：输出与 quote | `01-hello.el` |
| 2 | 类型与值 | `02-types.el` |
| 3 | 变量与绑定（含 special vs 词法） | `03-variables.el` |
| 4 | 函数 | `04-functions.el` |
| 5 | 控制流 | `05-control-flow.el` |
| 6 | 相等性 `eq` / `eql` / `=` / `equal` | `06-equality.el` |
| 7 | 列表与关联结构 | `07-lists.el` |
| 8 | 字符串与正则 | `08-strings-regexp.el` |
| 9 | 序列与 `cl-lib` | `09-sequences.el` |
| 10 | buffer 与 point | `10-buffers.el` |
| 11 | 文本属性与 overlay | `11-text-properties.el` |
| 12 | 文件与目录 | `12-files.el` |
| 13 | 交互式命令 | `13-interactive.el` |
| 14 | keymap 与按键绑定 | `14-keymaps.el` |
| 15 | minor mode | `15-minor-mode.el` |
| 16 | major mode | `16-major-mode.el` |
| 17 | hook | `17-hooks.el` |
| 18 | 可定制选项 `defcustom` | `18-custom.el` |
| 19 | advice | `19-advice.el` |
| 20 | 子进程 | `20-processes.el` |
| 21 | 定时器 | `21-timers.el` |
| 22 | 错误处理 | `22-errors.el` |
| 23 | 宏 | `23-macros.el` |
| 24 | 模块、加载与打包 | `24-packages.el` |
| 25 | 测试（ERT） | `25-tests.el` |
| 26 | 完整示例：一个 todo 扩展 | `26-todo-demo.el` |
| 附录 A | 常见坑速查（按症状查） | — |
| 附录 B | 命令与变量速查 | — |

## 示例文件约定

每个 `examples/NN-topic.el` 结构固定：

```elisp
;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; NN - 主题
;;;   本示例重点
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "NN-topic.el")'
;;; 运行：emacs -Q --batch -l NN-topic.el
;;; ============================================================

;;; 1) 第一节
;;; 2) 第二节
...

(princ "==== NN 结束 ====\n")
```

- 第一行的 `lexical-binding: t` **不能省**（否则退回动态作用域，语义完全不同）；
- 正文按 `;;; 1) 2) 3)` 分节，与教程正文的讲解编号对应；
- 最后一行固定打印结束标记。

## 当前状态

- **26 个示例全部通过**，`run-all.sh` 与 `build.ps1` 两个入口结果一致（Emacs 31.1，2026-09-16）。
- 教程正文（`Emacs扩展开发指南.md`）已按这套示例重写：27 章 + 2 个附录，
  文中引用的输出都是实际运行结果。
- 判定标准已用反向用例验证过：缺结束标记、stderr 非空、含控制字符三种情况两个入口都能正确报 FAIL。

## 说明

- 只使用 Emacs 内置库，不依赖任何第三方包，因此不需要 `package-install`。
- 示例不读用户配置（`-Q`），输出可复现。
- 示例里凡是演示「创建临时文件 / 启动进程 / 挂 advice / 起定时器」的，
  都在最后一步做了清理，并把清理结果也打印出来 —— 清理失败会让输出对不上，验证脚本会发现。
