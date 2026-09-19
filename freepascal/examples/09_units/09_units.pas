{$mode objfpc}{$codepage utf8}{$H+}
program units_demo;
{ 09 · 单元与工程组织：unit 两段式、uses 位置、initialization/finalization、
  多文件编译、条件编译。正文见 docs/09-units.md。
  本示例是三文件工程：09_units.pas + ugeometry.pas + ureport.pas
  （fpc 编主程序自动拉单元，脚本 -Fu 本目录）。 }
uses SysUtils, ugeometry, ureport;

var
  a, b: TPoint;

// ═══ 9.4 条件编译：一个源码服务多个方言/平台
procedure ShowIfDef;
begin
  // {$DEFINE} 可写在任意声明处或从命令行 -dDEMO_FEATURE 传入（别放进 const 段——
  // 实测会报 "identifier expected but BEGIN found"）
  {$DEFINE DEMO_FEATURE}
  {$IFDEF DEMO_FEATURE}
  WriteLn('  {$IFDEF DEMO_FEATURE} 生效：特性代码被编入');
  {$ELSE}
  WriteLn('  不会到达——DEF 未定义时这段根本不进产物');
  {$ENDIF}
  {$IFDEF WINDOWS}
  WriteLn('  WINDOWS 符号由编译器预定义（还有 LINUX/DARWIN/CPU64/CPUX86_64 等）');
  {$ENDIF}
  Assert({$IFDEF CPU64}True{$ELSE}False{$ENDIF}, '主线 win64：CPU64 预定义');
  // {$MODE OBJFPC} 也能在单元里逐个设置方言（本工程统一写在文件头）
end;

begin
  WriteLn('═══ 9.1 两段式单元：interface 对外，implementation 藏私');
  a.X := 0; a.Y := 0;
  b.X := 3; b.Y := 4;
  Assert(Abs(Distance(a, b) - 5) < 1e-12);
  Assert(RectArea(a, b) = 12);
  WriteLn('  Distance(0,0 → 3,4) = ', Distance(a, b):0:1, '  RectArea = ', RectArea(a, b):0:1);
  // ureport. 也能显式限定：ureport.ReportLine(...)——两个单元同名时必用
  WriteLn('  ', ureport.ReportLine('显式限定', 1.5));

  WriteLn('═══ 9.2 initialization 在主程序 begin 之前已跑');
  Assert(ugeometry.InitCount = 1, 'initialization 恰好执行一次');
  WriteLn('  InitCount=', ugeometry.InitCount, '（main 的第一行代码之前已置 1）');
  WriteLn('  UnitName=', UnitName);

  WriteLn('═══ 9.3 单元间分层：ureport 的实现段 uses ugeometry');
  WriteLn('  ', GeomSummary);

  WriteLn('═══ 9.4 条件编译');
  ShowIfDef;

  WriteLn('═══ 9.5 编译与增量');
  WriteLn('  fpc 编主程序自动在 -Fu 路径找 ugeometry/ureport 并编译；');
  WriteLn('  产物 .ppu/.o 缓存，单元没改动就不重编（-B 强制全量重建）');

  WriteLn;
  WriteLn('==== 09 结束 ====');
end.
