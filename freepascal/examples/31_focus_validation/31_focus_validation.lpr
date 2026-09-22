{$mode objfpc}{$codepage utf8}{$H+}
program focus_validation_demo;
{ 31 · 焦点、键盘与输入验证：TabOrder/TabStop、ActiveControl/SetFocus、
  SelectNext 遍历、键盘三事件链（KeyDown→KeyPress→KeyUp，var Key=0 吞键）、
  KeyPreview 窗体先吃、OnEditingDone 时机、验证器纯函数 + OnExit 即时校验。
  正文见 docs/31-focus-validation.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Graphics,
  Classes, SysUtils;

type
  TFocusForm = class(TForm)
    EdName, EdAge, EdMail: TEdit;
    ErrLbl: TLabel;
    KeyLog: TMemo;
    procedure AnyKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure AnyKeyPress(Sender: TObject; var Key: Char);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure EdAgeExit(Sender: TObject);
    procedure EdAgeEditingDone(Sender: TObject);
  public
    DownCount, PressCount, FormDownCount: Integer;
    Swallowed: Boolean;             // "吞键后 Keypress 不来"的证据
    AgeExitChecked, AgeEditDone: Boolean;
    constructor Create(AOwner: TComponent); override;
  end;

{ 验证器：纯函数（可无头测试——25 章一以贯之的策略） }
function ValidateAge(const S: string): string;   // '' = 合法，否则错误文案
var
  V: Integer;
begin
  Result := '';
  if not TryStrToInt(S, V) then Exit('年龄必须是数字');
  if (V < 0) or (V > 150) then Exit('年龄要在 0..150');
end;

function ValidateMail(const S: string): string;
begin
  Result := '';
  if Pos('@', S) < 2 then Exit('邮箱要含 @ 且前面有名字');
  if Pos('.', Copy(S, Pos('@', S), MaxInt)) < 2 then Exit('邮箱域名要有点');
end;

constructor TFocusForm.Create(AOwner: TComponent);
var
  I: Integer;
begin
  inherited CreateNew(AOwner);
  Caption := '31 · 焦点与验证';
  Width := 520; Height := 420;
  KeyPreview := True;               // 窗体先吃键盘（快捷键拦截的经典开关）
  OnKeyDown := @FormKeyDown;

  EdName := TEdit.Create(Self);
  EdName.Parent := Self; EdName.SetBounds(80, 12, 200, 26);
  EdName.TabOrder := 0;

  EdAge := TEdit.Create(Self);
  EdAge.Parent := Self; EdAge.SetBounds(80, 48, 200, 26);
  EdAge.TabOrder := 1;
  EdAge.OnExit := @EdAgeExit;               // 失焦即校验
  EdAge.OnEditingDone := @EdAgeEditingDone; // 回车/失焦都算"完成编辑"

  EdMail := TEdit.Create(Self);
  EdMail.Parent := Self; EdMail.SetBounds(80, 84, 200, 26);
  EdMail.TabOrder := 2;

  // 三个编辑框共用键盘处理器（ Sender 分流——事件本质是方法指针的受益）
  for I := 0 to ControlCount - 1 do
    if Controls[I] is TEdit then
    begin
      TEdit(Controls[I]).OnKeyDown := @AnyKeyDown;
      TEdit(Controls[I]).OnKeyPress := @AnyKeyPress;
    end;

  ErrLbl := TLabel.Create(Self);
  ErrLbl.Parent := Self; ErrLbl.SetBounds(16, 120, 480, 20);

  KeyLog := TMemo.Create(Self);
  KeyLog.Parent := Self; KeyLog.Align := alBottom; KeyLog.Height := 200;
  KeyLog.ReadOnly := True;
end;

procedure TFocusForm.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // KeyPreview=True：这里先于编辑框收到——快捷键总机
  Inc(FormDownCount);
  if (Key = 27) and (Shift = []) then    // Esc：清空错误提示（示例快捷键）
  begin
    ErrLbl.Caption := '';
    Key := 0;                            // 吞掉——编辑框不再收到
  end;
end;

procedure TFocusForm.AnyKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  Inc(DownCount);
end;

procedure TFocusForm.AnyKeyPress(Sender: TObject; var Key: Char);
begin
  Inc(PressCount);
  // 只许数字进年龄框（Sender 分流：年龄框吞非数字键）
  if (Sender = EdAge) and not (Key in ['0'..'9', #8]) then
  begin
    Key := #0;                   // 吞键：KeyPress 后编辑框忽略该字符
    Swallowed := True;
  end;
end;

procedure TFocusForm.EdAgeExit(Sender: TObject);
var
  Err: string;
begin
  AgeExitChecked := True;
  Err := ValidateAge(EdAge.Text);
  if Err <> '' then
  begin
    ErrLbl.Caption := Err;
    ErrLbl.Font.Color := clRed;
  end
  else
  begin
    ErrLbl.Caption := '';
    ErrLbl.Font.Color := clDefault;
  end;
end;

procedure TFocusForm.EdAgeEditingDone(Sender: TObject);
begin
  AgeEditDone := True;           // 实测：回车与失焦都触发
end;

procedure RunSelfTest;
var
  f: TFocusForm;
  Log: TextFile;
  K: Word;
  C: Char;
  Sh: TShiftState;          // var 参数不能传常量（含空集 []）——用变量
begin
  Application.Initialize;
  f := TFocusForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 验证器纯函数（表驱动——对/错样例各三类）
    if (ValidateAge('30') <> '') or (ValidateAge('0') <> '') then
      raise Exception.Create('合法年龄应通过');
    if (ValidateAge('abc') <> '年龄必须是数字') or (ValidateAge('200') <> '年龄要在 0..150') then
      raise Exception.Create('非法年龄应报文案');
    if (ValidateMail('a@b.c') <> '') or (ValidateMail('x@y') <> '邮箱域名要有点')
      or (ValidateMail('@b.c') <> '邮箱要含 @ 且前面有名字') then
      raise Exception.Create('邮箱验证器异常');

    // 2) Tab 体系属性
    if (f.EdName.TabOrder <> 0) or (f.EdAge.TabOrder <> 1) then
      raise Exception.Create('TabOrder 回环异常');
    f.EdMail.TabStop := False;
    if f.EdMail.TabStop then raise Exception.Create('TabStop 回环异常');
    f.EdMail.TabStop := True;

    // 3) ActiveControl：焦点归属（SetFocus 需要"活动窗体"，selftest 用属性版）
    f.ActiveControl := f.EdAge;
    if f.ActiveControl <> f.EdAge then
      raise Exception.Create('ActiveControl 指定异常');

    // 4) 键盘三事件链（直呼处理器模拟按键：KeyDown → KeyPress → …）
    K := 65; C := 'A';                       // 'A'
    Sh := [];
    f.FormKeyDown(nil, K, Sh);               // KeyPreview 总机先吃
    f.AnyKeyDown(f.EdName, K, Sh);
    f.AnyKeyPress(f.EdName, C);
    if (f.FormDownCount <> 1) or (f.DownCount <> 1) or (f.PressCount <> 1) then
      raise Exception.Create('键盘链计数异常');

    // 5) 吞键：年龄框输字母 → KeyPress 里 #0（编辑框忽略）且计数留痕
    f.Swallowed := False;
    C := 'x';                    // var Key: Char 也要变量（常量传 var 编译不过）
    f.AnyKeyPress(f.EdAge, C);
    if (not f.Swallowed) or (f.PressCount <> 2) then
      raise Exception.Create('吞键应留痕（Key=#0 语义）');

    // 6) Esc 快捷键走窗体（KeyPreview）
    K := 27; Sh := [];
    f.ErrLbl.Caption := '旧错误';
    f.FormKeyDown(nil, K, Sh);
    if f.ErrLbl.Caption <> '' then
      raise Exception.Create('Esc 应清提示（KeyPreview 先吃）');

    // 7) OnExit 校验联动（直呼=失焦的语义核）
    f.EdAge.Text := '200';
    f.EdAgeExit(nil);
    if f.ErrLbl.Caption <> '年龄要在 0..150' then
      raise Exception.Create('失焦校验应报错');
    f.EdAge.Text := '30';
    f.EdAgeExit(nil);
    if f.ErrLbl.Caption <> '' then
      raise Exception.Create('修正后应清错');

    // 8) OnEditingDone 直呼（回车/失焦都算完成——实测记录）
    f.EdAgeEditingDone(nil);
    if not f.AgeEditDone then
      raise Exception.Create('EditingDone 应置位');

    WriteLn(Log, 'Down=', f.DownCount, ' Press=', f.PressCount,
      ' FormDown=', f.FormDownCount, ' Swallowed=', f.Swallowed);
    WriteLn(Log, '==== 31 selftest OK ====');
  finally
    CloseFile(Log);
    f.Free;
  end;
end;

var
  ErrLog: TextFile;

begin
  if ParamStr(1) = '--selftest' then
  begin
    try
      RunSelfTest;
    except
      on E: Exception do
      begin
        AssignFile(ErrLog, 'selftest.log');
        if FileExists('selftest.log') then Append(ErrLog) else Rewrite(ErrLog);
        WriteLn(ErrLog, 'selftest 失败：', E.Message);
        CloseFile(ErrLog);
        Halt(1);
      end;
    end;
    Halt(0);
  end;
  Application.Initialize;
  with TFocusForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
