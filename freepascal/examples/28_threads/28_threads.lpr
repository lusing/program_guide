{$mode objfpc}{$codepage utf8}{$H+}
program threads_demo;
{ 28 · 多线程与后台任务（⭐）：TThread/Execute、Synchronize vs Queue、
  TCriticalSection、进度回传、取消。正文见 docs/28-threads.md。
  selftest 策略：无消息循环的环境用 CheckSynchronize 手动泵 Synchronize 队列；
  全部断言跑主线程，等待用 WaitFor——确定性可验。 }

uses
  {$IFDEF UNIX}cthreads,{$ENDIF}   // ★ Unix 必须显式挂线程驱动，且是 uses 第一个：
                                   //   漏了它 Windows 上照样跑，Unix 上变运行期
                                   //   Runtime error 232 "no thread support compiled in"
  Interfaces, Forms, Controls, StdCtrls, ComCtrls, ExtCtrls,
  Classes, SysUtils, SyncObjs;

type
  TWorker = class(TThread)
  private
    FTotal: Int64;
    FProgressPct: Integer;               // Synchronize 之外的线程侧状态（受锁保护）
    FProgressSeen: Integer;              // 主线程侧收到的进度次数
    FCrit: TCriticalSection;             // 互斥锁：保护跨线程计数
    procedure DoReportProgress;          // 将由 Synchronize 在主线程执行
  protected
    procedure Execute; override;
  public
    ProgressLimit: Integer;              // 每隔多少进度汇报一次
    constructor Create;
    destructor Destroy; override;
    property Total: Int64 read FTotal;
    property ProgressSeen: Integer read FProgressSeen;
  end;

  TDemoForm = class(TForm)
    Progress: TProgressBar;
    Log: TMemo;
    StartBtn: TButton;
    CancelBtn: TButton;
    procedure StartBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
  public
    Worker: TWorker;    // 坑（实测）：非 TPersistent 后代不能放 published 段（TForm 默认段）
    constructor Create(AOwner: TComponent); override;
  end;

{ TWorker }

constructor TWorker.Create;
begin
  FCrit := TCriticalSection.Create;
  FProgressPct := 0;
  FProgressSeen := 0;
  ProgressLimit := 10;
  // CreateSuspended=False：Create 返回时线程已在跑
  // FreeOnTerminate 默认 False：主线程负责 Free（selftest 需要读它的属性）
  inherited Create(False);
end;

destructor TWorker.Destroy;
begin
  FCrit.Free;
  inherited Destroy;
end;

procedure TWorker.DoReportProgress;
begin
  // 这里运行在【主线程】——碰 LCL 控件只允许在此（铁律见正文）
  Inc(FProgressSeen);
end;

procedure TWorker.Execute;
var
  i: Integer;
begin
  FTotal := 0;
  for i := 1 to 1000 do
  begin
    if Terminated then                   // 取消协作点：循环里定期查
      Break;
    FTotal += i;
    if (i mod ProgressLimit = 0) then
    begin
      FCrit.Enter;                       // 锁内改共享状态，出来再 Synchronize
      try
        FProgressPct := i div 10;
      finally
        FCrit.Leave;
      end;
      Synchronize(@DoReportProgress);    // 投递到主线程执行（阻塞等它跑完）
    end;
  end;
end;

{ TDemoForm }

constructor TDemoForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '28 · 多线程';
  Width := 520; Height := 380;

  Progress := TProgressBar.Create(Self);
  Progress.Parent := Self;
  Progress.SetBounds(12, 12, 480, 20);
  Progress.Max := 100;

  StartBtn := TButton.Create(Self);
  StartBtn.Parent := Self;
  StartBtn.SetBounds(12, 44, 96, 30);
  StartBtn.Caption := '开始';
  StartBtn.OnClick := @StartBtnClick;

  CancelBtn := TButton.Create(Self);
  CancelBtn.Parent := Self;
  CancelBtn.SetBounds(116, 44, 96, 30);
  CancelBtn.Caption := '取消';
  CancelBtn.OnClick := @CancelBtnClick;

  Log := TMemo.Create(Self);
  Log.Parent := Self;
  Log.SetBounds(12, 84, 480, 250);
  Log.ReadOnly := True;
end;

procedure TDemoForm.StartBtnClick(Sender: TObject);
begin
  Worker := TWorker.Create;
  while not Worker.Finished do
  begin
    Application.ProcessMessages;        // 有消息循环时：泵消息顺带处理 Synchronize 队列
    Sleep(1);
  end;
  Worker.WaitFor;
  Progress.Position := 100;
  Log.Lines.Append(Format('完成：1..1000 和=%d，进度回调 %d 次',
    [Worker.Total, Worker.ProgressSeen]));
  Worker.Free;
  Worker := nil;
end;

procedure TDemoForm.CancelBtnClick(Sender: TObject);
begin
  if Worker <> nil then
    Worker.Terminate;                   // 只是设标志——线程在协作点自己退出
end;

procedure RunSelfTest;
var
  f: TDemoForm;
  w, w2: TWorker;
  Log: TextFile;
begin
  Application.Initialize;
  f := TDemoForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // ── 全量计算 + Synchronize 泵 ──
    w := TWorker.Create;
    while not w.Finished do
    begin
      CheckSynchronize;                 // 无消息循环：手动泵 Synchronize 队列
      Sleep(1);
    end;
    w.WaitFor;
    if w.Total <> 500500 then           // 1..1000 求和
      raise Exception.Create('计算结果异常');
    if w.ProgressSeen < 100 then        // i mod 10 = 0 共 100 次汇报
      raise Exception.Create('进度回调次数异常');
    WriteLn(Log, '全量：Total=', w.Total, ' 进度回调=', w.ProgressSeen, ' 次（CheckSynchronize 泵）');
    w.Free;

    // ── 取消协作：ProgressLimit 调大 + 立即 Terminate ──
    w2 := TWorker.Create;
    w2.Terminate;                       // 立刻请求取消——线程在第一个协作点退出
    while not w2.Finished do
    begin
      CheckSynchronize;
      Sleep(1);
    end;
    w2.WaitFor;
    WriteLn(Log, '取消：Total=', w2.Total, '（Terminate 后早期退出，远小于 500500）');
    if w2.Total = 500500 then
      raise Exception.Create('取消未生效');
    w2.Free;

    // ── Synchronize vs Queue 语义（文档型断言）──
    WriteLn(Log, 'Synchronize=阻塞至主线程执行完；Queue=投递即返回（要求线程活得够久）');
    WriteLn(Log, 'LCL 铁律：非主线程不得直接碰控件——一律经 Synchronize/Queue 中转');
    WriteLn(Log, '==== 28 selftest OK ====');
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
  with TDemoForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
