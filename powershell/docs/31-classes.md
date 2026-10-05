# 31 类、枚举与结构化数据——当哈希表不够用

> 本章是扩充章。第 20 章的哈希表与 `[pscustomobject]` 覆盖了"装数据"的大多数场景；本章给两件更重的武器：**class/enum**（带类型、带方法、可继承的自定义类型）与 **JSON 深水区**（现代配置与 API 的通用语）。两者共同回答："我的数据结构需要升级吗？"

## 31.1 选型总表：装数据的四件容器

先给结论表（本章的地图）：

| 容器 | 长相 | 适合 | 限制 |
|---|---|---|---|
| 哈希表 `@{}` | 键值对、可变 | 快速组装、按名取值 | 无类型约束、无方法、键序不保（除非 ordered） |
| `[pscustomobject]` | 有属性的对象 | 管道输出、CSV/JSON 载体 | 属性定型后不易加、无方法 |
| **class** | 类型+属性+方法 | 领域模型（多处复用、要验证、要行为） | 需 5.0+；模块外使用要 `using` 或先定义 |
| **enum** | 命名常量集合 | 参数取值域、状态标记 | 值必须是整数 |

判断口诀：**装一次用一次→pscustomobject；反复用、要方法→class；取值就那几种→enum**。

## 31.2 class：语法全解

```powershell
class MachineInfo {
    # —— 属性（都带类型——class 的第一纪律） ——
    [string]$Name
    [int]$Score = 0                      # 带默认值
    static [int]$Created = 0             # 静态：属于类型不属于实例

    # —— 构造函数（可重载） ——
    MachineInfo([string]$name) {
        $this.Name = $name               # $this = 当前实例（注意：不是 $_）
        [MachineInfo]::Created++
    }
    MachineInfo([string]$name, [int]$score) {
        $this.Name = $name
        $this.Score = $score
        [MachineInfo]::Created++
    }

    # —— 方法 ——
    [string] Describe() {
        return "$($this.Name) 得分 $($this.Score)"
    }
    [void] AddScore([int]$delta) { $this.Score += $delta }
}
```

使用：

```powershell
$m = [MachineInfo]::new('srv1', 80)      # ::new() 实例化（5.0+；比 New-Object 地道）
$m.Describe()                             # srv1 得分 80
$m.AddScore(5); $m.Score                  # 85
[MachineInfo]::Created                    # 2 —— 静态成员经类名访问
```

与函数世界的关键差异四条：**属性方法都要显式类型**（返回值类型写在方法名前）；**`$this` 不是 `$_`**；**类型在编译期检查**（`$m.Score = 'abc'` 当场报错，不是运行到一半才炸）；**class 定义要先于使用**（文件里 class 在函数前面，或模块里 `using module` 引入——这是 class 在脚本里的最大组织约束）。

## 31.3 继承与 enum

**继承**：`class 子类 : 基类`，构造函数用 `: base(...)` 转发：

```powershell
class ScoredMachine : MachineInfo {
    [string]$Owner
    ScoredMachine([string]$name, [int]$score, [string]$owner) : base($name, $score) {
        $this.Owner = $owner
    }
    [string] Describe() {                 # 方法重载：覆盖父类行为
        return "$($this.Name)（$($this.Owner)）得分 $($this.Score)"
    }
}
```

继承的真实收益在"一族行为不同的模型"（不同机器类型有不同的巡检逻辑但共享基类骨架）；单打独斗的模型别为了继承而继承。

**enum**：命名常量集合，天生配参数：

```powershell
enum EnvKind { Development; Test; Production }
function Invoke-Deploy {
    param([EnvKind]$Environment)          # 参数类型是枚举——非法值门口拦截，Tab 补全免费
}
Invoke-Deploy -Environment Production     # ✔
Invoke-Deploy -Environment 'prod'         # ✗（不能转换为 EnvKind）
[EnvKind]::Test                           # 取值；[int][EnvKind]::Production 是 2
```

**enum 与 `[ValidateSet]` 的分界**：ValidateSet 是"字符串白名单"（轻、就地、无类型）；enum 是**真类型**（可在多处复用、参与 switch 分支、位标志 `[Flags()]` 可组合）。一次性参数用 ValidateSet，跨函数共享的领域概念用 enum。

