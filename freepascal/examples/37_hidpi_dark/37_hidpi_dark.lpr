{$mode objfpc}{$codepage utf8}{$H+}
program hidpi_dark_demo;
{ 37 · 高 DPI 深入与暗色主题：PixelsPerInch 体系、ScaleBy 比例缩放、
  AutoAdjustLayout、系统 DPI 感知声明；暗色 = 标题栏 DWM 属性
  （DwmSetWindowAttribute 外部声明）+ 控件配色自管（LCL 无全局主题）。
  正文见 docs/37-hidpi-dark.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Graphics, LCLType,
  Classes, SysUtils, Math, StrUtils;

const
  // Win10 1809+ / Win11：暗色标题栏的 DWM 属性号（旧版 19，新版 20——都试）
  DWMWA_USE_IMMERSIVE_DARK_MODE_OLD = 19;
  DWMWA_USE_IMMERSIVE_DARK_MODE     = 20;

// LCL 没封装 DWM——自己声明（dwmapi.dll 系统自带；HRESULT>=0 即成功）
function DwmSetWindowAttribute(hwnd: HWND; dwAttribute: DWORD;
  pvAttribute: Pointer; cbAttribute: DWORD): LongInt; stdcall; external 'dwmapi';

type
  THiDpiForm = class(TForm)
    Card: TPanel;
    BodyLbl, Info: TLabel;
    ZoomBtn, DarkBtn: TButton;
    procedure ZoomClick(Sender: TObject);
    procedure DarkClick(Sender: TObject);
  public
    Dark: Boolean;                     // 计数/状态字段放 public（published 只收类）
    function ApplyDarkTitleBar(OnOff: Boolean): LongInt;
    procedure ApplyDarkControls(OnOff: Boolean);
    constructor Create(AOwner: TComponent); override;
  end;

constructor THiDpiForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '37 · 高 DPI 与暗色';
  Width := 420; Height := 300;
  Dark := False;

  Card := TPanel.Create(Self);
  Card.Parent := Self;
  Card.SetBounds(16, 12, 384, 150);
  Card.Caption := '';

  BodyLbl := TLabel.Create(Self);
  BodyLbl.Parent := Card;
  BodyLbl.SetBounds(12, 12, 350, 60);
  BodyLbl.Caption := '高 DPI 的世界：设计基准 96，本窗体运行在当前系统密度。';

  ZoomBtn := TButton.Create(Self);
  ZoomBtn.Parent := Card;
  ZoomBtn.SetBounds(12, 90, 110, 32);
  ZoomBtn.Caption := '放大 1.5×';
  ZoomBtn.OnClick := @ZoomClick;

  DarkBtn := TButton.Create(Self);
  DarkBtn.Parent := Card;
  DarkBtn.SetBounds(132, 90, 110, 32);
  DarkBtn.Caption := '暗色';
  DarkBtn.OnClick := @DarkClick;

  Info := TLabel.Create(Self);
  Info.Parent := Self;
  Info.SetBounds(16, 172, 390, 100);
end;

procedure THiDpiForm.ZoomClick(Sender: TObject);
begin
  // ScaleBy(乘, 除)：整棵控件树按比例重排（字体也跟着）
  ScaleBy(3, 2);                                // 1.5×
  Info.Caption := Format('ScaleBy(3,2) 后 PixelsPerInch=%d  按钮=%d×%d', [
    PixelsPerInch, ZoomBtn.Width, ZoomBtn.Height]);
end;

function THiDpiForm.ApplyDarkTitleBar(OnOff: Boolean): LongInt;
var
  Flag: Integer;
begin
  // 暗色标题栏是窗口级 DWM 属性（1=开 0=关）；旧属性号 19 失败再试 20
  Flag := IfThen(OnOff, 1, 0);
  Result := DwmSetWindowAttribute(Handle, DWMWA_USE_IMMERSIVE_DARK_MODE,
    @Flag, SizeOf(Flag));
  if Result < 0 then
    Result := DwmSetWindowAttribute(Handle, DWMWA_USE_IMMERSIVE_DARK_MODE_OLD,
      @Flag, SizeOf(Flag));
end;

procedure THiDpiForm.ApplyDarkControls(OnOff: Boolean);
begin
  // LCL 没有全局暗色主题——控件配色自管（一套暗色调色板走天下）
  if OnOff then
  begin
    Color := TColor($202020);         // 窗体底：暗灰
    Card.Color := TColor($2D2D30);
    BodyLbl.Color := TColor($2D2D30);
    BodyLbl.Font.Color := clWhite;
    Info.Font.Color := clSilver;
  end
  else
  begin
    Color := clDefault;
    Card.Color := clDefault;
    BodyLbl.Color := clDefault;
    BodyLbl.Font.Color := clDefault;
    Info.Font.Color := clDefault;
  end;
end;

procedure THiDpiForm.DarkClick(Sender: TObject);
begin
  Dark := not Dark;
  ApplyDarkControls(Dark);
  ApplyDarkTitleBar(Dark);            // 标题栏由系统画——DWM 说了算
  DarkBtn.Caption := IfThen(Dark, '亮色', '暗色');
end;

procedure RunSelfTest;
var
  f: THiDpiForm;
  Log: TextFile;
  W0, H0: Integer;
  Hr: LongInt;
begin
  Application.Initialize;
  f := THiDpiForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) DPI 事实记录（96=设计基准；高 DPI 屏上更大）
    WriteLn(Log, 'PixelsPerInch=', f.PixelsPerInch, '（设计基准 96）');
    if f.PixelsPerInch < 96 then
      raise Exception.Create('PixelsPerInch 不应低于 96');

    // 2) ScaleBy 数学：按钮尺寸 3:2 精确缩放（含四舍五入）
    W0 := f.ZoomBtn.Width;  H0 := f.ZoomBtn.Height;
    f.ScaleBy(3, 2);
    if f.ZoomBtn.Width <> (W0 * 3 + 1) div 2 then   // 实测取整=四舍五入
      raise Exception.Create(Format('Width 缩放异常 %d→%d', [W0, f.ZoomBtn.Width]));
    WriteLn(Log, Format('按钮 %d×%d → %d×%d（1.5×）',
      [W0, H0, f.ZoomBtn.Width, f.ZoomBtn.Height]));
    f.ScaleBy(2, 3);                                 // 放回去（近似的代价见正文）

    // 3) 暗色控件配色回环
    f.ApplyDarkControls(True);
    if f.Color <> TColor($202020) then
      raise Exception.Create('暗色窗体底未生效');
    f.ApplyDarkControls(False);
    if f.Color <> clDefault then
      raise Exception.Create('恢复默认配色失败');

    // 4) DWM 标题栏属性调用（返回值记录：0=成功；负值=系统不支持/句柄未显示）
    Hr := f.ApplyDarkTitleBar(True);
    WriteLn(Log, 'DwmSetWindowAttribute(dark) HRESULT=', Hr);
    f.ApplyDarkTitleBar(False);
    WriteLn(Log, 'DwmSetWindowAttribute(light) HRESULT=', Hr);

    // 5) Scaled 属性（默认 True：跨 DPI 搬窗体时 LCL 自动按比例重排）
    if not f.Scaled then
      raise Exception.Create('Scaled 默认应为 True');

    WriteLn(Log, '==== 37 selftest OK ====');
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
  with THiDpiForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
