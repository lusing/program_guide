# 07 · 字符串与编码（⭐特色章）

字符串是 FPC 3.x 里概念密度最高的部分：一门语言同时养着**四代字符串**，还有码页标记、
引用计数、字面量重定型三重机关。网上资料大多是 Delphi 7 时代（无码页）或 Delphi 2009+
（UnicodeString 一统）的说法，放在 FPC 3.2.2 上**两头都不对**。本章全部结论来自本机实测。

## 1. 四代字符串：一个程序看全

| 类型 | 本质 | Length 语义 | 生存空间 |
|---|---|---|---|
| `ShortString`（`String[n]`） | 定长字节数组，`[0]` 存长度 | 字节（≤255） | 老代码、零堆分配场合 |
| `AnsiString`（= `{$H+}` 的 `string`） | 指针 + 引用计数 + **码页标记** | 字节 | FPC/Lazarus 主力 |
| `UTF8String` | AnsiString，标记恒 65001 | 字节 | Lazarus 的 UTF-8 世界观 |
| `UnicodeString` | UTF-16 + 引用计数 | **UTF-16 码元** | Windows API、跨码页中转 |

```pascal
sh := 'ShortStr 截断到 8 字节';
Assert(Length(sh) = 8);              // ShortString 超长静默截断
Assert(SizeOf(a) = 8);               // AnsiString/UnicodeString 变量本身只是 8 字节指针
```

**变量是 8 字节指针**、真实数据（长度/引用计数/码页/字节）在堆头部——这是除 ShortString
外三种字符串的共同构造。赋值、传 `const` 参数都是指针+引用计数操作，零拷贝。

## 2. 引用计数：赋值共享，写时脱离

```pascal
a := 'shared string ';
a := a + a;              // 修改 a：独占（重新分配）
b := a;                  // b 与 a 共享：引用计数 +1，零拷贝
b := b + 'x';            // 写 b：先脱离共享（真拷贝），再改
Assert(Length(a) = 28);  // 本体不受影响——写时复制（COW）
```

规则一句话：**读共享、写独占**。`b[i] := 'x'` 这种原地写也一样先 fpcCopy 拷贝。
风险点：拿着 `PChar(a)` 或 `@a[1]` 后又修改了 `a`——旧指针悬垂（见 8 节）。

## 3. 码页标记与字面量重定型（本教程最重要实测）

FPC 3.x 的 AnsiString 每个实例带一个**码页标记**（0..65535）。同一串字节，
标记不同，跨类型转换时的行为完全不同。三组实测（全部收录在示例 7.3–7.5）：

**实测一：赋值保留字面量的标记。**

```pascal
a := '中文';
Assert(StringCodePage(a) = 65001);   // 不是系统码页 936！{$codepage utf8} 源码的字面量标记 65001
Assert(Length(a) = 6);               // 字节计数
```

**实测二：字面量在"无类型上下文"里按 UnicodeString 解释。**
用重载探针直接问编译器（示例 7.3 原样可跑）：

```pascal
function Which(const s: string): string; overload;        // AnsiString
function Which(const s: UnicodeString): string; overload; // UTF-16

Which(a)          // → 'AnsiString'     （变量：绑定 AnsiString 重载）
Which('中文')     // → 'UnicodeString'  （字面量：绑定 UnicodeString 重载！）
Length('中文')    // → 2（按字符）      Length(a) → 6（按字节）
```

这就是 02 章埋的伏笔的机理：**UTF-8 标记的字面量直接放进表达式（不经 string 变量）
时，编译器把它当 UnicodeString 常量**——Length 按字符、for-in 按字符（04 章实测 4 次 vs
变量 8 次）。要按字节语义，**先存进 `string`/`UTF8String` 变量**。

**实测三：Pos 与 Copy 语义分裂。**

```pascal
a := '中文';
Assert(Pos('文', a) = 2);        // Pos：对 UTF-8 标记串按【字符】返回位置（RTL 特例）
Assert(Copy(a, 4, 3) = '文');    // Copy：仍按【字节】切
Assert(Length(a) = 6);           // Length：按【字节】
```

同一个字符串、同一章 RTL，三种坐标系统并存。守则：**字符串下标运算前先想清楚
自己在按字节还是按字符操作**；Lazarus 端有 `UTF8Copy`/`UTF8Pos` 全家（16 章起用），
纯 FPC 控制台下见第 6 节。

## 4. 标记比字节重要：错误标记 = 系统性乱码

```pascal
raw := a;                          // RawByteString：无码页语义的"字节袋"
SetCodePage(raw, 936, False);      // 只改标记不转字节：伪造"GBK 标记的 UTF-8 字节"
w := raw;                          // RTL 按 GBK 解码 UTF-8 字节 → 3 个乱码字符
Assert(Length(w) = 3);

SetCodePage(raw, 65001, False);    // 改回标记，字节一个没动
Assert(string(raw) = a);           // "复原"——错的从来不是字节，是标记
```

