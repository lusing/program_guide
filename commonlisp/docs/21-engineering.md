# 21 · 工程化：ASDF、测试、调试与部署

> 配套示例：[`examples/21_asdf/`](../examples/21_asdf/main.lisp)（channel: sbcl——
> ASDF 随 SBCL 内置；CLISP 需自装，见 21.6）

## 21.1 一个最小可用项目的结构

```
myproj/
├── myproj.asd          ← 系统定义（相当于 package.json / Cargo.toml）
├── src/
│   ├── package.lisp    ← 先定义包
│   └── main.lisp
├── tests/
│   └── tests.lisp
└── README.md
```

**关键约定**：`.asd` 文件必须和系统**同名**，且放在 ASDF 能找到的目录
（`~/quicklisp/local-projects/`、`~/common-lisp/` 或源注册表）。

## 21.2 ASDF 系统定义

`.asd` 里的 `defsystem` **不是 CL-USER 里的函数**——ASDF 加载 `.asd` 时把
`*package*` 绑到 `ASDF-USER`，`defsystem` 从那里继承。REPL 里手敲会报
`illegal function call`；手动加载用 `(asdf:load-asd ".../myproj.asd")`。

```lisp
(defsystem "myproj"
  :description "示例项目"
  :version "0.1.0"
  :depends-on ()                    ; 依赖列表，如 ("alexandria" "cl-ppcre")
  :serial t                         ; 按 components 顺序加载（有依赖时必须）
  :components ((:file "src/package")
               (:file "src/main"))
  :in-order-to ((test-op (test-op "myproj/tests"))))

(defsystem "myproj/tests"
  :depends-on ("myproj")
  :components ((:file "tests/tests"))
  :perform (test-op (o c) (symbol-call :myproj/tests :run-tests)))
```

加载与编译：

```lisp
(asdf:load-system "myproj")      ; 必要时编译再加载
(asdf:test-system "myproj")
```

命令行一步到位：

```bash
sbcl --non-interactive --eval '(require :asdf)' \
     --eval '(asdf:load-system "myproj")'
```

示例 21 做的是**完整真跑**：运行期生成 `.asd` + 源文件 → 注册
`*central-registry*` → `load-system` → 调用导出函数，最后自清理。

## 21.3 测试：从 assert 到迷你框架

CL 没有内置测试框架（`assert` 算半个），轻量测试用 assert 完全够：

```lisp
(defun run-tests ()
  (assert (= (my-add 1 2) 3))
  (assert (handler-case (progn (parse-integer "abc") nil)
            (parse-error () t)))     ; 「预期失败」的测法
  (format t "全部通过~%"))
```

再往前一步：**30 行宏写一个迷你框架**（示例 21 的 define-test / expect /
run-all-tests，五类用例含预期报错路径）——宏让这件事很轻松（14 章的实战）。
需要 fixture、报告、并行时上 **FiveAM** 或 **Rove**（ql:quickload :fiveam），
但别一开始就上框架。

## 21.4 调试工具箱

ANSI 内置的调试面（两实现都有）：

| 工具 | 用途 | 备注 |
|---|---|---|
| `trace`/`untrace` | 跟踪函数进出 | 输出走 `*trace-output*`（默认 stderr！） |
| `step` | 单步执行 | 交互式 |
| `inspect` | 交互式检视对象 | REPL 用 |
| `describe` | 打印对象全部信息 | **输出形态两实现不同**，别做比对 |
| `time` | 测耗时+分配 | 见 26 章 |
| `room` | 内存报告 | `(room nil)` 静默版 |
| `apropos` | 按名字找符号 | 06 章 |
| `disassemble` | 反汇编 | 26 章 |
| 调试器 | 报错时的栈帧/restart 菜单 | 18 章 |

要把 `trace` 输出收进 stdout：`(let ((*trace-output* *standard-output*)) ...)`。

**SLIME/sly**（Emacs）是社区标配：改函数 `C-c C-c` 热替换、报错进调试器、
`M-x sldb` 看栈挑 restart——「改完接着跑、不用复现」是 CL 开发体验的核心。
VS Code 用 alive 插件，Vim 用 vlime。

## 21.5 Quicklisp 与依赖管理

