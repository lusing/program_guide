# Ada 编程指南示例集

本目录按 `guide` 统一结构组织 Ada 教程与可编译示例。

## 目录结构

```text
Ada/
├── README.md
├── Ada开发指南.md
├── build.ps1
├── examples/
│   ├── ch01_hello.adb
│   ├── ch02_types.adb
│   ├── ...
│   ├── ch17_spark.adb
│   └── ch07_math_lib.ads/.adb
├── src/      (历史源码保留)
└── build/
```

说明：
- `examples/` 是标准化后的编译验证目录。
- `src/` 暂保留为历史来源，便于追溯。

## 构建工具链

- GCC Ada (GNAT)：`G:\scoop\apps\msys2\current\ucrt64\bin\gnatmake.exe`
- 来自：`G:\scoop\apps\msys2\current`

## 编译验证

```powershell
cd G:\code\guide\Ada
.\build.ps1 -All
```

单文件编译：

```powershell
.\build.ps1 -File ch10_oop.adb
```

清理：

```powershell
.\build.ps1 -Clean
```

