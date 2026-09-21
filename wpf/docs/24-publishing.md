# 24 · 部署与发布

> 对应示例：`examples/25_notepad_plus`（本章用实战项目实测三种发布模式）

> **本章你将学会**：三种发布模式的取舍、dotnet publish 常用参数、图标与元数据设置、发布前检查清单。
> **前置章节**：[25 实战项目](25-notepad-plus.md)的代码（本章拿它当发布对象）。

## 1. 三种发布模式：先看实测数字

程序写完交给用户，第一个问题是"用户的机器上有没有 .NET"。三种模式对应三种答案（以下为 `25_notepad_plus` 在 .NET 10 SDK 上的实测）：

| 模式 | 产物 | 体积 | 目标机器要求 |
|---|---|---|---|
| **框架依赖**（默认） | exe + 少量 dll | **226 KB** | 已装 .NET 10 Desktop Runtime |
| **自包含** self-contained | 整个文件夹 | **142 MB** | 无任何要求 |
| **单文件** single-file | 一个 exe（+3 个原生 dll） | **131 MB** | 无任何要求 |

结论先行：

- **内部工具、确定会装运行时的环境** → 框架依赖（体积最小，运行时统一升级）
- **分发给外部用户** → 自包含或单文件（用户零安装，体积代价换来的）
- 演示/U 盘场景 → 单文件最方便

## 2. 框架依赖发布（默认）

```powershell
cd examples\25_notepad_plus
dotnet publish -c Release -o publish\fdd
```

产物就 5 个文件 226KB：exe（启动器）+ 程序 dll + deps.json + runtimeconfig.json + pdb。**运行前提**：目标机器装了 `.NET Desktop Runtime 10`（WPF 程序要 "Desktop" 版运行时，不是基础版 ASP.NET 版）。没装的用户双击 exe 弹系统错误——分发给外部用户时这是主要劝退点。

给内部用户的标准做法：IT 统一部署运行时，所有 .NET 程序共享，安全补丁跟着 Windows Update 走。

## 3. 自包含发布

```powershell
dotnet publish -c Release -r win-x64 --self-contained -o publish\scd
```

`-r win-x64`（Runtime Identifier，运行时标识）指定目标平台；`--self-contained` 把整个 .NET 运行时 + WPF 打进产物。142MB 听着吓人，但对"用户什么都不用装"的诉求这是诚实的价格——现代 GUI 框架（Electron 动辄 200MB+）都这个量级。

要点：

- **RID 决定能跑在哪**：`win-x64`（64 位 Intel/AMD，覆盖面默认选它）、`win-arm64`（Surface/新架构）。一次 publish 只面向一个 RID
- 自包含 = 运行时被你"钉死"在产物里，**不会跟系统升级**——安全补丁要靠你重新发布
- 目标机器的运行时与你的产物互不干扰（并排加载），不怕用户装了旧版

## 4. 单文件发布

```powershell
dotnet publish -c Release -r win-x64 --self-contained -p:PublishSingleFile=true -o publish\single
```

把托管部分全部合并进一个 exe——实测 **NotepadPlus.exe 131MB**。但注意实测产物的真相：**WPF 的三个原生 dll（D3DCompiler、PresentationNative、PenImc）仍留在 exe 旁边**——WPF 的原生依赖默认不进单文件。要"真·单文件"再加一个参数：

```xml
<PropertyGroup>
  <IncludeNativeLibrariesForSelfExtract>true</IncludeNativeLibrariesForSelfExtract>
</PropertyGroup>
```

它把原生 dll 也压进 exe，**首次启动时解压到临时目录再加载**——首次启动变慢、磁盘上会多一个缓存目录。单文件是分发形态的优化，不是性能优化，想清楚再上。

另一个常被问的组合：**`PublishTrimmed`（裁剪）对 WPF 不可用**——WPF 依赖大量反射加载 XAML/资源，官方不支持裁剪，强行开会运行时炸。别把 MAUI/控制台的裁剪经验平移过来。

## 5. 发布前的工程配置

发布质量的一半在 csproj。实战项目的完整配置（按需取用）：

