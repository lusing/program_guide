# 27 模块开发——把函数编成正规军

> 本章是扩充章（原书第 07 章站在"用户"侧看模块；本章站到"作者"侧）。第 24 章的库文件（点源加载）能用，但模块才是函数的"正规编制"：自动发现、自动加载、版本管理、依赖声明、可发布。写完本章，你的工具能像 PSGallery 上的模块一样被人 `Install-Module`。

## 27.1 从库文件到模块：动机清单

点源库（`. .\MyLib.ps1`）的四个天花板，模块逐个击破：

| 库文件的局限 | 模块的答案 |
|---|---|
| 必须记得点源，别人拿到脚本跑不起来 | 放进模块路径，**自动发现 + 自动加载**（第 07 章） |
| 没有版本，改坏了就是坏了 | **ModuleVersion** 版本管理，多版本并存 |
| 函数全部暴露，内部辅助函数裸奔 | **Export-ModuleMember** 精确控制公开面 |
| 依赖靠嘴说（"先装 XX 模块"） | 清单 **RequiredModules** 声明，加载时自动连带 |

一句话动机：**库是"我自己的函数集"，模块是"能交给别人的产品"**。

## 27.2 脚本模块：最小可用的三件套

一个脚本模块就是"改了扩展名的函数库"加"一份说明书"：

```
PsTut/
├── PsTut.psd1      ← 模块清单（说明书+合同）
└── PsTut.psm1      ← 脚本模块（函数们）
```

**`PsTut.psm1`**（脚本模块本体）——就是第 24 章的库文件换个扩展名：

```powershell
function Get-InvUptime {
    [CmdletBinding()]
    param([string]$ComputerName = 'localhost')
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ComputerName $ComputerName
    [math]::Round(((Get-Date) - $os.LastBootUpTime).TotalDays, 1)
}
function Initialize-InvCache {
    # 内部辅助函数（不导出，外界不可见）
    $script:Cache = @{}
}
Export-ModuleMember -Function Get-InvUptime      # 只导出这一个
```

**`Export-ModuleMember` 是公开面的闸门**：列出的函数成为模块的"产品"，没列的（如 `Initialize-InvCache`）是内部实现——调用方 `Get-Command` 查不到、调不了。这是模块与库最大的架构差：**你可以重构内部而不动合同**。

**`PsTut.psd1`**（模块清单）——用命令生成而不是手写：

```powershell
New-ModuleManifest -Path .\PsTut\PsTut.psd1 `
    -ModuleVersion '1.0.0' -Author 'ops@example.com' `
    -RootModule 'PsTut.psm1' `
    -Description '教程演示模块' `
    -FunctionsToExport @('Get-InvUptime') `
    -PowerShellVersion '5.1'
