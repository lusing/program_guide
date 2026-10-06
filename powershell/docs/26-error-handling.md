# 26 错误处理——让工具体面地失败

> 本章是扩充章（原书第 27 章指路清单里"错误处理"一项的完整展开）。工具的可信度不取决于它成功时多漂亮，而取决于**它失败时的样子**。本章讲透 PowerShell 的双形态错误、try/catch 的正确用法、错误记录的解剖，以及"脚本该怎样收场"。

## 26.1 两种错误：终止与非终止

PowerShell 的错误分两种，一切错误处理知识的地基：

**非终止错误（non-terminating）**：命令对**某个对象**操作失败，但**继续处理后续对象**。比如 `Get-Content` 读十个文件，第三个没权限——报一条错误，接着读第四个。`Write-Error` 产生的也是这种（进 2 号错误流，执行不停）。这是**命令的默认行为**：健壮而宽容，适合"批处理里坏一个认一个"的世界。

**终止错误（terminating / exception）**：**异常**抛出，当前语句块**立即中断**。来源两种：引擎级错误（调用不存在的方法、语法错）和显式 `throw`。不接住就是满屏红字加执行停止。

关键结论（初学者最常栽的一条）：**try/catch 只抓终止错误**。

```powershell
try {
    Get-Content 'C:\不存在.txt'      # 非终止错误——catch 不接！红字照出，脚本继续
}
catch { '这条 catch 根本不会执行' }
```

## 26.2 把非终止升级：-ErrorAction 与 $ErrorActionPreference

想让非终止错误也进 catch，就得**升级**它。两种拧法：

**单命令**：`-ErrorAction Stop`（通用参数，第 03/23 章）：

```powershell
try {
    Get-Content 'C:\不存在.txt' -ErrorAction Stop    # 升级为终止 → catch 接住
}
catch {
    "拿不到文件：$($_.Exception.Message)"
}
```

**作用域全局**：`$ErrorActionPreference = 'Stop'`（该作用域内一切命令的非终止错误都升级）。脚本头加它是"严父模式"：任何小错都中断，逼你逐个处理——**工具类代码推荐**（配合 catch 精准接住预期的错误）；交互探索则用默认 `Continue`（宽容前进）。

`-ErrorAction` 的五个值顺口记住：`Continue`（默认，报错继续）、`SilentlyContinue`（闷头继续）、`Stop`（升级终止）、`Ignore`（丢弃连流都不进，7+）、`Inquire`（问一句）。**注意它管的是"命令的非终止错误"，管不了异常**（异常天生终止）。

## 26.3 try / catch / finally 全解

```powershell
try {
    # 保卫区：任何终止错误立即跳往匹配的 catch
    $risky = Get-Content $path -ErrorAction Stop
}
catch [System.IO.FileNotFoundException] {
    # 按"异常类型"精准接（可以有多个 catch，从 Specific 到宽泛排）
    "文件不存在：$path" | Write-Warning
    return $null
}
catch {
    # 兜底 catch：$_ 是 ErrorRecord（解剖见 26.4）
    "未知错误 [$($_.Exception.GetType().Name)]: $($_.Exception.Message)"
    throw        # 重新抛出：处理不了就别硬吞
}
finally {
    # 无论正常/异常/return 都执行——清理资源的唯一可靠位置
    Remove-PSSession $s -ErrorAction SilentlyContinue
}
```

四条使用纪律：

1. **catch 按类型分流**（`catch [类型]`），多个 catch 从窄到宽；裸 catch 是兜底；
2. **处理不了就 re-throw**（裸 `throw` 重抛当前异常）——**吞错**（接住后什么都不做）比不处理更坏，它把故障藏到更难查的地方；
3. **finally 只放清理**（关会话、停转录、删临时文件），不放业务逻辑；return/异常都拦不住它执行；
4. try 块别包整个脚本——**只保卫"可能出错的那句"**，粒度越细错误处置越准。

## 26.4 错误记录的解剖：$_ 的五脏

catch 里的 `$_`（以及错误流里的对象）是 **ErrorRecord**，解剖它就掌握了"错误给了你什么信息"：

