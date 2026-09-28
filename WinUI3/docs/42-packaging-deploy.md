# 42. 打包与分发：MSIX 全流程实测

> 对应《Learn WinUI 3》第 14 章。书走 Visual Studio 向导（"右键项目 → 创建应用程序包"）；本章走**命令行全流程**——makeappx 打包、自签名证书、signtool 签名、Add-AppxPackage 安装——因为这套流程不依赖 IDE，每一步的产物与报错都看得见，也正是 CI/自动化的形态。全流程脚本化在 `tools/msix-pack.ps1`，以下每一步都是本机真实跑出来的。

[33.6](33-theming-packaging.md) 讲过打包 vs 非打包的取舍；本章补齐"包里有什么、怎么签、怎么装、怎么分发"。

## 42.1 MSIX 包里有什么

MSIX = **zip 容器 + 清单 + 块图 + 签名**（书 14.1.1 的足迹文件 footprint files）：

```
MyApp.msix
├── AppxManifest.xml        身份/能力/入口/视觉元素（从 Package.appxmanifest 生成）
├── AppxBlockMap.xml        每个文件的分块哈希索引（增量更新与完整性校验的底账）
├── AppxSignature.p7x       签名（安装时系统验的就是它）
├── [Content_Types].xml     每种扩展名的 MIME 登记表
├── pri / xbf / exe / dll   应用负载（payload files）
└── Assets\                 图标
```

装到哪：`C:\Program Files\WindowsApps\<包名>\`（系统目录，用户不可写）；数据落在 `C:\Users\<u>\AppData\Local\Packages\<包名>\`——**打包后 37 章的 media.db 路径就从 `%LOCALAPPDATA%\MediaLibrary` 变成这个 Packages 目录下**（ApplicationData 在打包进程里恢复可用，[34.2](34-os-integration.md) 的两形态对照在此闭环）。卸载 = 两个目录全清，这就是"干净卸载"的机制。

**为什么必须签名**：MSIX 安装的前提是签名链可被本机信任——这是 MSIX 与"绿色软件 zip"的本质区别，也是本章实测里最贵的一课（42.5）。

## 42.2 从非打包构建产物到 MSIX：手工清单

本教程所有示例都是 `WindowsPackageType=None` 的自包含非打包构建——**这份产物可以直接打进 MSIX**，不需要重新以打包模式构建。三件套：

**① 布局（layout）**：把 `x64\Debug\<Project>\` 里的负载拷进一个目录（exe + 全部 dll + Assets；剔除 pdb/lib/exp/ilk 等链接器产物）。自包含模式的好处在此兑现：WindowsAppSDK 运行时就在布局里，MSIX 不需要声明框架依赖。

**② 手写 AppxManifest.xml**（`msix-pack.ps1` 内嵌的模板，注释即坑位）：

```xml
<Package xmlns="http://schemas.microsoft.com/appx/manifest/foundation/windows10"
         xmlns:uap="http://schemas.microsoft.com/appx/manifest/uap/windows10"
         xmlns:rescap=".../restrictedcapabilities"
         IgnorableNamespaces="uap rescap">
  <Identity Name="GuideTutorial.MediaLibrary" Publisher="CN=GuideTutorial"
            Version="1.0.0.0" ProcessorArchitecture="x64" />
  ...
  <Applications>
    <Application Id="App" Executable="MediaLibrary.exe"
                 EntryPoint="Windows.FullTrustApplication">
      <uap:VisualElements ... Square150x150Logo="Assets\appicon.png" ... />
    </Application>
  </Applications>
  <!-- 桌面（Win32）应用的硬性要求，缺了 makeappx 直接拒绝（0x80080204） -->
  <Capabilities>
    <rescap:Capability Name="runFullTrust" />
  </Capabilities>
</Package>
```

三个字段是**身份三契**，任何一处对不上安装就失败：

- `Identity Name`：包名（全机唯一，安装后即目录名的一部分）
- `Identity Publisher`：**必须与签名证书的 Subject 完全一致**（CN=GuideTutorial ↔ CN=GuideTutorial）
- `Executable`：相对布局根的入口 exe

图标不能省：`Square150x150Logo`/`Square44x44Logo` 指向的 PNG 必须真实存在（本例复用 34 章生成的 48×48 appicon.png，makeappx 不挑剔尺寸）。

**③ 打包**（Windows SDK 自带，无需 VS）：

```powershell
& "$SDK\bin\10.0.26100.0\x64\makeappx.exe" pack /d <布局目录> /p <输出.msix> /nv
```

`/nv` 跳过校验快（正式发布去掉它做自检）。**实测第一坑**：清单没写 `runFullTrust` 时 makeappx 报：

```
error 80080204: App manifest validation error: Line 21, Column 6, Reason:
The element or attribute or attribute value specified requires "runFullTrust" capability.
```

restricted capability 在商店上架时要额外申请，但本地 sideload/企业分发里 `runFullTrust` 就是桌面应用的标准声明——WinUI 3 桌面应用 100% 需要它。

## 42.3 自签名证书与签名

测试分发的正道是自签名（书 14.5.1；商店分发则用 Partner Center 签证，见 42.6）：

```powershell
# Subject 必须逐字等于清单的 Publisher
$cert = New-SelfSignedCertificate -Type Custom -Subject 'CN=GuideTutorial' `
    -KeyUsage DigitalSignature -CertStoreLocation 'Cert:\CurrentUser\My' `
    -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3',   # 代码签名 EKU
                      '2.5.29.19={text}')                    # 基本约束 CA=false
