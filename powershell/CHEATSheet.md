# PowerShell 教程 CHEATSheet——实测坑位汇总

本表收录**本教程构建过程实测踩到**的坑（每条都来自双通道验证器的真实报错与修复），以及验证协议速查。教程正文的逐章坑位表见各章"高频坑位"小节。

## 一、构建与验证协议

| 项 | 约定 |
|---|---|
| 双通道（Windows） | pwsh 7（主线）+ powershell 5.1（差异通道），`build.ps1` 各跑全部示例 |
| 单引擎（macOS/Linux） | **Windows PowerShell 5.1 只存在于 Windows**，故 `./run-all.sh` 按单引擎纪律：同命令连跑两遍，`report.txt` 逐字节一致 |
| 报告协议 | 每示例写 `report.txt`（UTF-8）；行前缀 `OK:` / `SKIP: 理由` / `FAIL:`；退出码非零=失败 |
| 对账剥离 | 行尾 `[ch7-only]` `[ch51-only]` `[platform]` `[env]` 的行不参与比对（但仍计入各自通道判定） |
| 标记语义 | `[ch7-only]`/`[ch51-only]`=引擎差异；`[env]`=环境依赖；**`[platform]`=操作系统差异**（本轮新增，见第五节） |
| 零断言告警 | 某示例 report 里一条 `OK:` 都没有（全 SKIP）时 `run-all.sh` 单独点名——「没失败」不等于「验证到了东西」 |
| BOM 铁律 | `examples/`、`tools/` 下 `.ps1/.psd1/.psm1` 一律 UTF-8 带 BOM（build 自动补） |
| 模块路径隔离 | 子引擎启动前清空继承的 `PSModulePath`，让各引擎用自身默认搜索路径（见坑 1） |
| 平台能力探测 | 统一用 `(Get-Command X).Parameters.ContainsKey('Y')` 或 `Get-Command X -EA SilentlyContinue`；**不按平台宏 `#ifdef`** |

## 二、实测坑位（构建期亲历）

