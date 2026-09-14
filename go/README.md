# Go 开发指南示例集

本目录按照 `guide` 统一标准整理为“教程文档 + 独立示例工程 + 构建脚本”的结构，便于在本机 Go 工具链上实际编译和验证 Go 代码。

## 目录结构

```text
go/
├── README.md
├── Go开发指南.md
├── build.ps1
├── examples/
│   ├── 01_hello/
│   │   └── main.go
│   ├── 02_variables/
│   │   └── main.go
│   ├── 03_functions/
│   │   └── main.go
│   ├── 04_structs/
│   │   └── main.go
│   └── 05_concurrency/
│       └── main.go
└── build/
```

## 构建工具链

- Go：`G:\scoop\apps\go\current\bin\go.exe`

## 编译与验证

```powershell
cd G:\code\guide\go
.\build.ps1 -All
```

单个示例：

```powershell
.\build.ps1 -Project 03_functions
```

清理：

```powershell
.\build.ps1 -Clean
```

## 说明

- Go 是 Google 推出的静态类型编程语言，适合后端服务、CLI、云原生和系统编程。
- 本目录通过本机 Go 编译器对每个示例做 `go build`/`go run` 验证，确保脚本在当前环境中真实可编译。
- 示例涵盖了基础语法、变量、函数、结构体和并发等核心知识点。