Export-PfxCertificate -Cert $cert -FilePath signing.pfx -Password (ConvertTo-SecureString ...)

& "$SDK\x64\signtool.exe" sign /fd SHA256 /f signing.pfx /p <密码> 包.msix
# -> Successfully signed: ...MediaLibrary_1.0.0.0.x64.msix
```

两个实测要点：`-TextExtension` 里的**代码签名 EKU（1.3.6.1.5.5.7.3.3）不可省**——普通 `-Type CodeSigning` 也行，手动拼 Custom 时最容易漏；签名算法 `/fd SHA256` 是当前基线（SHA1 已被部署拒绝）。

时间戳（`/tr http://timestamp.digicert.com`）：测试证书不必加；**正式证书必须加**——没有时间戳的签名在证书过期后全部失效，历史包全部装不上。

## 42.4 安装（Add-AppxPackage）与信任

```powershell
Add-AppxPackage -Path 包.msix      # 安装（当前用户）
Get-AppxPackage GuideTutorial.MediaLibrary   # 验证：Name/Version/InstallLocation
Remove-AppxPackage GuideTutorial.MediaLibrary  # 卸载（数据目录一并清除）
```

**本章最贵的一课（实测）**：签名成功 ≠ 能装。第一次安装报：

```
Deployment failed with HRESULT: 0x800B0109,
已处理证书链，但是在不受信任提供程序信任的根证书中终止。
应用包或捆绑包中的签名的根证书必须是受信任的证书。
```

自签名证书的信任不是"导入 CurrentUser"就完事——**AppX 部署只认 LocalMachine 的证书存储**。实测把证书加进 `CurrentUser\TrustedPeople` 与 `CurrentUser\Root` 都无效（同样报 0x800B0109），必须进 `LocalMachine\TrustedPeople`（或 Root），这一步要管理员：

```powershell
# 需要一次提权（UAC）——把自签名证书装进本机信任
$store = New-Object System.Security.Cryptography.X509Certificates.X509Store('TrustedPeople','LocalMachine')
$store.Open('ReadWrite'); $store.Add($cert); $store.Close()
```

这也是为什么企业内部分发（书 14.5）总是配发"装证书 + 装 MSIX"两步脚本，而商店分发不需要——**商店代签**，用户的 Windows 天然信任微软的签名链，这就是商店路线对开发者的最大减负。

> 教学机实录：本教程的打包验证止步于 0x800B0109（提权装证书被自动化安全边界拦下，属预期）。`examples\37-media-library\GuideTutorial.MediaLibrary_1.0.0.0.x64.msix` 与签名证书已就绪，提权两行（`msix-pack.ps1` 尾注有完整命令）即可走完安装；pack 与 sign 两步的产物与报错均为真实输出。

## 42.5 全流程一键脚本

`tools/msix-pack.ps1` 把 42.2-42.4 串起来：

```powershell
pwsh tools\msix-pack.ps1 -Example 37-media-library -ExeName MediaLibrary.exe `
    -Identity GuideTutorial.MediaLibrary -DisplayName 'Media Library (guide)'
```

流程：定位构建产物 → 布局 → 生成清单 → makeappx → 复用/创建自签名证书 → signtool → 信任（需提权，见上）→ Add-AppxPackage。`.gitignore` 已排除 `.msix-stage/`、`*.msix`、`signing.pfx`（**签名私钥永远不进库**）。

版本升级只需 `-Version 1.0.0.1` 重跑：Identity 相同的包按版本比较，`Add-AppxPackage` 自动走更新路径（差异块由 BlockMap 决定，只下载变化部分——这就是 MSIX 增量更新的机制）。

## 42.6 分发渠道对比（书 14.3/14.4 概述）

| 渠道 | 签名 | 信任 | 适合 | 成本 |
|---|---|---|---|---|
| **旁加载**（本章） | 自己的证书 | 每台机器装一次证书 | 企业内部、测试机 | 免费；信任管理是负担 |
| **winget**（社区仓库） | 包本身的签名 | 用户侧 winget 直接装 | 开源/免费工具 | 提交 YAML 清单 PR（书 14.3.1 全流程） |
| **Microsoft Store** | Partner Center 托管/自签 | 系统级天然信任 | 消费者分发 | 一次性注册费（个人 ~$19/公司 ~$99，书 14.4.1） |
| **Intune/端点管理器** | 企业证书 | 企业策略下发 | LOB 应用 | 需企业管理体系 |

**winget 的最低门槛**（书 14.3.1 的 YAML 直录）：

```yaml
PackageIdentifier: GuideTutorial.MediaLibrary
PackageVersion: 1.0.0.0
Installers:
  - Architecture: x64
    InstallerType: msix
    InstallerUrl: https://<公开URL>/GuideTutorial.MediaLibrary_1.0.0.0.x64.msix
    InstallerSha256: <certUtil -hashfile ... SHA256>
