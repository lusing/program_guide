# Julia 编程指南示例集

本目录按 `guide` 统一结构组织 Julia 教程与可验证示例。

## 目录结构

```text
julia/
├── README.md
├── Julia编程指南.md
├── build.ps1
└── examples/
    ├── 01_hello.jl
    ├── 02_types_variables.jl
    ├── 03_control_flow.jl
    ├── 04_functions_dispatch.jl
    ├── 05_arrays_broadcast.jl
    ├── 06_dict_set.jl
    ├── 07_structs.jl
    ├── 08_error_handling.jl
    ├── 09_file_io.jl
    ├── 10_modules.jl
    ├── 11_iterators.jl
    ├── 12_comprehension.jl
    ├── 13_linear_algebra.jl
    ├── 14_async_tasks.jl
    └── 15_testing_style.jl
```

## 构建工具链

- Julia：`G:\scoop\apps\julia\current`
- 可执行文件：`G:\scoop\apps\julia\current\bin\julia.exe`

## 编译/验证

```powershell
cd G:\code\guide\julia
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File 09_file_io.jl
```

清理：

```powershell
.\build.ps1 -Clean
```

