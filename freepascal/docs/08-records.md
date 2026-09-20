# 08 · 记录与指针

## 1. record：值语义的聚合体

```pascal
type
  TPoint2D = record
    X, Y: Double;
  end;
var
  p, q: TPoint2D;
begin
  p.X := 3; p.Y := 4;
  with p do
    Assert(X * X + Y * Y = 25);     // with 省前缀（别嵌套）
  q := p;                            // 深拷贝！
  q.X := 99;
  Assert(p.X = 3);                   // record 赋值即拷贝（与动态数组相反）
```

record 与动态数组的赋值语义对照（06 章表的另一半）：

| | record | 动态数组 |
|---|---|---|
| `q := p` | 逐字段深拷贝 | 共享 |
| 内含引用类型字段 | 字段指针被拷贝（浅层） | — |

注意"深拷贝"只到字段一层：字段若是 string/动态数组/接口，拷的是**引用**（它们自己有
引用计数保平安）。

## 2. packed 与内存布局

```pascal
type
  TPadded = record
    A: Byte;      // 1 字节 + 3 字节对齐填充
    B: Integer;   // 4 字节
  end;
  TPackedRec = packed record          // packed：不要填充
    A: Byte;
    B: Integer;
  end;

Assert(SizeOf(TPadded) = 8);          // 实测
Assert(SizeOf(TPackedRec) = 5);
```

默认布局按成员的自然对齐填充（CPU 友好）；`packed` 压平——**读文件格式、网络协议、
C 结构体对接时必用 packed**，但访问未对齐字段在个别平台有代价。跟 C 互通时还要
对照 C 端的 `#pragma pack` 设置。

## 3. variant record：一段内存两种视图

```pascal
type
  TPacket = record
    Kind: Integer;
    case Boolean of                    // case 段必须在最后，无 end 配对
      True:  (Raw: array[0..3] of Byte);
      False: (Value: Integer);
  end;

pkt.Value := $01020304;
Assert(pkt.Raw[0] = 4);                // 小端机：最低字节落 Raw[0]
```

这是 C union 的安全版（公共前缀字段是允许的，如同例的 `Kind`——"带标签的联合"）。
现代代码更常用 `case Kind of` 让标签驱动解释。写入一个视图读另一个视图是**未定义
类型层面**的 reinterpret，除了协议解析别用它。

## 4. record 方法与运算符重载（FPC 扩展）

record 能有方法、属性、运算符——但要开开关：

```pascal
{$modeswitch advancedrecords}          // 文件头开启（实测：不开直接报语法错）

type
  TVec2 = record
  public
    X, Y: Double;
    function Len: Double;
    class operator +(const a, b: TVec2): TVec2;
    class operator =(const a, b: TVec2): Boolean;
  end;

v.X := 3; v.Y := 4;
Assert(Abs(v.Len - 5) < 1e-12);
w := v + v;                            // 运算符直接用
```

- **record 可重载运算符，class 不行**（类只能用命名方法）——数学向量/复数用 record。
- objfpc 的老式全局运算符（`operator +(a, b: TVec2): TVec2;` 独立函数）也有效，
  成员式更内聚。
- record 没有继承与虚方法——要那些就用 class（12 章）。

## 5. 指针基础：@ 与 ^、New/Dispose

```pascal
n := 42;
p := @n;          // @ 取地址
p^ := 99;         // ^ 解引用（读/写）
Assert(n = 99);   // 指针改的就是本体

New(p);           // 堆上分配"一个 Integer"，typed pointer 的配对分配
p^ := 7;
Dispose(p);       // 严格配对释放
```

| 操作 | 含义 | C 对应 |
|---|---|---|
| `@x` | 取地址 | `&x` |
| `p^` | 解引用 | `*p` |
| `New(p)` / `Dispose(p)` | 按指针类型分配/释放 | `malloc(sizeof)` / `free` |
| `GetMem(p, n)` / `FreeMem(p)` | 按字节分配/释放 | `malloc(n)` / `free` |

## 6. GetMem/FreeMem 与内存纪律

```pascal
GetMem(p, 4 * SizeOf(Integer));
pi := PInteger(p);
for i := 0 to 3 do pi[i] := i * 10;    // 指针下标访问
FreeMem(p);
```

Pascal 没有 GC，但有**引用计数类型**兜底（string/动态数组/接口自动释放）。
纯手动内存的纪律只有三条：**谁分配谁释放、GetMem/FreeMem 字节数配对、释放后立刻丢指针**。
排查工具用 heaptrc（编译加 `-gh`）：

```text
# 编译：fpc -gh 08_records.pas —— 运行结束打印到 stderr：
103 memory blocks allocated : 5578/5832
103 memory blocks freed     : 5578/5832
0 unfreeed memory blocks : 0        ← 0 即无泄漏
```

