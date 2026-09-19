# 09 · 单元与工程

## 1. unit 的两段式结构

Pascal 的模块单位是 **unit**（单元），一个文件一个单元，天生两段式：

```pascal
unit ugeometry;

interface                    { 接口段：对外可见的"目录"——类型、过程签名、常量、变量 }

uses SysUtils;               { 接口段用到的单元在这里声明 }

type
  TPoint = record X, Y: Double; end;

function Distance(const a, b: TPoint): Double;    { 只有签名，没有身体 }

implementation               { 实现段：藏私。接口段没列的一切外部不可见 }

var
  LoadedAt: string;          { 私有变量：外部永远摸不到 }

function Distance(const a, b: TPoint): Double;    { 实现必须与接口签名逐字一致 }
begin
  Result := Sqrt(Sqr(b.X - a.X) + Sqr(b.Y - a.Y));
end;

initialization              { 单元加载时执行一次（早于主程序 begin） }
  LoadedAt := {$I %DATE%};

finalization                { 程序退出时执行（各单元按加载反序） }
  ;

end.
```

要点：

- **interface = 头文件 + 目录**，implementation = 私有实现——C 需要两个文件维持的约定，
  Pascal 用语言机制固化，改签名时接口实现两处必须同步（编译器强制）。
- `initialization`/`finalization` 是单元级构造/析构：不用写任何调用代码，uses 它就执行
  （实测：主程序第一行跑之前 `InitCount` 已是 1）。
- 单元文件名 = 单元名（ugeometry.pas 里 `unit ugeometry`），编译器按名找人。

## 2. uses 的两个位置：接口侧与实现侧

```pascal
unit ureport;
interface
  function GeomSummary: string;     // 接口段没用 ugeometry 的类型 → 不需要引它
implementation
  uses SysUtils, ugeometry;         // 实现段用到才引——每段 uses 各自负责！
```

**坑（实测）**：实现段调用 `Format` 却没在实现段引 SysUtils → `Identifier not found "Format"`。
uses 不是文件级而是**段级**的——接口段和实现段各自声明各需要的单元。

放哪一侧还有性能与耦合含义：接口侧 uses 的单元会被 uses 本单元的人**间接拉进来**
（改它 = 全量重编下游）；实现侧的不会。原则：**能放实现侧就放实现侧**。

## 3. 循环引用：两把钥匙

A 的接口用 B、B 的接口用 A——编译器单遍处理必然死锁（`Circular unit reference`）。
两把钥匙（按优先级）：

1. **挪到实现段**（最常用）：把任意一侧的 uses 挪到 implementation——只要不是两侧的
   *接口*都互相需要类型，就解了。
2. **提取公共单元**：把两边都要的类型抽到第三个单元 C，A/B 都 uses C。

## 4. 多文件工程：编译模型

```text
examples/09_units/
├── 09_units.pas      主程序（program）
├── ugeometry.pas     单元
└── ureport.pas       单元（实现段 uses ugeometry —— 分层）
```

```powershell
fpc 09_units.pas          # 只编主程序——uses 的单元自动找、自动编
```

- 编译器在 `-Fu` 路径（默认含当前目录）按单元名找 `.pas/.ppu`。
- 单元首次编译产出 **`.ppu`（接口缓存）+ `.o`（目标码）**；没改动就复用——这就是增量编译。
  `-B` 强制全量重建（本教程检查通道带 `-B`，保证干净）。
- 依赖链：改 ugeometry 接口 → ureport 与主程序重编；只改实现段 → 只重编它自己。
- Lazarus IDE 的"工程"（.lpi，15 章三件套）本质就是这份多文件结构 + 元数据。

## 5. 条件编译：一份源码服务多方言/平台

```pascal
{$DEFINE DEMO_FEATURE}          // 本地定义；命令行等价物 -dDEMO_FEATURE
{$IFDEF DEMO_FEATURE}
  // 编入
{$ELSE}
  // 整段不进产物
{$ENDIF}

{$IFDEF WINDOWS} ... {$ENDIF}   // 编译器预定义：WINDOWS/LINUX/DARWIN/CPU64/CPUX86_64
{$MODE OBJFPC}                  // 逐单元指定方言（本工程统一写在文件头）
```

- `{$IFDEF}/{$IFNDEF}/{$ELSE}/{$ENDIF}` 是无值开关；`{$IF DEFINED(X) AND (Y > 2)}`
  支持表达式（较少用）。
- **坑（实测）**：`{$DEFINE}` 放进 `const` 段会报 `"identifier" expected but "BEGIN" found`——
  编译指令不是 const 声明，放开头或过程 begin 前的声明区。
- 定位跨平台差异的标准三板斧：`{$IFDEF WINDOWS}/{$IFDEF LINUX}` 包平台 API；
  `CPU64/CPU32` 包指针宽度代码；`{$MODE}` 处理方言差异。

## 6. 单元命名与组织惯例

| 惯例 | 例 |
|---|---|
| 单元名 u 前缀（社区主流）或无前缀 | `ugeometry` / `geometry` |
| 一个单元一个主题 | 几何归几何、报表归报表 |
| 分层单向依赖 | ureport → ugeometry → RTL；禁止回头 |
| 主程序薄 | 只 uses + 串流程，逻辑进单元 |

## 7. 示例与验证

本章示例 `examples/09_units`（三文件工程）：两段式、init/finalization 计数实测、
实现段 uses 分层、条件编译。编译入口与单文件示例完全一样——`build.ps1` 传主程序，
`-Fu` 本目录让兄弟单元可寻：

```powershell
pwsh -File build.ps1 -Example 09_units
```

## 8. 坑位清单（实测）

1. **uses 是段级的**：实现段用 `Format` 没引 SysUtils → `Identifier not found`；
   老资料"unit 顶部 uses 一把梭"的截图容易误导（那是接口段）。
2. `{$DEFINE}` 放 const 段 → `"identifier" expected but "BEGIN" found`。
3. 接口签名与实现签名必须逐字一致（参数名不同也算错）。
4. circular unit reference：先试挪实现段，不行抽公共单元。
5. 改接口段会级联重编所有下游单元——大工程里把"只在实现里用的 uses"留在实现侧。

---
上一章：[08 记录与指针](08-records.md) ｜ 下一章：[10 异常与资源保护](10-exceptions.md) ｜ 返回：[README](../README.md)