| # | 现象 | 根因 | 对策 |
|---|---|---|---|
| 1 | 子 5.1 找不到/多找到模块，两通道表现漂移 | 父 pwsh 的 `PSModulePath` 被子进程继承，覆盖 5.1 默认路径 | build 启动子引擎前 `Remove-Item Env:\PSModulePath`，各引擎自建默认 |
| 2 | 5.1 报"意外的标记 }"，中文模块语法错 | `.psm1` 漏在 BOM 修复清单外；无 BOM 的 UTF-8 被 5.1 按 ANSI 解析，中文串的字节吞掉引号/括号 | BOM 清单加 `*.psm1`；含中文脚本必须 UTF-8 带 BOM |
| 3 | `Get-Help 脚本` 只有语法没有注释帮助 | **文件首行存在普通注释或 `#Requires`** 会破坏注释帮助识别（实测两引擎一致） | `<# … #>` 帮助块必须真正的文件第一行 |
| 4 | 高级函数管道行为怪异/$_ 拿不到对象 | 函数 `process` 块里 `$_` 无定义（那是 ForEach-Object 的专利）；且未声明 `ValueFromPipeline` 时管道对象根本进不来 | 接管道必须 `[Parameter(ValueFromPipeline)]` + process 里用绑定参数 |
| 5 | `Compare-Object` 断言顺序相关 | 输出行序不保证 | 断言前 `Sort-Object`；拼接标记串注意 `名=指示符` 会产生 `==>` 双等号形态 |
| 6 | Format-Table 产物类型断言失败 | Format 输出是**一组**格式对象（Start/Entry/End），数组上 `.GetType()` 得 `Object[]` | `\| Select-Object -First 1` 后再断言类型名含 `Format` |
| 7 | 别名解析断言失败 | `Get-Command gps` 返回**别名对象本身**（Name=gps 不是目标）；多命中时 `.Source` 变拼接串 | 用 `Get-Alias -Definition` 或 `(Get-Alias 别名).Definition`；多命中先 `@(...)[0]` |
| 8 | 远程示例无法跑 | 本机 WinRM 未启用（家庭机常态） | `Test-WSMan` 探针门控：不通全 SKIP 带理由；正文讲清 Enable 步骤，绝不改系统状态 |
| 9 | ThreadJob 在 5.1"时有时无" | 模块物理上只在 pwsh 7 目录；5.1 是否可见取决于当时的 PSModulePath（与坑 1 叠加） | 探针 + `[env]` 标记；文档讲明"5.1 需另装" |
| 10 | 5.1 `Install-Module` 报 ShouldContinue NullReference | PowerShellGet 在该上下文的已知问题 | 用 pwsh 的 `Save-Module -Path <5.1 用户模块目录>` 直接落盘 |
| 11 | `New-PSSessionOption` 断言 600000 失败 | 属性是 **TimeSpan** 不是毫秒数（毫秒只是入参单位） | 用 `.TotalMinutes`/`.TotalSeconds` 读 |
| 12 | enum 参数"非法值"没被拦 | enum 绑定接受**唯一前缀缩写**（`prod`→Production，与参数名缩写同理） | 测试用完全不沾边的值；把"前缀可绑"写进文档当特性 |
| 13 | JSON 深层丢数据没察觉 | `ConvertTo-Json` 默认 Depth=2 截断：**5.1 纯静默、pwsh 7 仅一条警告流**（重定向下易错过） | 生产代码显式 `-Depth`；教程断言四层嵌套实测截断 |
| 14 | `Get-Service -ComputerName` 在 pwsh 7 报"找不到参数" | 参数被 pwsh 7 移除（.NET 服务远程不可用） | 跨机改 `Invoke-Command`/CIM；`(Get-Command X).Parameters.ContainsKey` 做能力探测 |
| 15 | `PSComputerName` 断言空值失败 | 本机直连（COM）时该属性**存在但值为空**，远程查询才填充 | 断言"属性存在"而非"值非空" |
| 16 | 管道单结果后 `.Count` 不稳 | 管道返回单元素时是标量（单元素陷阱在管道口的形态） | 恒 `@(...)` 包裹 |
| 17 | `N0`/`P0` 格式断言两机不同 | 千分位/百分号渲染随**文化**变化 | 文化相关断言只查数字主体（`-match '1,?234'`），别锚定完整文案 |
| 18 | `Format-Table -Property` 选列后列头断言错 | 屏幕列头是视图别名（PM(K)），选中属性后列头变属性名 | 列头断言前先想"我在视图层还是数据层" |
| 7a | `PSModulePath` 按 `;` 切分在 macOS 上只得 1 项 | `PSModulePath` 是**平台相关的路径列表**：Windows 用 `;`，Unix/macOS 用 `:`（写死 `;` 等于没切） | 用 `[System.IO.Path]::PathSeparator` + `-split [regex]::Escape(...)` |
| 26a | `Start-Process -WindowStyle Hidden` 抛"参数在此 edition 上不支持" | 该参数**在参数表里存在**（`ContainsKey` 为真）但非 Windows 版调用即抛——**不能按参数表判断支持度** | 按"实际调用是否抛错"这个事实条件 try/catch 分支，catch 里去掉该参数重试 |
| 17a | `Set-ExecutionPolicy -Scope Process` 抛 "Operation is not supported on this platform" | 执行策略是 **Windows 专属机制**；Unix 上恒 `Unrestricted` 且任何作用域都不可设 | try/catch 后按"生效值是不是真变成 Bypass"分支，否则 SKIP `[platform]` |
| 8a | 拿 `'FileSystemInfo'` 去 match 目录的 TypeName 断言失败 | `Get-Member` 的 `TypeName` 给的是**运行时类型名**（`DirectoryInfo`/`FileInfo`），基类名压根不出现在这串里 | 判类型归属用 `-is [System.IO.FileSystemInfo]` 走继承链，别 match 字符串 |
| 9a | `Get-Process -Name` 喂裸字符串报 "cannot be bound"，但元数据 `ByValue=True` | Unix 版 `Get-Process` 的 `-Name` 参数集**只实现 ByPropertyName**，元数据声明与实际实现不符 | ByValue 另锚 `ForEach-Object -Process`（两引擎真跑通）；别拿元数据当实现证明 |
| 5a | 自造的"注册表替身"断言失败（`Set-ItemProperty Env:\X -Name Y`） | `Env:`/`Variable:` 提供程序**整个没实现 `IPropertyCmdletProvider`**（不是缺某个属性名）；`FileSystem:` 实现了但只认自己定义的属性名（`IsReadOnly` 等），任意属性名报 "does not exist" | 提供程序能力差异要用**该提供程序真有的属性名**去断言，别造通用替身 |
| 34a | `grep -c` 计数把换行打进表格，列全错位 | `grep -c` 无匹配时**仍输出 `0` 并返回 1**，写成 `$(grep -c ... || echo 0)` 就变成 `0\n0` | 只写 `$(grep -c ...)` 并用 `|| true` 兜退出码，**不要再补 `echo 0`** |
| 26b | `pwsh -File x.ps1` 在本机崩（`Call to 'procargs' failed with errno 5`） | pwsh 7.6.6 在 macOS 上的 `-File` 传参路径有缺陷 | 一律 `pwsh -NoProfile -Command '& ./x.ps1'`；不要写 `-File` |

