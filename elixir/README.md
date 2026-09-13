# Elixir 编程指南示例集

本目录按 `guide` 统一结构组织 Elixir 教程与可编译示例。

## 目录结构

```text
elixir/
├── README.md
├── Elixir编程指南.md
├── build.ps1
└── examples/
    ├── 01_hello.ex
    ├── 02_types_pattern.ex
    ├── 03_enum_pipeline.ex
    ├── 04_recursion.ex
    ├── 05_struct_protocol.ex
    ├── 06_error_handling.ex
    ├── 07_module_alias_import.ex
    ├── 08_task_async.ex
    ├── 09_agent_state.ex
    ├── 10_genserver_counter.ex
    ├── 11_supervisor_spec.ex
    ├── 12_file_io.ex
    ├── 13_regex_binary.ex
    ├── 14_macro_demo.ex
    └── 15_streams.ex
```

## 构建工具链

- Elixir：`G:\scoop\apps\elixir\current`
- 编译器：`G:\scoop\apps\elixir\current\bin\elixirc.bat`

## 编译验证

```powershell
cd G:\code\guide\elixir
.\build.ps1 -All
```

单文件编译：

```powershell
.\build.ps1 -File 10_genserver_counter.ex
```

清理：

```powershell
.\build.ps1 -Clean
```

