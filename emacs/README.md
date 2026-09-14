# Emacs 扩展开发指南示例集

本目录按 `guide` 统一结构组织 Emacs Lisp 扩展开发教程与可验证示例。

## 目录结构

```text
emacs/
├── README.md
├── Emacs扩展开发指南.md
├── build.ps1
├── examples/
│   ├── 01_hello.el
│   ├── 02_variables.el
│   ├── 03_functions.el
│   ├── 04_conditionals.el
│   ├── 05_lists.el
│   ├── 06_buffers.el
│   ├── 07_files.el
│   ├── 08_keymaps.el
│   ├── 09_hooks.el
│   ├── 10_major_modes.el
│   ├── 11_processes.el
│   ├── 12_custom_variables.el
│   ├── 13_advice.el
│   └── 14_package_loading.el
└── build/
```

## 构建工具链

- Emacs 安装目录：`G:\scoop\apps\emacs\current`
- 可执行文件：`G:\scoop\apps\emacs\current\bin\emacs.exe`
- 源码参考：`G:\github\ide\emacs`

## 编译/验证

```powershell
cd G:\code\guide\emacs
.\build.ps1 -All
```

单文件验证：

```powershell
.\build.ps1 -File 08_keymaps.el
```

清理：

```powershell
.\build.ps1 -Clean
```

## 说明

- 本教程面向 Emacs Lisp（Elisp）扩展开发与插件编写。
- 示例统一使用 `emacs --batch` 做最小编译和加载验证，确保代码能够被 Emacs 解释器正确字节编译。
- 适合从基本语法、缓冲区/文件操作、keymap、hook、mode，到后续的 package、advice 与 process 调用，逐步学习。
