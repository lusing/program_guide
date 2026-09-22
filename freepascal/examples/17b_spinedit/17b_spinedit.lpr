{$mode objfpc}{$codepage utf8}{$H+}
program spinedit_demo;
{ 17b · TSpinEdit 与 TFloatSpinEdit（unit Spin）：整型/浮点数值输入框。
  要点：默认值域 0..100 的隐形钳制（忘改 MaxValue 输入被静默吞掉——实测第一坑）、
  赋值顺序（先定 Min/Max 再赋 Value）、DecimalPlaces 小数位、Increment 步长、
  OnChange 与键盘行为。正文见 docs/17-value-controls.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls, Spin, Graphics,
  Classes, SysUtils;

type
  TSpinForm = class(TForm)
    Count: TSpinEdit;         // 整型：件数
    Price: TFloatSpinEdit;    // 浮点：单价
    TotalLbl: TLabel;
    procedure ValueChange(Sender: TObject);
  public
    ChangeCount: Integer;
    constructor Create(AOwner: TComponent); override;
    function Total: Double;
  end;

constructor TSpinForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '17b · SpinEdit 预算计算器';
  Width := 460; Height := 240;

  with TLabel.Create(Self) do
  begin
    Parent := Self; SetBounds(16, 12, 300, 20);
    Caption := '件数（TSpinEdit，整型）';
  end;

  Count := TSpinEdit.Create(Self);
  Count.Parent := Self;
  Count.SetBounds(16, 36, 140, 28);
  // 坑：不设值域时默认 0..100——输入 999 退出编辑后被静默钳成 100
  Count.MinValue := 1; Count.MaxValue := 99;
  Count.Increment := 5;             // 上下箭头步长
  Count.Value := 10;                // 注意顺序：先 Min/Max 再 Value
  Count.OnChange := @ValueChange;

  with TLabel.Create(Self) do
  begin
    Parent := Self; SetBounds(16, 76, 300, 20);
    Caption := '单价（TFloatSpinEdit，浮点）';
  end;

  Price := TFloatSpinEdit.Create(Self);
  Price.Parent := Self;
  Price.SetBounds(16, 100, 160, 28);
  Price.MinValue := 0;
  Price.MaxValue := 10000;
  Price.Increment := 0.5;           // 浮点步长也支持
  Price.DecimalPlaces := 2;         // 保留 2 位小数（显示与取值都受影响）
  Price.Value := 12.5;
  Price.OnChange := @ValueChange;

  TotalLbl := TLabel.Create(Self);
  TotalLbl.Parent := Self;
  TotalLbl.SetBounds(16, 148, 420, 40);
  TotalLbl.Font.Size := 14;
  ValueChange(nil);
end;

function TSpinForm.Total: Double;
begin
  Result := Count.Value * Price.Value;
end;

procedure TSpinForm.ValueChange(Sender: TObject);
begin
  Inc(ChangeCount);
  TotalLbl.Caption := Format('合计：%d 件 × %.2f 元 = %.2f 元',
    [Count.Value, Price.Value, Total]);
end;

procedure RunSelfTest;
var
  f: TSpinForm;
  Log: TextFile;
begin
  Application.Initialize;
  f := TSpinForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 整型初值与计算
    if (f.Count.Value <> 10) or (f.Price.Value <> 12.5) then
      raise Exception.Create('Spin 初值异常');
    if Abs(f.Total - 125.0) > 0.001 then
      raise Exception.Create('合计计算异常');

    // 2) 越界钳制（TSpinEdit 与 TFloatSpinEdit 都钳）
    f.Count.Value := 999;
    if f.Count.Value <> 99 then
      raise Exception.Create('整型越界应钳到 MaxValue=99，实测=' + IntToStr(f.Count.Value));
    f.Count.Value := 0;
    if f.Count.Value <> 1 then
      raise Exception.Create('低于 MinValue 应钳到 1，实测=' + IntToStr(f.Count.Value));
    f.Price.Value := 99999;
    if f.Price.Value <> 10000 then
      raise Exception.Create('浮点越界应钳到 10000');

    // 3) 程序赋值触发 OnChange（Spin 家族与 TrackBar 同、与 TEdit 异）
    f.ChangeCount := 0;
    f.Count.Value := 50;
    if f.ChangeCount < 1 then
      raise Exception.Create('SpinEdit 程序赋值应触发 OnChange');
    f.ChangeCount := 0;

    // 4) DecimalPlaces：显示与取值精度
    f.Price.DecimalPlaces := 2;
    f.Price.Value := 3.14159;
    if Abs(f.Price.Value - 3.14) > 0.005 then
      raise Exception.Create('DecimalPlaces=2 应取两位，实测=' + FloatToStr(f.Price.Value));

    // 5) Increment 回环（箭头步长，键盘行为不影响程序赋值）
    if (f.Count.Increment <> 5) or (Abs(f.Price.Increment - 0.5) > 0.001) then
      raise Exception.Create('Increment 回环异常');

    // 6) 默认值域陷阱实证：默认 Min=0/Max=0——0 表示"不限"！
    //    忘了设 MaxValue 的 SpinEdit 会放行任意大的输入（比被钳更危险）
    with TSpinEdit.Create(f) do
    begin
      Parent := f;
      if (MinValue <> 0) or (MaxValue <> 0) then
        raise Exception.Create(Format('默认值域实测 Min=%d Max=%d',
          [MinValue, MaxValue]));
      Value := 500;
      if Value <> 500 then
        raise Exception.Create('默认(0/0)=不限，500 不应被钳，实测=' + IntToStr(Value));
      Free;
    end;

    WriteLn(Log, 'Total=', f.Total:0:2, ' Count=', f.Count.Value,
      ' Price=', f.Price.Value:0:2);
    WriteLn(Log, '==== 17b selftest OK ====');
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
  with TSpinForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
