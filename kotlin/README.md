# Kotlin 编程指南示例工程

该目录用于存放 `KOTLIN_GUIDE.md` 中的可运行源码与配套示例，并提供统一编译验证入口。

## 目录结构

- `snippets/`：从指南中提取的所有代码块，按语言和章节分组（共 169 个）
- `examples/`：可在当前 JVM 环境下编译验证的 Kotlin 示例（当前 6 个）
- `build.ps1`：统一编译验证脚本
- `build/`：编译验证产物与临时输出目录

## 编译与验证

```powershell
# 编译可验证的全部 Kotlin 示例
.\build.ps1 -All

# 编译单个示例
.\build.ps1 -File "8._协程\036_8._协程_8.4_协程取消与超时.kt"

# 清理编译产物
.\build.ps1 -Clean
```

## 说明

- 当前环境中的 Kotlin 编译器位于 `G:\scoop\apps\kotlin\2.4.20\bin\kotlinc-jvm.bat`
- JavaFX 与 Kotlin/JS 章节需要额外的平台工具链，因此目前只保留在 `snippets/` 中，不纳入本地 JVM 编译验证