```

清单是**哈希表字面量**（第 20 章 `@{}` 的实战现场）：`Get-Content PsTut.psd1` 看一眼就懂。关键字段五类：身份（`ModuleVersion`/`GUID`/`Author`）、入口（`RootModule` 指向 .psm1）、**公开面（`FunctionsToExport`——与 Export-ModuleMember 双保险，两者都该列）**、依赖（`RequiredModules`/`RequiredAssemblies`）、兼容（`PowerShellVersion`/`PSEdition`）。

## 27.3 加载与开发循环

**开发期**：按路径直载，最快捷的迭代方式：

```powershell
Import-Module .\PsTut\PsTut.psd1     # 或指向 .psm1
Get-InvUptime                        # 用！
```

**改了代码之后必须先卸再载**——模块一旦加载就驻留内存，直接再 Import 不会刷新：

```powershell
Import-Module .\PsTut\PsTut.psd1          # 普通再 Import：不刷新（模块已加载，直接跳过）
Import-Module .\PsTut\PsTut.psd1 -Force   # -Force：强制重载（等价于 Remove+Import 一步到位）
Remove-Module PsTut; Import-Module .\PsTut\PsTut.psd1    # 经典两步：卸载再加载
```

这个 **Import → 改 → Remove（或 -Force）→ 再 Import** 的循环是模块开发的"保存并刷新"，忘记刷新是模块作者第一大坑（"我明明改了怎么没反应"——实测：不带 `-Force` 的重复 Import 悄悄跳过，模块还是旧代码）。

**部署期**：把模块目录放进 `$env:PSModulePath` 下的任一位置（用户模块目录最常见：`Documents\PowerShell\Modules\PsTut\`），从此**自动发现**——`Get-Module -ListAvailable` 看得见、直接调函数自动加载（第 07 章的机制反向兑现）。注意双引擎各有各的用户模块目录（第 07 章的差异表），要两边可用就得复制两份或放共享路径。

## 27.4 FunctionsToExport 的讲究：为什么别用 `*`

清单里 `FunctionsToExport = @('Get-InvUptime')` 看似啰嗦——模块一变大就明白它的分量：

- **补全与帮助的清单**：引擎靠它决定"哪些命令进入命令发现"；`'*'` 意味着每次会话启动都要**扫描整个模块**枚举命令（拖慢补全响应）；
- **改名的自由**：内部函数随便重命名，只要导出面不变，用户无感——公开面越窄，重构越自由；
- **读者的地图**：清单即 API 文档——`FunctionsToExport` 列表就是"这个模块提供什么"的权威答案。

规范：**逐个列出导出函数**（与 .psm1 里的 Export-ModuleMember 保持一致），绝不用通配符。配套习惯：每个导出函数配注释帮助（23 章）——`Get-Help Get-InvUptime` 对模块函数同样离线可用。

## 27.5 依赖与嵌套：RequiredModules 的连锁

清单里声明依赖：

```powershell
RequiredModules = @(@{ ModuleName = 'CimCmdlets'; ModuleVersion = '1.0' })
```

Import 本模块时引擎**自动连带加载**依赖（缺了就报错——比"跑到一半发现少东西"体面）。依赖树的两条纪律：**能不依赖就不依赖**（每加一个依赖，用户多一个安装步骤）；**版本范围写宽**（`ModuleVersion` 是"最低版本"语义，不是精确锁定）。大型模块的进阶结构（`NestedModules`、按平台分支 `ScriptsToProcess`、格式与类型文件 `FormatsToProcess`/`TypesToProcess`——第 10 章格式化配置的作者侧入口）用到再查 `about_Modules`。

## 27.6 发布：从本地目录到 PSGallery

模块的最后一公里——发布到仓库（PSGallery 或企业内部源）：

```powershell
# 发布前体检
Test-ModuleManifest .\PsTut\PsTut.psd1            # 清单合法性
Invoke-ScriptAnalyzer -Path .\PsTut                # 代码体检（32 章主角）

# 发布（需要 PSGallery 的 API Key，首次在 powershellgallery.com 注册获取）
Publish-Module -Path .\PsTut -NuGetApiKey 'xxxx' -Repository PSGallery
```

发布后全世界 `Install-Module PsTut` 就能装（第 07 章的生态闭环：你从生态的消费者变成了生产者）。**发布前的两道安检**：把 `.psd1` 里能填的元数据填齐（描述、标签、项目地址——`Find-Module` 的搜索依据）；跑一遍 ScriptAnalyzer 清零警告。企业内部分发走私有仓库（`Register-PSRepository` 指向内部 NuGet 源）或干脆文件服务器 + `Save-Module`，命令同源。

## 27.7 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| 改了 .psm1 不生效 | 模块驻留内存，Import 不刷新 | **先 `Remove-Module` 再 Import**（开发循环铁律） |
| 内部函数被外界调用 | 没控制导出面 | `Export-ModuleMember` + 清单 `FunctionsToExport` 双闸 |
| 清单改坏了整模块加载失败 | .psd1 语法错/字段值非法 | `Test-ModuleManifest` 随手验；改清单小步走 |
| 自动加载不生效 | 模块目录不在 PSModulePath / 目录名与模块名不一致 | 目录名=模块名；放进第 07 章的路径表 |
| 依赖缺失报错发生在使用时 | 没写 RequiredModules | 依赖进清单，加载期就报 |
| 两台引擎一边找得到一边找不到 | 用户模块目录按引擎隔离（第 07 章） | 双目录部署或共享路径 |
| `Import-Module` 报"无法加载" | 执行策略/未签名（17 章） | RemoteSigned 或签名后分发 |

## 27.7.1 模块的一生：从想法到发布的状态机

把本章流程画成状态机（每一步的动作与命令）：

```
[想法]
  │ 写 .psm1（函数 + Export-ModuleMember）
  ▼
