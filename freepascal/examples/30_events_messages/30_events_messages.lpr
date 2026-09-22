{$mode objfpc}{$codepage utf8}{$H+}
program events_messages_demo;
{ 30 · 事件系统与消息循环：事件=方法指针（ TObject 的发布机制）、消息三通道
  （Perform 同步 / PostMessage 异步 / SendMessage 直呼 WndProc）、自定义消息
  （LM_USER+n）与 WndProc 覆写拦截、Application.QueueAsyncCall 主线程排队、
  ProcessMessages 手动泵与重入陷阱。正文见 docs/30-events-messages.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Graphics,
  LCLIntf, LMessages, LCLType,
  Classes, SysUtils;

const
  LM_APP_PING = LM_USER + 100;    // 自定义消息：LM_USER($400) 起自编
  LM_APP_DATA = LM_USER + 101;

type
  TMsgForm = class(TForm)
    Info: TLabel;
    procedure HandlePing(var Msg: TLMessage); message LM_APP_PING;
  protected
    procedure WndProc(var TheMessage: TLMessage); override;   // 拦截层
  public
    WndHits: Integer;             // WndProc 里截到 LM_APP_* 的次数
    LastWParam: PtrInt;           // 最近一次的 WParam 证据
    PingCount: Integer;           // message 方法命中数
    AsyncDone: Boolean;           // QueueAsyncCall 回调证据
    AsyncData: PtrInt;
    constructor Create(AOwner: TComponent); override;
    procedure DoAsync(Data: PtrInt);
  end;

constructor TMsgForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '30 · 事件与消息';
  Width := 460; Height := 200;
  Info := TLabel.Create(Self);
  Info.Parent := Self;
  Info.SetBounds(16, 12, 420, 170);
  Info.Caption := 'selftest：Perform/PostMessage/QueueAsyncCall 三通道';
end;

procedure TMsgForm.WndProc(var TheMessage: TLMessage);
begin
  // 所有消息的必经之路（比事件更底层）——先记账再放行给 LCL 默认处理
  case TheMessage.Msg of
    LM_APP_PING, LM_APP_DATA:
      begin
        Inc(WndHits);
        LastWParam := TheMessage.WParam;
      end;
  end;
  inherited WndProc(TheMessage);   // 不转发 = 吞掉（默认绘制/鼠标全停摆）
end;

procedure TMsgForm.HandlePing(var Msg: TLMessage);
begin
  // message 指令：消息→方法的静态绑定（比 WndProc case 更"事件"的写法）
  Inc(PingCount);
end;

procedure TMsgForm.DoAsync(Data: PtrInt);
begin
  // QueueAsyncCall 的回调：在主线程消息循环里执行（线程安全的"回主线程"通道）
  AsyncDone := True;
  AsyncData := Data;
end;

procedure RunSelfTest;
var
  f: TMsgForm;
  Log: TextFile;
  I: Integer;
begin
  Application.Initialize;
  f := TMsgForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) Perform：同步直呼——发完 WndProc 已执行（不用泵）
    f.Perform(LM_APP_PING, 42, 0);                // 返回值视处理而定，只看副作用
    if (f.WndHits <> 1) or (f.LastWParam <> 42) then
      raise Exception.Create('Perform 应同步到达 WndProc');
    if f.PingCount <> 1 then
      raise Exception.Create('message 方法应命中');

    // 2) PostMessage：异步入队——发完还没到，泵了才到
    for I := 1 to 3 do
      PostMessage(f.Handle, LM_APP_DATA, I, 0);   // Handle 触发句柄创建
    if f.WndHits <> 1 then
      raise Exception.Create('PostMessage 泵前不应到达（实测异步语义）');
    for I := 1 to 20 do
      Application.ProcessMessages;                // 手动泵
    if f.WndHits <> 4 then
      raise Exception.Create(Format('泵后应到 3 条，实测共 %d', [f.WndHits - 1]));
    if f.LastWParam <> 3 then
      raise Exception.Create('队列应保序（最后 WParam=3）');

    // 3) QueueAsyncCall：LCL 的"回主线程"标准通道（28 章 Synchronize 的近亲）
    f.AsyncDone := False;
    Application.QueueAsyncCall(@f.DoAsync, 77);
    if f.AsyncDone then
      raise Exception.Create('异步调用泵前不应执行');
    Application.ProcessMessages;
    if (not f.AsyncDone) or (f.AsyncData <> 77) then
      raise Exception.Create('泵后应带参执行');

    // 4) 事件是方法指针：未挂接 = nil（挂接就是 @方法 的赋值——16 章起一直在用）
    if Assigned(f.OnClick) then
      raise Exception.Create('未挂接的 OnClick 应为 nil');

    WriteLn(Log, 'WndHits=', f.WndHits, ' PingCount=', f.PingCount,
      ' AsyncData=', f.AsyncData);
    WriteLn(Log, '==== 30 selftest OK ====');
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
  with TMsgForm.Create(nil) do
  begin
    Show;
    Application.Run;      // 主消息循环：Perform 的消息也从这走（无头验证已覆盖语义）
    Free;
  end;
end.