一个实测惊喜：**enum 参数绑定接受唯一前缀缩写**——`-Environment prod` 能绑到 `Production`（与参数名缩写同理，第 03 章）；但 `'zzz'` 这种完全不沾边的值会被 `ParameterArgumentTransformationError` 当场拦下。所以 enum 的门禁是"前缀可缩、乱值必拦"。

## 31.4 JSON：现代数据交换语

`ConvertFrom-Json` / `ConvertTo-Json`（注意动词是 Convert 不是 Export——文件落盘自己 `Set-Content`，第 06 章动词合同）：

```powershell
$obj = Get-Service -Name winmgmt | Select-Object Name, Status
$obj | ConvertTo-Json                       # 对象 → JSON 文本
'{ "name": "svc", "port": 9100 }' | ConvertFrom-Json     # JSON 文本 → pscustomobject
```

**坑一：`-Depth` 默认 2 的截断**。嵌套对象超过两三层，深层被替换掉——实测四层嵌套（A→B→C→D）时 `贵重数据` 直接消失。**双引擎差异（实测）**：pwsh 7 会发一条警告流提示（"生成的 JSON 已被截断……"，第 3 条流，重定向下极易错过）；**5.1 连警告都没有，纯静默截断**——更危险：

```powershell
$deep = @{ A = @{ B = @{ C = @{ D = '贵重数据' } } } }
$deep | ConvertTo-Json                     # D 层没了，只有一条易被忽略的警告
$deep | ConvertTo-Json -Depth 5            # 深度给够，数据完整
```

**习惯：生产代码的 ConvertTo-Json 一律显式 `-Depth`**（给 10 不伤人）；配套 `-Compress`（压成单行，给 API 用）与 `-AsArray`（7+，强制数组包裹）。

**坑二：读回来的类型**。`ConvertFrom-Json` 默认产出 `pscustomobject`——只读数据载体；要往里塞键/改值，5.1 里很别扭（对象属性不能随意加），**pwsh 7 的 `-AsHashtable`** 直接给哈希表（可变、可增删）：

```powershell
$config = '{ "a": 1 }' | ConvertFrom-Json -AsHashtable      # [ch7-only]
$config['b'] = 2                                             # 哈希表随便加
```

**坑三：单元素数组消失**。JSON 里的 `["a"]` 读回来，5.1 给单元素（数组形态丢失——又是第 20 章的单元素陷阱！）；管道时 `@(...)` 包裹或 7+ 的 `-AsHashtable` 保留原形。**往返保真**（round-trip）是 JSON 处理的自检动作：

```powershell
$rt = ($obj | ConvertTo-Json -Depth 5) | ConvertFrom-Json
$rt.Name -eq $obj.Name          # True 才算"没丢"
```

## 31.5 结构化数据三选：CSV / JSON / Clixml

第 06 章给了 CSV 与 Clixml；JSON 入座后，三件套的分工表（数据交换的完整地图）：

| 格式 | 命令 | 保真度 | 互操作性 | 适用 |
|---|---|---|---|---|
| CSV | `Export/Import-Csv` | 平面数据（无嵌套） | 人人能读（Excel） | 表格类导出/报表 |
| **JSON** | `ConvertTo/From-Json` | 嵌套+类型近似 | **Web/API/配置的通用语** | 配置文件、API 载荷、NoSQL |
| Clixml | `Export/Import-Clixml` | 最全（含类型深度） | PowerShell 专属 | 快照/基线（第 06 章） |

配置文件选 JSON（通用、可读、工具链全）；PowerShell 内部快照选 Clixml（保真最高）；给人看的表格选 CSV。**"快照给机器、JSON 给世界、CSV 给人"**。

## 31.5.1 class 的进阶件：静态工具类与隐藏成员

两个进阶件让 class 在工具箱里的位置更清晰：

**静态类=命名空间工具集**：全部成员 static 的 class 就是一个"函数包"，调用不必实例化——.NET 里 `[math]`、`[string]` 的组织方式（第 08 章"车库"）在自制工具里的对应物：

