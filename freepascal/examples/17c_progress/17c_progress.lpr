{$mode objfpc}{$codepage utf8}{$H+}
program progress_demo;
{ 17c · TProgressBar 进度条：Min/Max/Position、Step+StepBy 步进、Smooth 平滑、
  Style=pbstMarquee 跑马灯（"不知道总量"的不确定进度）、BarShowText 百分比文字。
  定时驱动用 TTimer；selftest 只测数据语义不依赖消息循环。正文见 docs/17-value-controls.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls, Graphics,
  Classes, SysUtils;

type
  TProgressForm = class(TForm)
    Bar: TProgressBar;
    StartBtn: TButton;
    StatusLbl: TLabel;
    Tick: TTimer;
    procedure StartClick(Sender: TObject);
    procedure TickTimer(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

constructor TProgressForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '17c · ProgressBar 安装模拟';
  Width := 480; Height := 200;

  StatusLbl := TLabel.Create(Self);
  StatusLbl.Parent := Self;
  StatusLbl.SetBounds(16, 12, 440, 20);
  StatusLbl.Caption := '点「安装」开始';

  Bar := TProgressBar.Create(Self);
  Bar.Parent := Self;
  Bar.SetBounds(16, 44, 440, 24);
  Bar.Min := 0; Bar.Max := 100;
  Bar.Step := 4;                 // StepBy 每跳的步长（Step 属性配 StepIt/StepBy）
  Bar.Smooth := True;            // 平滑条（默认分块）
  Bar.BarShowText := True;       // 条内显示百分比（部分 widgetset 忽略）

  StartBtn := TButton.Create(Self);
  StartBtn.Parent := Self;
  StartBtn.SetBounds(16, 84, 100, 30);
  StartBtn.Caption := '安装';
  StartBtn.OnClick := @StartClick;

  // TTimer：每个间隔发 OnTimer（消息驱动，无头 selftest 不依赖它）
  Tick := TTimer.Create(Self);
  Tick.Interval := 60;           // 毫秒
  Tick.Enabled := False;
  Tick.OnTimer := @TickTimer;
end;

procedure TProgressForm.StartClick(Sender: TObject);
begin
  Bar.Style := pbstMarquee;      // 阶段一：跑马灯（总量未知的"准备中"）
  Bar.Position := 0;             // marquee 下 Position 不参与显示
  StatusLbl.Caption := '准备中（pbstMarquee）…';
  StartBtn.Enabled := False;
  Tick.Tag := 0;                 // Tag 当阶段计数器
  Tick.Enabled := True;
end;

procedure TProgressForm.TickTimer(Sender: TObject);
begin
  Tick.Tag := Tick.Tag + 1;   // Inc 不能用于属性（取不了地址），Tag 是 property
  if Tick.Tag > 15 then
  begin
    if Tick.Tag = 16 then
    begin
      Bar.Style := pbstNormal;   // 阶段二：真实进度
      Bar.Position := 0;
      StatusLbl.Caption := '安装中…';
    end;
    Bar.StepBy(4);               // 按 Step 语义推进（等价 Position += 4）
    if Bar.Position >= Bar.Max then
    begin
      Tick.Enabled := False;
      StatusLbl.Caption := '完成。';
      StartBtn.Enabled := True;
    end;
  end;
end;

procedure RunSelfTest;
var
  f: TProgressForm;
  Log: TextFile;
begin
  Application.Initialize;
  f := TProgressForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 初值与默认：Step 默认 10、Smooth 可开关
    if (f.Bar.Min <> 0) or (f.Bar.Max <> 100) or (f.Bar.Step <> 4) then
      raise Exception.Create('进度条初值异常');
    f.Bar.Smooth := False;
    if f.Bar.Smooth then raise Exception.Create('Smooth 回环异常');
    f.Bar.Smooth := True;

    // 2) 越界钳制
    f.Bar.Position := 500;
    if f.Bar.Position <> 100 then
      raise Exception.Create('Position 越界应钳到 Max，实测=' + IntToStr(f.Bar.Position));
    f.Bar.Position := -1;
    if f.Bar.Position <> 0 then
      raise Exception.Create('Position 负值应钳到 0');

    // 3) StepBy 步进与累计
    f.Bar.Position := 90;
    f.Bar.StepBy(4);
    if f.Bar.Position <> 94 then
      raise Exception.Create('StepBy 步进异常');
    f.Bar.StepBy(99);
    if f.Bar.Position <> 100 then
      raise Exception.Create('StepBy 越过 Max 应钳到 100');

    // 4) 收窄 Max 时 Position 被钳
    f.Bar.Position := 100;
    f.Bar.Max := 50;
    if f.Bar.Position <> 50 then
      raise Exception.Create('Max 收窄后 Position 应钳到 50，实测=' + IntToStr(f.Bar.Position));
    f.Bar.Max := 100;

    // 5) Style 回环（marquee 是属性，切回 normal 后 Position 恢复语义）
    f.Bar.Style := pbstMarquee;
    if f.Bar.Style <> pbstMarquee then raise Exception.Create('Style=marquee 回环异常');
    f.Bar.Position := 33;        // marquee 下赋值照常存储，只是不显示
    f.Bar.Style := pbstNormal;
    if (f.Bar.Style <> pbstNormal) or (f.Bar.Position <> 33) then
      raise Exception.Create('Style 切回后 Position 语义异常');

    // 6) TTimer 属性（不等待触发）
    if (f.Tick.Interval <> 60) or f.Tick.Enabled then
      raise Exception.Create('Timer 属性异常');

    WriteLn(Log, 'Position=', f.Bar.Position, ' Style=normal Step=', f.Bar.Step);
    WriteLn(Log, '==== 17c selftest OK ====');
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
  with TProgressForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
