# 34 · 初始化文件与 mode line

> 所属部分：第 9 部分 · 跟随 eintr：调试与收尾项目

> 示例：`examples/34-init-mode-line.el`

到上一章为止，你已经会写函数、会调 bug 了。但还剩两个「每天都在用、却很少有人真正理解」的东西：一是**你的代码住在哪里**——Emacs 启动时读的那份 `init.el` 到底是怎么被找到、被拆分、被懒加载的；二是**屏幕最下面那条 mode line**——它不是一段写死的文字，而是一个**每次重绘都重新求值的模板列表**。eintr 在书末对 `.emacs` 文件和 mode line 各有交代，本章把它们在 Emacs 31.1 下完整讲透，并且照旧：**每个结论都有实测输出背书**。

## 34.1 你的代码总得有个家：init 文件在哪里

Emacs 启动时会读两份配置文件：**`early-init.el`**（很早，图形界面还没起来就加载，适合放启动开销相关的设置）和 **`init.el`**（主体配置）。它们都在你的**用户 Emacs 目录**里。示例第 1 节把这件事「问」了出来：

```elisp
(princ "== 1) 初始化文件在哪里 ==\n")
(princ (format "user-init-file = %S（-Q 不读 init，正常启动时指向它）\n"
               user-init-file))
(princ (format "user-emacs-directory = %S\n" user-emacs-directory))
(princ (format "init 文件  = %s\n" (locate-user-emacs-file "init.el")))
(princ (format "early-init = %s\n" (locate-user-emacs-file "early-init.el")))
(princ (format "custom 文件 = %s（M-x customize 的改动落在这里）\n"
               (locate-user-emacs-file "custom.el")))
```

```text
== 1) 初始化文件在哪里 ==
user-init-file = nil（-Q 不读 init，正常启动时指向它）
user-emacs-directory = "~/.emacs.d/"
init 文件  = ~/.emacs.d/init.el
early-init = ~/.emacs.d/early-init.el
custom 文件 = ~/.emacs.d/custom.el（M-x customize 的改动落在这里）
```

一行一行读：

- **`user-init-file`**——**实际被加载的那个 init 文件的路径**。交互式 Emacs 里执行 `C-h v user-init-file RET`，看到的就是你机器上的答案；本示例用 `-Q --batch` 跑，`-Q` 表示「不读任何配置」，所以是 `nil`。**想知道自己的配置到底生效没有，看这个变量比猜可靠**。
- **`user-emacs-directory`**——用户配置的根目录。这里显示 `"~/.emacs.d/"`。注意 Emacs 31 的规则：**如果你的家目录下存在 `~/.config/emacs/`，它会被优先采用**（XDG 规范），`~/.emacs.d/` 是退路。两个目录并存时，改错了目录的 init 是「配置不生效」的头号原因。
- **`locate-user-emacs-file`**——「把文件名拼到用户目录下」的标准做法。它比手动 `concat` 好在两点：尊重上面说的目录选择规则；而且**目录不存在时会顺手创建**。`custom.el` 是 `M-x customize` 系列命令落盘的地方——手写配置和 customize 界面写的配置互不覆盖，各归各家。

> **找 init 的完整顺序**（交互启动时）：先看 `user-emacs-directory`（`~/.config/emacs/` 存在则用它，否则 `~/.emacs.d/`）下的 `init.el` / `init.elc`；都没有才退回**老式的** `~/.emacs`、`~/.emacs.el`。`early-init.el` 更早——在图形界面（工具栏、字体框架）初始化之前加载。你在这章之后写的所有配置，默认都应该放进 `~/.emacs.d/init.el`。

## 34.2 `setq` 与 `setq-default`：init.el 里最容易踩的一颗雷

[03 · 变量](03-variables.md) 讲过：很多 Emacs 变量是 **buffer-local** 的——每个缓冲区可以有自己的局部值。`make-variable-buffer-local` 声明「这个变量在任何缓冲区里一旦被赋值，就自动变成局部值」。这在 init.el 里引出一个经典错误：**想改全局默认，却用了 `setq`**。示例第 2 节把两种赋值的行为摆在一起：

