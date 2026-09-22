{$mode objfpc}{$codepage utf8}{$H+}
program drawgrid_demo;
{ 19b · TDrawGrid：没有 Cells 存储——每个格子画什么全由你（OnDrawCell 必须实现）。
  与 TStringGrid 的分工：数据/渲染全自理 vs 存储/编辑全代劳。
  本例 8×8 像素画板：模型（色板数组）与视图（DrawGrid）分离，
  鼠标 MouseToCell 换色，清空/随机操作模型后 Invalidate。正文见 docs/19-grids.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Grids, Graphics,
  Classes, SysUtils;

const
  N = 8;                       // 8×8 板
  Palette: array[0..3] of TColor = (clWhite, clBlack, clRed, clYellow);

type
  TPixelForm = class(TForm)
    Grid: TDrawGrid;
    ClearButton, RandButton: TButton;
    CountLbl: TLabel;
    function CellIndex(C, R: Integer): Integer; inline;
    function NextColor(C: TColor): TColor;
    procedure GridDrawCell(Sender: TObject; ACol, ARow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure GridMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ClearClick(Sender: TObject);
    procedure RandClick(Sender: TObject);
    procedure RefreshCount;
  public
    // 模型：格子颜色（Flat 数组，(行*8+列) 寻址——与 DrawGrid 无耦合）。
    // 数组字段不能放 published（FPC 只允许类类型），显式 public
    Cells: array[0..N * N - 1] of TColor;
    constructor Create(AOwner: TComponent); override;
  end;

function TPixelForm.CellIndex(C, R: Integer): Integer;
begin
  Result := R * N + C;         // 行主序：DrawGrid 事件给的是 (列,行)——换算别搞反
end;

function TPixelForm.NextColor(C: TColor): TColor;
var
  I: Integer;
begin
  Result := Palette[0];
  for I := High(Palette) downto 0 do
    if Palette[I] = C then
    begin
      Result := Palette[(I + 1) mod Length(Palette)];
      Exit;
    end;
end;

constructor TPixelForm.Create(AOwner: TComponent);
var
  I: Integer;
begin
  inherited CreateNew(AOwner);
  Caption := '19b · DrawGrid 像素画板';
  Width := 480; Height := 420;
  for I := 0 to High(Cells) do Cells[I] := clWhite;   // 坑：clWhite=$FFFFFF 不是 0！

  Grid := TDrawGrid.Create(Self);
  Grid.Parent := Self;
  Grid.SetBounds(16, 12, 8 * 40 + 4, 8 * 40 + 4);
  Grid.ColCount := N;
  Grid.RowCount := N;
  Grid.FixedRows := 0;                     // 无表头：全板都是数据格（StringGrid 少见的形态）
  Grid.FixedCols := 0;
  Grid.DefaultColWidth := 40;
  Grid.DefaultRowHeight := 40;
  Grid.Options := Grid.Options - [goRangeSelect] - [goFixedHorzLine, goFixedVertLine];
  Grid.OnDrawCell := @GridDrawCell;
  Grid.OnMouseDown := @GridMouseDown;

  ClearButton := TButton.Create(Self);
  ClearButton.Parent := Self;
  ClearButton.SetBounds(360, 16, 96, 30);
  ClearButton.Caption := '清空';
  ClearButton.OnClick := @ClearClick;

  RandButton := TButton.Create(Self);
  RandButton.Parent := Self;
  RandButton.SetBounds(360, 52, 96, 30);
  RandButton.Caption := '随机';
  RandButton.OnClick := @RandClick;

  CountLbl := TLabel.Create(Self);
  CountLbl.Parent := Self;
  CountLbl.SetBounds(360, 90, 110, 60);
  RefreshCount;
end;

procedure TPixelForm.GridDrawCell(Sender: TObject; ACol, ARow: Integer;
  aRect: TRect; aState: TGridDrawState);
begin
  // DrawGrid 的本体：每格必画（不画=白板），数据从模型取
  Grid.Canvas.Brush.Color := Cells[CellIndex(ACol, ARow)];
  Grid.Canvas.FillRect(aRect);
end;

procedure TPixelForm.GridMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  C, R: Integer;
begin
  Grid.MouseToCell(X, Y, C, R);            // 像素坐标 → 格坐标（左键进/右键退）
  if (C < 0) or (R < 0) then Exit;
  if Button = mbLeft then
    Cells[CellIndex(C, R)] := NextColor(Cells[CellIndex(C, R)])
  else
    Cells[CellIndex(C, R)] := clWhite;
  Grid.Invalidate;                          // 模型变了通知视图重画（M-V 单向流）
  RefreshCount;
end;

procedure TPixelForm.ClearClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to High(Cells) do Cells[I] := clWhite;
  Grid.Invalidate;
  RefreshCount;
end;

procedure TPixelForm.RandClick(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to High(Cells) do
    Cells[I] := Palette[Random(Length(Palette))];
  Grid.Invalidate;
  RefreshCount;
end;

procedure TPixelForm.RefreshCount;
var
  I, Colored: Integer;
begin
  Colored := 0;
  for I := 0 to High(Cells) do
    if Cells[I] <> clWhite then Inc(Colored);
  CountLbl.Caption := Format('已涂 %d / %d 格', [Colored, N * N]);
end;

procedure RunSelfTest;
var
  f: TPixelForm;
  Log: TextFile;
begin
  Application.Initialize;
  f := TPixelForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 网格形态：8×8 无固定行列
    if (f.Grid.ColCount <> N) or (f.Grid.RowCount <> N)
      or (f.Grid.FixedRows <> 0) or (f.Grid.FixedCols <> 0) then
      raise Exception.Create('DrawGrid 形态异常');

    // 2) 模型独立性：不碰 Grid 也能读写格子（DrawGrid 的意义所在）
    f.Cells[f.CellIndex(0, 0)] := clBlack;
    f.Cells[f.CellIndex(7, 7)] := clRed;
    if (f.Cells[0] <> clBlack) or (f.Cells[63] <> clRed) then
      raise Exception.Create('模型数组读写异常');

    // 3) CellIndex 行主序换算（DrawGrid 给 (列,行)，模型存 [行*8+列]）
    if f.CellIndex(3, 5) <> 43 then
      raise Exception.Create('CellIndex(列=3,行=5) 应=43（5*8+3）');

    // 4) NextColor 循环（白→黑→红→黄→白）
    if (f.NextColor(clWhite) <> clBlack) or (f.NextColor(clYellow) <> clWhite) then
      raise Exception.Create('调色循环异常');
    if f.NextColor(clSkyBlue) <> clWhite then
      raise Exception.Create('板外色应回到首色');

    // 5) 清空语义
    f.ClearClick(nil);
    if f.Cells[0] <> clWhite then
      raise Exception.Create('清空后应全白');

    // 6) 随机（种子固定可复现）
    RandSeed := 42;
    f.RandClick(nil);
    RandSeed := 42;
    if f.Cells[0] <> Palette[Random(Length(Palette))] then
      raise Exception.Create('固定种子随机应可复现');

    WriteLn(Log, '网格=8x8 无固定行列；模型数组独立于控件');
    WriteLn(Log, '==== 19b selftest OK ====');
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
  with TPixelForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