## 三、双引擎差异速查（正文 34.5 的构建佐证）

构建期实际触发过的差异（全部有示例断言兜底）：`Get-WmiObject` 移除（14）、`Get-Service -ComputerName` 移除（09）、ThreadJob 默认不可见（15）、作业初始目录不同（15）、`-Parallel`（16）、`-HostName` SSH（19）、`-AsHashtable`（31）、JSON 截断警告（31）、Pester 内置 3.4 vs 自装 v6（32）、`$IsWindows` 等平台变量未定义（02）。

## 四、Windows / macOS 平台差异速查（本轮 macOS 校验新增）

macOS 上 pwsh 7.6.6 实测：**34/34 全绿**（19 个示例零 SKIP，15 个含 SKIP）。
下面这些能力在 macOS 上**确实不存在**，相关断言一律走 `[platform]` SKIP，不放宽判据：

| 能力 | macOS 现状 | 受影响章 | 替代锚点 |
|---|---|---|---|
| `Get-Service` | 不存在（launchd 不是 SCM） | 01 03 04 08 09 10 11 | `Get-Process` / `Get-ChildItem` |
| `Get-CimInstance`/`Get-CimClass`/`Invoke-CimMethod`/`Get-WmiObject` | 全不存在（CIM/WMI 是 Windows COM/DCOM 技术栈） | 11 12 14 33 | `Get-PSDrive -PSProvider FileSystem` |
| `Registry::` 提供程序 | 不存在 | 05 | `FileSystem:` 的 `IsReadOnly` 属性 |
| `Get-AuthenticodeSignature` | 不存在（Windows-only） | 17 | — |
| `Get-Item -Stream` / ADS / `Zone.Identifier` / MOTW | 参数不在参数表（APFS 无备用数据流） | 17 | — |
| 执行策略 `Set-ExecutionPolicy` | 抛 "not supported on this platform"，恒 `Unrestricted` | 17 | — |
| `New-PSSessionOption` 的 WSMan 超时参数 | 被剔除，只剩 `SkipCACheck`/`SkipCNCheck` | 19 | — |
| `WinRM` / `WSMan:` / 端点 | 无此服务 | 19 | SSH 腿（`-HostName` 在 Unix 上可用） |
| `$IsWindows` 等平台变量 | **5.1 里未定义**，不能直接引用 | 33 | 改用 `Get-Command Get-CimInstance` 探测 |

反过来的坑：**`Get-PSDrive` 没有 `Size` 字段**，只有 `Used`/`Free`，总量得自己 `Used+Free` 算（12 章的 CIM 分支是 `Size`/`FreeSpace` 两个独立字段，两条轨的计算属性写法因此不同）。

## 五、验证状态

- **Windows**：`pwsh -File build.ps1`——34/34 示例**双通道全绿**（远程/SSH/Pester/Analyzer 按探针带理由 SKIP 的通道不计失败）。
- **macOS 14.8.9 / pwsh 7.6.6 (Core)**：`./run-all.sh`——**34/34 全绿**，共 **370 条 `OK:` 断言 + 23 条带理由 SKIP**，0 条 FAIL。
  24 个示例零 SKIP（全断言跑通），10 个含 SKIP；其中 `32_testing` 为**零断言通过**（本机无 Pester / PSScriptAnalyzer），`run-all.sh` 会显式点名。
- 全部示例自演自净：临时目录/注册表键/别名/进程/变量建删成对；系统级设置零改动。
- **无法在本机验证的结论**：一切"仅 Windows 成立"的行为——CIM/WQL 方言、WSMan 端点与 WinRM、NTFS ADS/MOTW、Authenticode 签名状态、执行策略五作用域的真实拦截效果。这些在 Windows 侧由 `build.ps1` 双通道覆盖，macOS 侧只验证了"能力缺失时正确降级"。
