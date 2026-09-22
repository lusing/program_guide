{$mode objfpc}{$codepage utf8}{$H+}
program paint_demo;
{ 27 · 绘图与自绘（⭐）：TCanvas（Pen/Brush/Font）、OnPaint 与无效区、双缓冲
  （TBitmap 离屏合成）、鼠标事件画板、TPaintBox vs TImage、像素操作。
  正文见 docs/27-canvas.md。
  selftest 策略：全部绘制在离屏 TBitmap 上做，像素级断言（无头可验）。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Graphics,
  Classes, SysUtils;

type
  TDrawPadForm = class(TForm)
    Pad: TPaintBox;                      // 画板：只给一块 OnPaint 区域（内容不持久）
    Buffer: TBitmap;                     // 离屏缓冲：所有笔迹画这里（双缓冲主角）
    Info: TLabel;
    procedure PadPaint(Sender: TObject);
    procedure PadMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PadMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure PadMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    FDrawing: Boolean;
    FLast: TPoint;
    FStrokeCount: Integer;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RenderTo(ACanvas: TCanvas);          // 合成逻辑与目标无关（可测核心）
    procedure Clear;
    property StrokeCount: Integer read FStrokeCount;
  end;

constructor TDrawPadForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '27 · Canvas 画板（双缓冲）';
  Width := 560; Height := 420;

  Buffer := TBitmap.Create;              // 离屏位图：尺寸即画布
  Buffer.SetSize(520, 340);
  Buffer.Canvas.Brush.Color := clWhite;
  Buffer.Canvas.FillRect(0, 0, Buffer.Width, Buffer.Height);
  // 预画一组演示图形（含文字——TextOut/TextHeight）
  Buffer.Canvas.Pen.Color := clRed;
  Buffer.Canvas.Pen.Width := 2;
  Buffer.Canvas.Line(10, 10, 100, 60);
  Buffer.Canvas.Brush.Color := clYellow;
  Buffer.Canvas.Rectangle(120, 10, 200, 60);
  Buffer.Canvas.Brush.Color := clSkyBlue;
  Buffer.Canvas.Ellipse(220, 10, 300, 60);
  Buffer.Canvas.Font.Color := clGreen;
  Buffer.Canvas.Font.Size := 14;
  Buffer.Canvas.TextOut(10, 70, '离屏缓冲上的文字');

  Pad := TPaintBox.Create(Self);         // TPaintBox：没有自己的位图，只发 OnPaint
  Pad.Parent := Self;
  Pad.SetBounds(8, 28, 520, 340);
  Pad.OnPaint := @PadPaint;
  Pad.OnMouseDown := @PadMouseDown;
  Pad.OnMouseMove := @PadMouseMove;
  Pad.OnMouseUp := @PadMouseUp;

  Info := TLabel.Create(Self);
  Info.Parent := Self;
  Info.SetBounds(8, 6, 400, 18);
  Info.Caption := '拖动鼠标画笔迹（双缓冲：笔迹在离屏位图，重绘只做一次整图拷贝）';
end;

destructor TDrawPadForm.Destroy;
begin
  Buffer.Free;
  inherited Destroy;
end;

procedure TDrawPadForm.RenderTo(ACanvas: TCanvas);
begin
  // 双缓冲的"合成"一步：把离屏位图整体画到目标 Canvas（窗体/打印机/测试皆可）
  ACanvas.Draw(0, 0, Buffer);
end;

procedure TDrawPadForm.Clear;
begin
  Buffer.Canvas.Brush.Color := clWhite;
  Buffer.Canvas.FillRect(0, 0, Buffer.Width, Buffer.Height);
  FStrokeCount := 0;
end;

procedure TDrawPadForm.PadPaint(Sender: TObject);
begin
  RenderTo(Pad.Canvas);                  // OnPaint：整图拷贝——闪烁的根治（见正文）
end;

procedure TDrawPadForm.PadMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FDrawing := True;
  FLast := Point(X, Y);
  Inc(FStrokeCount);
end;

procedure TDrawPadForm.PadMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if not FDrawing then Exit;
  Buffer.Canvas.Pen.Color := clBlack;    // 笔迹只写离屏缓冲——画完 Invalidate
  Buffer.Canvas.Pen.Width := 3;
  Buffer.Canvas.Line(FLast, Point(X, Y));
  FLast := Point(X, Y);
  Pad.Invalidate;                        // 请求重绘（下次 OnPaint 整图拷出）
end;

procedure TDrawPadForm.PadMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  FDrawing := False;
end;

procedure RunSelfTest;
var
  f: TDrawPadForm;
  Log: TextFile;
  OutBmp: TBitmap;   // out 是保留字（参数方向），不能做变量名
begin
  Application.Initialize;
  f := TDrawPadForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // ── 基本图形像素验证（离屏位图直接可查）──
    if f.Buffer.Canvas.Pixels[55, 35] <> clRed then      // 红线中点（10,10→100,60）
      raise Exception.Create('线段像素验证失败');
    if f.Buffer.Canvas.Pixels[160, 35] <> clYellow then  // 黄矩形内部
      raise Exception.Create('矩形填充像素验证失败');
    if f.Buffer.Canvas.Pixels[260, 35] <> clSkyBlue then // 蓝椭圆中心
      raise Exception.Create('椭圆填充像素验证失败');
    WriteLn(Log, '基本图形像素：线/矩形/椭圆 全部命中');

    // ── 文字测量与像素 ──
    WriteLn(Log, 'TextHeight(14pt)=', f.Buffer.Canvas.TextHeight('字'),
      ' TextWidth=', f.Buffer.Canvas.TextWidth('字'),
      '（先测量后布局的依据）');
    if f.Buffer.Canvas.Pixels[12, 72] = clWhite then     // 文字起点附近应有墨迹
      raise Exception.Create('文字像素验证失败');
    WriteLn(Log, 'TextOut 像素命中 ✓');

    // ── 鼠标画笔逻辑（直接调处理器，走一遍画笔路径）──
    f.PadMouseDown(nil, mbLeft, [], 300, 200);
    f.PadMouseMove(nil, [], 320, 210);
    f.PadMouseMove(nil, [], 340, 220);
    f.PadMouseUp(nil, mbLeft, [], 340, 220);
    if f.StrokeCount <> 1 then
      raise Exception.Create('笔迹计数异常');
    // 线段中点（约 320,210）应有黑墨
    if f.Buffer.Canvas.Pixels[320, 210] = clWhite then
      raise Exception.Create('笔迹像素验证失败');
    WriteLn(Log, '鼠标画笔：3 段移动 → 笔迹像素命中，StrokeCount=1');

    // ── 双缓冲合成：RenderTo 输出到第二张位图再验像素 ──
    OutBmp := TBitmap.Create;
    OutBmp.SetSize(520, 340);
    OutBmp.Canvas.Brush.Color := clFuchsia;  // 底色故意不同（洋红），证明拷贝覆盖
    OutBmp.Canvas.FillRect(0, 0, 520, 340);
    f.RenderTo(OutBmp.Canvas);
    if OutBmp.Canvas.Pixels[160, 35] <> clYellow then
      raise Exception.Create('合成输出像素验证失败');
    if OutBmp.Canvas.Pixels[320, 210] = clFuchsia then
      raise Exception.Create('合成应包含笔迹（墨迹应盖过洋红底）');
    WriteLn(Log, '双缓冲合成：RenderTo 第二位图 → 像素与源一致');
    OutBmp.Free;

    // ── Clear ──
    f.Clear;
    if f.Buffer.Canvas.Pixels[55, 35] <> clWhite then
      raise Exception.Create('清空后应为白底');
    if f.StrokeCount <> 0 then
      raise Exception.Create('清空未重置计数');
    WriteLn(Log, 'Clear → 白底 + 计数归零');
    WriteLn(Log, '==== 27 selftest OK ====');
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
  with TDrawPadForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