```powershell
try { Get-Content 'x:\nope' -ErrorAction Stop } catch {
    $_.Exception.Message      # 人类可读的一句话（"找不到路径…"）
    $_.Exception.GetType().Name        # 异常类型（FileNotFoundException? DirectoryNotFoundException?）
    $_.CategoryInfo.Category          # 错误类别（OpenError / ReadError / …）
    $_.FullyQualifiedErrorId          # 错误的"身份证号"（如 PathNotFound,Microsoft.PowerShell.Commands.GetContentCommand）
    $_.InvocationInfo.PositionMessage # ★ 出错位置：脚本名 + 行号 + 那行代码 + 指示的光标
    $_.TargetObject                   # 出错时正在处理的对象（哪个文件、哪台机器）
    $_.ScriptStackTrace               # 调用栈（函数层层调用的路径）
}
```

**`InvocationInfo` 是定位脚本错误的金矿**：它把"哪个文件第几行第几列出错、那行代码长什么样、错误光标指在哪个字符"一次给全。给同事排错时贴 `InvocationInfo.PositionMessage` 一段，顶得上一百句描述。`ScriptStackTrace` 则回答"错误从哪条调用链来"——多层函数工具里不可或缺。

历史错误的仓库：**`$Error`** 数组（每个会话一个，最新的在 `$Error[0]`，`$Error.Clear()` 清空）——"刚才那条红字说了什么"的后悔药。

## 26.5 throw 与 exit：工具的两把收场钥匙

```powershell
function Set-InvConfig {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        throw "配置文件不存在：$Path"        # throw 字符串 → 产生 RuntimeException（终止）
    }
}
```

**`throw` 抛异常**：参数校验失败、前置条件不满足时用——调用方用 try/catch 接住处理。抛字符串最简单；抛异常对象（`throw [System.IO.FileNotFoundException]::new($path)`）类型更精确（catch 方能分流）。**throw 是"契约的执行"**：函数的 `.PARAMETER` 说明就是契约，违约即 throw。

**`exit` 设退出码**：脚本对**进程外**世界的收场（第 22 章）——0 成功、非 0 失败。工具脚本的标准收尾：

```powershell
try { Do-TheWork -ErrorAction Stop; exit 0 }
catch {
    Write-Error $_
    exit 1          # 计划任务/CI 看 $LASTEXITCODE 立刻知道败了
}
```

**throw 与 exit 的分工**：throw 对内（调用链上层接住），exit 对外（进程边界汇报）。库/模块函数里只 throw 不 exit（库不该替调用者决定进程生死）；脚本入口层只 exit 不 throw（没人会接你的异常了）。

还有个易混的小兄弟：**`$?`**（上一次命令成功与否的布尔）与 **`$LASTEXITCODE`**（上一次**外部程序**的退出码）。判定"外部程序成没成"用 `$LASTEXITCODE -eq 0`；`$?` 在管道/函数场景偶有反直觉，重要判断走 try/catch 更稳。

## 26.6 旁路收集：-ErrorVariable

不想中断、又想事后检查错误时（批处理"坏一个认一个，但最后要汇总"）：

```powershell
Get-Content a.txt, b.txt, c.txt -ErrorVariable missed -ErrorAction SilentlyContinue
if ($missed) {
    "有 $($missed.Count) 个文件没读成：" 
    $missed | ForEach-Object { " - $($_.TargetObject)（$($_.Exception.Message)）" }
}
```

`-ErrorVariable 名字`（**不带 $**；加 `+名字` 是追加进已有变量）把错误收进指定变量——错误流照常走（除非配 SilentlyContinue），你手里多一份清单。它是"宽容执行 + 事后审计"模式的钥匙，与 try/catch 的"严格模式"互补。第 33 章的收官工具会同时用两套：局部风险点 try/catch，全局清单 -ErrorVariable。

## 26.7 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| catch 没接到错误 | 非终止错误默认不进 catch | 关键命令 `-ErrorAction Stop` |
| 异常被吞、故障难查 | 裸 catch 里空处理 | 处理不了就 re-throw |
| finally 里的清理报错 | 清理本身没防错 | 清理命令加 `-ErrorAction SilentlyContinue` |
| `$_.Exception.Message` 两台机器文案不同 | 消息是本地化的 | 类型判定用 `$_.FullyQualifiedErrorId` / 异常类型，别匹配文案 |
| 外部程序失败脚本还 exit 0 | exe 的失败不抛异常，只设退出码 | `$LASTEXITCODE` 检查 |
| throw 字符串类型太宽 | 都是 RuntimeException | 要分流就抛类型化异常 |
| `$Error` 越积越多 | 会话级仓库不自动清 | 排错前 `$Error.Clear()`，取 `$Error[0]` |
| `Start-Process -WindowStyle Hidden` 抛"参数在此 edition 上不支持" | 该参数**在参数表里存在**（`ContainsKey` 为真），但非 Windows 版调用即抛——不能按参数表判断支持度 | 按"实际调用是否抛错"这个事实条件 try/catch，catch 里去掉该参数重试 |

