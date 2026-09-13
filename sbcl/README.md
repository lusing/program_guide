# SBCL / Common Lisp 教程示例集

本目录包含 Common Lisp（以 SBCL 为主）的教程文档与可编译示例代码。

## 目录结构

```text
sbcl/
├── README.md
├── common-lisp-guide.md
├── build.ps1
├── 01-hello-world.lisp
├── 02-data-types.lisp
├── ...
├── 17-testing-and-deployment.lisp
└── build/
```

## 工具链

- SBCL: `G:\scoop\apps\sbcl\current\sbcl.exe`

## 编译验证

```powershell
cd G:\code\guide\sbcl
.\build.ps1 -All
```

编译单个文件：

```powershell
.\build.ps1 -File 04-functions.lisp
```

清理产物：

```powershell
.\build.ps1 -Clean
```

## 已验证示例章节

- 01 Hello World 与脚本运行
- 02 数据类型
- 03 控制结构
- 04 函数与闭包
- 05 宏
- 06 CLOS
- 07 包管理
- 08 条件系统
- 09 文件 IO
- 10 format 格式化
- 11 SBCL 扩展
- 12 线程
- 13 FFI
- 14 性能
- 15 ASDF/Quicklisp
- 16 序列与哈希表
- 17 测试与部署

