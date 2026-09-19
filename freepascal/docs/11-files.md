# 11 · 文件与序列化

## 1. TextFile：最经典的文本 IO

```pascal
var f: TextFile; line: string;
begin
  AssignFile(f, 'demo.txt');            // 关联（还没打开）
  SetTextCodePage(f, 65001);            // ⚠️ UTF-8 文件必设（见下）
  Rewrite(f);                           // 打开清空写；Reset 只读；Append 追加
  WriteLn(f, '第一行');
  CloseFile(f);

  Reset(f);
  while not Eof(f) do
    ReadLn(f, line);                    // 整行读（自动处理 CRLF/LF）
  CloseFile(f);
```

**编码大坑（实测）**：TextFile 默认按**系统码页**读写。源码是 `{$codepage utf8}`、
WriteLn 写出的是 UTF-8 字节，但 ReadLn 读回的字符串被标记成系统码页（936）——
再与 UTF-8 字面量比较必不相等（07 章标记机制的文件版）。**解法**：`AssignFile` 之后
立刻 `SetTextCodePage(f, 65001)`，一次 Assign 的设置对后续 Rewrite/Reset 都生效。
示例 11.1 的断言就是靠它才通过的。

## 2. {$I-} + IOResult：老派错误处理（读老代码必备）

```pascal
{$I-}                          // 关闭 IO 异常
AssignFile(f, '不存在的文件.txt');
Reset(f);
rc := IOResult;                // 立即取错误码（0=成功；再调一次就清零）
{$I+}
```

异常普及前的标准姿势，Turbo Pascal 时代的遗产。现代代码用
`FileExists` 预查 + 让异常自然抛（`EStreamError` 家族）。读老代码认识它即可。

## 3. typed file：file of 记录

```pascal
type
  TPersonRec = packed record            // packed：布局确定，SizeOf 可预测
    Id: Integer;
    Age: Byte;
    Name: array[0..15] of AnsiChar;     // 定长字段才能算偏移
  end;
var
  f: file of TPersonRec;                // 元素=记录的文件
begin
  Rewrite(f);
  Write(f, p);                          // 写一条（一个记录）
  Seek(f, 0);                           // 按记录数定位——不是字节数！
  Read(f, q);
  FileSize(f);                          // 记录数（不是字节数）
end;
```

`file of T` 是"穷人版随机访问数据库"：`Seek`/`FileSize`/`FilePos` 全部以**记录**为单位。
限制同样明显：字段必须定长（string 不行，用 `array of AnsiChar`），
所以中文姓名按字节管理很别扭（示例用 ASCII 名 + 注释说明了原因——07 章码页标记的坑）。
现代选择是流 + 自己序列化（下一节）。

## 4. TFileStream：二进制流（现代姿势）

```pascal
fs := TFileStream.Create('data.bin', fmCreate);   // fmCreate 覆盖建新
try
  fs.WriteBuffer(buf, SizeOf(buf));               // Buffer 版失败抛异常
finally
  fs.Free;
end;

fs := TFileStream.Create('data.bin', fmOpenRead);
try
  fs.ReadBuffer(buf, SizeOf(buf));
  WriteLn(fs.Size);                               // 字节数
finally
  fs.Free;
end;
```

- `Write/Read`（返回字节数）与 `WriteBuffer/ReadBuffer`（不够即抛异常）——
  优先 Buffer 版，失败有异常可捕。
- 模式旗标：`fmCreate`/`fmOpenRead`/`fmOpenWrite`/`fmOpenReadWrite`（可 or `fmShareDenyWrite`）。
- `Position`/`Seek()` 手动定位；GUI 端（图片/文档读写）全是它，24 章记事本+ 用它读写文本。

## 5. TIniFile：配置文件的标准答案

```pascal
ini := TIniFile.Create('settings.ini');
try
  ini.WriteInteger('window', 'width', 800);
finally
  ini.Free;                 // ⚠️ Free 时才落盘！忘了 Free = 配置全丢
end;

v := ini.ReadInteger('window', 'width', 0);      // 第 4 参 = 缺省值
```

- 读 API 全家带**缺省值参数**——键不存在/文件不存在都不报错，适合配置读取。
- **坑（实测）**：Windows 上 TIniFile 走 ANSI INI API，中文节/键/值按系统码页落盘（GBK）；
  读写两侧码页标记错位时键都查不到（文件里同一节重复出现）。**惯例：节/键名一律
  ASCII**；值需要中文时改用 `TStringList`（SaveToFile 支持 UTF-8 编码参数）。
- `ini.UpdateFile` 可强制立即落盘；`ReadSections/ReadKeys` 遍历。

## 6. 目录与文件操作速查

```pascal
FileExists('demo.txt');  DirectoryExists('subdir');
CreateDir('subdir');     ForceDirectories('a\b\c');   // 多级一次建
DeleteFile('demo.txt');  RenameFile('a.txt', 'b.txt');

ExtractFileName('G:\code\demo.txt');   // 'demo.txt'
ExtractFilePath('G:\code\demo.txt');   // 'G:\code\'
ExtractFileExt('data.bin');            // '.bin'
IncludeTrailingPathDelimiter('G:\x');  // 'G:\x\'
```

全在 SysUtils。找文件（`FindFirst/FindNext`）示例没展开，需要时查 CHEATSheet。

## 7. 时间与随机：确定性输出的两条纪律

```pascal
fixed := EncodeDate(2026, 9, 19);
Assert(FormatDateTime('yyyy-mm-dd', fixed) = '2026-09-19');

RandSeed := 42;                 // 固定种子：Random 序列每次运行完全相同
d1 := Random(100);
```

- `Now/Date/Time` 返回实时时钟——**演示可以、打印输出别用**（输出不可复现，
  本教程双通道逐字节比对会炸）。需要日期输出时 `EncodeDate` 固定时刻。
- `Randomize` 用系统时钟播熵——**示例/测试一律不调**，改设 `RandSeed := 42`；
  正式产品在 main 开头调一次。
- `FormatDateTime` 格式串区分大小写：`yyyy-mm-dd hh:nn:ss`（**分钟是 nn**，mm 是月份——
  经典手误点）。

## 8. 示例与验证

本章示例 `examples/11_files`：TextFile（含码页修正）、{$I-}+IOResult、typed file、
TFileStream、TIniFile、目录操作、固定时间/随机数。文件产物落在运行目录
（`build/check|release/`），不进版本库。

```powershell
pwsh -File build.ps1 -Example 11_files
```

## 9. 坑位清单（实测）

1. TextFile 默认按系统码页标记读写——UTF-8 中文读回后与字面量比较**必不相等**；
   `AssignFile` 后立刻 `SetTextCodePage(f, 65001)`。
2. `SetTextCodePage` 一次设置对同一次 Assign 的 Rewrite/Reset 都生效（放 Reset 之后无效）。
3. TIniFile 在 Windows 走 ANSI API：中文节/键按 GBK 落盘，标记错位时键查不到且文件
   节重复——节/键名一律 ASCII。
4. `TIniFile.Free` 才落盘——只 Create 不 Free 的实例配置全丢。
5. typed file 的 `Seek/FileSize` 以**记录**为单位不是字节；字段必须定长
   （string 进不了记录）。
6. FormatDateTime 的分钟占位是 **nn**（mm 是月份）。
7. 示例/测试不调 `Randomize`，固定 `RandSeed`；不打印 `Now`——可复现输出是一切自动
   验证的前提。

---
上一章：[10 异常与资源保护](10-exceptions.md) ｜ 下一章：[12 OOP I：类与封装](12-oop1.md) ｜ 返回：[README](../README.md)
