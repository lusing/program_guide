{$mode objfpc}{$codepage utf8}{$H+}
program menus_demo;
{ 19 · 菜单、工具栏与 Action：TMainMenu/TPopupMenu、快捷键、TActionList 统一命令
  （菜单/工具栏/快捷键三绑定）、TStatusBar 窗格。正文见 docs/19-menus.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ComCtrls, ActnList, Menus, ExtCtrls,
  Classes, SysUtils;

function AddActionItem(AParent: TMenuItem; A: TAction): TMenuItem;
begin
  Result := TMenuItem.Create(A);
  Result.Action := A;                    // Caption/快捷键/Enabled 全由 Action 供给
  AParent.Add(Result);
end;

function MakeMenu(const ACaption: string; const AActs: array of TAction): TMenuItem;
var
  i: Integer;
begin
  Result := TMenuItem.Create(Application);
  Result.Caption := ACaption;
  for i := 0 to High(AActs) do
    AddActionItem(Result, AActs[i]);
end;

type
  TDemoForm = class(TForm)
    MenuBar: TMainMenu;
    Popup: TPopupMenu;
    Actions: TActionList;
    Toolbar: TToolBar;
    Status: TStatusBar;
    Log: TMemo;
    ActNew, ActOpen, ActAbout: TAction;
    ToolNew, ToolOpen, ToolAbout: TToolButton;
    procedure ActNewExecute(Sender: TObject);
    procedure ActOpenExecute(Sender: TObject);
    procedure ActAboutExecute(Sender: TObject);
    procedure ActionsUpdate(AAction: TBasicAction; var Handled: Boolean);
  public
    NewCount: Integer;
    constructor Create(AOwner: TComponent); override;
  end;

constructor TDemoForm.Create(AOwner: TComponent);
var
  mFile, mHelp: TMenuItem;
begin
  inherited CreateNew(AOwner);
  Caption := '19 · 菜单与 Action';
  Width := 560; Height := 420;

  // ── 先造 Action：命令的"单一事实来源" ──
  Actions := TActionList.Create(Self);

  ActNew := TAction.Create(Self);
  ActNew.ActionList := Actions;
  ActNew.Caption := '新建(&N)';
  ActNew.Hint := '新建文档';
  ActNew.ShortCut := ShortCut(Ord('N'), [ssCtrl]);   // Ctrl+N（用 ShortCut() 组合，别写魔数）
  ActNew.OnExecute := @ActNewExecute;

  ActOpen := TAction.Create(Self);
  ActOpen.ActionList := Actions;
  ActOpen.Caption := '打开(&O)...';
  ActOpen.ShortCut := ShortCut(Ord('O'), [ssCtrl]);
  ActOpen.OnExecute := @ActOpenExecute;

  ActAbout := TAction.Create(Self);
  ActAbout.ActionList := Actions;
  ActAbout.Caption := '关于(&A)';
  ActAbout.OnExecute := @ActAboutExecute;

  Actions.OnUpdate := @ActionsUpdate;    // 空闲时批量刷新动作状态

  // ── 菜单栏：菜单项挂 Action ──
  // 坑（实测）①：字段别叫 Menu——TForm.Menu 是现成属性（Duplicate identifier）；
  // ② MenuItem.Add 只收 TMenuItem，挂 Action 要"包一层菜单项"再设 .Action（辅助函数）；
  // ③ with 块里 Self 仍指窗体不是 with 变量——别玩 with 花活
  MenuBar := TMainMenu.Create(Self);
  mFile := MakeMenu('文件(&F)', [ActNew, ActOpen]);
  MenuBar.Items.Add(mFile);
  mHelp := MakeMenu('帮助(&H)', [ActAbout]);
  MenuBar.Items.Add(mHelp);

  // ── 弹出菜单：同一个 Action 再绑一处 ──
  Popup := TPopupMenu.Create(Self);
  AddActionItem(Popup.Items, ActNew);
  AddActionItem(Popup.Items, ActOpen);
  AddActionItem(Popup.Items, ActAbout);

  // ── 工具栏：工具按钮也挂同一个 Action（第三处绑定）──
  Toolbar := TToolBar.Create(Self);
  Toolbar.Parent := Self;
  Toolbar.Align := alTop;
  Toolbar.ButtonHeight := 28;
  Toolbar.ButtonWidth := 32;
  ToolNew := TToolButton.Create(Self);
  ToolNew.Parent := Toolbar;
  ToolNew.Action := ActNew;              // 按钮的 Caption/Hint/OnClick 全由 Action 供给
  ToolOpen := TToolButton.Create(Self);
  ToolOpen.Parent := Toolbar;
  ToolOpen.Action := ActOpen;
  ToolAbout := TToolButton.Create(Self);
  ToolAbout.Parent := Toolbar;
  ToolAbout.Action := ActAbout;

  // ── 状态栏：三窗格 ──
  Status := TStatusBar.Create(Self);
  Status.Parent := Self;
  Status.Align := alBottom;
  Status.SimplePanel := False;
  Status.Panels.Add.Width := 200;        // 窗格 0：宽 200
  Status.Panels.Add.Width := 150;        // 窗格 1
  Status.Panels.Add;                     // 窗格 2：吃掉剩余宽度
  Status.Panels[0].Text := '就绪';
  Status.Panels[1].Text := 'Ctrl+N 新建';

  // ── 日志区 ──
  Log := TMemo.Create(Self);
  Log.Parent := Self;
  Log.Align := alClient;
  Log.ReadOnly := True;
end;

procedure TDemoForm.ActNewExecute(Sender: TObject);
begin
  Inc(NewCount);
  Log.Lines.Append(Format('[新建] 第 %d 次', [NewCount]));
  Status.Panels[0].Text := Format('新建了 %d 个', [NewCount]);
end;

procedure TDemoForm.ActOpenExecute(Sender: TObject);
begin
  Log.Lines.Append('[打开] 20 章换真对话框');
  Status.Panels[0].Text := '打开命令';
end;

procedure TDemoForm.ActAboutExecute(Sender: TObject);
begin
  Log.Lines.Append('[关于] 菜单与 Action 演示');
end;

procedure TDemoForm.ActionsUpdate(AAction: TBasicAction; var Handled: Boolean);
begin
  // OnUpdate：应用空闲时轮询——把"能不能用"集中在一处
  if AAction = ActOpen then
    ActOpen.Enabled := NewCount > 0;     // 打开只有新建过才可用（演示状态同步）
  Handled := False;                      // False = 继续默认处理
end;

procedure RunSelfTest;
var
  f: TDemoForm;
  Log: TextFile;
  h: Boolean;
begin
  Application.Initialize;
  f := TDemoForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 菜单结构
    if f.MenuBar.Items.Count <> 2 then
      raise Exception.Create('顶级菜单数量异常');
    if f.MenuBar.Items[0].Count <> 2 then
      raise Exception.Create('文件菜单项数量异常');
    WriteLn(Log, '菜单：顶级=', f.MenuBar.Items.Count, ' 文件子项=', f.MenuBar.Items[0].Count);
    WriteLn(Log, '文件[0].Caption=', f.MenuBar.Items[0][0].Caption,
      ' ShortCut值=', f.MenuBar.Items[0][0].ShortCut, '（Ctrl+N）');

    // 弹出菜单共享同一 Action
    if f.Popup.Items.Count <> 3 then
      raise Exception.Create('弹出菜单项数量异常');
    if f.Popup.Items[0].Action <> f.ActNew then
      raise Exception.Create('弹出菜单未共享 Action');
    WriteLn(Log, 'Popup[0] 与菜单/工具栏共享 ActNew ✓');

    // Action.Execute：直接执行命令（等效点击）
    f.ActNew.Execute;
    f.ActNew.Execute;
    if f.NewCount <> 2 then
      raise Exception.Create('Action 执行计数异常');
    if Pos('第 2 次', f.Log.Text) = 0 then
      raise Exception.Create('Action 日志未记录');
    if f.Status.Panels[0].Text <> '新建了 2 个' then
      raise Exception.Create('状态栏窗格未更新');
    WriteLn(Log, 'ActNew.Execute x2 → NewCount=2，状态栏=', f.Status.Panels[0].Text);

    // OnUpdate 状态同步（工具栏/菜单的 Enabled 由 Action 统一供给）
    h := False;
    f.ActOpen.Enabled := False;          // 先关掉，看 OnUpdate 能否打开
    f.ActionsUpdate(f.ActOpen, h);
    if not f.ActOpen.Enabled then
      raise Exception.Create('OnUpdate 状态同步异常（NewCount>0 应把 ActOpen 置可用）');
    f.ActOpen.Execute;
    if (Pos('[打开]', f.Log.Text) = 0) or (f.Status.Panels[0].Text <> '打开命令') then
      raise Exception.Create('ActOpen 执行异常');
    WriteLn(Log, 'ActOpen.Enabled 同步 + Execute ✓');

    // 工具栏按钮经 Action 取 Caption
    if f.ToolNew.Caption <> '新建(&N)' then
      raise Exception.Create('工具按钮 Caption 未随 Action');
    WriteLn(Log, '工具栏按钮 Caption 随 Action ✓');
    WriteLn(Log, '==== 19 selftest OK ====');
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