```elisp
(defvar my-tabs 'default-value "演示用：带 buffer-local 的选项。")
(make-variable-buffer-local 'my-tabs)

(with-temp-buffer
  (setq my-tabs 'only-in-A)                    ; 只在 A 这个缓冲区里生效
  (princ (format "缓冲区 A：setq 后值 = %S，local-variable-p = %S\n"
                 my-tabs (local-variable-p 'my-tabs))))
(with-temp-buffer
  (princ (format "缓冲区 B：值 = %S（回落到默认），local-variable-p = %S\n"
                 my-tabs (local-variable-p 'my-tabs))))
(setq-default my-tabs 'new-default)            ; 改的是「默认值」
(princ (format "setq-default 后：default-value = %S\n" (default-value 'my-tabs)))
(with-temp-buffer
  (princ (format "缓冲区 C：值 = %S（用上了新默认）\n" my-tabs)))
```

```text
== 2) setq 与 setq-default ==
缓冲区 A：setq 后值 = only-in-A，local-variable-p = t
缓冲区 B：值 = default-value（回落到默认），local-variable-p = nil
setq-default 后：default-value = new-default
缓冲区 C：值 = new-default（用上了新默认）
```

读法：

- **缓冲区 A** 里 `(setq my-tabs 'only-in-A)` 只建了一个**局部值**：`local-variable-p` 返回 `t`，表示「这个缓冲区有自己的值」。
- **缓冲区 B** 从没赋过值：`local-variable-p` 是 `nil`，读到的是**默认值** `default-value`。每个变量都有这样一层「默认值」垫底，局部值只是覆盖它。
- **`(setq-default my-tabs 'new-default)`** 改的是这层默认值本身：`(default-value 'my-tabs)` 变成了 `new-default`。
- **缓冲区 C** 新开出来，没有局部值，于是读到**新默认**。

所以规则只有一句话：**`setq` 改「当前缓冲区」的局部值，`setq-default` 改「所有缓冲区」的默认值**。

那颗雷现在可以拆了：init.el 在启动时求值，当时「当前缓冲区」只有一个。如果你在 init.el 里对 buffer-local 变量（比如 `indent-tabs-mode`、`tab-width` 这类）直接 `setq`，**你只改了启动时那个缓冲区**，之后打开的每一个文件都回落到出厂默认——而且没有任何报错。**init.el 里想改这类变量，一律用 `setq-default`**。

反过来还有个顺序细节：`setq-default` 只改默认层，**碰不到已经存在的局部值**。如果一个缓冲区已经 `setq` 过，`setq-default` 之后它仍是旧局部值——上面输出里若再回看缓冲区 A，它的值依然是 `only-in-A`。

## 34.3 拆分配置：`provide` / `require` / `with-eval-after-load`

init.el 写到几百行就该拆文件了。惯用结构是一个目录加一串模块：

```text
~/.emacs.d/
├── init.el            ; 入口：设 load-path，逐个 require
└── lisp/
    ├── my-init-ui.el       ; 界面相关
    ├── my-init-editing.el  ; 编辑行为
    └── ...
```

每个模块文件末尾写 `(provide 'my-init-ui)`——**宣告「我提供了这个特性」**；入口文件写 `(require 'my-init-ui)`——**「把这个特性装载进来，已装过就直接跳过」**。示例第 3 节用「现场生成第二个文件」的办法，把整套机制真实地跑了一遍：

