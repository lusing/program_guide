{$mode objfpc}{$codepage utf8}{$H+}
program more_controls_demo;
{ 17 · 更多控件：TrackBar/SpinEdit/ProgressBar/Calendar/ColorBox/StringGrid/
  TTabControl vs TPageControl/TImage/TFrame（纯代码创建）。
  正文见 docs/17-more-controls.md。
  注：TDateTimePicker 在独立包 datetimectrls（lpi 要加包），本章用 lcl 的 TCalendar。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls,
  Spin, ColorBox, Grids, Calendar, Graphics,
  uheaderframe { THeaderFrame },
  Classes, SysUtils;

type
  // ═══ TFrame 见 uheaderframe 单元：Frame 与 .lfm 配对（Create 必须找到同名资源）
  TDemoForm = class(TForm)
    Track: TTrackBar;
    Spinner: TSpinEdit;
    Progress: TProgressBar;
    ColorBox: TColorBox;
    Cal: TCalendar;
    Grid: TStringGrid;
    Tabs: TTabControl;
    Pages: TPageControl;
    Img: TImage;
    FrameA: THeaderFrame;
    Log: TMemo;
    procedure TrackChange(Sender: TObject);
    procedure GridSelectCell(Sender: TObject; ACol, ARow: Longint; var CanSelect: Boolean);
  public
    constructor Create(AOwner: TComponent); override;
  end;

{ TDemoForm }

constructor TDemoForm.Create(AOwner: TComponent);
var
  page: TTabSheet;
  i: Integer;
begin
  inherited CreateNew(AOwner);
  Caption := '17 · 更多控件';
  Width := 760; Height := 520;

  // ── 数值与状态行（顶部 Panel） ──
  with TPanel.Create(Self) do
  begin
    Parent := Self;
    Align := alTop;
    Height := 96;
    Caption := '';

    Track := TTrackBar.Create(Self);          // 滑杆：Min..Max 连续取值
    Track.Parent := Parent as TWinControl;
    Track.SetBounds(8, 6, 220, 32);
    Track.Min := 0; Track.Max := 100;
    Track.Position := 30;
    Track.OnChange := @TrackChange;

    Spinner := TSpinEdit.Create(Self);        // 数字输入框：上下箭头步进
    Spinner.Parent := Parent as TWinControl;
    Spinner.SetBounds(240, 6, 90, 28);
    Spinner.MinValue := 0; Spinner.MaxValue := 1000;
    Spinner.Value := 42;

    Progress := TProgressBar.Create(Self);    // 进度条：22 章多线程的标配
    Progress.Parent := Parent as TWinControl;
    Progress.SetBounds(8, 48, 220, 20);
    Progress.Min := 0; Progress.Max := 100;
    Progress.Position := 60;

    ColorBox := TColorBox.Create(Self);       // 颜色下拉（自绘项）
    ColorBox.Parent := Parent as TWinControl;
    ColorBox.SetBounds(240, 44, 120, 26);
    ColorBox.Selected := clRed;
  end;

  // ── 左列：日历 + TFrame ──
  with TPanel.Create(Self) do
  begin
    Parent := Self;
    Align := alLeft;
    Width := 240;
    Caption := '';

    Cal := TCalendar.Create(Self);            // 月历（纯 lcl；DateTimePicker 见正文）
    Cal.Parent := Parent as TWinControl;
    Cal.SetBounds(8, 8, 224, 160);
    Cal.DateTime := EncodeDate(2026, 9, 19);

    FrameA := THeaderFrame.Create(Self);      // Frame 挂进窗体——复用的最小示例
    FrameA.Parent := Parent as TWinControl;
    FrameA.SetBounds(8, 180, 224, 44);
  end;

  // ── 中列：StringGrid 表格 ──
  Grid := TStringGrid.Create(Self);
  Grid.Parent := Self;
  Grid.Align := alClient;
  Grid.ColCount := 3;
  Grid.RowCount := 4;
  Grid.FixedRows := 1;                        // 首行为表头（灰底不可编辑）
  Grid.Options := Grid.Options + [goEditing]; // 单元格可编辑（F2/双击）
  Grid.Cells[0, 0] := '姓名';
  Grid.Cells[1, 0] := '年龄';
  Grid.Cells[2, 0] := '城市';
  Grid.Cells[0, 1] := '张三';  Grid.Cells[1, 1] := '30'; Grid.Cells[2, 1] := '北京';
  Grid.Cells[0, 2] := '李四';  Grid.Cells[1, 2] := '25'; Grid.Cells[2, 2] := '上海';
  Grid.OnSelectCell := @GridSelectCell;

  // ── 右列：Tabs vs Pages + 图片 ──
  with TPanel.Create(Self) do
  begin
    Parent := Self;
    Align := alRight;
    Width := 280;
    Caption := '';

    // TTabControl：只有一排标签页头（内容自己换）——轻量
    Tabs := TTabControl.Create(Self);
    Tabs.Parent := Parent as TWinControl;
    Tabs.SetBounds(8, 8, 264, 60);
    Tabs.Tabs.Add('标签 A');
    Tabs.Tabs.Add('标签 B');
    Tabs.TabIndex := 0;

    // TPageControl：每页一个 TTabSheet 容器（各有自己的控件）——重型多页
    Pages := TPageControl.Create(Self);
    Pages.Parent := Parent as TWinControl;
    Pages.SetBounds(8, 76, 264, 120);
    for i := 1 to 3 do
    begin
      page := Pages.AddTabSheet;              // 动态加页
      page.Caption := Format('页 %d', [i]);
      with TLabel.Create(page) do
      begin
        Parent := page;
        SetBounds(12, 12, 200, 20);
        Caption := Format('第 %d 页的内容', [i]);
      end;
    end;

    // TImage：程序画一张位图挂上去（21 章 Canvas 细讲）
    Img := TImage.Create(Self);
    Img.Parent := Parent as TWinControl;
    Img.SetBounds(8, 204, 120, 90);
    Img.Picture.Bitmap.SetSize(120, 90);
    Img.Picture.Bitmap.Canvas.Brush.Color := clSkyBlue;
    Img.Picture.Bitmap.Canvas.FillRect(0, 0, 120, 90);
    Img.Picture.Bitmap.Canvas.Brush.Color := clYellow;
    Img.Picture.Bitmap.Canvas.Ellipse(20, 15, 100, 75);
  end;

  Log := TMemo.Create(Self);
  Log.Parent := Self;
  Log.Align := alBottom;
  Log.Height := 80;
  Log.ReadOnly := True;
end;

procedure TDemoForm.TrackChange(Sender: TObject);
begin
  Log.Lines.Append(Format('[TrackBar] Position=%d', [Track.Position]));
end;

procedure TDemoForm.GridSelectCell(Sender: TObject; ACol, ARow: Longint;
  var CanSelect: Boolean);
begin
  Log.Lines.Append(Format('[Grid] 选中 %d,%d = %s', [ACol, ARow, Grid.Cells[ACol, ARow]]));
end;

procedure RunSelfTest;
var
  f: TDemoForm;
  Log: TextFile;
  bmp: TBitmap;
begin
  Application.Initialize;
  f := TDemoForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 数值类
    if (f.Track.Position <> 30) or (f.Spinner.Value <> 42) or (f.Progress.Position <> 60) then
      raise Exception.Create('数值控件初值异常');
    f.Track.Position := 70;                 // OnChange 触发（实测）
    if f.Log.Lines.Count < 1 then
      raise Exception.Create('TrackBar OnChange 未触发');
    f.Spinner.Value := 100;
    if f.Spinner.Value <> 100 then
      raise Exception.Create('SpinEdit 赋值异常');
    WriteLn(Log, 'Track=', f.Track.Position, ' Spin=', f.Spinner.Value,
      ' Progress=', f.Progress.Position, ' Color=', ColorToString(f.ColorBox.Selected));

    // 日历
    if f.Cal.DateTime <> EncodeDate(2026, 9, 19) then
      raise Exception.Create('Calendar 日期异常');
    WriteLn(Log, 'Calendar=', FormatDateTime('yyyy-mm-dd', f.Cal.DateTime));

    // StringGrid
    if f.Grid.Cells[2, 2] <> '上海' then
      raise Exception.Create('Grid 单元格读取异常');
    f.Grid.Cells[1, 2] := '26';
    if f.Grid.ColCount <> 3 then
      raise Exception.Create('Grid 列数异常');
    WriteLn(Log, 'Grid[0,1]=', f.Grid.Cells[0, 1], ' [1,2]=', f.Grid.Cells[1, 2]);

    // Tabs vs Pages
    if (f.Tabs.Tabs.Count <> 2) or (f.Pages.PageCount <> 3) then
      raise Exception.Create('标签/分页数量异常');
    if f.Pages.Pages[2].Caption <> '页 3' then
      raise Exception.Create('PageControl 页标题异常');
    WriteLn(Log, 'Tabs=', f.Tabs.Tabs.Count, ' Pages=', f.Pages.PageCount,
      ' 页3标题=', f.Pages.Pages[2].Caption);

    // TImage 位图像素验证（离屏像素可查）
    bmp := f.Img.Picture.Bitmap;
    if bmp.Canvas.Pixels[60, 45] <> clYellow then      // 椭圆中心
      raise Exception.Create('位图绘制像素验证失败');
    if bmp.Canvas.Pixels[5, 5] <> clSkyBlue then       // 左上角背景
      raise Exception.Create('位图背景像素验证失败');
    WriteLn(Log, '位图像素验证通过（黄椭圆/蓝背景）');

    // TFrame
    f.FrameA.BtnPingClick(nil);
    f.FrameA.BtnPingClick(nil);
    if f.FrameA.ClickCount <> 2 then
      raise Exception.Create('Frame 事件计数异常');
    if f.FrameA.LblTitle.Caption <> 'Frame 点击 2 次' then
      raise Exception.Create('Frame 标签未随事件更新');
    WriteLn(Log, 'Frame 点击 2 次后标题=', f.FrameA.LblTitle.Caption);
    WriteLn(Log, '==== 17 selftest OK ====');
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
      // 坑（实测）：GUI 程序未捕获异常会弹 LCL 消息框——无头验证环境直接挂死！
      // selftest 必须自捕获：错误写日志、exit 1，绝不弹框
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
  with TDemoForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
