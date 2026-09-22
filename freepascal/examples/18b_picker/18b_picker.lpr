{$mode objfpc}{$codepage utf8}{$H+}
program picker_demo;
{ 18b · TDateTimePicker（在独立包 DateTimeCtrls 里的单元 DateTimePicker——
  .lpi 的 RequiredPackages 要加包，uses 要引单元，这是"LCL 基础包之外第一课"）：
  Kind=dtkDate/dtkTime/dtkDateTime 三形态、MinDate/MaxDate 值域、
  ShowCheckBox+Checked 可空选择、TimeFormat=tf12/tf24 小时制。正文见
  docs/18-picker-controls.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, DateTimePicker, Graphics,
  Classes, SysUtils, DateUtils, StrUtils;

type
  TPickerForm = class(TForm)
    DatePick: TDateTimePicker;   // 日期形态
    TimePick: TDateTimePicker;   // 时间形态
    OptionalPick: TDateTimePicker;  // 带勾选框的可空日期
    InfoLbl: TLabel;
    procedure PickChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

constructor TPickerForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '18b · DateTimePicker';
  Width := 420; Height := 300;

  with TLabel.Create(Self) do
  begin
    Parent := Self; SetBounds(16, 12, 200, 20);
    Caption := '日期（Kind=dtkDate）';
  end;

  DatePick := TDateTimePicker.Create(Self);
  DatePick.Parent := Self;
  DatePick.SetBounds(16, 36, 180, 28);
  DatePick.Kind := dtkDate;
  DatePick.DateTime := EncodeDate(2026, 9, 22);
  DatePick.MinDate := EncodeDate(2026, 1, 1);    // 值域：下限
  DatePick.MaxDate := EncodeDate(2026, 12, 31);  // 上限（日历越界日变灰）
  DatePick.OnChange := @PickChange;

  with TLabel.Create(Self) do
  begin
    Parent := Self; SetBounds(216, 12, 200, 20);
    Caption := '时间（Kind=dtkTime）';
  end;

  TimePick := TDateTimePicker.Create(Self);
  TimePick.Parent := Self;
  TimePick.SetBounds(216, 36, 170, 28);
  TimePick.Kind := dtkTime;
  TimePick.TimeFormat := tf24;                  // 24 小时制（TTimeFormat 只有 tf12/tf24）
  TimePick.DateTime := EncodeTime(14, 30, 5, 0);
  TimePick.OnChange := @PickChange;

  with TLabel.Create(Self) do
  begin
    Parent := Self; SetBounds(16, 76, 380, 20);
    Caption := '可空日期（ShowCheckBox：不勾=未选择）';
  end;

  OptionalPick := TDateTimePicker.Create(Self);
  OptionalPick.Parent := Self;
  OptionalPick.SetBounds(16, 100, 180, 28);
  OptionalPick.Kind := dtkDate;
  OptionalPick.DateTime := Date;                 // 今天（Now/Date 系统时间）
  OptionalPick.ShowCheckBox := True;
  OptionalPick.Checked := False;                 // 未勾选 = 表单里的"无日期"

  InfoLbl := TLabel.Create(Self);
  InfoLbl.Parent := Self;
  InfoLbl.SetBounds(16, 144, 390, 120);
  PickChange(nil);
end;

procedure TPickerForm.PickChange(Sender: TObject);
begin
  InfoLbl.Caption := Format('日期：%s%s时间：%s%s可选日期：%s',
    [FormatDateTime('yyyy-mm-dd', DatePick.DateTime), #10,
     FormatDateTime('hh:nn:ss', TimePick.DateTime), #10,
     IfThen(OptionalPick.Checked, FormatDateTime('yyyy-mm-dd', OptionalPick.DateTime), '（未勾选）')]);
end;

procedure RunSelfTest;
var
  f: TPickerForm;
  Log: TextFile;
begin
  Application.Initialize;
  f := TPickerForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 日期回环
    if f.DatePick.DateTime <> EncodeDate(2026, 9, 22) then
      raise Exception.Create('Picker 日期回环异常');

    // 2) 越界钳制（低于 MinDate）
    f.DatePick.DateTime := EncodeDate(2025, 6, 1);
    if f.DatePick.DateTime < f.DatePick.MinDate then
      raise Exception.Create('低于 MinDate 应被钳起');

    // 3) Kind 双形态回环
    f.TimePick.Kind := dtkDate;
    if f.TimePick.Kind <> dtkDate then
      raise Exception.Create('Kind 切换回环异常');
    f.TimePick.Kind := dtkTime;

    // 4) TimeFormat 回环（只有 tf12/tf24——12/24 小时制，不是"粒度"）
    if f.TimePick.TimeFormat <> tf24 then
      raise Exception.Create('TimeFormat 回环异常');

    // 5) 勾选框语义：Checked=False 表"无值"（配 NullInputAllowed 讲正文）
    if f.OptionalPick.Checked then
      raise Exception.Create('可选日期初值应为未勾选');
    f.OptionalPick.Checked := True;
    if not f.OptionalPick.Checked then
      raise Exception.Create('勾选回环异常');

    // 6) 时间部分独立（TDateTime 浮点：小数部分=时间）
    f.TimePick.DateTime := EncodeTime(23, 59, 59, 0);
    if Abs(f.TimePick.DateTime - Frac(EncodeTime(23, 59, 59, 0))) > 1e-9 then
      raise Exception.Create('时间分量语义异常');
    if HourOfTheDay(f.TimePick.DateTime) <> 23 then
      raise Exception.Create('HourOf 语义异常');

    WriteLn(Log, 'Date=', FormatDateTime('yyyy-mm-dd', f.DatePick.DateTime),
      ' Time=', FormatDateTime('hh:nn:ss', f.TimePick.DateTime));
    WriteLn(Log, '==== 18b selftest OK ====');
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
  with TPickerForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