```elisp
(declare-function my-init-extra-greet "my-init-extra") ; 告诉编译器：这函数在别的文件里

;; 模拟拆出去的第二个配置文件（真实场景放在 ~/.emacs.d/lisp/ 之类的目录）
(let ((dir (make-temp-file "myinit" t)))
  (with-temp-file (expand-file-name "my-init-extra.el" dir)
    (insert ";;; -*- lexical-binding: t; -*-\n"
            "(defun my-init-extra-greet (name)\n"
            "  (format \"你好，%s！——来自 my-init-extra\" name))\n"
            "(provide 'my-init-extra)\n"))
  (let ((load-path (cons dir load-path)))
    (with-eval-after-load 'my-init-extra
      (princ ">> 钩子触发：my-init-extra 刚刚装载完成\n"))
    (require 'my-init-extra)
    (princ (format "require 之后调用： %s\n" (my-init-extra-greet "读者")))))
```

```text
== 3) 拆分配置：provide / require / with-eval-after-load ==
>> 钩子触发：my-init-extra 刚刚装载完成
require 之后调用： 你好，读者！——来自 my-init-extra
```

四个部件各司其职：

- **`load-path`**——`require` 找文件的搜索路径。真实场景是 `(add-to-list 'load-path "~/.emacs.d/lisp/")`；示例为了自包含，用 `let` 给它临时添了一个目录，再用 `with-temp-file` 在里面生成 `my-init-extra.el`。
- **`declare-function`**——一行声明，告诉字节编译器「`my-init-extra-greet` 定义在 `my-init-extra` 文件里，别报警告」。**跨文件调用函数就该写这一行**；没有它，字节编译会把「这个函数我不认识」当警告打出来。
- **`provide` / `require`**——配对使用。`require` 的行为是幂等的：特性已在 `features` 列表里就直接返回，**反复 require 不会重复加载**，所以入口文件里每个模块 require 一次即可，模块之间互相 require 也不会出乱子。
- **`with-eval-after-load`**——登记「**等这个特性装载完成之后**，执行这段代码」。注意输出里的顺序：`>> 钩子触发` 打印在 `require 之后调用` **之前**。因为 `require` 内部执行了 `load`：先把 `my-init-extra.el` 里所有表单跑完（最后一句是 `provide`），**装载完成的那一刻钩子立即触发**，然后 `require` 才返回、轮到下一行打印。

`with-eval-after-load` 的价值在于**时序解耦**：注册钩子的时候，目标文件可以还没装载（比如另一个包要等用户打开对应文件才加载）。你先「挂号」，装载事件一发生它就会补跑。第 15 章讲 minor mode、第 17 章讲 hook 时埋的「钩子」思想，在这里换了个载体又出现了。

## 34.4 autoload：用到才加载

`require` 是「**现在就**装载」。而 Emacs 自己有几千个命令，如果启动时全装进来，启动就要慢上几秒。它的答案是 **autoload**：先登记一张「欠条」，**第一次真正调用时才去装载**。示例第 4 节：

```elisp
(autoload 'my-lazy-fn "my-lazy-lib")
(princ (format "登记后：fboundp = %S，函数体 = %S（只是一张欠条）\n"
               (fboundp 'my-lazy-fn) (symbol-function 'my-lazy-fn)))
(let ((dir (make-temp-file "mylibs" t)))
  (with-temp-file (expand-file-name "my-lazy-lib.el" dir)
    (insert ";;; -*- lexical-binding: t; -*-\n"
            "(provide 'my-lazy-lib)\n"
            "(defun my-lazy-fn () (+ 1 2))\n"))
  (let ((load-path (cons dir load-path)))
    (princ (format "第一次调用 my-lazy-fn = %S\n" (my-lazy-fn)))
    (princ (format "调用后函数体 = %S（欠条换成了真函数）\n"
                   (symbol-function 'my-lazy-fn)))))
```

```text
== 4) autoload：用到才加载 ==
登记后：fboundp = t，函数体 = (autoload "my-lazy-lib" nil nil nil)（只是一张欠条）
第一次调用 my-lazy-fn = 3
调用后函数体 = #[nil ((+ 1 2)) (t)]（欠条换成了真函数）
```

逐行读：

