# 23 · 部署与发布：静态/动态链接与打包

> 对应示例：本章不新增示例工程，直接复用 `examples/25_notepad_plus`，用 `build.ps1 -Static` 产出第二套构建做对比。

> **本章你将学会**：MFC 程序的动态/静态链接差异（同一份代码实测体积与依赖）、`mfc140u.dll` 等 DLL 的分发方式、清单文件里 DPI 与视觉样式两个关键声明，以及交付前的自查方法。
> **前置知识**：第 02 章的命令行构建参数、第 14 章的 DPI。

## 1. 两种链接方式

前面所有示例都用 `/D_AFXDLL /MD` 编译——这是**动态链接**：MFC 和 C 运行库不进 exe，运行时从系统加载。换 `/MT`（去掉 `/D_AFXDLL`）就是**静态链接**：用到的库代码全部塞进 exe。

MFC 库按"动态/静态 × Debug/Release"分四种，命名规律 `mfc140[u][d]`：

| 组合 | 导入库（链接时） | 运行时 |
|---|---|---|
| 动态 Release | `mfc140u.lib` | `mfc140u.dll` |
| 动态 Debug | `mfc140ud.lib` | `mfc140ud.dll` |
| 静态 Release | `mfc140u.lib`（静态版） | 代码进 exe，无 DLL |
| 静态 Debug | `mfc140ud.lib`（静态版） | 同上 |

CRT 同理：`/MD` → `MSVCP140.dll` + `VCRUNTIME140.dll`；`/MT` → 进 exe。

"你的 exe 依赖了谁"：

```text
动态链接                                静态链接
┌─────────────┐                        ┌──────────────────┐
│ 你的 exe    │ ← 只有你的代码          │ 你的 exe          │
└──────┬──────┘                        │  + 你的代码       │
       │ 加载这些：                     │  + MFC 代码       │
       ▼                               │  + CRT 代码       │
 mfc140u.dll（MFC，Unicode）           └──────┬───────────┘
 MSVCP140.dll / VCRUNTIME140.dll              │ 加载这些：
 VCRUNTIME140_1.dll                           ▼
 api-ms-win-crt-*.dll（UCRT）           KERNEL32 / USER32 / GDI32
 KERNEL32 / USER32 / GDI32 …            （系统必有，不用管）
```

右边的系统 DLL 每台 Windows 都有；左边加粗那组是"拷到别人机器就报缺少 DLL"的元凶。

## 2. 实测：同一份代码的两种体积

用 `examples/25_notepad_plus` 同一份代码构建两版（build.ps1 的两种模式恰好对应两条命令行）：

| 构建 | 命令行 | 体积（实测） |
|---|---|---|
| 动态 | `cl /D_AFXDLL /MD` | **63,488 字节**（约 62 KB） |
| 静态 | `cl /MT`（无 `/D_AFXDLL`） | **2,555,904 字节**（约 2.4 MB） |

差了 40 倍。再用 `dumpbin /dependents` 看两版的外部依赖（这是 VS 自带的工具，vcvars 环境里运行）：

动态版依赖：

| DLL | 性质 | 目标机器上有吗 |
|---|---|---|
| `mfc140u.dll` | MFC（Unicode） | **不一定**——装了 VC 运行库才有 |
| `MSVCP140.dll` / `VCRUNTIME140.dll` / `VCRUNTIME140_1.dll` | VC 运行库 | 同上 |
| `api-ms-win-crt-*.dll` | UCRT（系统组件） | Win10/11 自带 |
| `KERNEL32/USER32/GDI32.dll` | 系统 | 必有 |

静态版依赖只剩系统 DLL（KERNEL32、USER32、GDI32、UxTheme、ole32、SHELL32 等）——**没有 `mfc140u.dll`，也没有 VCRUNTIME**。

体积差从哪来：静态链接把"用到的 MFC 模块 + CRT"整段编进 exe。代价不只是体积——MFC/CRT 的任何更新（安全补丁）都不会惠及你的 exe，得自己重编重发。

选型：**内部工具、便携绿色版、单文件交付 → 静态**；正常对外分发、多个程序共享运行库 → 动态。

## 3. 动态链接的部署清单

动态版要跑起来，目标机器必须有 MFC 和 VC 运行库。三种分发方式：

1. **`vc_redist.x64.exe`**——微软官方运行库安装器，最标准。安装包把它作为前置步骤跑一次；绿色分发没有安装环节，用不了这条
2. **应用本地部署（app-local）**——把 `mfc140u.dll`、`msvcp140.dll`、`vcruntime140.dll`、`vcruntime140_1.dll` 直接拷到 exe 旁边。加载器找 DLL 时先看 exe 目录，就地命中。注意分发这些 DLL 要遵守微软的分发条款（随 VS 安装的红istributable 文件允许随应用分发）
3. **静态链接**——什么都不用拷，一劳永逸；代价是第 2 节的 40 倍体积

"开发机跑得好好的，拷到别人机器就报缺少 DLL"的成因就一句话：**开发机装了 VS（运行库全在），目标机器没有**。排查顺序：看报错弹窗点名哪个 DLL → `dumpbin /dependents` 列全清单 → 逐个确认目标机器有无 → 缺的用上面三种方式之一补。

## 4. 清单文件：DPI 与视觉样式

清单（manifest）是一段 XML，可以放在 exe 旁边的 `<exe名>.exe.manifest`，也可以编译进资源（VC 工程默认后者）。对 MFC 程序最要紧的两个声明：

