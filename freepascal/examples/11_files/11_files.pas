{$mode objfpc}{$codepage utf8}{$H+}
program files_demo;
{ 11 · 文件与序列化：TextFile 全家、{$I-}+IOResult、typed file、TFileStream、
  TIniFile、目录操作、固定时刻时间与确定性随机。正文见 docs/11-files.md。
  文件产物写在运行目录（build/check|release），不进版本库。 }
uses
  {$IFDEF UNIX}cwstring,{$ENDIF}   // ★ Unix：必须是 uses 第一个——否则 WriteLn 中文字面量全变 ?（见 02 章 2.3）
  SysUtils, Classes, IniFiles;

type
  // ═══ 11.3 typed file 的定长记录（packed 保证与磁盘布局一致）
  TPersonRec = packed record
    Id: Integer;
    Age: Byte;
    Name: array[0..15] of AnsiChar;       // 定长字段才能算 seek 偏移
  end;

// ═══ 11.1 TextFile：最经典的 Pascal 文本 IO
procedure ShowTextFile;
var
  f: TextFile;
  line, first: string;
  cnt: Integer;
begin
  AssignFile(f, 'demo.txt');              // 关联文件名（还没打开）
  SetTextCodePage(f, 65001);              // 坑（实测）：不声明则按系统码页(936)读写，
                                          // UTF-8 中文读回后与字面量比较必不相等
  Rewrite(f);                             // 打开并清空（写模式）；Append 续写；Reset 只读
  WriteLn(f, '第一行');
  WriteLn(f, '第二行');
  WriteLn(f, '第三行');
  CloseFile(f);                           // CloseFile 必须配对（老资料写 Close——是同义词）

  Reset(f);                               // 只读打开（codepage 仍在：一次 AssignFile
                                          //  后的设置对 Rewrite/Reset 都生效）
  cnt := 0;
  first := '';
  while not Eof(f) do
  begin
    ReadLn(f, line);                      // ReadLn 读整行（自动处理 CRLF/LF）
    Inc(cnt);
    if cnt = 1 then first := line;
  end;
  CloseFile(f);
  Assert(cnt = 3);
  Assert(first = '第一行');
  WriteLn('  TextFile：写入 3 行读回 ', cnt, ' 行，首行="', first, '"');
end;

// ═══ 11.2 {$I-} + IOResult：异常普及前的老派检查（读老代码必备）
procedure ShowIOResult;
var
  f: TextFile;
  line: string;
  rc: Integer;
begin
  {$I-}                                   // 关闭 IO 异常：错误改由 IOResult 报告
  AssignFile(f, '不存在的文件.txt');
  Reset(f);
  rc := IOResult;                         // 取错误码（0=成功）；必须立即取，第二次调用清零
  {$I+}
  Assert(rc <> 0, '打开不存在的文件：IOResult 非零');
  WriteLn('  {$I-}+IOResult：打开不存在文件返回码=', rc, '（新版代码用 FileExists 预查 + 异常）');

  if rc = 0 then CloseFile(f);            // 演示代码：成功才关（实际 rc<>0）
end;

// ═══ 11.3 typed file：file of 记录——随机访问的"数据库雏形"
procedure ShowTypedFile;
var
  f: file of TPersonRec;
  p, q: TPersonRec;
begin
  FillChar(p, SizeOf(p), 0);
  // 注意：定长 AnsiChar 数组存中文要按字节管理，等值比较受码页标记影响（07 章坑），
  // 真实代码建议定长字段用 ASCII 或改用 string + 流式序列化
  p.Id := 1; p.Age := 30;
  StrPCopy(p.Name, 'ZhangSan');
  AssignFile(f, 'persons.dat');
  Rewrite(f);
  Write(f, p);                            // 写一条（一个记录大小）
  p.Id := 2; p.Age := 25;
  StrPCopy(p.Name, 'LiSi');
  Write(f, p);
  Seek(f, 0);                             // 定位到第 0 条（按记录数不是字节数！）
  Read(f, q);
  CloseFile(f);
  Assert((q.Id = 1) and (q.Age = 30));
  Assert(StrPas(q.Name) = 'ZhangSan');
  WriteLn('  typed file：Seek(0) 读回第一条：', StrPas(q.Name), ' id=', q.Id, '（定长 AnsiChar 用 ASCII）');
end;

// ═══ 11.4 TFileStream：二进制流（现代姿势，GUI 端也用它）
procedure ShowFileStream;
var
  fs: TFileStream;
  buf: array[0..3] of Integer;
  i: Integer;
