{$mode objfpc}{$codepage utf8}{$H+}
program custom_controls_demo;
{ 34 · 自定义控件与组件开发：TValueBar（TCustomControl：published 属性/自绘/
  行为）与 TBadgeLabel（TGraphicControl 无句柄轻量）两个自制控件上窗体；
  讲注册进 IDE 面板的 Register 流程（命令行不需要，正文展开）。
  正文见 docs/34-custom-controls.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Graphics,
  uvaluebar { TValueBar, TBadgeLabel },
  Classes, SysUtils;

type
  TCtrlForm = class(TForm)
    Bar: TValueBar;
    Badge: TBadgeLabel;
    ResetBtn: TButton;
    Info: TLabel;
  public
    constructor Create(AOwner: TComponent); override;
  end;

constructor TCtrlForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '34 · 自定义控件';
  Width := 480; Height := 240;

  Bar := TValueBar.Create(Self);       // 自定义控件用起来与原生无差别
  Bar.Parent := Self;
  Bar.SetBounds(16, 16, 300, 24);
  Bar.Max := 100;
  Bar.BarColor := clTeal;
  Bar.Value := 30;

  Badge := TBadgeLabel.Create(Self);
  Badge.Parent := Self;
  Badge.SetBounds(330, 16, 100, 24);
  Badge.BgColor := clYellow;

  ResetBtn := TButton.Create(Self);
  ResetBtn.Parent := Self;
  ResetBtn.SetBounds(16, 56, 100, 30);
  ResetBtn.Caption := '清零';

  Info := TLabel.Create(Self);
  Info.Parent := Self;
  Info.SetBounds(16, 100, 440, 100);
  Info.Caption := '点蓝条：+10（控件自己的行为）；TGraphicLabel 徽章不抢焦点';
end;

procedure RunSelfTest;
var
  f: TCtrlForm;
  Log: TextFile;
begin
  Application.Initialize;
  f := TCtrlForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) published 属性回环 + 钳制
    if (f.Bar.Value <> 30) or (f.Bar.Max <> 100) then
      raise Exception.Create('初值回读异常');
    f.Bar.Value := 500;
    if f.Bar.Value <> 100 then
      raise Exception.Create('Value 越界应钳到 Max');
    f.Bar.Max := 50;                   // 值域收紧——值要重钳
    if f.Bar.Value <> 50 then
      raise Exception.Create('Max 收紧后 Value 应重钳');
    f.Bar.BarColor := clRed;
    if f.Bar.BarColor <> clRed then
      raise Exception.Create('BarColor 回环异常');

    // 2) 行为：Click +10（覆写的 Click——含继承链）
    f.Bar.Value := 0;
    f.Bar.Click;
    f.Bar.Click;
    if f.Bar.Value <> 20 then
      raise Exception.Create('点两下应 +20');

    // 3) 祖先 published 放行
    f.Bar.Hint := '测试提示';
    if f.Bar.Hint <> '测试提示' then
      raise Exception.Create('放行的祖先属性应可用');

    // 4) 两系身份：句柄系 vs 无句柄系
    //    （教学点实证：写 "Badge is TWinControl" 编译器直接拒绝——类不相关；
    //     写 "Badge.TabStop" 也拒绝——TGraphicControl 没这属性。编译期防错）
    if not (f.Badge is TGraphicControl) then
      raise Exception.Create('Badge 应 is TGraphicControl');
    if not (f.Bar is TWinControl) then
      raise Exception.Create('Bar 应 is TWinControl（句柄系可持焦点）');

    // 5) default 指令语义：新实例初值走 default（不落流）
    with TValueBar.Create(f) do
    begin
      Parent := f;
      if (Value <> 0) or (Max <> 100) then
        raise Exception.Create('default 初值异常');
      Free;
    end;

    WriteLn(Log, 'Bar.Value=', f.Bar.Value, ' Max=', f.Bar.Max);
    WriteLn(Log, '==== 34 selftest OK ====');
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
  with TCtrlForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
