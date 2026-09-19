{$mode objfpc}{$codepage utf8}{$H+}
program lazarus_hello;
{ 15 · Lazarus 入门工程：.lpr 主程序 + .lpi 工程文件 + uhelloform.pas/.lfm 窗体对。
  --selftest 分支：无头建窗体验证 lfm 流加载与事件（写 selftest.log 后退出）。
  正文见 docs/15-lazarus.md。 }

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,                       // Linux 下多线程 LCL 需要它（Windows 不用）
  {$ENDIF}{$ENDIF}
  Interfaces,                    // ⚠️ 必须是 LCL 单元之首（ctheads 除外）——漏了它
                                 //    链接器报 "unit Interfaces missing" 类错误
  Forms, Classes, SysUtils,
  uhelloform { MainForm };

procedure RunSelfTest;
var
  f: TMainForm;
  Log: TextFile;
begin
  Application.Initialize;
  f := TMainForm.Create(nil);            // 不 Show：流机制照样按 lfm 建控件
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    WriteLn(Log, 'Caption=', f.Caption);
    WriteLn(Log, 'BtnHello=/', f.BtnHello <> nil, '/ Caption=', f.BtnHello.Caption);
    WriteLn(Log, 'LblMessage=/', f.LblMessage <> nil, '/ Caption=', f.LblMessage.Caption);
    WriteLn(Log, 'ControlCount=', f.ControlCount);
    // 直接调事件方法（不点鼠标）：验证处理器逻辑
    f.BtnHelloClick(nil);
    WriteLn(Log, 'AfterClick LblMessage=', f.LblMessage.Caption);
    // 断言自检（selftest 构建未开 -Sa，用显式检查写日志）
    if (f.BtnHello = nil) or (f.LblMessage = nil) then
      raise Exception.Create('lfm 流加载失败：published 字段未填充');
    if f.BtnHello.Caption <> '问好' then
      raise Exception.Create('lfm 中文 Caption 加载异常');
    if f.LblMessage.Caption <> '你好，Lazarus！' then
      raise Exception.Create('事件处理器未生效');
    if f.ControlCount <> 2 then
      raise Exception.Create('控件数量异常');
    WriteLn(Log, '==== 15 selftest OK ====');
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
      // GUI 程序未捕获异常会弹 LCL 消息框（无头环境挂死）——selftest 必须自捕获
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
  Application.CreateForm(TMainForm, MainForm);   // 正常路径：IDE 向导的标准形态
  Application.Run;
end.
