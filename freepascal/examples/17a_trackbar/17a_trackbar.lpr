{$mode objfpc}{$codepage utf8}{$H+}
program trackbar_demo;
{ 17a · TTrackBar 滑杆：Min/Max/Position、刻度三件套（TickStyle/TickMarks/Frequency）、
  键盘步进（LineSize=方向键 / PageSize=翻页键）、选择区间（SelStart/SelEnd/
  ShowSelRange）、OnChange 触发面（拖动/键盘/程序赋值一视同仁——和 TEdit 家族
  的"程序赋值不触发"正相反，是实测第一坑）。
  正文见 docs/17-value-controls.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls, Graphics,
  Classes, SysUtils;

type
  TTrackForm = class(TForm)
    TrRed, TrGreen, TrBlue: TTrackBar;
    Preview: TPanel;
    ValueLbl: TLabel;
    procedure SliderChange(Sender: TObject);
  public
    ChangeCount: Integer;   // 统计 OnChange 触发次数（selftest 用）
    constructor Create(AOwner: TComponent); override;
  end;

constructor TTrackForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '17a · TrackBar 调色台';
  Width := 520; Height := 300;

  // ── 三条滑杆：Min/Max 定值域，Frequency 定刻度间隔 ──
  TrRed := TTrackBar.Create(Self);
  TrRed.Parent := Self;
  TrRed.SetBounds(16, 12, 460, 40);
  TrRed.Min := 0; TrRed.Max := 255;
  TrRed.Position := 200;
  TrRed.Frequency := 51;              // 每 51 一条刻度（0/51/102/…/255）
  TrRed.LineSize := 1;                // ←→ 方向键步长
  TrRed.PageSize := 16;               // PgUp/PgDn 步长
  TrRed.TickMarks := tmBottomRight;   // 刻度在下侧（tmTopLeft 反之，tmBoth 两侧）
  TrRed.TickStyle := tsAuto;          // 自动按 Frequency 画（tsNone 不画；tsManual 手工）
  TrRed.OnChange := @SliderChange;

  TrGreen := TTrackBar.Create(Self);
  TrGreen.Parent := Self;
  TrGreen.SetBounds(16, 56, 460, 40);
  TrGreen.Min := 0; TrGreen.Max := 255;
  TrGreen.Position := 128;
  TrGreen.Frequency := 51;
  TrGreen.OnChange := @SliderChange;

  TrBlue := TTrackBar.Create(Self);
  TrBlue.Parent := Self;
  TrBlue.SetBounds(16, 100, 460, 40);
  TrBlue.Min := 0; TrBlue.Max := 255;
  TrBlue.Position := 64;
  TrBlue.Frequency := 51;
  TrBlue.OnChange := @SliderChange;

  // ── 预览板 + 数值标签 ──
  Preview := TPanel.Create(Self);
  Preview.Parent := Self;
  Preview.SetBounds(16, 148, 200, 120);
  Preview.Caption := '';
  Preview.Color := RGBToColor(TrRed.Position, TrGreen.Position, TrBlue.Position);

  ValueLbl := TLabel.Create(Self);
  ValueLbl.Parent := Self;
  ValueLbl.SetBounds(232, 148, 260, 120);
  ValueLbl.Caption := '';
  SliderChange(nil);
end;

procedure TTrackForm.SliderChange(Sender: TObject);
begin
  Inc(ChangeCount);
  Preview.Color := RGBToColor(TrRed.Position, TrGreen.Position, TrBlue.Position);
  ValueLbl.Caption := Format('R=%d  G=%d  B=%d%s#%02x%02x%02x',
    [TrRed.Position, TrGreen.Position, TrBlue.Position, #10,
     TrRed.Position, TrGreen.Position, TrBlue.Position]);
end;

procedure RunSelfTest;
var
  f: TTrackForm;
  Log: TextFile;
begin
  Application.Initialize;
  f := TTrackForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 初值：构造器里 Position 赋值发生在 OnChange 挂接之前——所以不触发（顺序敏感，正文有讲）
    if (f.TrRed.Position <> 200) or (f.TrGreen.Position <> 128) or (f.TrBlue.Position <> 64) then
      raise Exception.Create('滑杆初值异常');
    if f.ChangeCount <> 1 then       // 只有构造器末尾那次直呼 SliderChange
      raise Exception.Create('构造期 ChangeCount 应为 1（挂接前赋值不触发）');
    WriteLn(Log, '初值 OK；构造期 ChangeCount=', f.ChangeCount);

    // 2) 程序赋值触发 OnChange（与 TEdit 相反的实测行为）
    f.ChangeCount := 0;
    f.TrRed.Position := 100;
    if (f.TrRed.Position <> 100) or (f.ChangeCount < 1) then
      raise Exception.Create('程序赋值应触发 OnChange');
    f.ChangeCount := 0;

    // 3) 越界赋值被钳制到边界（实测：setter 内部钳）
    f.TrRed.Position := 999;
    if f.TrRed.Position <> 255 then
      raise Exception.Create('越界赋值应钳制到 Max，实测=' + IntToStr(f.TrRed.Position));
    f.TrRed.Position := -5;
    if f.TrRed.Position <> 0 then
      raise Exception.Create('负值赋值应钳制到 Min，实测=' + IntToStr(f.TrRed.Position));

    // 4) 值域读写回环 + 联动钳制（实测：改 Min/Max 会立即重钳 Position，不是等下次赋值）
    f.TrRed.Min := 10;               // Position 0 < 10 → 立刻钳到 10
    if f.TrRed.Position <> 10 then
      raise Exception.Create('抬高 Min 应立即钳 Position，实测=' + IntToStr(f.TrRed.Position));
    f.TrRed.Max := 20;
    if (f.TrRed.Min <> 10) or (f.TrRed.Max <> 20) then
      raise Exception.Create('Min/Max 回环异常');
    if f.TrRed.Position <> 10 then   // 10 在 [10,20] 内，原样保留
      raise Exception.Create('区间内 Position 不应变动');
    f.TrRed.Min := 0; f.TrRed.Max := 255;

    // 5) 键盘步进与刻度三件套回环
    if (f.TrRed.LineSize <> 1) or (f.TrRed.PageSize <> 16) or (f.TrRed.Frequency <> 51) then
      raise Exception.Create('LineSize/PageSize/Frequency 回环异常');
    if (f.TrRed.TickStyle <> tsAuto) or (f.TrRed.TickMarks <> tmBottomRight) then
      raise Exception.Create('TickStyle/TickMarks 回环异常');
    f.TrRed.TickStyle := tsManual;
    f.TrRed.TickMarks := tmBoth;
    if (f.TrRed.TickStyle <> tsManual) or (f.TrRed.TickMarks <> tmBoth) then
      raise Exception.Create('刻度样式二段回环异常');
    f.TrRed.TickStyle := tsAuto; f.TrRed.TickMarks := tmBottomRight;

    // 6) 选择区间：滑道上一段高亮（配 TrackBar 的"有效范围"语义）
    f.TrRed.SelStart := 50; f.TrRed.SelEnd := 200;
    if (f.TrRed.SelStart <> 50) or (f.TrRed.SelEnd <> 200) then
      raise Exception.Create('SelStart/SelEnd 回环异常');
    if not f.TrRed.ShowSelRange then   // 默认 True？
      WriteLn(Log, '注意：ShowSelRange 默认=', f.TrRed.ShowSelRange);
    f.TrRed.ShowSelRange := False;
    if f.TrRed.ShowSelRange then
      raise Exception.Create('ShowSelRange 关闭回环异常');
    f.TrRed.ShowSelRange := True;

    // 7) 方向：横向↔纵向
    f.TrRed.Orientation := trVertical;
    if f.TrRed.Orientation <> trVertical then
      raise Exception.Create('Orientation 回环异常');
    f.TrRed.Orientation := trHorizontal;

    WriteLn(Log, 'RGB=#', Format('%02x%02x%02x',
      [f.TrRed.Position, f.TrGreen.Position, f.TrBlue.Position]));
    WriteLn(Log, '==== 17a selftest OK ====');
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
      // 坑（实测）：GUI 程序未捕获异常会弹 LCL 消息框——无头验证环境直接挂死
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
  with TTrackForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
