# Boost C++ 教程示例集

本目录按 `guide` 统一结构组织 Boost 教程与可编译示例。

## 目录结构

```text
boost/
├── README.md
├── BOOST编程指南.md
├── build.ps1
└── examples/
    ├── 01_algorithm_string.cpp
    ├── 02_optional.cpp
    ├── 03_variant.cpp
    ├── 04_dynamic_bitset.cpp
    ├── 05_property_tree_json.cpp
    ├── 06_uuid.cpp
    ├── 07_asio_timer.cpp
    └── 08_multi_index.cpp
```

## 构建工具链

- Boost: `G:\scoop\apps\boost\current`
- VC: `G:\Program Files\Microsoft Visual Studio\18\Community\VC`
- 编译器: `cl.exe (MSVC)`

## 编译验证

```powershell
cd G:\code\guide\boost
.\build.ps1 -All
```

清理：

```powershell
.\build.ps1 -Clean
```

单文件：

```powershell
.\build.ps1 -File 07_asio_timer.cpp
```