- `(autoload 'my-lazy-fn "my-lazy-lib")` 之后，**函数 symbol 已经「有定义」**——`fboundp` 返回 `t`，但定义的内容是 `(autoload "my-lazy-lib" nil nil nil)`：一条记录，写着「真身叫 `my-lazy-fn`，住在 `my-lazy-lib` 文件里」。**调用它时，Emacs 发现函数体是欠条，就去 `load-path` 里找 `my-lazy-lib.el` 加载，加载完再重新分发这次调用**——对调用方完全透明。
- 第一次调用返回 `3`，说明文件已装载、真函数已执行。再看函数体：`#[nil ((+ 1 2)) (t)]`。**这个 `#[…]` 不是字节编译的产物**：从 Emacs 30 起，解释执行的函数有了自己的类型（`interpreted-function`），打印出来就是这种紧凑形式——依次是参数表 `nil`、函数体 `((+ 1 2))`、词法环境标记 `(t)`。
- 交互式里你很少手写 `(autoload …)`——**包管理器替你做**：包的注释里出现 `;;;###autoload` 魔法注释的函数，安装时会自动生成一张欠条表（[24 · 包管理](24-packages.md) 讲过 `package.el` 的这套机制）。手写 autoload 的场景，主要是给自己的零散小脚本做「用到再装」。

一句话总结这一节和上一节的关系：**`require` 表达「我依赖它，现在就要」；`autoload` 表达「我知道它在哪，用时再取」**。写 init.el 的大原则：能用 `autoload` 的不要 `require`，能 `with-eval-after-load` 的不要裸放顶层——你的启动速度就是这样省出来的。

## 34.5 常用开关四件套

有了上面的地基，init.el 里最高频的四类语句就都好理解了。示例第 5 节各演一个：

```elisp
(menu-bar-mode -1)
(princ (format "(menu-bar-mode -1) 后变量 = %S（nil = 关）\n" menu-bar-mode))
(global-auto-revert-mode 1)
(princ (format "(global-auto-revert-mode 1) 后变量 = %S（t = 开）\n"
               global-auto-revert-mode))
(add-to-list 'auto-mode-alist '("\\.myext\\'" . text-mode))
(princ (format "auto-mode-alist 新增：%S\n" (assoc "\\.myext\\'" auto-mode-alist)))

(defun my-open-config ()
  "跳到 init 文件（教学用占位命令）。"
  (interactive)
  nil)
;; 交互式里惯用 (kbd "C-c t")；--batch 下 read-kbd-macro 不可靠，
;; 这里直接写按键向量的字面量，两者是同一个按键序列。
(global-set-key [(control c) ?t] 'my-open-config)
(let ((keys (car (where-is-internal 'my-open-config))))
  (princ (format "C-c t 绑定情况： 向量 = %S，人话 = %s\n"
                 keys (key-description keys))))
```

```text
== 5) 常用开关：模式、文件类型、快捷键 ==
(menu-bar-mode -1) 后变量 = nil（nil = 关）
(global-auto-revert-mode 1) 后变量 = t（t = 开）
auto-mode-alist 新增：("\\.myext\\'" . text-mode)
C-c t 绑定情况： 向量 = [3 116]，人话 = C-c t
```

