{$mode objfpc}{$codepage utf8}{$H+}
program form_lifecycle_demo;
{ 29 · 应用与窗体生命周期：TForm 事件顺序实测（OnCreate→OnShow→OnActivate→…
  →OnCloseQuery→OnClose→OnDestroy）、OnCloseQuery 的 CanClose 否决、
  OnClose 的 TCloseAction 四值语义、ModalResult 与 ShowModal 的关系、
  窗体继承（class(TBaseForm)+inherited lfm）。无头 selftest 不跑 ShowModal
  （会进模态循环挂死）——ModalResult 只测纯逻辑。正文见 docs/29-form-lifecycle.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Graphics,
  ubaseform { TBaseForm },
  uadvform { TAdvForm },
  Classes, SysUtils;

var
  DestroyRecorder: TStringList;   // OnDestroy 的外部见证（窗体死后 EvLog 读不了）

type
  TLifeForm = class(TForm)
    Info: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
  public
    EvLog: TStringList;        // 事件顺序记录（selftest 的证据链）
    VetoClose: Boolean;        // OnCloseQuery 否决开关
    NextAction: TCloseAction;  // OnClose 要返回的 Action
    constructor Create(AOwner: TComponent); override;
  end;

constructor TLifeForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '29 · 窗体生命周期';
  Width := 420; Height := 200;
  // 实测：先挂事件再 inherited？——CreateNew 不发 OnCreate；OnCreate 是 IDE 生成
  // 窗体的机制（Create 从流装配后回调）。纯代码窗体没有 OnCreate——
  // 构造器本体就是你的 OnCreate（正文展开）。
  OnShow := @FormShow;
  OnActivate := @FormActivate;
  OnDeactivate := @FormDeactivate;
  OnHide := @FormHide;
  OnCloseQuery := @FormCloseQuery;
  OnClose := @FormClose;
  OnDestroy := @FormDestroy;
  VetoClose := False;
  NextAction := caHide;
  EvLog := TStringList.Create;

  Info := TLabel.Create(Self);
  Info.Parent := Self;
  Info.SetBounds(16, 12, 380, 160);
  Info.Caption := '看 selftest.log 的事件顺序记录';
end;

procedure TLifeForm.FormCreate(Sender: TObject);
begin
  EvLog.Append('OnCreate');
end;

procedure TLifeForm.FormShow(Sender: TObject);
begin
  EvLog.Append('OnShow');
end;

procedure TLifeForm.FormActivate(Sender: TObject);
begin
  EvLog.Append('OnActivate');
end;

procedure TLifeForm.FormDeactivate(Sender: TObject);
begin
  EvLog.Append('OnDeactivate');
end;

procedure TLifeForm.FormHide(Sender: TObject);
begin
  EvLog.Append('OnHide');
end;

procedure TLifeForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  EvLog.Append('OnCloseQuery');
  CanClose := not VetoClose;    // 否决 = 记录"还有未保存"后拦下关闭
end;

procedure TLifeForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  EvLog.Append('OnClose');
  CloseAction := NextAction;    // caNone/caHide/caFree/caMinimize（正文表）
end;

procedure TLifeForm.FormDestroy(Sender: TObject);
begin
  EvLog.Append('OnDestroy');
  DestroyRecorder.Append('OnDestroy');   // 外部副本：窗体释放后仍可核对
end;

procedure RunSelfTest;
var
  f: TLifeForm;
  Log: TextFile;
  Adv: TAdvForm;
begin
  Application.Initialize;
  DestroyRecorder := TStringList.Create;
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  f := TLifeForm.Create(nil);   // CreateNew 路线：构造器=你的 OnCreate
  try
    // 1) Show 循环（不进 Run：Show→ProcessMessages→Close）
    f.Show;
    Application.ProcessMessages;
    if f.EvLog[0] <> 'OnShow' then
      raise Exception.Create('首个事件应 OnShow，实测=' + f.EvLog[0]);
    if f.EvLog.IndexOf('OnActivate') < 0 then
      raise Exception.Create('Show 后应有 OnActivate');
    if f.EvLog.IndexOf('OnActivate') < f.EvLog.IndexOf('OnShow') then
      raise Exception.Create('OnShow 应先于 OnActivate');
    WriteLn(Log, 'Show 序列: ', f.EvLog.CommaText);

    // 2) 正常关闭：OnCloseQuery(CanClose=True) → OnClose(caHide)
    f.Close;
    Application.ProcessMessages;
    if f.EvLog.IndexOf('OnCloseQuery') < 0 then
      raise Exception.Create('Close 应触发 OnCloseQuery');
    if f.EvLog.IndexOf('OnClose') < f.EvLog.IndexOf('OnCloseQuery') then
      raise Exception.Create('OnCloseQuery 应先于 OnClose');

    // 3) 否决：CanClose=False 时 Close 被拦（没有 OnClose、窗体还在）
    f.VetoClose := True;
    f.Show; Application.ProcessMessages;
    f.EvLog.Clear;
    f.Close;
    Application.ProcessMessages;
    if f.EvLog.IndexOf('OnClose') >= 0 then
      raise Exception.Create('否决后不应有 OnClose');
    if not f.Visible then
      raise Exception.Create('否决后窗体应仍可见');
    WriteLn(Log, '否决序列: ', f.EvLog.CommaText);

    // 4) TCloseAction 直呼语义（不真跑 caFree——Release 是异步的）
    f.VetoClose := False;
    f.FormClose(nil, f.NextAction);
    if f.NextAction <> caHide then
      raise Exception.Create('CloseAction 参数回写异常');

    // 5) ModalResult 纯逻辑（ShowModal 无头会挂——25 章纯逻辑核同思路）
    //    mrOk=1 mrCancel=2（ubaseform.lfm 里按钮设的就是这两个值）
    Adv := TAdvForm.Create(nil);
    try
      if Adv.BtnOk.ModalResult <> mrOk then
        raise Exception.Create('BtnOk.ModalResult 应 mrOk=1');
      if Adv.BtnCancel.ModalResult <> mrCancel then
        raise Exception.Create('BtnCancel.ModalResult 应 mrCancel=2');

      // 6) 窗体继承：父资源装配 + 根级差异 + is 判定
      if Adv.Caption <> '高级设置' then
        raise Exception.Create('inherited lfm 根级 Caption 应生效，实测=' + Adv.Caption);
      if Adv.LblTitle.Caption <> '高级设置（子窗体改的）' then
        raise Exception.Create('子控件覆盖（代码）应生效');
      if not (Adv is TBaseForm) then
        raise Exception.Create('TAdvForm 应 is TBaseForm');
      if (Adv.BtnOk = nil) or (Adv.BtnCancel = nil) then
        raise Exception.Create('父窗体按钮应被装配出来');
    finally
      Adv.Free;
    end;

    // 7) OnDestroy：Free 时最后一个事件（见证者在外部记录器）
    if f.EvLog.IndexOf('OnDestroy') >= 0 then
      raise Exception.Create('活着时不该有 OnDestroy');
    f.Free;
    f := nil;
    if DestroyRecorder.Count < 1 then
      raise Exception.Create('Free 应触发 OnDestroy');

    WriteLn(Log, '==== 29 selftest OK ====');
  finally
    if f <> nil then f.Free;    // 失败路径兜底（成功路径已在步骤 7 释放）
    CloseFile(Log);
    DestroyRecorder.Free;
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
  with TLifeForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
