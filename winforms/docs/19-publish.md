# 19 · 发布与部署

> 对应示例：`examples/19_publish/csharp`（"我是谁"演示程序：版本/运行时/目录摆在明面上）

> **本章你将学会**：dotnet publish 三种形态与体积权衡、单文件、C++/CLI 的部署注意、ClickOnce 一瞥。
> **前置章节**：全部——这是毕业分发。

## 1. 教材的"打包"与现代等价物

书的第 10 章用 Visual Studio Installer Projects 造 MSI 安装包（2018 年的标准流程：添加工程 → 选输出 → 生成 .msi）。现代 .NET 的日常分发是 **`dotnet publish`** 三形态——先跑起来再谈安装包。

## 2. 三种发布形态（本机实测数字）

对 19 示例（`PublishWin.csproj`，net10.0-windows）实测：

```powershell
cd examples/19_publish/csharp
dotnet publish -c Release -o build/fx                                    # 框架依赖
dotnet publish -c Release -o build/self -r win-x64 --self-contained true # 自包含
dotnet publish -c Release -o build/single -r win-x64 --self-contained true `
                -p:PublishSingleFile=true                               # 单文件
```

| 形态 | 文件数 | 体积 | 目标机要求 |
|---|---|---|---|
| 框架依赖 | 5 | **0.2 MB** | 需装 .NET 10 Desktop Runtime |
| 自包含 win-x64 | 271 | 117.2 MB | 无（运行时一起带走） |
| 单文件自包含 | 2 | 110.7 MB | 无（一个 exe 拉起） |

```text
fx/      PublishWin.exe + .dll + .deps.json + .runtimeconfig.json + .pdb
self/    上述 + 全套运行时 dll + e_*.dll 原生库…
single/  PublishWin.exe（110.7 MB）+ .pdb（正式发布可去掉）
```

单文件 exe 双击即跑（实测拉起正常）。**选型**：内网工具且能装运行时 → 框架依赖；发给客户/绿色版 → 单文件自包含。

### 常用附加开关

```powershell
-p:PublishSingleFile=true        # 单文件（需 self-contained 才有意义）
-p:IncludeNativeLibrariesForSelfExtract=true   # 原生库也打进单文件（首次启动解压到临时目录）
-p:PublishTrimmed=true           # 裁剪未用 IL——⚠️ WinForms 反射重灾区，轻易别开（控件/序列化类型被裁掉运行时才炸）
-p:EnableCompressionInSingleFile=true         # 单文件压缩
-p:DebugType=none                # 不带 pdb
```

**Trim 与 WinForms 相性差**：框架内部大量按字符串反射找类型，裁剪器看不出来，运行时 `TypeLoadException`/缺控件——要上 Trim 必须配 TrimmerRootDescriptor 逐个保根，教学项目直接不开。

## 3. 版本信息

```xml
<PropertyGroup>
  <Version>1.2.0</Version>
  <AssemblyTitle>发布演示</AssemblyTitle>
</PropertyGroup>
```

```csharp
var asm = Assembly.GetExecutingAssembly();
asm.GetName().Name;      // 程序集名
asm.GetName().Version;   // 1.2.0（文件属性 → 详细信息里就是它）
```

19 示例把版本、运行时、`AppContext.BaseDirectory` 全显示出来——三种形态各跑一遍，肉眼确认"我到底是谁、从哪来"。

## 4. C++/CLI 的部署注意

混合模式 DLL 的发布多两件事：

1. **`Ijwhost.dll` 必须随行**——它混合模式程序集的加载器（构建自动拷到输出目录，自包含/单文件发布时确认它在）。单文件场景建议 `-p:IncludeNativeLibrariesForSelfExtract=true` 把它一起吞进去。
2. **平台是 x64 定死**的（C++/CLI 不产 AnyCPU）——目标机架构要在发布参数里对齐（`-r win-x64`）。
3. 18 章的教训依然有效：**vcxproj 中转的 NuGet 依赖不流动**，最终 exe 工程要把包声明齐。

## 5. ClickOnce 一瞥

VS 里的"发布向导"（项目属性 → 发布）生成 ClickOnce 部署：一个 URL/共享目录，客户端装上后**自动检查更新**。适合企业内部分发的自动更新场景。命令行等价物是 `dotnet publish /p:PublishProfile=...`（.pubxml 描述 Profile）。想要传统安装体验（开始菜单/卸载项）再看 VS Installer Projects 扩展（书里第 10 章流程的现代版）或 WiX——它们把 publish 产物打包成 MSI。

## 6. 应用程序图标与元数据

```xml
<PropertyGroup>
  <ApplicationIcon>app.ico</ApplicationIcon>     <!-- exe 的资源管理器图标 -->
  <Product>发布演示</Product>
  <Company>winforms 教程</Company>
</PropertyGroup>
```

窗体标题栏图标则是 `form.Icon = new Icon("app.ico")`（或嵌进资源后 `Properties.Resources`）。

## 坑位清单

1. 单文件发布忘了 `--self-contained` → 出来的还是一堆文件（单文件的意义在自带运行时）。
2. WinForms 开 `PublishTrimmed` → 反射类型被裁，运行时缺控件/炸 TypeLoad。
3. 框架依赖发给没装运行时的机器 → 双击弹"要下载 .NET"（这也是它的用途——引导安装）。
4. C++/CLI 部署漏 `Ijwhost.dll` → 加载失败。
5. 单文件模式首次启动慢 → 原生库在解压；`IncludeNativeLibrariesForSelfExtract` 是双刃剑。

## 自测

1. 三种形态的体积-依赖权衡？内网工具 vs 绿色外发各选哪个？
2. 为什么 WinForms 与 Trim 相性差？
3. 单文件 exe 的 `AppContext.BaseDirectory` 指向哪？（19 示例实测看）
4. C++/CLI 部署比纯托管多带什么文件？为什么？
5. ClickOnce 相比 MSI 的核心优势？

---

上一章：[18 SQLite 与三层雏形](18-data.md) · 下一章：[20 实战：客房管理系统](20-project.md)