- **模式开关是「函数 + 同名变量」**。`menu-bar-mode` 这类 minor mode 函数（[15 · minor mode](15-minor-mode.md)）不传参数是「切换」，传参数则 `非零开、零或负关`。状态就记在**同名变量**里——`nil` 关、`t` 开。**init.el 里推荐永远传参**（`(menu-bar-mode -1)` 而不是裸 `(menu-bar-mode)`）：切换的结局取决于当前状态，配置文件的含义就变成「取决于之前执行过什么」，不可复现。带 `global-` 前缀的变体（`global-auto-revert-mode`）把开关作用到**所有缓冲区**。
- **文件类型分派**：`auto-mode-alist` 是「文件名正则 → 主模式」的表（[16 · major mode](16-major-mode.md)）。`(add-to-list 'auto-mode-alist '("\\.myext\\'" . text-mode))` 往表头加一条；输出里 `assoc` 查到了它。**用 `add-to-list` 而不是 `push`**：`add-to-list` 幂等，同一条目重复执行不会重复添加——init.el 可能被反复求值（比如 `eval-buffer` 调试时），幂等是刚需。
- **快捷键**：`(global-set-key [(control c) ?t] 'my-open-config)` 把命令绑到 `C-c t`（[14 · 键位](14-keymaps.md)）。按键在这里是一个**向量**：`(control c)` 是带 Control 修饰的事件，归一化成整数 `3`（`C-c` 的控制字符码就是 0x03），`?t` 是普通字符 `116`。所以 `where-is-internal` 查出来的向量是 `[3 116]`；`key-description` 负责把向量翻译回人话 `C-c t`——你 `C-h k` 看到的就是这个函数的产出。

> **一个实测注记**：交互式 Emacs 里写按键惯用 `(kbd "C-c t")`，它把字符串描述解析成按键序列。但 `--batch` 下 `read-kbd-macro` 的行为不可靠（本机实测：`C-x C-f` 解析成空串、`C-c t` 解析成单个 `t`，且输出会夹带原始控制字节）。**脚本的输出要保持干净，就用向量字面量；交互式里才用 `kbd`。** 两者对应同一个按键序列，只是写法不同。

## 34.6 mode line：一个每次重绘都重新求值的模板

现在拆 mode line。先建立一个反直觉的认知：**mode line 不是「一段会自动更新的文字」，而是变量 `mode-line-format` 里存的一个模板，Emacs 每次重绘时把整个模板重新求值一遍**。你看到的行号、星号、模式名，全是「求值那一刻」的产物。

### 模板长什么样

示例第 6 节先把默认模板的**顶层元素**逐个打印：

```elisp
(princ "默认 mode-line-format 的顶层元素：\n")
(let ((i 0))
  (dolist (elt mode-line-format)
    (princ (format "  [%2d] %S\n" i elt))
    (setq i (1+ i))))
```

```text
  [ 0] "%e"
  [ 1] mode-line-front-space
  [ 2] mode-line-mule-info
  [ 3] mode-line-client
  [ 4] mode-line-modified
  [ 5] mode-line-remote
  [ 6] mode-line-window-dedicated
  [ 7] mode-line-frame-identification
  [ 8] mode-line-buffer-identification
  [ 9] "   "
  [10] mode-line-position
  [11] (project-mode-line project-mode-line-format)
  [12] (vc-mode vc-mode)
  [13] "  "
  [14] mode-line-modes
  [15] mode-line-misc-info
  [16] mode-line-end-spaces
```

对照你屏幕上的 mode line，这些片段各就各位：`mode-line-modified` 是那个 `**` / `--` 修改标记；`mode-line-buffer-identification` 是缓冲区名；`mode-line-position` 组装出行号、列号、百分比；`mode-line-modes` 给出主模式名和 minor mode 串；`mode-line-misc-info` 是各路 minor mode、包「寄存」信息的公共摊位。**所以「mode line 变成什么样」几乎总等于「mode-line-misc-info 里被塞了什么」**——定制 mode line 的第一步通常是看这个变量。

特别注意 `[11]` 和 `[12]`——它们不是字符串也不是符号，而是 `(project-mode-line project-mode-line-format)`、`(vc-mode vc-mode)` 这样的**列表**。这是模板里最巧的一种片段，马上讲。

### 五种片段：官方规则

`mode-line-format` 的变量文档（`C-h v mode-line-format`）开头就给出了完整规则：