## 26.7.1 处置决策树：拿到错误往哪走

错误接住之后的**处置**是比捕获更难的设计。一棵决策树（接住之后照着走）：

```
这个错误预期会出现吗？（如"文件不存在""机器离线"）
├─ 不预期（真正的 bug）→ re-throw，让它炸到最顶层被看见
├─ 预期，且调用方必须知道 → 转成结果的一部分（结果对象带 Status 字段 / 输出警告流）
├─ 预期，且可以自动补救 → 降级重试（换路径/等 3 秒再试一次/跳过该目标）
└─ 预期，且无需任何人知道 → 记 -ErrorVariable 做审计，静默前进
```

四个出口对应四种真实需求：**炸**（bug 必须暴露）、**报**（用户要决策）、**补**（脚本自己能救）、**记**（宽容但留痕）。最常见的错误是只有"静默"一个出口——所有 catch 都空着，等于把整棵树砍成 stump。

配套的**重试**小骨架（"补"出口的参考实现）：

```powershell
$maxRetry = 3
for ($i = 1; $i -le $maxRetry; $i++) {
    try { $result = Invoke-RestMethod $url -TimeoutSec 5 -ErrorAction Stop; break }
    catch {
        if ($i -eq $maxRetry) { throw }        # 最后一次仍失败：上抛
        Start-Sleep -Seconds (2 * $i)          # 指数退避
    }
}
```

三行核心：尝试、失败睡一会、到顶上抛。网络类操作的标准护栏，也是第 33 章工具的标配组件。

## 26.8 本章要点

- 双形态：**非终止**（默认，报错继续）与**终止/异常**（中断）；**try/catch 只抓终止**。
- 升级开关：`-ErrorAction Stop`（单命令）与 `$ErrorActionPreference='Stop'`（作用域）。
- try 三纪律：**按类型 catch、处理不了 re-throw、finally 只放清理**；粒度最小化。
- ErrorRecord 解剖：`Exception.Message`（人读）、`FullyQualifiedErrorId`（身份证）、**`InvocationInfo`（定位金矿）**、`ScriptStackTrace`（调用链）、`$Error[0]`（后悔药）。
- **throw 对内（契约）、exit 对外（进程）**；`-ErrorVariable` 旁路收集做"宽容+审计"。

**动手实验**：① 复现 26.1（catch 接不住非终止错误）；② 加 `-ErrorAction Stop` 让它进 catch，打印 `InvocationInfo.PositionMessage` 与 `FullyQualifiedErrorId`；③ 写三段 catch（文件不存在/目录不存在/兜底 re-throw）分流；④ `Get-Content` 一好三坏四个文件配 `-ErrorVariable`，最后打印坏文件清单；⑤ 写 throw 版校验函数与 exit 0/1 版脚本收尾，各验证一次；⑥ 故意制造一个错误后读 `$Error[0].ScriptStackTrace`。

实验参考：①红字出现但 catch 块没跑（脚本继续）——这个"看到红字≠进了 catch"的画面值得记住；②`PositionMessage` 会精确到行、列和那行代码；④`$missed` 里每个都是完整 ErrorRecord，`.TargetObject` 就是那个坏文件名。

对应示例（可选）：`examples/26_error_handling/`——双形态对照、-EA Stop 升级、类型分流 catch、finally 执行保证、ErrorRecord 五脏、-ErrorVariable 清单、throw/exit 分工。

---

本篇（五 工具制作）其余各章：[24 函数](./24-functions.md) · [25 高级函数](./25-advanced-functions.md) · [27 模块开发](./27-modules-dev.md) · [28 正则](./28-regex.md) · [29 技巧](./29-tips.md) · [30 他人脚本](./30-others-scripts.md)

---

本篇（五 工具制作）导航：[24 函数](./24-functions.md) · [25 高级函数](./25-advanced-functions.md) · [26 错误处理](./26-error-handling.md) · [27 模块开发](./27-modules-dev.md) · [28 正则](./28-regex.md) · [29 技巧](./29-tips.md) · [30 他人脚本](./30-others-scripts.md)

实验参考：①红字出现但 catch 没跑是本章最重要的一幅画面；⑥ScriptStackTrace 在多层函数里能看到完整调用链。
