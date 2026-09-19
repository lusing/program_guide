{$mode objfpc}{$codepage utf8}{$H+}
unit ureport;
{ 09 · 单元示范 2：报表单元——展示"实现段 uses"（解循环引用的标准姿势）与
  单元间分层调用。正文见 docs/09-units.md。 }

interface

function ReportLine(const label_: string; value: Double): string;
function GeomSummary: string;

implementation

uses SysUtils, ugeometry;          // 实现段 uses：本段用到的单元在这里声明
                                  // （坑：每段 uses 各自负责，实现段用 Format 就得引 SysUtils）
                                  // 如果 ugeometry 反过来也要用本单元的接口，
                                  // 两边都把对方放实现段，循环引用即解

const
  FmtStr = '%s=%.2f';

function ReportLine(const label_: string; value: Double): string;
begin
  Result := Format(FmtStr, [label_, value]);
end;

function GeomSummary: string;
var
  a, b: TPoint;
begin
  a.X := 0; a.Y := 0;
  b.X := 3; b.Y := 4;
  Result := ReportLine('距离', Distance(a, b)) + ' / ' + ReportLine('面积', RectArea(a, b));
end;

end.
