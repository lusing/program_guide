{$mode objfpc}{$codepage utf8}{$H+}
unit uchecks;
{ 40 · 迷你断言单元——"自制测试框架"的落地（正文 40.8 节）。
  设计动机：selftest 构建没开 -Sa（Assert 蒸发不了也编不进），且 GUI 程序的
  Assert 失败会弹 LCL 框挂死无头环境。Check/CheckEq 全部走"记数 + 失败抛异常
  （被 selftest 外层捕获写日志）"，与语言篇的 Assert 双通道互为镜像。 }

interface

var
  CheckPass: Integer = 0;
  CheckFail: Integer = 0;

procedure Check(Cond: Boolean; const Msg: string);
procedure CheckEqInt(Got, Want: Int64; const Msg: string);
procedure CheckEqStr(const Got, Want: string; const Msg: string);
function CheckSummary: string;

implementation

uses SysUtils;

procedure Fail(const Msg: string; const Detail: string);
begin
  Inc(CheckFail);
  if Detail <> '' then
    raise Exception.Create(Format('%s：%s', [Msg, Detail]))
  else
    raise Exception.Create(Msg);
end;

procedure Check(Cond: Boolean; const Msg: string);
begin
  if Cond then
    Inc(CheckPass)
  else
    Fail(Msg, '');
end;

procedure CheckEqInt(Got, Want: Int64; const Msg: string);
begin
  if Got = Want then
    Inc(CheckPass)
  else
    Fail(Msg, Format('得到 %d，期望 %d', [Got, Want]));
end;

procedure CheckEqStr(const Got, Want: string; const Msg: string);
begin
  if Got = Want then
    Inc(CheckPass)
  else
    Fail(Msg, Format('得到 "%s"，期望 "%s"', [Got, Want]));
end;

function CheckSummary: string;
begin
  Result := Format('断言 %d 通过 / %d 失败', [CheckPass, CheckFail]);
end;

end.