```text
Template for displaying mode line for a window’s buffer.

The value may be nil, a string, a symbol or a list.
...
A list whose car is a string or list is processed by processing each
 of the list elements recursively, as separate mode line constructs,
 and concatenating the results.

A list of the form ‘(:eval FORM)’ is processed by evaluating FORM and
 using the result as a mode line construct. ...

A list of the form ‘(:propertize ELT PROPS...)’ is processed by
 processing ELT as the mode line construct, and adding the text
 properties PROPS to the result.

A list whose car is a symbol is processed by examining the symbol’s
 value, and, if that value is non-nil, processing the cadr of the
 list recursively; and if that value is nil, processing the caddr of
 the list recursively.
```

整理成表：

| 片段形式 | 渲染规则 | 例子 |
|---|---|---|
| 字符串 | 按原文输出，但处理其中的 %-构造 | `"   "`、`"%b"` |
| 符号（非 `t`/`nil`） | **解引用**：把符号的值再当模板渲染（可以套娃） | `mode-line-position` |
| `(:eval FORM)` | 求值 FORM，结果再当模板渲染 | `(:eval (format "«%d 字符»" …))` |
| `(:propertize ELT PROPS…)` | 渲染 ELT 并加上文本属性（颜色、字重等，[11 · 文本属性](11-text-properties.md)） | `(:propertize "只读" face bold)` |
| `(变量 非空时 [空时])` | **条件片段**：变量非空渲染第二段，为空渲染可选的第三段 | `(vc-mode vc-mode)` |
| `nil` | 整条 mode line 不显示 | —— |

回看 `[12] (vc-mode vc-mode)`：`vc-mode` 是版本控制状态（Git 分支等）的缓冲区局部变量。**没在版本控制下它就是 `nil`，片段渲染成空；一旦有值，就「把它自己再渲染一遍」**。mode line 能按上下文伸缩，靠的全是这种条件片段。

### %-构造：模板里的占位符

字符串里的 %-构造是最后一层「活字」。变量文档给出了完整清单，挑常用的：

| 构造 | 含义 |
|---|---|
| `%b` | 缓冲区名 |
| `%f` | 访问的文件名 |
| `%l` / `%c` | 行号 / 列号（列从 0 起算；想让列号实时更新需开 `column-number-mode`） |
| `%p` / `%P` | 光标相对窗口顶 / 窗口底位置的百分比，或 `Top`/`Bot`/`All` |
| `%n` | 处于 narrow 状态时打印 `Narrow` |
| `%i` / `%I` | 缓冲区大小；`%I` 用 k、M、G 缩写 |
| `%*` / `%+` / `%&` | 只读、已修改状态的星号组合（三者措辞略异，见文档） |
| `%-` | 填满剩余空间的横线 |
| `%%` | 百分号字面量 |

**没有 `%m` 这个构造**——老资料里的 `%m`（模式名）在现行 Emacs 里已由 `mode-line-modes` 片段承担。看到旧配置里写 `%m` 直接报错，原因在此。完整清单随时可查：`C-h v mode-line-format` 的文档字符串就是表本身。

### 自己写一个渲染器

「求值一个模板」听起来玄，其实递归就能写完。示例实现了一个教学用小渲染器（真实实现还处理整数宽度填充等边角，这里只保留主干）。第一半处理字符串里的 %-构造：

```elisp
(defun my-fill-percent (s)
  "把字符串 S 里的 %-构造替换成实际内容（只支持常用的一小撮）。"
  (let ((out "") (i 0) (n (length s)))
    (while (< i n)
      (let ((ch (aref s i)))
        (if (and (eq ch ?%) (< (1+ i) n))
            (let ((c (aref s (1+ i))))
              (setq out (concat out
                                (cond
                                 ((eq c ?b) (buffer-name))
                                 ((eq c ?f) (or (buffer-file-name) "(无文件)"))
                                 ((eq c ?l) (number-to-string (line-number-at-pos)))
                                 ((eq c ?c) (number-to-string (current-column)))
                                 ((eq c ?n) (if (buffer-narrowed-p) "Narrow " ""))
                                 ((eq c ?p) (number-to-string
                                             (if (<= (point-max) (point-min)) 100
                                               (/ (* 100 (- (point) (point-min)))
                                                  (- (point-max) (point-min))))))
                                 ((eq c ?-) "-")
                                 ((eq c ?%) "%")
                                 (t (format "%%%c" c))))
                    i (+ i 2)))
          (setq out (concat out (char-to-string ch)) i (1+ i)))))
    out))
```

