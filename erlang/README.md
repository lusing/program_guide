# Erlang/OTP 编程指南示例集

本目录按 `guide` 统一结构组织 Erlang/OTP 教程与可编译示例。

## 目录结构

```text
erlang/
├── README.md
├── Erlang-OTP编程指南.md
├── build.ps1
└── examples/
    ├── e01_hello.erl
    ├── e02_types_pattern.erl
    ├── e03_lists_tuples.erl
    ├── e04_recursion_guards.erl
    ├── e05_hof.erl
    ├── e06_error_handling.erl
    ├── e07_records_maps.erl
    ├── e08_process_message.erl
    ├── e09_counter_server.erl
    ├── e10_ets_demo.erl
    ├── e11_binary_bitstring.erl
    ├── e12_string_unicode.erl
    ├── e13_case_if.erl
    ├── e14_list_comprehension.erl
    ├── e15_proplists.erl
    ├── e16_sets_demo.erl
    ├── e17_gb_trees_demo.erl
    ├── e18_queue_demo.erl
    ├── e19_orddict_demo.erl
    ├── e20_timer_timeout.erl
    ├── e21_monitor_demo.erl
    ├── e22_supervisor_spec.erl
    ├── e23_application_env.erl
    ├── e24_file_io.erl
    ├── e25_regex_demo.erl
    ├── e26_term_binary.erl
    ├── e27_rand_demo.erl
    ├── e28_spawn_pool.erl
    ├── e29_maps_advanced.erl
    └── e30_logger_demo.erl
```

## 构建工具链

- Erlang/OTP：`G:\scoop\apps\erlang\current`
- 编译器：`G:\scoop\apps\erlang\current\bin\erlc.exe`

## 编译验证

```powershell
cd G:\code\guide\erlang
.\build.ps1 -All
```

单文件编译：

```powershell
.\build.ps1 -File e08_process_message.erl
```

清理：

```powershell
.\build.ps1 -Clean
```