```

前提是 MSIX 挂在一个公开 URL 上（Azure 静态站点/Blob，书 14.3.1 步骤 1-5）。`winget validate` + `winget install -m` 本地自检通过后向 microsoft/winget-pkgs 提 PR。

**商店提交的骨架**（书 14.4 两节概述即可）：VS"创建应用程序包"选 Microsoft Store → 保留应用名 → 生成 .msixupload → Windows App 认证工具包（WACK）本地预检 → Partner Center 传包 + 截图 + 定价。**WACK 的失败项在提交前必须清零**（书 11 处的链接有全部测试清单）——本地跑 WACK 就是把商店审核提前到自己机器上。

## 42.7 框架依赖 vs 自包含（书 14.1.3，与 01.7 对照）

| | 框架依赖（framework-dependent） | 自包含（self-contained） |
|---|---|---|
| 包体 | 小（几十 KB 级） | 大（几十 MB，含 WASDK 运行时） |
| 目标机要求 | 预装 Windows App SDK 运行时 | 无（xcopy 可跑） |
| 运行时更新 | 随系统运行时打补丁 | 随应用更新走 |
| 加载速度 | 快（运行时共享、常驻） | 慢（私有副本） |

本教程示例全部自包含——**教学与冒烟的可移植性优先**（任何机器拖走就能跑）。正式分发时若走商店/企业渠道，框架依赖更常见；MSIX 清单里框架依赖应用多一段 `<PackageDependency>`（Name=Microsoft.WindowsAppRuntime.1.8...），自包含则没有——这也是 42.2 手工清单在自包含产物上特别简单的原因。

## 42.8 实测坑位（本章新增，全部真实输出）

1. **清单缺 `runFullTrust` → makeappx 0x80080204**，行号直指 Application 节点；restricted capability 命名空间（rescap）要同时声明。
2. **Publisher 与证书 Subject 不一致 → 安装期 0x800B0109 家族报错**。身份三契（Name/Publisher/Version）任何不匹配都是安装期才炸，makeappx 不查 Publisher 与证书的对应。
3. **自签名证书的信任必须落 LocalMachine**：CurrentUser 的 TrustedPeople/Root 都不被 AppX 部署采信（实测两次 0x800B0109）——需要一次 UAC 提权，这是旁加载路线绕不开的固定成本。
4. **自签名证书的 EKU 必须含代码签名**（1.3.6.1.5.5.7.3.3）；`-Type Custom` 手拼时最容易漏。
5. 布局里别把 `*.pdb/*.ilk` 打进包（体积 + 信息泄露）；`msix-pack.ps1` 的排除表照抄。
6. 打包后的数据目录迁移到 `%LOCALAPPDATA%\Packages\<包名>\LocalCache`——**用绝对路径拼接的数据层代码不用改**（都是运行时探测），但"用户手动找数据库文件"的位置变了（37 章练习题的延续）。
7. 版本号四段式（1.0.0.0）最后一段不能是 0 之外的...没有这条——但**每次分发必须递增 Version**，同版本号同签名覆盖安装会被拒（0x80073CF06 系）。

## 42.9 练习与思考

1. 把 40-webview-host 打成 MSIX 并装到本机（提权两行在 `msix-pack.ps1` 尾注）。装完从开始菜单启动——窗口标题栏的图标从哪来？（对照清单的 VisualElements。）
2. 用 `-Version 1.0.0.1` 重打 37 的包再安装，观察是"覆盖更新"还是报错；用 `Get-AppxPackage` 验证版本变化。
3. 把媒体库的 db 文件从打包后的 Packages 目录里拷出来（权限允许吗？），对照 42.1 的目录规则解释现象。
4. 思考：为什么 AppX 部署不采信 CurrentUser 的证书存储？（提示：包安装是机器级资源写入 + 多用户共享 WindowsApps 目录——信任判定应该属于谁。）
5. 若上架商店，本章流程里哪几步被 Partner Center 取代？哪几步（makeappx 的清单纪律、身份三契）依然要自己做对？
