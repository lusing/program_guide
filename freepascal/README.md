# Free Pascal 编程指南示例集

本目录按 `guide` 统一结构组织 Free Pascal / Lazarus 教程与可验证示例。

## 目录结构

```text
freepascal/
├── README.md
├── Free Pascal编程指南.md
├── build.ps1            PowerShell 入口（自动探测工具链）
├── run-all.sh           等价的 shell 入口
├── examples/
│   ├── 01_hello.pas
│   ├── 02_variables.pas
│   ├── 03_arithmetic.pas
│   ├── 04_if_case.pas
│   ├── 05_loops.pas
│   ├── 06_procedures.pas
│   ├── 07_records.pas
│   ├── 08_arrays.pas
│   ├── 09_strings_sets.pas
│   ├── 10_pointers.pas
│   ├── 11_file_io.pas
│   ├── 12_classes.pas
│   ├── 13_lazarus_gui/
│   │   ├── LazarusGuiDemo.lpr
│   │   ├── LazarusGuiDemo.lpi
│   │   ├── Unit1.pas
│   │   └── Unit1.lfm
│   ├── 14_lazarus_advanced_controls/
│   │   ├── AdvancedControlsDemo.lpr
│   │   ├── AdvancedControlsDemo.lpi
│   │   ├── Unit1.pas
│   │   └── Unit1.lfm
│   └── 15_lazarus_menus_dialogs/
│       ├── LazarusMenusDemo.lpr
│       ├── LazarusMenusDemo.lpi
│       ├── MainForm.pas
│       ├── SecondForm.pas
│       └── (可选的 .lfm 资源文件)
└── build/
```

## 构建工具链

| | Windows | macOS |
|---|---|---|
| 编译器 | `G:\scoop\apps\freepascal\current\bin\i386-win32\fpc.exe` | `/opt/local/bin/fpc`（3.2.2，x86_64-apple-darwin） |
| GUI 构建 | `G:\scoop\apps\lazarus\current\lazbuild.exe` | `/opt/local/bin/lazbuild`（4.8，控件集默认 cocoa） |
| 入口脚本 | `build.ps1`（pwsh 或 Windows PowerShell） | `run-all.sh`（等价 shell 入口，`build.ps1` 同样可用） |

两个入口都会按 `FPC` / `LAZBUILD` 环境变量 → PATH → 上表常见路径的顺序探测工具链，
换机器不必改脚本。

## 编译/验证

全部示例（Windows）：

```powershell
cd G:\code\guide\freepascal
.\build.ps1 -All
```

全部示例（macOS / Linux）：

```bash
./run-all.sh                # 12 个命令行示例 × 两种语言模式 + 3 个 Lazarus 工程
./run-all.sh 03 09          # 只跑指定编号
./run-all.sh -v 08          # 附带每个示例的完整输出
./run-all.sh --gui          # 只构建 Lazarus 工程
```

单文件验证：

```powershell
.\build.ps1 -File 08_arrays.pas
```

```bash
./run-all.sh 08             # 等价写法，也支持 ./build.ps1 -File 08
```

清理：

```powershell
.\build.ps1 -Clean
```

```bash
./run-all.sh --clean
```

## 判定标准

每个示例四条：退出码为 0、stderr 为空、stdout 无多余控制字符、输出里有结束标记
`==== NN 结束 ====`。目前本目录的 12 个示例还没有打印结束标记，这一条按「stdout 非空」
降级判定并在摘要里单独提示；示例补上标记后两个入口都会自动收紧。
任一示例失败时脚本返回退出码 1，便于做回归。

## 说明

- Free Pascal 是经典 Pascal 语言的现代实现，适合学习结构化编程、过程式编程和面向对象编程。
- 本目录的 12 个命令行示例已在 Windows 与 macOS 两套工具链上完成「编译 + 运行」验证：
  源码本身不含任何平台相关代码（`examples/` 里没有 `uses Windows`），差异只在编译器路径和
  可执行文件后缀（Windows 带 `.exe`，macOS/Linux 无扩展名）。
- 每个示例额外用 `-MDelphi` 语言模式跑一遍作对照，两模式输出逐字节一致。FPC 默认模式
  （`-MFPC`）编不过 `11_file_io.pas` 与 `12_classes.pas`，所以对照通道选 delphi 而不是默认模式。
- 3 个 Lazarus 工程（`13_lazarus_gui/`、`14_lazarus_advanced_controls/`、`15_lazarus_menus_dialogs/`）
  用 `lazbuild` 做构建验证，Win32 与 macOS cocoa 两套 LCL 工程都能正常编译，产物可启动。
  `lazbuild` 不指定控件集时按宿主平台取默认值，工程文件本身是跨平台的。
- `examples/*/lib/` 是 Lazarus 的编译产物目录，只会生成当前平台那一个（Windows 下 `x86_64-win64`、
  Intel Mac 下 `x86_64-darwin`）。历史的 `lib/x86_64-win64/` 产物已从仓库清除，根 `.gitignore`
  增加了 `freepascal/examples/*/lib/`、`*.ppu`、`*.compiled` 三条规则，重新构建不会再进版本库。