读法：**逐字符扫描**。普通字符原样拼接（`i` 前进 1）；遇到 `%` 就看下一个字符，从 `cond` 表里查替换结果（`i` 前进 2）。三个细节值得记：

- **`%p` 的公式**：`(* 100 (- (point) (point-min))) / (- (point-max) (point-min))`——点位置相对缓冲区开头的百分比。分母可能为零的缓冲区（空缓冲区）要单独兜成 `100`。
- **未知构造原样吐回**：`(t (format "%%%c" c))`。`format` 里 `%%` 才是一个真正的 `%`，所以 `"%%%c"` 打出来是 `%` 跟着字符——**没实现的构造不吞掉、不报错，按「不认识就照抄」处理**，这和真实实现的兜底精神一致。
- `i (+ i 2)` 只写在 `%` 分支里——**别忘了给普通字符分支也推进 `i`**。这是写这种「手工扫描循环」最容易犯的错（忘了推进就是死循环，[05 · 控制流](05-control-flow.md) 的 `while` 帮不了你）。

第二半处理五种片段，就是一个按「片段类型」分派的递归：

```elisp
(defun my-render-mode-line (fmt)
  "把 mode-line 模板 FMT 渲染成字符串（教学用简化版）。"
  (cond
   ((or (null fmt) (eq fmt t)) "")
   ((stringp fmt) (my-fill-percent fmt))
   ((symbolp fmt) (my-render-mode-line (symbol-value fmt)))
   ((consp fmt)
    (cond
     ((eq (car fmt) :eval) (my-render-mode-line (eval (cadr fmt) t)))
     ((eq (car fmt) :propertize) (my-render-mode-line (cadr fmt)))
     ((symbolp (car fmt))                    ; (变量 非空时 空时) 条件片段
      (if (and (boundp (car fmt)) (symbol-value (car fmt)))
          (my-render-mode-line (cadr fmt))
        (my-render-mode-line (caddr fmt))))  ; 第三段可省略（省略时是 nil）
     (t (mapconcat #'my-render-mode-line fmt ""))))))
```

对着文档规则读：字符串交给 `my-fill-percent`；符号先 `symbol-value` 解引用再递归；列表看 `car`——`:eval` 就 `eval`（第二个参数 `t` 表示按词法绑定求值）、`:propertize` 渲染内层（教学版丢弃属性）、`car` 是符号就是条件片段（`boundp` 保护未定义的变量，`caddr` 缺省时是 `nil`，渲染成空串）、其余情形把整个列表逐元素递归、`mapconcat` 拼起来（[07 · 列表](07-lists.md)）。

### 跑一遍，看两种状态

```elisp
(defvar my-mode-name "示例模式" "演示用：mode line 里的符号片段。")
(defvar my-flag nil "演示用：条件片段的开关。")

(with-temp-buffer
  (insert "第一行\n第二行\n第三行\n")
  (goto-char (point-min))
  (forward-line 2)
  (let ((mode-line-format
         (list "-" 'my-mode-name "：" "%b" "  行%l 列%c %p%%"
               '(my-flag " [旗]")
               " "
               '(:eval (format "«%d 字符»" (- (point-max) (point-min))))
               " "
               '(:propertize "只读" face bold))))
    (princ (format "渲染（my-flag = nil）  = %s\n"
                   (my-render-mode-line mode-line-format)))
    (let ((my-flag t))
      (princ (format "渲染（my-flag = t）    = %s\n"
                     (my-render-mode-line mode-line-format))))))
```

