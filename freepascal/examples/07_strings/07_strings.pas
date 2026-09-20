{$mode objfpc}{$codepage utf8}{$H+}
program strings_demo;
{ 07 · 字符串与编码（⭐特色章）：四代字符串、引用计数、码页标记、字面量重定型、
  Pos/Copy 语义差异、UTF-8 安全例程、Format、PChar。正文见 docs/07-strings.md。 }
uses
  {$IFDEF UNIX}cwstring,{$ENDIF}   // ★ Unix：必须是 uses 第一个——否则 WriteLn 中文字面量全变 ?（见 02 章 2.3）
  SysUtils;

type
  TShort = String[8];                      // ShortString：最长 8 字节，栈上定长

// ═══ 7.1 四代字符串：一个程序看全
procedure ShowStringKinds;
var
  sh: TShort;
  a: string;                               // {$H+} 下 = AnsiString（指针，引用计数，带码页标记）
  u8: UTF8String;                          // 也是 AnsiString，标记 cp=65001
  w: UnicodeString;                        // UTF-16，Windows API 的世界
begin
  sh := 'ShortStr 截断到 8 字节';
  Assert(Length(sh) = 8, 'ShortString 超长静默截断（长度字节在 [0]）');
  a := 'AnsiString';
  u8 := 'UTF8String 内容一样，标记不同';
  w := 'UnicodeString';
  WriteLn('SizeOf: ShortString=', SizeOf(sh), ' string=', SizeOf(a),
    ' UTF8String=', SizeOf(u8), ' UnicodeString=', SizeOf(w));
  Assert(SizeOf(a) = 8, 'AnsiString/UnicodeString 变量本身只是 8 字节指针');
  WriteLn('Length: a=', Length(a), ' w=', Length(w));
end;

// ═══ 7.2 AnsiString 引用计数：赋值共享，写时脱离
procedure ShowRefcount;
var
  a, b: string;
begin
  a := 'shared string ';
  a := a + a;                              // 修改变量触发重新分配（此时独占）
  b := a;                                  // 只读共享：引用计数 +1
  Assert(Length(b) = Length(a));
  b := b + 'x';                            // 写 b：脱离共享（COW）
  Assert(Length(a) = 28, 'shared string 14 字符翻倍 28');
  Assert(Length(b) = 29, '修改副本不影响本体——写时才拷贝');
  WriteLn('引用计数：a=', Length(a), ' b=', Length(b));
end;

// ═══ 7.3 字面量重定型（本教程最重要的一条实测）
function Which(const s: string): string; overload;
begin Result := 'AnsiString'; end;
function Which(const s: UnicodeString): string; overload;
begin Result := 'UnicodeString'; end;

procedure ShowLiteralTyping;
var
  a: string;
begin
  a := '中文';
  WriteLn('s := ''中文'' 后：绑定 ', Which(a), '，Length=', Length(a), '（按字节=6）');
  WriteLn('直接传字面量：绑定 ', Which('中文'), '，Length(''中文'')=', Length('中文'),
    '（按字符=2）');
  Assert(Which(a) = 'AnsiString');
  Assert(Which('中文') = 'UnicodeString', 'UTF-8 标记的字面量在无类型上下文按 UnicodeString');
  Assert(Length(a) = 6);
  Assert(Length('中文') = 2);
  WriteLn('StringCodePage(a)=', StringCodePage(a), '（65001：赋值保留字面量的码页标记）');
end;

// ═══ 7.4 同一字符串三种语义：Length 字节 / Pos 字符 / Copy 字节
procedure ShowPosCopyMismatch;
var
  a: string;
