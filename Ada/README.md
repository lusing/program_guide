# Ada 编程指南示例集

本目录按 `guide` 统一结构组织 Ada 教程与可编译示例。

## 目录结构

```text
Ada/
├── README.md
├── Ada开发指南.md
├── build.ps1        (Windows 构建脚本)
├── run-all.sh       (Linux/macOS 构建运行脚本)
├── examples/
│   ├── ch01_hello.adb
│   ├── ch02_types.adb
│   ├── ...
│   ├── ch17_spark.adb
│   └── ch07_math_lib.ads/.adb
├── src/      (历史源码保留，与 examples/ 内容一致)
└── build/    (构建输出，已加入 .gitignore)
```

说明：
- `examples/` 是标准化后的编译验证目录。
- `src/` 暂保留为历史来源，便于追溯。
- 根目录下的 `.ali`/`.o` 等 GNAT 中间产物不再纳入版本控制。

## 构建工具链

- Windows：GCC Ada (GNAT)，MSYS2 UCRT64
- Linux：发行版自带 GNAT（如 `sudo apt install gnat`），或 Alire 工具链

## 编译验证

Windows (PowerShell)：

```powershell
cd G:\code\guide\Ada
.\build.ps1 -All
```

Linux / macOS：

```bash
cd guide/Ada
./run-all.sh            # 编译并运行全部 17 个示例
./run-all.sh 01 13      # 只跑指定章节
./run-all.sh --clean    # 清理 build 目录
```

单文件编译（以 ch10 为例）：

```powershell
# Windows
.\build.ps1 -File ch10_oop.adb

# Linux / macOS
./run-all.sh 10
```

## 平台差异说明

- `ch13_c_interop` 导入 C 的 `sqrtf`，Linux 下数学函数位于独立的
  libm，需附加链接选项 `-largs -lm`（`run-all.sh` 已自动处理；
  Windows UCRT 已把数学函数并入主 C 运行时，无需指定）。
- `ch16_contracts` / `ch17_spark` 需 `-gnata` 启用契约断言
  （两个构建脚本均已自动处理）。
- 手动编译示例：

```bash
# Linux 下单文件编译
gnatmake -o ch01_hello examples/ch01_hello.adb        # 一般示例
gnatmake -o ch13_c_interop examples/ch13_c_interop.adb -largs -lm   # 需 libm
gnatmake -gnata -o ch16_contracts examples/ch16_contracts.adb       # 需断言
```