Quicklisp 是事实标准包管理器：

```bash
curl -O https://beta.quicklisp.org/quicklisp.lisp
sbcl --load quicklisp.lisp --eval '(quicklisp-quickstart:install)' \
     --eval '(ql:add-to-init-file)'
```

```lisp
(ql:quickload :alexandria)     ; 自动下载、编译、加载
(ql:system-apropos "json")    ; 搜库
```

**依赖要写进 `.asd` 的 `:depends-on`**——Quicklisp 只是「拿到依赖」的手段，
`:depends-on` 才是「声明依赖」的地方。自己的项目放进 `~/quicklisp/local-projects/`
即可被 quickload。常用库速记：alexandria（工具函数）、bordeaux-threads（可移植线程）、
cffi（可移植 FFI）、cl-ppcre（正则）、fiveam（测试）、hunchentoot（Web）、
drakma（HTTP 客户端）。

## 21.6 CLISP 的工程化差异

- **ASDF 不随 CLISP 内置**（本机 2.49.95 实测 `(require "asdf")` 得 NIL）：
  从 [asdf.common-lisp.dev](https://asdf.common-lisp.dev) 下载 asdf.lisp，
  `(load "asdf.lisp")` 后一切照旧；或直接用 Quicklisp（它也支持 CLISP）；
- **CLISP 映像**：`clisp -M myimg.mem` 加载内存映像（比 SBCL 的可执行文件小得多，
  但不带运行时）；`ext:saveinitmem` 生成；
- **启动快**是 CLISP 的工程优势——脚本场景（每次冷启动）常常选它。

## 21.7 部署：入口函数与 save-lisp-and-die

入口函数模式（退出码约定 0 成功/非 0 失败）：

```lisp
(defun app-main ()
  (format t "应用启动~%")
  0)
```

SBCL 打包成独立可执行文件：

```bash
sbcl --eval '(asdf:load-system "myproj")' \
     --eval '(sb-ext:save-lisp-and-die "myapp" :toplevel #'myproj:main :executable t)'
./myapp
```

要点：`:toplevel` 指定入口（不指定进 REPL）；**save-lisp-and-die 不返回**
（保存完就退出进程，必须是最后一条）；Windows 产物加 `.exe`；
体积 ≈ SBCL 运行时（几十 MB 起步），嫌大用 `:compression t` 或改 CLISP 映像
（23 章）。

## 21.8 本仓库的验证约定

`commonlisp/` 每个示例遵守：

1. **结尾打印结束标记** `==== NN 结束 ====`——防「静音错误、退出码 0」；
2. **输出走 stdout、警告走 stderr**——「stderr 为空」=「零警告」，这条真拦得住东西；
3. **不用会变的东西做输出**：地址、gensym 编号、哈希顺序、调度顺序，要么消掉
   要么排序；
4. **双通道逐字节一致**（both 通道）——把可移植性变成可判定的断言；
5. **并发示例自己加打印锁**，关键结论与调度无关。

```bash
./run-all.sh                    # macOS/Linux：SBCL+CLISP 双通道 47 单元
SBCL=/path/sbcl CLISP=/path/clisp ./run-all.sh
```

**两个入口（run-all.sh / build.ps1）不要并行跑**——共用 `build/` 产物目录，
会互相覆盖（实测并行时误报「缺结束标记」）。

正文的 `; =>` 断言可一键复核：

```bash
python3 verify-guide.py          # 核验 docs/*.md 全部代码块（SBCL 通道）
```

## 21.9 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| ASDF 找不到系统 | .asd 不在注册目录/名字不符 | 放 local-projects，文件与系统同名 |
| 加载顺序错乱 | 没写 `:serial t` | 有依赖就加 |
| REPL 手敲 defsystem 报非法调用 | 它在 ASDF-USER 包 | `asdf:load-asd` |
| trace 输出污染 stderr | *trace-output* 默认 stderr | 绑到 *standard-output* |
| CLISP require asdf 得 NIL | 本构建不带 ASDF | load asdf.lisp / 装 Quicklisp |
| save-lisp-and-die 后的代码没跑 | 它不返回 | 放最后一条 |
| 「通过」但其实没执行 | --script 与 --non-interactive 连用 | --load（02 章） |
