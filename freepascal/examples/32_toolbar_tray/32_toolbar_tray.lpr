{$mode objfpc}{$codepage utf8}{$H+}
program toolbar_tray_demo;
{ 32 · 工具栏、图像列表与系统托盘：TImageList（代码画图标 + Add/GetBitmap
  像素级回读）、TToolBar/TToolButton（tbsButton/tbsCheck/tbsSeparator/
  tbsDropDown 四种、ShowCaptions/Flat）、TStatusBar（Panels vs SimplePanel）、
  TTrayIcon（Icon/BalloonHint/Animate——托盘常驻型程序的骨架）。
  正文见 docs/32-toolbar-tray.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls, Menus, Graphics,
  Classes, SysUtils;

type
  TBarForm = class(TForm)
    Imgs: TImageList;
    Bar: TToolBar;
    Status: TStatusBar;
    Tray: TTrayIcon;
    Popup: TPopupMenu;
    Log: TMemo;
    procedure BtnClick(Sender: TObject);
  public
    ClickTag: Integer;
    constructor Create(AOwner: TComponent); override;
    function MakeIconBmp(Fill: TColor): TBitmap;
  end;

{ 代码画图标：16×16 色块（不依赖 .res/.png 资源——本教程一贯的可复现路线） }
function TBarForm.MakeIconBmp(Fill: TColor): TBitmap;
begin
  Result := TBitmap.Create;
  Result.SetSize(16, 16);
  Result.Canvas.Brush.Color := Fill;
  Result.Canvas.FillRect(0, 0, 16, 16);
end;

constructor TBarForm.Create(AOwner: TComponent);
var
  B: TToolButton;
  Mi: TMenuItem;
begin
  inherited CreateNew(AOwner);
  Caption := '32 · 工具栏与托盘';
  Width := 560; Height := 420;

  // ── 图像列表：工具栏图标的仓库（按 ImageIndex 取用）──
  Imgs := TImageList.Create(Self);
  Imgs.Width := 16;  Imgs.Height := 16;
  Imgs.Add(MakeIconBmp(clGreen), nil);    // 0：新建
  Imgs.Add(MakeIconBmp(clBlue), nil);     // 1：保存
  Imgs.Add(MakeIconBmp(clRed), nil);      // 2：删除

  // ── 工具栏 ──
  Bar := TToolBar.Create(Self);
  Bar.Parent := Self;
  Bar.Align := alTop;
  Bar.Images := Imgs;                     // 图标来源
  Bar.ShowCaptions := True;               // 按钮显示文字（占宽变大——取舍见正文）
  Bar.List := True;                       // 图标+文字横排（配 ShowCaptions）

  B := TToolButton.Create(Bar);
  B.Parent := Bar;
  B.Style := tbsButton;  B.ImageIndex := 0;  B.Caption := '新建';  B.Tag := 1;
  B.OnClick := @BtnClick;

  B := TToolButton.Create(Bar);
  B.Parent := Bar;
  B.Style := tbsButton;  B.ImageIndex := 1;  B.Caption := '保存';  B.Tag := 2;
  B.OnClick := @BtnClick;

  B := TToolButton.Create(Bar);           // 分隔：tbsSeparator 占位 / tbsDivider 带竖线
  B.Parent := Bar;
  B.Style := tbsDivider;

  B := TToolButton.Create(Bar);
  B.Parent := Bar;
  B.Style := tbsCheck;                    // 勾选型（Down 状态保持）
  B.ImageIndex := 2;  B.Caption := '只读';  B.Tag := 3;
  B.OnClick := @BtnClick;

  // ── 状态栏 ──
  Status := TStatusBar.Create(Self);
  Status.Parent := Self;
  Status.Align := alBottom;
  with Status.Panels.Add do Width := 220;  // 多窗格：每格独立 Width/Text/Alignment
  with Status.Panels.Add do Width := 200;
  Status.Panels[0].Text := '就绪';
  Status.Panels[1].Text := '3 个图标';

  // ── 托盘：PopupMenu + TTrayIcon（29 章 caHide 的搭档）──
  Popup := TPopupMenu.Create(Self);
  Mi := TMenuItem.Create(Popup);            // TMenuItem.Add 收"已有项"：
  Mi.Caption := '显示窗口'; Mi.Tag := 10; Mi.OnClick := @BtnClick;
  Popup.Items.Add(Mi);                      // 先 Create 再 Add（与 Panels.Add 不同）
  Mi := TMenuItem.Create(Popup);
  Mi.Caption := '气泡'; Mi.Tag := 11; Mi.OnClick := @BtnClick;
  Popup.Items.Add(Mi);

  Tray := TTrayIcon.Create(Self);
  Tray.Icon.Assign(MakeIconBmp(clMaroon)); // 托盘图标（程序画）
  Tray.Hint := '32 示例在托盘';
  Tray.PopUpMenu := Popup;                  // 右键菜单
  Tray.BalloonHint := '这是气泡通知（点托盘菜单"气泡"）';
  Tray.BalloonFlags := bfInfo;
  Tray.BalloonTimeout := 3000;
  Tray.Visible := True;                     // 常驻显示（主程序模式；selftest 会关掉）

  Log := TMemo.Create(Self);
  Log.Parent := Self;
  Log.Align := alClient;
  Log.ReadOnly := True;
end;

procedure TBarForm.BtnClick(Sender: TObject);
begin
  ClickTag := (Sender as TComponent).Tag;
  case ClickTag of
    11: Tray.ShowBalloonHint;              // 气泡通知（托盘图标须 Visible）
    10: Show;                              // "显示窗口"（配 29 章 caHide 隐藏）
  end;
  Log.Lines.Append(Format('[点击] Tag=%d', [ClickTag]));
end;

procedure RunSelfTest;
var
  f: TBarForm;
  Log: TextFile;
  Bmp: TBitmap;
begin
  Application.Initialize;
  f := TBarForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 图像列表：Count + GetBitmap 像素回读（图标不是黑盒）
    if f.Imgs.Count <> 3 then
      raise Exception.Create('ImageList 应 3 枚');
    Bmp := TBitmap.Create;
    try
      f.Imgs.GetBitmap(0, Bmp);
      if Bmp.Canvas.Pixels[8, 8] <> clGreen then
        raise Exception.Create('图标 0 像素应绿（Add/GetBitmap 往返）');
    finally
      Bmp.Free;
    end;

    // 2) 工具栏按钮形态
    if f.Bar.ButtonCount <> 4 then
      raise Exception.Create('按钮数应 4（含分隔条）');
    if f.Bar.Buttons[2].Style <> tbsDivider then
      raise Exception.Create('第 3 枚应是 tbsDivider');
    if (f.Bar.Buttons[0].ImageIndex <> 0) or (f.Bar.Buttons[3].ImageIndex <> 2) then
      raise Exception.Create('ImageIndex 回读异常');
    f.Bar.Buttons[3].Down := True;         // tbsCheck 的勾选态可程序设定
    if not f.Bar.Buttons[3].Down then
      raise Exception.Create('tbsCheck Down 回环异常');

    // 3) 按钮点击分流（Tag 路由——一个处理器多个按钮）
    f.BtnClick(f.Bar.Buttons[0]);
    if f.ClickTag <> 1 then
      raise Exception.Create('Tag 路由异常');

    // 4) 状态栏：Panels 多窗格与 SimplePanel 二选一
    if f.Status.Panels.Count <> 2 then
      raise Exception.Create('状态栏应 2 窗格');
    if f.Status.Panels[0].Text <> '就绪' then
      raise Exception.Create('窗格文本回读异常');
    f.Status.SimplePanel := True;
    f.Status.SimpleText := '单行模式';
    if f.Status.SimpleText <> '单行模式' then
      raise Exception.Create('SimpleText 回环异常');
    f.Status.SimplePanel := False;

    // 5) 托盘属性（selftest 不弹气泡——ShowBalloonHint 需要真实托盘交互环境）
    if not f.Tray.Visible then
      raise Exception.Create('托盘应已显示（构造器设过）');
    f.Tray.Visible := False;               // 测完即收（无头环境不留图标）
    if f.Tray.Visible then
      raise Exception.Create('托盘关闭回环异常');
    if (f.Tray.BalloonFlags <> bfInfo) or (f.Tray.BalloonTimeout <> 3000) then
      raise Exception.Create('气泡属性回读异常');
    if f.Tray.PopUpMenu <> f.Popup then
      raise Exception.Create('托盘菜单关联异常');

    WriteLn(Log, 'Buttons=', f.Bar.ButtonCount, ' Panels=', f.Status.Panels.Count,
      ' Imgs=', f.Imgs.Count);
    WriteLn(Log, '==== 32 selftest OK ====');
  finally
    f.Tray.Visible := False;               // 无论如何不留托盘残留
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
  with TBarForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Tray.Visible := False;
    Free;
  end;
end.
