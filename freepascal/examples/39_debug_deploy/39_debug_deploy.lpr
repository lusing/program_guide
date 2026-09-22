{$mode objfpc}{$codepage utf8}{$H+}{$ASSERTIONS ON}
program debug_deploy_demo;
{ 39 · 调试、性能与部署：LazLogger（DebugLn + TLazLoggerFile 落盘）、
  System.Assert（{$ASSERTIONS} 编译开关）、GetTickCount 微基准、
  发布体检（单文件 exe 的部署清单——LCL 静态链接无运行时依赖）。
  正文见 docs/39-debug-deploy.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Graphics, LazLogger,
  Classes, SysUtils, LCLIntf;

type
  TDebugForm = class(TForm)
    Info: TLabel;
    constructor Create(AOwner: TComponent); override;
  end;

constructor TDebugForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '39 · 调试与部署';
  Width := 460; Height := 220;
  Info := TLabel.Create(Self);
  Info.Parent := Self;
  Info.SetBounds(16, 12, 420, 180);
  Info.Caption := '本工程的知识点大多在"怎么编译、怎么跑"层面——看正文与 selftest';
end;

procedure RunSelfTest;
var
  f: TDebugForm;
  Log: TextFile;
  Lg: TLazLoggerFile;
  S: string;
  T0: Int64;
  I: Integer;
  N: Int64;                     // 坑（实测）：Integer 装不下 5×10^11——静默回绕
  ExeSize: Int64;
  Dbg: TextFile;
begin
  Application.Initialize;
  f := TDebugForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) LazLogger 落盘：TLazLoggerFile + SetDebugLogger（--debug-log 的程序版）
    SysUtils.DeleteFile('debug.log');
    Lg := TLazLoggerFile.Create;
    Lg.LogName := 'debug.log';
    SetDebugLogger(Lg);                 // 换全局 logger（默认写 stderr）
    DebugLn('selftest 写入的一行 debug');
    Lg.Finish;                          // 冲盘（析构也做，显式更稳）
    if not FileExists('debug.log') then
      raise Exception.Create('debug.log 未生成');
    AssignFile(Dbg, 'debug.log');
    Reset(Dbg);
    ReadLn(Dbg, S);
    CloseFile(Dbg);
    if Pos('selftest 写入的一行 debug', S) = 0 then
      raise Exception.Create('DebugLn 内容未落盘：' + S);
    WriteLn(Log, 'DebugLn 落盘 OK');

    // 2) Assert 语义（{$ASSERTIONS ON} 在本文件头）：False 必抛
    try
      Assert(1 = 2, '数学坏了');
      raise Exception.Create('Assert(False) 应抛 EAssertionFailed');
    except
      on E: EAssertionFailed do
        WriteLn(Log, 'Assert 抛错 OK：', E.Message);
    end;

    // 3) 微基准最小工具：GetTickCount64（毫秒）——测一段真实计算
    //    （首版 N 用 Integer：500000500000 回绕成 1784293664——无 {$R+} 静默错，
    //     自测断言当场抓获；这就是 selftest 的价值）
    T0 := GetTickCount64;
    N := 0;
    for I := 1 to 1000000 do
      N := N + I;
    WriteLn(Log, Format('100 万次累加=%d，耗时 %d ms', [N, GetTickCount64 - T0]));
    if N <> 500000500000 then
      raise Exception.Create('累加结果异常');

    // 4) 部署体检：单文件产物（LCL 静态链接——exe 不依赖 Lazarus 运行时）
    with TFileStream.Create(ParamStr(0), fmOpenRead or fmShareDenyNone) do
    try
      ExeSize := Size;
    finally
      Free;
    end;
    WriteLn(Log, 'exe=', ExtractFileName(ParamStr(0)), ' 大小=', ExeSize div 1024, ' KB');
    if ExeSize < 100 * 1024 then
      raise Exception.Create('LCL GUI exe 不可能小于 100KB——体检异常');

    WriteLn(Log, '==== 39 selftest OK ====');
  finally
    CloseFile(Log);
    SysUtils.DeleteFile('debug.log');
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
  with TDebugForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