```xml
<PropertyGroup>
    <OutputType>WinExe</OutputType>
    <TargetFramework>net10.0-windows</TargetFramework>
    <UseWPF>true</UseWPF>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <!-- 发布相关 -->
    <ApplicationIcon>app.ico</ApplicationIcon>          <!-- exe 文件图标 -->
    <AssemblyName>NotepadPlus</AssemblyName>             <!-- exe/dll 文件名 -->
    <Version>1.2.0</Version>                             <!-- 文件属性里的版本号 -->
    <Product>记事本+</Product>
    <Company>...</Company>
    <InvariantGlobalization>false</InvariantGlobalization>
    <!-- 想固定某种模式，写进 csproj 免得每次敲参数：
    <SelfContained>true</SelfContained>
    <RuntimeIdentifier>win-x64</RuntimeIdentifier>
    <PublishSingleFile>true</PublishSingleFile>
    -->
</PropertyGroup>
```

**窗口左上角与任务栏图标**是另一个位置：`<Window Icon="app.ico">`——`ApplicationIcon` 只管 exe 文件的图标，窗口图标要单独设（新手常改了一个问另一个为什么没变）。

版本号语义建议：主版本.次版本.修订（1.2.0），每次发布递增——将来做"检查更新"时它就是比对依据。

## 6. 发布前检查清单

- [ ] **Release 配置**：`-c Release`（Debug 产物慢且大，别拿去分发）
- [ ] **pdb 想清楚要不要**：默认跟着发（崩溃栈可读）；不给用户符号就 `-p:DebugType=none`
- [ ] **真机冒烟**：在**没装 SDK 的机器**（或干净的虚拟机）上跑一遍产物——"我机器上好好的"是部署期最贵的句子
- [ ] **全局异常钩子**（第 02 章）+ 日志落盘：用户机器上没有你的调试器
- [ ] **DPI/缩放**：100%/150%/200% 各过一眼（WPF 默认 PerMonitorV2，一般不用动，自定义 UI 要自查）
- [ ] 管理员权限需求？默认不需要，别把"要权限才能写"的目录当数据目录——配置存 `%APPDATA%`（第 25 章的 RecentFilesService 是标准做法）

## 7. 常见坑

**目标机器双击没反应**：框架依赖模式 + 没装 Desktop Runtime。要么改自包含，要么装运行时（下载页选 ".NET Desktop Runtime"，不是 ASP.NET 的）。

**单文件后 WPF 程序启动变慢**：IncludeNativeLibrariesForSelfExtract 首启解压的正常代价；介意就回普通自包含。

**PublishTrimmed 开了各种崩**：WPF 不支持裁剪（第 4 节），关掉。

**在 arm64 机器上发 win-x64 包**：能跑（模拟层）但原生 dll 加载失败的边缘问题不少——arm64 机器发 win-arm64 包。

**发布目录里一堆 Debug 的旧文件**：发布永远指向干净目录（-o publish\... 且目录名带模式），不要复用 bin 目录。

**图标只在文件属性里变了**：窗口图标（Window.Icon）与 exe 图标（ApplicationIcon）是两处，都要设；资源缓存（Windows 图标缓存）可能让旧图标赖着——改图标后重启资源管理器或换文件名验证。

## 8. 实战建议

- 个人/团队工具默认框架依赖；对外分发默认自包含单文件——两个 PowerShell 脚本（publish-fdd.ps1 / publish-scd.ps1）放仓库里，一条命令出包
- 检查更新的最小实现：GitHub Releases / 内网共享放个 `latest.json`（版本号 + 下载地址），启动时比对 Version 提示下载
- 安装包（MSIX/Inno Setup/NSIS）是下一步：开始菜单、卸载、文件关联。MSIX 是微软正统但签名要求麻烦；Inno Setup 对内部工具够用。本章的产物就是它们的输入
- 把"发布 + 真机冒烟"做成发版流程的一环（哪怕手动的），比任何事后补救便宜

## 自测

1. **三种发布模式各自的适用场景？** —— 框架依赖（内部/已装运行时）、自包含（外部分发）、单文件（便携场景）。
2. **为什么 WPF 的单文件旁边还有三个原生 dll？** —— 原生依赖默认不合并；IncludeNativeLibrariesForSelfExtract 才进 exe（首启解压的代价）。
3. **PublishTrimmed 为什么对 WPF 禁用？** —— WPF 大量反射加载（XAML/资源），裁剪砍掉后运行时炸，官方不支持。
4. **exe 图标和窗口图标是一回事吗？** —— 不是：ApplicationIcon（文件）与 Window.Icon（窗口/任务栏）两处各设各的。

---
上一章：[23 窗口与页面导航](23-navigation.md) ｜ 下一章：[25 实战项目：WPF 记事本+](25-notepad-plus.md)