注意（实测）：`-gh` 的报告**固定走 stderr 且零泄漏也打印**，所以本教程的验证通道不含
`-gh`（stderr 必须为空）；排查泄漏时手动加开关单跑。有意泄漏的排查演示见示例目录注释。

## 7. {$POINTERMATH}：指针算术开关

```pascal
p := @arr[0];
Assert(p[3] = 40);                    // 下标式一直可用

{$POINTERMATH ON}
Assert((p + 3)^ = 40);                // p+3 按【元素宽度】前进（不是字节！）
{$POINTERMATH OFF}
// 关掉后 p+3 直接编译错误——C 的指针算术要显式开开关
```

实测：POINTERMATH 的加法按**基类型宽度**跳（`PInteger + 3` = 字节 +12），语义与 C 相同，
但**默认关闭**——防止无心的指针漫游。写解析器/缓冲区遍历时打开，用完关上。

## 8. 过程类型与回调

```pascal
type
  TComparator = function(a, b: Integer): Integer;    // 过程类型=函数指针

procedure BubbleSort(var arr: array of Integer; cmp: TComparator);
  ...
  if cmp(arr[j], arr[j + 1]) > 0 then ...            // 经 cmp 间接调用

BubbleSort(a, @Asc);                  // objfpc 模式传函数地址必须带 @
```

- 过程类型分两种形态：全局函数指针（`function(...): ...`）与**方法指针**
  （`function(...) of object`，绑实例+方法对——LCL 事件系统的地基，16 章重点）。
- objfpc 模式下传函数要 `@Asc`（Delphi 模式可省 @）。
- GUI 的一切事件（OnClick/OnChange）本质都是方法指针——这里是它的语言基础。

## 9. 调 DLL：external + cdecl/stdcall + varargs

```pascal
// varargs：cdecl 变参函数的声明方式——调用时直接跟参数，不打包数组
// 坑（实测）：库名是平台相关的——Windows 是 msvcrt，Unix 是 libc（macOS 写 'c' 即可，
// libSystem 提供别名）。库名要是编译期字面量，不能用变量，所以只能 IFDEF 分叉两条声明。
function printf(fmt: PAnsiChar): Integer; cdecl; varargs;
  {$IFDEF WINDOWS}external 'msvcrt';{$ELSE}external 'c';{$ENDIF}

Flush(Output);                                   // 先冲掉 Pascal 自己的缓冲，输出才可复现
printf('printf from C runtime: %d + %d = %d' + #10, 1, 2, 3);   // 实测直通 C 运行库
```

> 坑（实测）：`printf` 走 C 自己的 stdout 缓冲，和 Pascal 的 `Output` 是**两套缓冲**——
> 不先 `Flush(Output)`，两边在退出时各刷一次，谁先谁后不定，双通道输出比对就会随机失败。

三件套：

1. **`external '库名'`**：链接期绑定到 DLL 的导出符号（可加 `name '真名'` 改名）。
2. **调用约定**：C 运行库/多数开源库 `cdecl`；Windows API 一律 `stdcall`——**约定错 =
   栈失衡崩溃**，没有商量。
3. **`varargs`**：printf 这类变参函数必须在声明加它，调用时参数直接罗列（不是数组）。

Windows API 的调用（`external 'user32'` 等）同套路，32 位/64 位符号名差异
（`MessageBoxA/W`）在 64 位下不再敏感。Lazarus 自带完整的 **Windows 单元**
（`uses Windows`）把 Win32 API 全声明好了——实战直接用它，手写 external 留给
第三方 DLL。

## 10. 示例与验证

本章示例 `examples/08_records`：record 语义/packed/variant record/运算符、指针全家、
POINTERMATH、回调排序、C 运行库直调（Windows: msvcrt / Unix: libc）。

```powershell
pwsh -File build.ps1 -Example 08_records
# 泄漏排查（不进验证通道，手动单跑）：
#   fpc -gh examples\08_records\08_records.pas && 08_records.exe   →  stderr 看 unfreed
```

## 11. 坑位清单（实测）

1. record 方法/运算符必须 `{$modeswitch advancedrecords}`，报错却是语法错
   （`':' expected`）——离根因很远。
2. **class 不能重载运算符**，record 才能——数学类型选 record。
3. 指针算术默认非法，`{$POINTERMATH ON}` 后 `p+n` 按**元素宽度**不是字节。
4. objfpc 传函数地址必须 `@`（Delphi 模式不用）——LCL 事件赋值 `OnClick := @BtnClick`
   同理。
5. `-gh` 报告走 stderr 且零泄漏也打印——别混进"stderr 必须为空"的验证通道。
6. cdecl/stdcall 用错 = 玄学崩溃；Win32 API 一律 stdcall（Lazarus 的 Windows 单元已备好）。
7. `varargs` 函数调用时参数**直接罗列**，不打包 `[...]` 数组（与 array of const 相反）。

---
上一章：[07 字符串与编码](07-strings.md) ｜ 下一章：[09 单元与工程](09-units.md) ｜ 返回：[README](../README.md)