```xml
<!-- ① Per-Monitor v2 DPI 感知：比 API 调用更早生效、更可靠 -->
<application xmlns="urn:schemas-microsoft-com:asm.v3">
  <windowsSettings>
    <dpiAwareness xmlns="http://schemas.microsoft.com/SMI/2016/WindowsSettings">PerMonitorV2</dpiAwareness>
  </windowsSettings>
</application>

<!-- ② 视觉样式：声明 Common-Controls 6.0，控件才有现代外观 -->
<dependency>
  <dependentAssembly>
    <assemblyIdentity type="win32" name="Microsoft.Windows.Common-Controls"
      version="6.0.0.0" processorArchitecture="*"
      publicKeyToken="6595b64144ccf1df" language="*" />
  </dependentAssembly>
</dependency>
```

- **DPI**：第 14 章用 `SetProcessDpiAwarenessContext` API 声明，但清单在**进程加载时**就生效，比任何 API 调用都早，两者选一（清单优先）。本章的命令行构建没有清单，所以第 14 章示例走了 API 路线
- **视觉样式**：不声明 Common-Controls 6.0，按钮/滚动条就是 Windows 95 经典外观——很多"我的 MFC 程序界面很老气"其实只是缺这一段
- `/MANIFESTUAC`（或清单里的 `requestedExecutionLevel`）控制 UAC：`asInvoker`（默认，跟启动者走）／`highestAvailable`／`requireAdministrator`（强制管理员）

## 5. 打包与分发

一个最小发布目录：

```text
MyApp/
├── MyApp.exe              ← release 构建（绝不放 /MDd 的 debug 版）
├── mfc140u.dll 等         ← 动态链接时的 app-local 运行库（或装 vc_redist）
├── MyApp.exe.manifest     ← 外部清单（若没编进资源）
└── 资源文件（配置/图片/语言文件）
```

交付前的自查三步：

1. **`dumpbin /dependents MyApp.exe`** 列出全部依赖，逐个确认目标环境（或打包清单）覆盖
2. **在干净环境实测**：没装 VS 的机器、或干净的 Windows 虚拟机——"开发机能跑"不算验证
3. **确认是 release 构建**：Debug 版依赖 `mfc140ud.dll` 和调试 CRT，**根本不该被分发**（而且微软条款禁止单独分发调试 CRT）

分发形态：ZIP 绿色包（解压即用，配合静态链接最省心）对工具类程序足够；安装包（MSI/WiX、NSIS、Inno Setup）处理"写注册表、建快捷方式、装运行库"这些事——原理都在上面，本书不实操安装包制作。

## 常见坑

1. **静态链接时忘了去掉 `/D_AFXDLL`**
   `/D_AFXDLL`（MFC 动态）与 `/MT`（CRT 静态）混用，链接器报运行时库冲突（LNK4098 起，严重的直接 LNK 错误）。两条线一起切：动态 = `/D_AFXDLL /MD`，静态 = 无 `/D_AFXDLL` + `/MT`——build.ps1 的 `-Static` 开关就是干这个的。

2. **动态版只拷了 exe**
   目标机器弹"无法启动，缺少 mfc140u.dll"。`dumpbin /dependents` 交付前自查一遍，缺什么补什么（或改静态）。

3. **清单里的 `Common-Controls` 写成 5.x**
   版本号 5.x 是旧版控件库，视觉样式不生效——界面依然是 Win95 外观。必须 6.0.0.0。

4. **静态版体积暴涨当成 bug**
   63 KB → 2.4 MB 是静态链接的正常代价（MFC + CRT 全进 exe），不是"编错了"。对照本节实测数字就心里有数。

5. **把 Debug 构建发给用户**
   `/MDd` 版依赖调试 CRT 与 `mfc140ud.dll`，用户机器上没有，也没有分发渠道。发版检查清单第一条：确认编译参数里没有 `d`。

## 实战建议

- 内部工具直接静态链接（`-Static`），拷过去就能跑，省掉所有运行库沟通成本；对外正式分发用动态 + `vc_redist`，体积小且补丁跟随系统
- 交付前 `dumpbin /dependents` 自查是零成本的保险——写进打包脚本
- 清单文件从项目第一天就加上（DPI + Common-Controls 6.0），后期补清单容易漏掉"某些窗口忘了跟随"的暗病
- 干净虚拟机是部署测试的最小标配：开发机的"能跑"永远不作数

## 自测

1. **动态和静态链接的编译参数差异是什么？各自的体积与依赖代价？**
   —— 动态 `/D_AFXDLL /MD`，exe 小（实测 63 KB）但依赖 `mfc140u.dll` + VC 运行库；静态去掉 `/D_AFXDLL` 用 `/MT`，体积暴涨（实测 2.4 MB）但只剩系统 DLL 依赖，拷走即跑。

2. **"拷到别人机器报缺少 DLL"，成因和排查方法？**
   —— 开发机有 VS 运行库、目标机器没有。`dumpbin /dependents` 列全依赖清单，对照确认哪些缺失；用 `vc_redist`、app-local 拷 DLL 或改静态链接补齐。

3. **清单文件里对 MFC 程序最重要的两个声明是什么？**
   —— `dpiAwareness = PerMonitorV2`（比 API 更早生效的 DPI 感知）和 `Microsoft.Windows.Common-Controls 6.0`（视觉样式，缺了就是 Win95 外观）。

4. **为什么 Debug 构建绝不能分发？**
   —— 它依赖调试版 CRT（`/MDd` → `mfc140ud.dll` 等），用户机器上没有，微软条款也不允许单独分发调试 CRT；而且 Debug 版没优化、体积大。发版只放 release 构建。

---
上一章：[22 现代绘图：GDI+ 与 Direct2D](22-modern-drawing.md) ｜ 下一章：[24 MFC 与现代 C++](24-modern-cpp.md)
