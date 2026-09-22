{$mode objfpc}{$codepage utf8}{$H+}
program calendar_demo;
{ 18a · TCalendar 月历（unit Calendar）：DateTime 取所值、FirstDayOfWeek 周起始、
  OnChange 与 OnDayChanged 两个事件的分工（实测：程序赋值只发 OnChange，
  翻月不动所选日时连 OnChange 都不发）。日期语义配 DateUtils。正文见
  docs/18-picker-controls.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Calendar, Graphics,
  Classes, SysUtils, DateUtils;

type
  TCalForm = class(TForm)
    Cal: TCalendar;
    InfoLbl: TLabel;
    EventLbl: TLabel;
    procedure CalChange(Sender: TObject);
    procedure CalDayChanged(Sender: TObject);
  public
    // 坑（实测）：FPC 的 published 区只放类类型字段——Integer 计数器必须显式 public
    ChangeCount, DayChangedCount: Integer;
    constructor Create(AOwner: TComponent); override;
  end;

constructor TCalForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '18a · Calendar 月历';
  Width := 460; Height := 400;

  Cal := TCalendar.Create(Self);
  Cal.Parent := Self;
  Cal.SetBounds(16, 12, 260, 180);
  Cal.FirstDayOfWeek := dowMonday;    // 周一开头（默认 dowLocale 跟系统）
  Cal.DateTime := EncodeDate(2026, 9, 22);
  Cal.OnChange := @CalChange;
  Cal.OnDayChanged := @CalDayChanged;

  InfoLbl := TLabel.Create(Self);
  InfoLbl.Parent := Self;
  InfoLbl.SetBounds(292, 12, 150, 160);
  InfoLbl.Caption := '';

  EventLbl := TLabel.Create(Self);
  EventLbl.Parent := Self;
  EventLbl.SetBounds(16, 200, 430, 160);
  EventLbl.Caption := '点日期 / 翻月，看两个事件的分工';
end;

function CnWeekDay(D: TDateTime): string;   // 1=周一 … 7=周日
const
  Names: array[1..7] of string = ('一', '二', '三', '四', '五', '六', '日');
begin
  Result := Names[DayOfTheWeek(D)];
end;

procedure TCalForm.CalChange(Sender: TObject);
begin
  Inc(ChangeCount);
  InfoLbl.Caption := Format('%s%s星期%s%s当年第 %d 天',
    [FormatDateTime('yyyy-mm-dd', Cal.DateTime), #10,
     CnWeekDay(Cal.DateTime), #10, DayOfTheYear(Cal.DateTime)]);
  EventLbl.Caption := Format('OnChange=%d 次   OnDayChanged=%d 次',
    [ChangeCount, DayChangedCount]);
end;

procedure TCalForm.CalDayChanged(Sender: TObject);
begin
  Inc(DayChangedCount);
end;

procedure RunSelfTest;
var
  f: TCalForm;
  Log: TextFile;
begin
  Application.Initialize;
  f := TCalForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 所选日期回环（TDateTime 是天为单位的浮点）
    if f.Cal.DateTime <> EncodeDate(2026, 9, 22) then
      raise Exception.Create('Calendar 所选日期异常');
    if (YearOf(f.Cal.DateTime) <> 2026) or (MonthOf(f.Cal.DateTime) <> 9)
      or (DayOf(f.Cal.DateTime) <> 22) then
      raise Exception.Create('Year/Month/Day 分解异常');

    // 2) 程序赋值两个事件都不发（实测：与 TrackBar 的"程序赋值也触发"正相反！
    //    OnChange 只属于用户交互）
    f.ChangeCount := 0; f.DayChangedCount := 0;
    f.Cal.DateTime := EncodeDate(2026, 10, 1);
    if f.Cal.DateTime <> EncodeDate(2026, 10, 1) then
      raise Exception.Create('改选 10-1 失败');
    if (f.ChangeCount <> 0) or (f.DayChangedCount <> 0) then
      raise Exception.Create(Format('程序赋值不应触发事件，实测 OnChange=%d OnDayChanged=%d',
        [f.ChangeCount, f.DayChangedCount]));
    WriteLn(Log, '程序改日: OnChange=', f.ChangeCount,
      ' OnDayChanged=', f.DayChangedCount);

    // 3) 周起始回环
    if f.Cal.FirstDayOfWeek <> dowMonday then
      raise Exception.Create('FirstDayOfWeek 回环异常');
    f.Cal.FirstDayOfWeek := dowSunday;
    if f.Cal.FirstDayOfWeek <> dowSunday then
      raise Exception.Create('FirstDayOfWeek 二段回环异常');
    f.Cal.FirstDayOfWeek := dowMonday;

    // 4) 日期算术：IncMonth 翻月、DayOfTheWeek/DayOfTheYear 语义
    f.Cal.DateTime := IncMonth(EncodeDate(2026, 9, 22), 3);   // +3 月 → 2026-12-22
    if FormatDateTime('yyyy-mm-dd', f.Cal.DateTime) <> '2026-12-22' then
      raise Exception.Create('IncMonth +3 异常');
    if DayOfTheWeek(EncodeDate(2026, 9, 22)) <> 2 then        // 周二
      raise Exception.Create('DayOfTheWeek 语义异常（2026-09-22 应为周二=2）');
    if DayOfTheYear(EncodeDate(2026, 1, 1)) <> 1 then
      raise Exception.Create('DayOfTheYear 元旦应=1');

    // 5) 月末语义：1月31日 +1月 → 2月28日（IncMonth 钳到月末，不跨溢出）
    if FormatDateTime('yyyy-mm-dd', IncMonth(EncodeDate(2026, 1, 31), 1)) <> '2026-02-28' then
      raise Exception.Create('IncMonth 月末钳制异常');

    WriteLn(Log, '所选=', FormatDateTime('yyyy-mm-dd', f.Cal.DateTime));
    WriteLn(Log, '==== 18a selftest OK ====');
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
  with TCalForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