```powershell
class InvRules {
    static [int] $DefaultThreshold = 10
    static [bool] IsCritical([int]$freePct) { return $freePct -lt [InvRules]::DefaultThreshold }
}
[InvRules]::IsCritical(5)              # True —— 不 new 直接用
```

**隐藏成员**：属性/方法标 `hidden` 后对 `Get-Member` 与格式化默认视图隐身（序列化也不带）——内部状态的标准藏法：

```powershell
class Cache2 {
    hidden [hashtable]$Store = @{}
    [void] Put([string]$k, $v) { $this.Store[$k] = $v }
    [object] Get([string]$k) { return $this.Store[$k] }
}
$c = [Cache2]::new(); $c.Put('a', 1)
$c | Get-Member -MemberType Property    # 看不到 Store —— 公开面干净
```

`hidden` 与第 27 章 `Export-ModuleMember` 是同一思想在不同层的实现：**公开面越窄，重构越自由**。

## 31.6 本章高频坑位

| 现象 | 原因 | 对策 |
|---|---|---|
| class 用在定义之前报"找不到类型" | class 需先定义后使用 | class 放文件/模块前部；跨文件用 `using module` |
| 方法里 `$_.Name` 拿不到 | class 里是 `$this` | `$_` 是管道专利 |
| JSON 深层字段变类型名/丢失 | `-Depth` 默认 2 截断 | 显式 `-Depth 10` |
| 读回的 JSON 改不动 | 默认产出 pscustomobject | 7+ 用 `-AsHashtable`；5.1 转 `[pscustomobject]` 哈希表重建 |
| `["a"]` 读回变标量 `'a'` | 单元素数组陷阱 | `@()` 包裹；7+ `-AsHashtable` 保留 |
| enum 参数收不了简写 | 枚举不做模糊匹配（实测：唯一前缀**可以**，乱值才拦） | 传全名最稳；利用前缀缩写时确认唯一 |
| `New-Object` 造不了带参 class 实例 | 老命令与新类型不合 | 一律 `[类型]::new(参数)` |

## 31.7 本章要点

- 选型四件套：**一次性 pscustomobject、领域模型 class、取值域 enum、快装哈希表**。
- class：属性/方法显式类型、构造可重载（`: base()` 转发）、`$this`/`::`/`::new()`；**先定义后使用**。
- enum 是真类型：参数门口拦截+Tab 枚举+switch 分支；与 ValidateSet 的分界是复用面。
- JSON 三坑：**`-Depth` 显式给**、默认读回 pscustomobject（7+ `-AsHashtable`）、单元素数组消失——**往返保真**做自检。
- 数据格式三选：快照 Clixml、交换 JSON、给人 CSV。

**动手实验**：① 把 31.2 的 class 敲一遍，故意 `$m.Score = 'abc'` 看编译期报错；② 加继承的 `ScoredMachine`，观察 `Describe()` 被覆盖；③ 定义 `EnvKind` enum 做 `switch ($env)` 分支；④ 复现 `-Depth` 截断（三层嵌套不给 Depth）再给 `-Depth 5` 对照；⑤ JSON 往返保真检查一条链路；⑥ `-AsHashtable` 在两个引擎各试一次（5.1 应报参数不存在——差异标注的活样本）。

实验参考：④截断时最深层显示成字符串化的类型提示——**没有任何警告**，这就是"坑一"的可怕之处；⑥5.1 的报错是"找不到参数 AsHashtable"，与第 09 章 ComputerName 的"参数级差异"同款判读法。

对应示例（可选）：`examples/31_classes/`——class 构造/静态/方法、继承覆盖、enum 验证与 switch、JSON 深度截断对照、往返保真、-AsHashtable 双引擎分岔。

---

本篇（六 进阶收官）其余各章：[32 测试](./32-testing.md) · [33 工具制作收官](./33-toolmaking.md) · [34 备忘清单](./34-cheatsheet.md)

实验参考：①报错信息会精确到"无法转换类型"并指明属性名；⑥5.1 报"找不到参数 AsHashtable"——两代 JSON 能力的分界线。

---

本篇（六 进阶收官）导航：[31 类与 JSON](./31-classes.md) · [32 测试](./32-testing.md) · [33 工具制作收官](./33-toolmaking.md) · [34 备忘清单](./34-cheatsheet.md)