```text
渲染（my-flag = nil）  = -示例模式： *temp*  行3 列0 66% «12 字符» 只读
渲染（my-flag = t）    = -示例模式： *temp*  行3 列0 66% [旗] «12 字符» 只读
```

对照模板逐段验收：

- `-` `示例模式` `：` ` *temp*`——字符串、**符号片段**（`my-mode-name` 解引用出 `"示例模式"`）、字符串、**%-构造 `%b`** 各出一截。
- ` *temp*` 里那个**前导空格不是 bug**：`with-temp-buffer` 建的临时缓冲区名叫 `" *temp*"`——Emacs 约定**以空格开头的缓冲区名是「内部缓冲区」**，不出现在缓冲区列表里（`C-x C-b` 看不到它们）。
- `行3 列0 66%`——`%l` `%c` `%p` 各自求值。光标在第 3 行行首（`forward-line 2`），列是 0；缓冲区共 12 个字符、光标走过 8 个，`8 / 12 = 66%`。
- `«12 字符»` 是 **`:eval` 片段**当场算的；`只读` 是 **`:propertize` 片段**（教学渲染器丢掉了 `face bold` 属性，交互式里它是加粗的）。
- 两行输出的**唯一差别**是 `[旗]`：条件片段 `(my-flag " [旗]")` 在 `my-flag` 为 `nil` 时渲染成空、为 `t` 时渲染出来。**mode line 的「按需伸缩」，你刚刚亲手复现了**——默认模板里 `(vc-mode vc-mode)` 也是同一个机制。

> **为什么示例要自渲染？** Emacs 其实内置了模板求值函数 `format-mode-line`，但它在 `--batch` 下**恒返回空串**——mode line 的求值和重绘（redisplay）是绑在一起的，批处理没有 redisplay。所以「无界面可复现」的路只有一条：把求值逻辑自己实现一遍。交互式里你改完 `mode-line-format` 后想立刻看到效果，可以 `M-x force-mode-line-update`（或者干脆敲个键触发重绘）。

## 34.7 小结

| 你想做的事 | 用什么 | 关键点 |
|---|---|---|
| 找到 / 拼出用户配置路径 | `user-init-file`、`user-emacs-directory`、`locate-user-emacs-file` | `~/.config/emacs/` 存在则优先于 `~/.emacs.d/`；`user-init-file` 指向实际加载的那份 |
| 改所有缓冲区的默认值 | `setq-default` | 对 buffer-local 变量直接 `setq` 只改当前缓冲区——init.el 里的大坑 |
| 拆分配置 | `provide` / `require` + `load-path` | `require` 幂等；`declare-function` 让跨文件调用过编译 |
| 「装载完成后做某事」 | `with-eval-after-load` | 先挂号、后触发；目标文件晚装也不漏 |
| 按需加载 | `autoload` + `;;;###autoload` | 欠条机制：首次调用才装载；启动速度的关键 |
| 开关一个 minor mode | `(menu-bar-mode -1)` 这类**传参调用** | 状态在同名变量里；init 里永远传参，别用「切换」 |
| 按扩展名选模式 | `add-to-list` 到 `auto-mode-alist` | 幂等添加，别用 `push` |
| 定制 mode line | 改 `mode-line-format` | 字符串/符号/`:eval`/`:propertize`/条件片段五种；常用 %-构造见表；改完 `force-mode-line-update` |

这一章之前，你写的代码都活在「示例」里；从这一章起，它们有了正式的住处——init.el 与它拆出来的模块。下一章是全书的收尾项目：回到 eintr 的最后一章，把 cons 单元、递归、循环这些零件拼起来，**打印一张带坐标轴的柱状图**。

上一章：[33 · 调试：debug-on-entry、edebug 与 batch 下的排查](33-debugging.md)　｜　下一章：[35 · 收尾项目：打印一张带坐标的柱状图](35-graph.md)　｜　返回：[Emacs 扩展开发指南](README.md)