转换函数族都在 System/SysUtils：`UnicodeString(s)`（按标记解码）、`UTF8String(s)`（按标记
编码）、`SetCodePage(s, cp, Convert)`（`Convert=True` 时真转字节，`False` 只改标记——
上面演示的就是 False 的"作弊"用法，用来理解标记的语义）。

排乱码问题的第一问永远是：**这串字节的标记是什么？**（`StringCodePage(s)` 直接问）
第二问：目标上下文期望什么标记？02 章的控制台输出（WriteLn 按活动控制台码页转码）
本质也是这套机制。

## 5. 字符串例程：字节语义为主

```pascal
Pos('文', a)      // 例外：UTF-8 标记串按字符（见 §3）
Copy(a, 4, 3)     // 按字节
Delete/Insert     // 按字节
Length(a)         // 按字节
Trim / UpperCase / LowerCase   // 单字节 ASCII 生效，多字节原样通过（不破坏 UTF-8）
```

`UpperCase` 对中文无害但也无用（不认识多字节字母）——要真国际化用 `AnsiUpperCaseProc`
可换的 RTL 钩子或转 UnicodeString 处理。

## 6. UTF-8 安全的"按字符"操作：手写

纯 RTL 没有现成的"数 UTF-8 字符"（Lazarus 的 LCL 有 `UTF8Length`，GUI 篇直接用）。
控制台程序自己写，顺便理解 UTF-8 的结构：

```pascal
function CountUtf8Chars(const s: UTF8String): Integer;
var i: Integer;
begin
  Result := 0;
  for i := 1 to Length(s) do
    if Byte(s[i]) and $C0 <> $80 then    // 非"续字节"(10xxxxxx) 即新字符起点
      Inc(Result);
end;
```

另一条路：经 `UnicodeString` 中转（`Length(UnicodeString(u8))` 直接按字符），代价一次
解码。逆操作同理。

## 7. Format 与字符串数字互转

```pascal
Format('%s 得了 %d 分（%.1f%%）', ['张三', 95, 95.0]);   // "张三 得了 95 分（95.0%）"
Format('%5.2f', [3.14159]);                              // ' 3.14'（宽度 5 右对齐）
Format('%x', [255]);                                     // 'FF'
TryStrToInt('42', n);                                    // 布尔版（不抛异常）
StrToInt('42');                                          // 失败抛 EConvertError
Val('12x', n, code);                                     // 老派：code=出错位置
```

`Format` 就是 05 章 `array of const` 的最大受益者——记住 `%d %s %f %x` 四件套够用。

## 8. PChar：与 C 世界的握手

```pascal
a := 'Hello';
p := PChar(a);              // 零拷贝转换：指向内部缓冲，且保证 #0 结尾
Assert(StrLen(p) = 5);      // C 语义：按 #0 找尾

a := a + ' World';          // ⚠️ a 可能重新分配——p 已悬垂，必须重新 PChar(a)
```

string → PChar 免费且安全（编译器保证 NUL 结尾）；PChar → string 走拷贝。
悬垂风险来自 string 的重新分配——**每次 string 变动后重新取 PChar**。调 C DLL 时
（08 章实战）PChar 是主角。

## 9. 示例与验证

本章示例 `examples/07_strings`：四代字符串、引用计数 COW、重载探针实测字面量重定型、
Pos/Copy 分裂、SetCodePage 乱码实验、手写 CountUtf8Chars、Format、PChar。

```powershell
pwsh -File build.ps1 -Example 07_strings
```

## 10. 坑位清单（实测）

1. **字面量重定型**：`Length('中文')`=2（字符）、`Length(s)`（先赋值）=6（字节）；
   for-in 同样分裂。要字节语义，先入 `string` 变量。
2. **Pos 按字符、Copy/Length 按字节**（UTF-8 标记串）——三种坐标系统并存于同一 RTL。
3. 赋值保留字面量码页标记（`StringCodePage(a)=65001`，不是系统码页）——跨类型转换前
   先看标记，别赌默认。
4. ShortString 超长**静默截断**（无警告）；`String[8]` 的 8 是字节数。
5. `SetCodePage(s, cp, False)` 只改标记不转字节——排乱码时的"作弊器"，也是乱码的
   常见肇事者。
6. string 变动（拼接/SetLength）后旧 PChar 悬垂。
7. 网上 Delphi 资料的"string=AnsiString 无码页"（D7 前）或"string=UnicodeString"
   （D2009+）在 FPC 都不成立——FPC 的 string 是带码页的 AnsiString。

---
上一章：[06 数组与集合](06-arrays.md) ｜ 下一章：[08 记录与指针](08-records.md) ｜ 返回：[README](../README.md)
