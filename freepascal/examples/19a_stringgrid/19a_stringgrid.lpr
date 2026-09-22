{$mode objfpc}{$codepage utf8}{$H+}
program stringgrid_demo;
{ 19a · TStringGrid 深挖（unit Grids）：Cells[列,行]（列在前的经典手误点）、
  Options 开关（goEditing/goColSizing/goTabs/goCellEllipsis…）、
  OnValidateEntry 编辑校验（var NewValue 改回旧值=拒绝）、
  OnPrepareCanvas 逐格换笔（不及格红字）、OnHeaderClick 点表头排序
  （SortColRow + SortOrder + OnCompareCells 数值比较——字符串序会把 9 排在 80 后）、
  InsertRowWithValues/DeleteRow 动态行。正文见 docs/19-grids.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Grids, Graphics,
  Classes, SysUtils, StrUtils, Math;

type
  TGridForm = class(TForm)
    Grid: TStringGrid;
    Bottom: TPanel;
    AddBtn, DelBtn, SortBtn: TButton;
    Log: TMemo;
    procedure GridValidateEntry(Sender: TObject; ACol, ARow: Integer;
      const OldValue: string; var NewValue: String);
    procedure GridPrepareCanvas(Sender: TObject; ACol, ARow: Integer;
      AState: TGridDrawState);
    procedure GridHeaderClick(Sender: TObject; IsColumn: Boolean; Index: Integer);
    procedure GridCompareCells(Sender: TObject; ACol, ARow, BCol, BRow: Integer;
      var Result: Integer);
    procedure AddClick(Sender: TObject);
    procedure DelClick(Sender: TObject);
    procedure SortClick(Sender: TObject);
  public
    SortAsc: Boolean;                     // 自管排序的当前方向（与内建排序无关）
    function CompareRow(const A, B: string; ACol: Integer): Integer;
    procedure SortByCol(ACol: Integer; Asc: Boolean);
    constructor Create(AOwner: TComponent); override;
  end;

constructor TGridForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '19a · StringGrid 成绩表';
  Width := 640; Height := 480;

  Grid := TStringGrid.Create(Self);
  Grid.Parent := Self;
  Grid.Align := alClient;
  Grid.ColCount := 4;                 // 姓名 | 语文 | 数学 | 平均
  Grid.RowCount := 5;                 // 1 表头 + 4 学生
  Grid.FixedRows := 1;                // 首行表头：灰底、不随滚动、点它发 OnHeaderClick
  Grid.Options := Grid.Options
    + [goEditing, goColSizing, goTabs, goCellEllipsis, goDrawFocusSelected];
  // goEditing：F2/双击进编辑；goColSizing：拖列宽；goTabs：Tab 键横向跳格
  // goCellEllipsis：放不下的文字显示省略号

  Grid.Cells[0, 0] := '姓名';         // Cells[列, 行]——列在前！
  Grid.Cells[1, 0] := '语文';
  Grid.Cells[2, 0] := '数学';
  Grid.Cells[3, 0] := '平均';
  Grid.Rows[1].CommaText := '张三,77,84,80.5';    // 整行赋值（TStrings 视图）
  Grid.Rows[2].CommaText := '李四,58,92,75.0';
  Grid.Rows[3].CommaText := '王五,90,66,78.0';
  Grid.Rows[4].CommaText := '赵六,45,71,58.0';

  Grid.OnValidateEntry := @GridValidateEntry;
  Grid.OnPrepareCanvas := @GridPrepareCanvas;
  // 内建表头排序：ColumnClickSorts + OnCompareCells（点表头即排，同列再点反向）
  Grid.ColumnClickSorts := True;
  Grid.OnCompareCells := @GridCompareCells;
  Grid.OnHeaderClick := @GridHeaderClick;     // 只记日志（排序由上面的内建做）

  // ── 底部：按钮行 + 操作日志 ──
  Bottom := TPanel.Create(Self);
  Bottom.Parent := Self;
  Bottom.Align := alBottom;
  Bottom.Height := 120;
  Bottom.Caption := '';

  AddBtn := TButton.Create(Self);
  AddBtn.Parent := Bottom;             // 挂进 Panel：Parent 指 Panel 不是窗体
  AddBtn.SetBounds(8, 6, 90, 28);
  AddBtn.Caption := '加一行';
  AddBtn.OnClick := @AddClick;

  DelBtn := TButton.Create(Self);
  DelBtn.Parent := Bottom;
  DelBtn.SetBounds(104, 6, 90, 28);
  DelBtn.Caption := '删当前行';
  DelBtn.OnClick := @DelClick;

  SortBtn := TButton.Create(Self);
  SortBtn.Parent := Bottom;
  SortBtn.SetBounds(200, 6, 120, 28);
  SortBtn.Caption := '语文排序(自管)';
  SortBtn.OnClick := @SortClick;

  Log := TMemo.Create(Self);
  Log.Parent := Bottom;
  Log.SetBounds(200, 4, 420, 110);
  Log.ReadOnly := True;
end;

procedure TGridForm.GridValidateEntry(Sender: TObject; ACol, ARow: Integer;
  const OldValue: string; var NewValue: String);
var
  V: Integer;
begin
  // 只校验成绩列；姓名列放行
  if ACol in [1, 2] then
  begin
    if not TryStrToInt(NewValue, V) or (V < 0) or (V > 100) then
    begin
      // 拒绝的方式：把 var NewValue 改回 OldValue（没有"取消编辑"的返回通道）
      NewValue := OldValue;
      Log.Lines.Append(Format('[校验] (%d,%d) "%s" 不是 0..100，退回', [ACol, ARow, OldValue]));
    end;
  end;
end;

procedure TGridForm.GridPrepareCanvas(Sender: TObject; ACol, ARow: Integer;
  AState: TGridDrawState);
var
  V: Integer;
begin
  // 每格绘制前调一次：改 Canvas 的笔/字——比 OnDrawCell 全自绘轻得多
  if ARow = 0 then
    Grid.Canvas.Font.Bold := True               // 表头加粗
  else if (ACol in [1, 2]) and TryStrToInt(Grid.Cells[ACol, ARow], V) and (V < 60) then
    Grid.Canvas.Font.Color := clRed;            // 不及格红字（OnPrepareCanvas 的招牌用法）
end;

procedure TGridForm.GridHeaderClick(Sender: TObject; IsColumn: Boolean; Index: Integer);
begin
  // 排序本身由内建做（ColumnClickSorts=True），这里只记账——
  // 千万别再调一次排序：双重排序=方向翻两次，实测净效果等于没排（19 章头号坑）
  if IsColumn then
    Log.Lines.Append(Format('[表头] 点了第 %d 列（内建已排，方向 %s）', [Index,
      IfThen(Grid.SortOrder = soAscending, '升序', '降序')]));
end;

procedure TGridForm.GridCompareCells(Sender: TObject; ACol, ARow, BCol, BRow: Integer;
  var Result: Integer);
begin
  Result := CompareRow(Grid.Cells[ACol, ARow], Grid.Cells[BCol, BRow], ACol);
end;

// 比较器：数值列按数值比（默认字符串序会把 9 排在 80 后——经典坑）
function TGridForm.CompareRow(const A, B: string; ACol: Integer): Integer;
var
  VA, VB: Integer;
begin
  if (ACol in [1, 2]) and TryStrToInt(A, VA) and TryStrToInt(B, VB) then
    Result := VA - VB                                 // 负=A 在前
  else
    Result := AnsiCompareText(A, B);
end;

// 自管排序：快照数据行 → 选择排序 → 写回（要程序化触发/要稳定序时走这条）
procedure TGridForm.SortByCol(ACol: Integer; Asc: Boolean);
var
  RowsData: array of array of string;
  R, C, I, J, Min: Integer;
  Tmp: array of string;
begin
  SetLength(RowsData, Grid.RowCount - Grid.FixedRows, Grid.ColCount);
  for R := 0 to High(RowsData) do
    for C := 0 to Grid.ColCount - 1 do
      RowsData[R][C] := Grid.Cells[C, R + Grid.FixedRows];
  // 选择排序（数据量小，稳定好懂；方向由翻转比较结果实现）
  SetLength(Tmp, Grid.ColCount);
  for I := 0 to High(RowsData) - 1 do
  begin
    Min := I;
    for J := I + 1 to High(RowsData) do
      if CompareRow(RowsData[J][ACol], RowsData[Min][ACol], ACol) *
         IfThen(Asc, 1, -1) < 0 then
        Min := J;
    Tmp := RowsData[I]; RowsData[I] := RowsData[Min]; RowsData[Min] := Tmp;
  end;
  for R := 0 to High(RowsData) do
    for C := 0 to Grid.ColCount - 1 do
      Grid.Cells[C, R + Grid.FixedRows] := RowsData[R][C];
end;

procedure TGridForm.AddClick(Sender: TObject);
begin
  // 插到末尾（FixedRows=1 所以从第 1 行起是数据）
  Grid.InsertRowWithValues(Grid.RowCount, ['新同学', '60', '60', '60.0']);
end;

procedure TGridForm.SortClick(Sender: TObject);
begin
  SortAsc := not SortAsc;                    // 按钮演示自管排序（语文列）
  SortByCol(1, SortAsc);
  Log.Lines.Append(Format('[自管排序] 语文 %s', [IfThen(SortAsc, '升序', '降序')]));
end;

procedure TGridForm.DelClick(Sender: TObject);
begin
  if Grid.Row > 0 then                 // Grid.Row = 当前行（0 是表头不许删）
    Grid.DeleteRow(Grid.Row);
end;

procedure RunSelfTest;
var
  f: TGridForm;
  Log: TextFile;
  NewVal: string;
begin
  Application.Initialize;
  f := TGridForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) Cells[列,行] 语义实证：[0,2] 是"第 0 列第 2 行"=李四
    if f.Grid.Cells[0, 2] <> '李四' then
      raise Exception.Create('Cells[列,行] 语义异常：Cells[0,2]=' + f.Grid.Cells[0, 2]);
    if f.Grid.Cells[1, 2] <> '58' then
      raise Exception.Create('Cells[1,2] 应为语文 58');

    // 2) Rows[i] 整行视图（CommaText 赋的值回读）
    if f.Grid.Rows[4].Strings[0] <> '赵六' then
      raise Exception.Create('Rows[4][0] 应为赵六');

    // 3) 编辑校验：非法值退回旧值（直呼事件处理器模拟编辑提交）
    NewVal := '150';
    f.GridValidateEntry(nil, 1, 1, f.Grid.Cells[1, 1], NewVal);
    if NewVal <> f.Grid.Cells[1, 1] then
      raise Exception.Create('非法 150 应退回旧值');
    NewVal := '88';
    f.GridValidateEntry(nil, 1, 1, f.Grid.Cells[1, 1], NewVal);
    if NewVal <> '88' then
      raise Exception.Create('合法 88 应放行');

    // 4) 自管数值排序：语文列升序 → 赵六(45) 第一；降序 → 王五(90) 第一
    f.SortByCol(1, True);
    if f.Grid.Cells[0, 1] <> '赵六' then
      raise Exception.Create('语文升序第一名应赵六(45)，实测=' + f.Grid.Cells[0, 1]);
    if (f.Grid.Cells[1, 1] <> '45') or (f.Grid.Cells[1, 2] <> '58') then
      raise Exception.Create('语文升序数值序异常（9>80 的字符串序没修掉？）');
    f.SortByCol(1, False);
    if f.Grid.Cells[0, 1] <> '王五' then
      raise Exception.Create('语文降序第一名应王五(90)，实测=' + f.Grid.Cells[0, 1]);

    // 5) 中文姓名列排序（AnsiCompareText 按码点，端点单调即可）
    f.SortByCol(0, True);
    if AnsiCompareText(f.Grid.Cells[0, 1], f.Grid.Cells[0, 4]) > 0 then
      raise Exception.Create('姓名升序端点异常');
    f.SortByCol(1, True);                     // 恢复语文升序，供下面步骤

    // 5b) 内建排序在位：ColumnClickSorts=True + OnCompareCells 已挂（UI 点表头生效）
    if not f.Grid.ColumnClickSorts then
      raise Exception.Create('ColumnClickSorts 应为 True');

    // 6) 动态行：插入与删除
    f.Grid.InsertRowWithValues(f.Grid.RowCount, ['新人', '70', '70', '70.0']);
    if (f.Grid.RowCount <> 6) or (f.Grid.Cells[0, 5] <> '新人') then
      raise Exception.Create('InsertRowWithValues 异常');
    f.Grid.DeleteRow(5);
    if f.Grid.RowCount <> 5 then
      raise Exception.Create('DeleteRow 异常');

    // 7) Options 断言
    if not (goEditing in f.Grid.Options) then
      raise Exception.Create('goEditing 应在 Options');
    if not (goFixedVertLine in f.Grid.Options) then      // 默认集保留
      raise Exception.Create('默认网格线选项不应丢失');

    WriteLn(Log, '首列顺序=', f.Grid.Cells[0, 1], ',',
      f.Grid.Cells[0, 2], ',', f.Grid.Cells[0, 3], ',', f.Grid.Cells[0, 4]);
    WriteLn(Log, '==== 19a selftest OK ====');
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
  with TGridForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
