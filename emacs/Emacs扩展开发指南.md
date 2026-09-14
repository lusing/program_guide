# Emacs 扩展开发教程

本文档聚焦 Emacs 扩展开发的核心思想与实践路线，目标是让读者能够从最基本的 Elisp 语法逐步过渡到插件和扩展编写。

## 1. Emacs 与 Elisp 简介

Emacs 是一个功能极强的文本编辑器，同时也是一个 Lisp 运行环境。它的很多能力并不是通过配置文件和插件界面完成，而是通过 Elisp 代码运行。也就是说，扩展 Emacs 本质上就是编写 Emacs Lisp（简称 Elisp）代码。

Emacs 的典型扩展包括：

- 自定义按键绑定
- 缓冲区与文件操作
- mode / hook / advice
- package 与 library 管理
- 进程调用与异步任务
- 交互式命令与 minibuffer 逻辑

## 2. 工作流：开发、测试、复用

一个常见的 Emacs 扩展开发流程：

1. 先写最小可运行示例
2. 用 `emacs --batch` 进行字节编译验证
3. 在 Emacs 中加载源码并反复调试
4. 把功能抽象到函数、keymap、custom-variable 或 mode 中
5. 封装成 package 或 library 供复用

本仓库中，所有示例都按同样标准保存在 `examples/` 中，并通过 `build.ps1` 执行本地编译验证。

## 3. 基础语法：变量、函数、条件分支

Elisp 是 Lisp 语法，函数调用使用前缀形式：

```elisp
(message "Hello, Emacs!")
(setq name "guide")
(defun square (n) (* n n))
```

关键点：

- `setq` 用于赋值
- `defun` 定义函数
- `let` 用于局部绑定
- `if` / `cond` 用于条件分支
- `list`、`car`、`cdr` 用于列表操作

## 4. 缓冲区、文件与临时对象

Emacs 的核心能力来自“缓冲区”与“文件”抽象。开发扩展时经常要：

- 创建临时缓冲区
- 插入文本
- 读取/写入文件
- 访问当前 buffer 的内容

示例：

```elisp
(with-temp-buffer
  (insert "hello from temp buffer\n")
  (goto-char (point-min))
  (message "%s" (buffer-string)))
```

## 5. Keymap、hook 与 mode

Emacs 扩展最常见的接入点包括：

- `keymap`：绑定快捷键
- `hook`：在特定事件发生前后执行代码
- `major-mode` / `minor-mode`：扩展编辑器行为

示例：

```elisp
(defvar my-map (make-sparse-keymap))
(define-key my-map (kbd "C-c x") #'message)
(add-hook 'find-file-hook #'my-buffer-hook)
```

这类机制使扩展能够无侵入式地增强编辑器。

## 6. advices、process 与异步任务

Emacs 中高级扩展常见手段：

- `advice-add`：修改已有函数行为
- `start-process`：启动外部进程
- `timer`：计划任务
- `run-with-idle-timer`：空闲时执行任务

这让 Emacs 不仅是编辑器，还可以承接命令行工具、构建系统与语言服务器等功能。

## 7. package 与 custom-variable

要把扩展做成可维护的工具，通常需要：

- 使用 `defgroup` / `defcustom` 定义配置项
- 提供 `provide` 语句
- 把功能拆成独立 library
- 按 package 结构组织目录

这样可以让扩展更容易分发和复用。

## 8. 推荐学习路线

从最基础的 Elisp 开始，可以按下面顺序设置学习路径：

1. 基本表达式、变量与函数
2. 列表、字符串与条件结构
3. 缓冲区与文件处理
4. keymap 与命令绑定
5. hook 与 major/minor mode
6. advice 与包级扩展
7. process、timer 与异步执行
8. package 与自定义变量

## 9. 当前示例目录说明

本目录中的示例文件已按标准结构整理，并由本机 Emacs 进行字节编译验证。关键示例包括：

- `01_hello.el`：最小运行示例
- `02_variables.el`：变量与基本赋值
- `03_functions.el`：函数与返回值
- `04_conditionals.el`：条件分支
- `05_lists.el`：列表操作
- `06_buffers.el`：buffer 处理
- `07_files.el`：临时文件处理
- `08_keymaps.el`：快捷键绑定
- `09_hooks.el`：hook 机制
- `10_major_modes.el`：mode 定义
- `11_processes.el`：外部进程
- `12_custom_variables.el`：自定义变量
- `13_advice.el`：advice 编程
- `14_package_loading.el`：package 与加载逻辑

## 10. 编译验证方式

本地实际验证使用以下方式：

```powershell
G:\scoop\apps\emacs\current\bin\emacs.exe -Q --batch --eval "(byte-compile-file \"<path-to-file>\")"
```

也可以通过目录 `build.ps1` 批量验证：

```powershell
cd G:\code\guide\emacs
.\build.ps1 -All
```

## 11. 适合的扩展场景

Emacs 扩展开发适合的领域包括：

- 代码导航与增强编辑
- 语言特定 mode
- 日志工具与代码生成器
- Git、Org、Project 管理工具
- 任务管理与笔记工作流
- 与外部工具链的集成

通过 Elisp，Emacs 可以构建出非常强大的工作环境，而不仅仅是一个文本编辑器。