begin
  a := '中文';
  WriteLn('Pos(''文'', a)=', Pos('文', a), '  Copy(a,4,3)=''', Copy(a, 4, 3),
    '''  Length=', Length(a));
  Assert(Pos('文', a) = 2, 'Pos 对 UTF-8 标记串按字符返回位置（AnsiStrings 单元特例）');
  Assert(Copy(a, 4, 3) = '文', 'Copy 仍按字节切——两者语义不一致！');
  Assert(Length(a) = 6, 'Length 按字节');
end;

// ═══ 7.5 标记比字节重要：错误标记 = 系统性乱码
procedure ShowCodepageMarking;
var
  a: string;
  raw: RawByteString;                      // RawByteString：无码页语义的"字节袋"
  w: UnicodeString;
begin
  a := '中文';
  Assert(UnicodeString(a) = '中文', '标记正确（65001）→ 转 UTF-16 结果正确');

  raw := a;
  SetCodePage(raw, 936, False);            // 只改标记不转字节：伪造"GBK 标记的 UTF-8 字节"
  w := raw;                                // RTL 按 GBK 解码 UTF-8 字节 → 乱码
  Assert(Length(w) = 3, '6 个 UTF-8 字节被按 GBK 解成 3 个乱码字符');
  Assert(w <> UnicodeString(a), '字节相同、标记不同，解码结果天差地别');
  WriteLn('标记错误演示：6 字节按 GBK 解码 → ', Length(w), ' 个乱码字符');

  SetCodePage(raw, 65001, False);          // 改回正确标记，字节一个没动
  Assert(string(raw) = a, '改回标记后内容"复原"——错的从来不是字节，是标记');
end;

// ═══ 7.6 UTF-8 安全的"按字符"操作：手写（RTL 不自带）
function CountUtf8Chars(const s: UTF8String): Integer;
var
  i: Integer;
begin
  Result := 0;
  i := 1;
  while i <= Length(s) do
  begin
    if Byte(s[i]) and $C0 <> $80 then      // 非续字节（10xxxxxx）就是一个新字符的起点
      Inc(Result);
    Inc(i);
  end;
end;

procedure ShowUtf8Helpers;
var
  u8: UTF8String;
begin
  u8 := 'a中文b';
  Assert(Length(u8) = 8, '字节：1+3+3+1');
  Assert(CountUtf8Chars(u8) = 4, '字符：a/中/文/b');
  WriteLn('UTF-8：Length=', Length(u8), ' 字节，手写 CountUtf8Chars=', CountUtf8Chars(u8), ' 字符');
  // Lazarus 的 LCL 提供 UTF8Length/UTF8Copy 全家（16 章起直接用）；
  // 纯 FPC 控制台程序要么手写（如上），要么转 UnicodeString 处理再转回来
  Assert(Length(UnicodeString(u8)) = 4, '经 UnicodeString 中转按字符计数');
end;

// ═══ 7.7 Format：array of const 的最大受益者
procedure ShowFormat;
var
  n: Integer;
begin
  WriteLn(Format('%s 得了 %d 分（%.1f%%）', ['张三', 95, 95.0]));
  Assert(Format('%d', [42]) = '42');
  Assert(Format('%5.2f', [3.14159]) = ' 3.14', '宽度 5 含小数点共 5 位，右对齐');
  Assert(Format('%x', [255]) = 'FF', '%x 十六进制大写');
  Assert(Format('[%10s]', ['abc']) = '[       abc]', '%10s 右对齐补空格');
  Assert(TryStrToInt('42', n) and (n = 42), 'TryStrToInt：不抛异常版');
end;

// ═══ 7.8 PChar：与 C 世界的握手
procedure ShowPChar;
var
  a: string;
  p: PChar;
  n: Integer;
begin
  a := 'Hello';
  p := PChar(a);                           // string → PChar：零拷贝（指向内部缓冲）
  Assert(p[0] = 'H');
  Assert(StrLen(p) = 5, 'StrLen 按 #0 找结尾（C 语义）');
  n := StrLen(p);
  Assert(n = 5);

  a := a + ' World';                       // 修改 a 可能 realloc——旧 PChar 已失效！
  WriteLn('PChar：StrLen=5，string 变动后旧 PChar 必须重新获取（悬垂风险）');
end;

begin
  WriteLn('═══ 7.1 四代字符串');
  ShowStringKinds;
  WriteLn('═══ 7.2 引用计数');
  ShowRefcount;
  WriteLn('═══ 7.3 字面量重定型');
  ShowLiteralTyping;
  WriteLn('═══ 7.4 Pos/Copy 语义差异');
  ShowPosCopyMismatch;
  WriteLn('═══ 7.5 码页标记');
  ShowCodepageMarking;
  WriteLn('═══ 7.6 UTF-8 安全例程');
  ShowUtf8Helpers;
  WriteLn('═══ 7.7 Format');
  ShowFormat;
  WriteLn('═══ 7.8 PChar');
  ShowPChar;
  WriteLn;
  WriteLn('==== 07 结束 ====');
end.
