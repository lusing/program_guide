{$mode objfpc}{$codepage utf8}{$H+}
program colorbox_demo;
{ 18c · TColorBox 与 TColorListBox（unit ColorBox）：Style 集合决定下拉里有哪些色
  （cbStandardColors/cbExtendedColors/cbSystemColors/cbIncludeNone/cbIncludeDefault/
  cbPrettyNames/cbCustomColors+OnGetColors 自定义）、Selected 取色、
  TColor 的 BGR 位布局与 ColorToString/StringToColor 互转。正文见
  docs/18-picker-controls.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, ColorBox, Graphics,
  Classes, SysUtils;

type
  TColorForm = class(TForm)
    Box: TColorBox;
    List: TColorListBox;
    Preview: TPanel;
    RgbLbl: TLabel;
    procedure SelChange(Sender: TObject);
    // 坑（实测）：LCL 的 TGetColorsEvent 首参是具体类型 TCustomColorBox 而非 TObject
    procedure BoxGetColors(Sender: TCustomColorBox; AItems: TStrings);
  public
    constructor Create(AOwner: TComponent); override;
  end;

constructor TColorForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '18c · ColorBox / ColorListBox';
  Width := 460; Height := 420;

  with TLabel.Create(Self) do
  begin
    Parent := Self; SetBounds(16, 12, 380, 20);
    Caption := '下拉选色（cbPrettyNames：显示"红"而非 clRed）';
  end;

  Box := TColorBox.Create(Self);
  Box.Parent := Self;
  Box.SetBounds(16, 36, 240, 26);
  // 顺序敏感（实测）：先挂 OnGetColors 再设 Style——Style 赋值触发条目重建，
  // 先设 Style 再挂事件，自定义色就不会出现在首轮条目里
  Box.OnGetColors := @BoxGetColors;   // cbCustomColors 开着才回调：追加自定义色
  Box.Style := [cbStandardColors, cbExtendedColors, cbSystemColors,
    cbIncludeDefault, cbPrettyNames, cbCustomColors];
  Box.Selected := clRed;
  Box.OnChange := @SelChange;

  with TLabel.Create(Self) do
  begin
    Parent := Self; SetBounds(16, 72, 380, 20);
    Caption := '列表选色（同样一套 Style 语义）';
  end;

  List := TColorListBox.Create(Self);
  List.Parent := Self;
  List.SetBounds(16, 96, 240, 200);
  List.Style := Box.Style;
  List.Selected := clBlue;

  Preview := TPanel.Create(Self);
  Preview.Parent := Self;
  Preview.SetBounds(272, 36, 160, 120);
  Preview.Caption := '';
  Preview.Color := Box.Selected;

  RgbLbl := TLabel.Create(Self);
  RgbLbl.Parent := Self;
  RgbLbl.SetBounds(272, 168, 170, 120);
  SelChange(nil);
end;

procedure TColorForm.BoxGetColors(Sender: TCustomColorBox; AItems: TStrings);
begin
  // 自定义色：TColor($00BGR 布局) 追加两项（cbCustomColors 触发）
  AItems.AddObject('品牌蓝', TObject(PtrUInt($CC6633)));  // BGR: B=CC G=66 R=33
  AItems.AddObject('奶油白', TObject(PtrUInt($F0F8E8)));
end;

procedure TColorForm.SelChange(Sender: TObject);
var
  C: TColor;
begin
  C := ColorToRGB(Box.Selected);      // 系统色(clBtnFace 等)解析成具体 RGB
  Preview.Color := Box.Selected;
  // TColor 低 24 位按 BGR 排布：低字节=蓝、中=绿、高=红
  RgbLbl.Caption := Format('R=%d  G=%d  B=%d%s识别名=%s', [
    (C shr 16) and $FF, (C shr 8) and $FF, C and $FF, #10,
    ColorToString(Box.Selected)]);
end;

procedure RunSelfTest;
var
  f: TColorForm;
  Log: TextFile;
  BaseCount: Integer;
begin
  Application.Initialize;
  f := TColorForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) Selected 回环
    if f.Box.Selected <> clRed then
      raise Exception.Create('ColorBox Selected 初值异常');
    f.Box.Selected := clGreen;
    if f.Box.Selected <> clGreen then
      raise Exception.Create('Selected 回环异常');

    // 2) Style 增减 → 条目数变化（cbSystemColors 一族占大头）
    BaseCount := f.Box.Items.Count;
    f.Box.Style := f.Box.Style - [cbSystemColors];
    if f.Box.Items.Count >= BaseCount then
      raise Exception.Create('去掉 cbSystemColors 条目应减少');
    f.Box.Style := f.Box.Style + [cbSystemColors];
    if f.Box.Items.Count <> BaseCount then
      raise Exception.Create('恢复 Style 条目数应一致');

    // 3) 自定义色生效（OnGetColors 追加了 2 项）
    if f.Box.Items.IndexOf('品牌蓝') < 0 then
      raise Exception.Create('OnGetColors 自定义色未出现');

    // 4) cbPrettyNames：显示名友好（记录实测；IndexOfObject 按色值找下标）
    BaseCount := f.Box.Items.IndexOfObject(TObject(PtrUInt(clRed)));
    if BaseCount < 0 then
      raise Exception.Create('clRed 应在下拉条目里');
    WriteLn(Log, '第0项=', f.Box.Items[0], '  clRed 显示名=', f.Box.Items[BaseCount]);

    // 5) ColorToString / StringToColor 互转（识别名体系）
    if ColorToString(clRed) <> 'clRed' then
      raise Exception.Create('ColorToString(clRed) 应为 clRed，实测=' + ColorToString(clRed));
    if StringToColor('clRed') <> clRed then
      raise Exception.Create('StringToColor 回环异常');
    if StringToColor('$0000FF') <> clRed then      // $00BBGGRR：FF 在低位是蓝？不——
      raise Exception.Create('$0000FF 语义异常');   // $0000FF=红? 见正文 BGR 布局表

    // 6) RGBToColor 与位分解互逆（R=51 G=102 B=204 → $00BBGGRR = $CC6633）
    if RGBToColor(51, 102, 204) <> TColor($CC6633) then
      raise Exception.Create('RGBToColor BGR 布局异常');
    f.Preview.Color := $CC6633;
    if ColorToRGB(f.Preview.Color) <> $CC6633 then
      raise Exception.Create('ColorToRGB 回环异常');

    // 7) ColorListBox Selected 回环
    f.List.Selected := clGreen;
    if f.List.Selected <> clGreen then
      raise Exception.Create('ColorListBox Selected 回环异常');

    WriteLn(Log, 'Items.Count=', f.Box.Items.Count);
    WriteLn(Log, '==== 18c selftest OK ====');
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
  with TColorForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