[本地循环]  Import → 用 → 改 → Remove → 再 Import（27.3）
  │ 稳定，生成清单 New-ModuleManifest
  ▼
[带证模块]  Test-ModuleManifest 验清单；ScriptAnalyzer 清警告
  │ 复制进 $env:PSModulePath 的用户模块目录
  ▼
[可发现]    Get-Module -ListAvailable 可见；直接调用自动加载
  │ 团队要用
  ▼
[发布]      Publish-Module（PSGallery/私有源）；他人 Install-Module
  │ 有 bug/新需求 → 回到[本地循环]，ModuleVersion +1 再发布
  ▼
[版本化迭代] 1.0.0 → 1.1.0（功能）/ 1.0.1（修复）/ 2.0.0（破坏性变更）
```

版本号的语义约定（SemVer 的 PowerShell 读法）：**主.次.修**——不兼容的接口变更动主号、加功能动次号、修 bug 动修订号。用户侧 `#Requires -Modules @{ModuleName='X'; ModuleVersion='2.0'}` 按这个语义锁下限。

三个常见问答收尾：

**问：一个模块该装多少函数？** 主题聚合优先于数量——"磁盘巡检"一个模块（五六个函数）比"运维百宝箱"（一百个函数）健康；后者迟早变成谁也不敢动的巨石。

**问：.psm1 里能放变量吗？** 能（模块级变量，函数间共享），配合 `$script:` 前缀明确作用域。但它对导入者不可见——想暴露"配置"，用导出函数 `Get-XConfig` 包装，别让人直接摸变量。

**问：测试怎么组织？** 测试文件（`*.Tests.ps1`）放模块目录旁（不入模块导出面），Pester 从外部 Import 后测——第 32 章的完整流程。

## 27.8 本章要点

- 模块三件套：**目录 + .psm1（函数与导出闸门）+ .psd1（清单合同）**；`New-ModuleManifest` 生成别手写。
- `Export-ModuleMember`/`FunctionsToExport` 控公开面——**逐个列，别用 `*`**；内部函数自由重构。
- 开发循环 **Import → 改 → Remove → Import**；部署进 PSModulePath 得自动发现；双引擎目录隔离。
- `RequiredModules` 声明依赖连锁；发布：`Test-ModuleManifest` + `ScriptAnalyzer` → `Publish-Module`；企业走私有源。

**动手实验**：① 建目录 `PsTut`，写 .psm1（一个导出函数 + 一个内部函数）与 `New-ModuleManifest` 生成清单；② Import 后验证导出函数可调、内部函数 `Get-Command` 查无；③ 改 .psm1 里的输出文案，直接再 Import 验证"没反应"，然后 Remove → Import 见证刷新；④ 把 `FunctionsToExport` 改成 `'*'` 再看 `Get-Command -Module PsTut` 的差异；⑤ `Test-ModuleManifest` 验清单。

实验参考：②内部函数报"无法识别"——它对会话不可见，这正是导出闸门的意义；③这是模块开发第一天必踩的坑，踩一次就永远记得。

对应示例（可选）：`examples/27_modules_dev/`——临时目录搭完整模块（New-ModuleManifest 生成清单）、导入后导出面验证、内部函数不可见、Remove/再 Import 刷新验证、清单版本一致性，全程自演自净。

---

本篇（五 工具制作）其余各章：[24 函数](./24-functions.md) · [25 高级函数](./25-advanced-functions.md) · [26 错误处理](./26-error-handling.md) · [28 正则](./28-regex.md) · [29 技巧](./29-tips.md) · [30 他人脚本](./30-others-scripts.md)

---

本篇（五 工具制作）导航：[24 函数](./24-functions.md) · [25 高级函数](./25-advanced-functions.md) · [26 错误处理](./26-error-handling.md) · [27 模块开发](./27-modules-dev.md) · [28 正则](./28-regex.md) · [29 技巧](./29-tips.md) · [30 他人脚本](./30-others-scripts.md)

实验参考：②内部函数对会话不可见正是导出闸门的意义；⑤清单字段改错时 Test-ModuleManifest 的报错会精确到字段。

模块一生（27.7.1）与版本语义是团队协作的公共语言；下一章正则是文本世界的钥匙。
