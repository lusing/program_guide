# PowerShell 教程 CHEATSheet——实测坑位汇总

本表收录**本教程构建过程实测踩到**的坑（每条都来自双通道验证器的真实报错与修复），以及验证协议速查。教程正文的逐章坑位表见各章"高频坑位"小节。

## 一、构建与验证协议

| 项 | 约定 |
|---|---|
| 双通道 | pwsh 7（主线）+ powershell 5.1（差异通道），`build.ps1` 各跑全部示例 |
| 报告协议 | 每示例写 `report.txt`（UTF-8）；行前缀 `OK:` / `SKIP: 理由` / `FAIL:`；退出码非零=失败 |
| 对账剥离 | 行尾 `[ch7-only]` `[ch51-only]` `[env]` 的行不参与双通道比对（但仍计入各自通道判定） |
| BOM 铁律 | `examples/`、`tools/` 下 `.ps1/.psd1/.psm1` 一律 UTF-8 带 BOM（build 自动补） |
| 模块路径隔离 | 子引擎启动前清空继承的 `PSModulePath`，让各引擎用自身默认搜索路径（见坑 1） |

## 二、实测坑位（构建期亲历）

| # | 现象 | 根因 | 对策 |
|---|---|---|---|
| 1 | 子 5.1 找不到/多找到模块，两通道表现漂移 | 父 pwsh 的 `PSModulePath` 被子进程继承，覆盖 5.1 默认路径 | build 启动子引擎前 `Remove-Item Env:\PSModulePath`，各引擎自建默认 |
| 2 | 5.1 报"意外的标记 }"，中文模块语法错 | `.psm1` 漏在 BOM 修复清单外；无 BOM 的 UTF-8 被 5.1 按 ANSI 解析，中文串的字节吞掉引号/括号 | BOM 清单加 `*.psm1`；含中文脚本必须 UTF-8 带 BOM |
| 3 | `Get-Help 脚本` 只有语法没有注释帮助 | **文件首行存在普通注释或 `#Requires`** 会破坏注释帮助识别（实测两引擎一致） | `<# … #>` 帮助块必须真正的文件第一行 |
| 4 | 高级函数管道行为怪异/$_ 拿不到对象 | 函数 `process` 块里 `$_` 无定义（那是 ForEach-Object 的专利）；且未声明 `ValueFromPipeline` 时管道对象根本进不来 | 接管道必须 `[Parameter(ValueFromPipeline)]` + process 里用绑定参数 |
| 5 | `Compare-Object` 断言顺序相关 | 输出行序不保证 | 断言前 `Sort-Object`；拼接标记串注意 `名=指示符` 会产生 `==>` 双等号形态 |
| 6 | Format-Table 产物类型断言失败 | Format 输出是**一组**格式对象（Start/Entry/End），数组上 `.GetType()` 得 `Object[]` | `| Select-Object -First 1` 后再断言类型名含 `Format` |
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

## 三、双引擎差异速查（正文 34.5 的构建佐证）

构建期实际触发过的差异（全部有示例断言兜底）：`Get-WmiObject` 移除（14）、`Get-Service -ComputerName` 移除（09）、ThreadJob 默认不可见（15）、作业初始目录不同（15）、`-Parallel`（16）、`-HostName` SSH（19）、`-AsHashtable`（31）、JSON 截断警告（31）、Pester 内置 3.4 vs 自装 v6（32）、`$IsWindows` 等平台变量未定义（02）。

## 四、验证状态

- `pwsh -File build.ps1`：**34/34 示例双通道全绿**（远程/SSH/Pester/Analyzer 按探针带理由 SKIP 的通道不计失败）。
- 全部示例自演自净：临时目录/注册表键/别名/进程建删成对；系统级设置零改动。
