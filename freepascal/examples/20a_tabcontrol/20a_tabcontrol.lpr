{$mode objfpc}{$codepage utf8}{$H+}
program tabcontrol_demo;
{ 20a · TTabControl：只有一排标签头、一块共享内容区——"同一份数据换视图"的控件。
  Tabs(TStrings)/TabIndex/OnChange 三件套；Options 里的 nboShowCloseButtons。
  实测：程序改 TabIndex 默认【不】触发 OnChange（与 Calendar 同类）——要它触发
  得加 Options 的 nboDoChangeOnSetIndex（LCL 专门为这事留的开关）。
  本例：一段文本的 文本/十六进制/统计 三视图。正文见 docs/20-tab-pages.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls, Graphics,
  Classes, SysUtils, LazUTF8;

type
  TTabForm = class(TForm)
    Tabs: TTabControl;
    View: TMemo;
    procedure TabsChange(Sender: TObject);
  public
    Data: string;
    ChangeCount: Integer;   // 计数器放 public（FPC published 区只收类类型字段）
    function RenderHex(const S: string): string;
    function RenderStat(const S: string): string;
    constructor Create(AOwner: TComponent); override;
  end;

constructor TTabForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '20a · TabControl 三视图';
  Width := 560; Height := 400;
  Data := 'LCL 你好 abc';

  Tabs := TTabControl.Create(Self);
  Tabs.Parent := Self;
  Tabs.Align := alTop;
  Tabs.Height := 32;
  Tabs.Tabs.Add('文本');
  Tabs.Tabs.Add('十六进制');
  Tabs.Tabs.Add('统计');
  Tabs.TabIndex := 0;
  Tabs.OnChange := @TabsChange;      // 顺序：初值先定，事件后挂——构造期不触发

  View := TMemo.Create(Self);
  View.Parent := Self;
  View.Align := alClient;
  View.ReadOnly := True;
  TabsChange(nil);
end;

function TTabForm.RenderHex(const S: string): string;
var
  I: Integer;
begin
  // 逐字节十六进制：Length(S) 是字节数（{$H+} 下 string=AnsiString），
  // "你"的 UTF-8 三字节会原样露出——字节视图的意义就在这
  Result := '';
  for I := 1 to Length(S) do
    Result := Result + IntToHex(Ord(S[I]), 2) + ' ';
end;

function TTabForm.RenderStat(const S: string): string;
begin
  Result := Format('字节数 %d%s字符数（UTF-8 解码）%d', [
    Length(S), #10, UTF8Length(S)]);
end;

procedure TTabForm.TabsChange(Sender: TObject);
begin
  Inc(ChangeCount);
  case Tabs.TabIndex of
    0: View.Text := Data;
    1: View.Text := RenderHex(Data);
    2: View.Text := RenderStat(Data);
  end;
end;

procedure RunSelfTest;
var
  f: TTabForm;
  Log: TextFile;
begin
  Application.Initialize;
  f := TTabForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) Tabs 容器操作（TStrings 全套可用）
    if f.Tabs.Tabs.Count <> 3 then
      raise Exception.Create('Tabs 数量异常');
    if f.Tabs.Tabs.IndexOf('统计') <> 2 then
      raise Exception.Create('IndexOf 定位异常');
    f.Tabs.Tabs.Delete(2);                       // 删"统计"
    if f.Tabs.Tabs.Count <> 2 then
      raise Exception.Create('Delete 后数量异常');
    f.Tabs.Tabs.Add('统计');                     // 加回末尾
    if f.Tabs.Tabs[2] <> '统计' then
      raise Exception.Create('Tabs[] 回读异常');

    // 2) 程序改 TabIndex 默认不触发 OnChange（实测；视图不换——得手动刷或开选项）
    f.ChangeCount := 0;
    f.Tabs.TabIndex := 1;
    if (f.Tabs.TabIndex <> 1) or (f.ChangeCount <> 0) then
      raise Exception.Create('默认程序改 TabIndex 不应触发 OnChange');
    if Pos('4C 43 4C', f.View.Text) > 0 then   // 视图还停在"文本"
      raise Exception.Create('视图不应自己换');
    f.TabsChange(nil);                          // 手动刷（或用下面的选项）
    if Pos('4C 43 4C', f.View.Text) <= 0 then  // "LCL" 的 ASCII
      raise Exception.Create('手动刷新后应显示十六进制');

    // 2b) nboDoChangeOnSetIndex：开了它，程序赋值才走 OnChange
    f.Tabs.Options := f.Tabs.Options + [nboDoChangeOnSetIndex];
    f.ChangeCount := 0;
    f.Tabs.TabIndex := 2;
    if f.ChangeCount < 1 then
      raise Exception.Create('nboDoChangeOnSetIndex 开启后应触发');
    if Pos('字节数 14', f.View.Text) <= 0 then
      raise Exception.Create('触发后应为统计视图');
    f.Tabs.Options := f.Tabs.Options - [nboDoChangeOnSetIndex];

    // 3) 字节/字符双坐标（{$H+} 的 AnsiString 语义 + UTF8Length）
    //    'LCL 你好 abc' = 3+1+3+1+3 = 11 字节？不——空格1 + abc3 + 空格1 = LCL(3)+sp(1)+你(3)+好(3)+sp(1)+abc(3) = 14 字节
    if Length(f.Data) <> 14 then
      raise Exception.Create('字节数应 14（含中文各 3 字节），实测=' + IntToStr(Length(f.Data)));
    if UTF8Length(f.Data) <> 10 then
      raise Exception.Create('字符数应 10，实测=' + IntToStr(UTF8Length(f.Data)));
    if Pos('字节数 14', f.View.Text) <= 0 then
      raise Exception.Create('统计视图字节数异常');

    // 4) 文本视图回到原始串
    f.Tabs.TabIndex := 0;
    f.TabsChange(nil);                          // 选项已关，手动刷回文本视图
    if f.View.Text <> f.Data then
      raise Exception.Create('文本视图应原样');

    // 5) Options：nboShowCloseButtons 可开（UI 行为，属性回环即可）
    f.Tabs.Options := f.Tabs.Options + [nboShowCloseButtons];
    if not (nboShowCloseButtons in f.Tabs.Options) then
      raise Exception.Create('Options 回环异常');
    f.Tabs.Options := f.Tabs.Options - [nboShowCloseButtons];

    WriteLn(Log, 'TabIndex=', f.Tabs.TabIndex, ' 视图=', f.View.Lines[0]);
    WriteLn(Log, '==== 20a selftest OK ====');
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
  with TTabForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