begin
  for i := 0 to 3 do
    buf[i] := (i + 1) * 100;
  fs := TFileStream.Create('data.bin', fmCreate);   // fmCreate 建新/覆盖
  try
    fs.WriteBuffer(buf, SizeOf(buf));               // Write/Read 低层 + Buffer 异常版
  finally
    fs.Free;
  end;

  FillChar(buf, SizeOf(buf), 0);
  fs := TFileStream.Create('data.bin', fmOpenRead);
  try
    fs.ReadBuffer(buf, SizeOf(buf));
    Assert(buf[3] = 400);
    WriteLn('  TFileStream：写入读回 buf[3]=', buf[3], '，Size=', fs.Size, ' 字节');
  finally
    fs.Free;
  end;
end;

// ═══ 11.5 TIniFile：配置文件的标准答案（40 章记事本+ 用它记忆设置）
procedure ShowIniFile;
var
  ini: TIniFile;
  v: Integer;
  s: string;
begin
  // 坑（实测）：Windows 上 TIniFile 走 ANSI INI API——中文节/键/值按系统码页转码落盘
  // （GBK），读写两侧标记错位时键都查不到（文件里段落重复出现）。
  // 惯例：配置文件的节/键名一律 ASCII；值需要中文时改用 TStringList 存 UTF-8。
  ini := TIniFile.Create('settings.ini');
  try
    ini.WriteInteger('window', 'width', 800);
    ini.WriteString('window', 'title', 'MyProgram');
    ini.WriteBool('editor', 'wordwrap', True);
  finally
    ini.Free;                             // TIniFile 在 Free 时才落盘！忘了 Free = 配置丢失
  end;

  ini := TIniFile.Create('settings.ini');
  try
    v := ini.ReadInteger('window', 'width', 0);       // 第 4 参是缺省值：键不存在时返回
    s := ini.ReadString('window', 'title', '');
    Assert((v = 800) and (s = 'MyProgram'));
    Assert(ini.ReadInteger('window', 'missing', -1) = -1, '缺省值机制');
  finally
    ini.Free;
  end;
  WriteLn('  TIniFile：读回 width=', v, ' title="', s, '"（缺省值机制实测）');
end;

// ═══ 11.6 目录与文件操作速查
procedure ShowFileOps;
begin
  if not DirectoryExists('subdir') then
    CreateDir('subdir');
  Assert(DirectoryExists('subdir'));
  Assert(ExtractFileExt('data.bin') = '.bin');
  // 实测：Extract* 三件套在 Unix 上也认反斜杠（darwin 实测返回 demo.txt / G:\code\），
  // 所以这两条断言两个平台都过。但别把这条推广到别的函数——DirectorySeparator
  // 在 Unix 上是 '/'，PathSep 是 ':'（Windows 是 '\' 与 ';'），拼路径一律用 IncludeTrailingPathDelimiter。
  Assert(ExtractFileName('G:\code\demo.txt') = 'demo.txt');
  Assert(ExtractFilePath('G:\code\demo.txt') = 'G:\code\');
  Assert(FileExists('demo.txt'));
  WriteLn('  文件操作：Extract* 三件套 + Exists/CreateDir 就位');
end;

// ═══ 11.7 时间与随机：确定性输出的两条纪律
procedure ShowTimeRandom;
var
  fixed: TDateTime;
  d1, d2: Integer;
begin
  fixed := EncodeDate(2026, 9, 19);               // 固定时刻：不依赖系统时钟
  Assert(FormatDateTime('yyyy-mm-dd', fixed) = '2026-09-19');
  WriteLn('  FormatDateTime(EncodeDate) = ', FormatDateTime('yyyy-mm-dd dddd', fixed));

  RandSeed := 42;                                 // 固定种子 = 确定性序列（不调 Randomize！）
  d1 := Random(100);
  d2 := Random(100);
  Assert((d1 >= 0) and (d1 < 100));
  WriteLn('  RandSeed=42 的前两个随机数：', d1, ' ', d2, '（每次运行必相同——可测试性）');
  Write('   Randomize 才引入系统时钟熵；示例/测试一律固定种子', #10,
        '   Now/Date 只演示不打印——打印实时时间会让验证输出不可复现');
end;

begin
  WriteLn('═══ 11.1 TextFile');
  ShowTextFile;
  WriteLn('═══ 11.2 {$I-}+IOResult');
  ShowIOResult;
  WriteLn('═══ 11.3 typed file');
  ShowTypedFile;
  WriteLn('═══ 11.4 TFileStream');
  ShowFileStream;
  WriteLn('═══ 11.5 TIniFile');
  ShowIniFile;
  WriteLn('═══ 11.6 文件操作');
  ShowFileOps;
  WriteLn('═══ 11.7 时间与随机');
  ShowTimeRandom;
  WriteLn;
  WriteLn('==== 11 结束 ====');
end.
