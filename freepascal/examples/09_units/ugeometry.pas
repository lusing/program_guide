{$mode objfpc}{$codepage utf8}{$H+}
unit ugeometry;
{ 09 · 单元示范 1：几何计算单元——展示 interface/implementation 两段式、
  initialization/finalization、接口侧 uses。正文见 docs/09-units.md。 }

interface

uses SysUtils;                    // 接口段用到的单元必须在这里声明

type
  TPoint = record
    X, Y: Double;
  end;

function Distance(const a, b: TPoint): Double;
function RectArea(const a, b: TPoint): Double;
function UnitName: string;

var
  InitCount: Integer;             // initialization 段跑过几次（应恰为 1）

implementation

var
  LoadedAt: string;               // 私有：接口段看不见（外部无法访问）

function Distance(const a, b: TPoint): Double;
begin
  Result := Sqrt(Sqr(b.X - a.X) + Sqr(b.Y - a.Y));
end;

function RectArea(const a, b: TPoint): Double;
begin
  Result := Abs(b.X - a.X) * Abs(b.Y - a.Y);
end;

function UnitName: string;
begin
  Result := 'ugeometry（编译于 ' + LoadedAt + ' 编译期，见实现段）';
end;

initialization                    // 单元被加载时执行一次（在主程序 begin 之前）
  InitCount := 1;
  LoadedAt := {$I %DATE%};

finalization                      // 程序结束时执行（与 initialization 反序）
  InitCount := 0;

end.
