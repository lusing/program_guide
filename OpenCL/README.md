# OpenCL Windows 平台开发教程示例工程

该目录用于存放 `OpenCL_Windows_Tutorial.md` 中的代码块，并提供统一编译验证入口。

## 目录结构

- `snippets/`：从教程中提取的全部代码块，按语言和章节分组
- `examples/`：可在当前环境下编译验证的 OpenCL 主机程序示例（当前 4 个）
- `build.ps1`：统一编译验证脚本
- `build/`：编译产物输出目录

## 编译与验证

```powershell
# 编译全部可验证示例
.\build.ps1 -All

# 编译单个示例
.\build.ps1 -File "第一个_OpenCL_程序\007_第一个_OpenCL_程序_section.c"

# 清理编译产物
.\build.ps1 -Clean
```

## 依赖说明

- OpenCL 头文件：`G:\cuda\v13.3\include\CL`
- OpenCL 库：`G:\cuda\v13.3\lib\x64\OpenCL.lib`
- Visual Studio：`G:\Program Files\Microsoft Visual Studio\18\Community`
