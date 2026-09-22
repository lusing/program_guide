{$mode objfpc}{$codepage utf8}{$H+}
program layout_demo;
{ 23 · 布局与锚定：Align 家族、Anchors 四向、BorderSpacing、TSplitter、
  PageControl 作布局、OnResize 手工布局。正文见 docs/23-layout.md。
  selftest 策略：对齐/锚点做属性级断言 + 手工布局函数以纯计算验证
  （无头环境下控件集布局引擎不等 Show，别赌它）。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls,
  Classes, SysUtils;

type
  TDemoForm = class(TForm)
    TopPanel: TPanel;
    BottomBar: TPanel;
    LeftList: TListBox;
    RightMemo: TMemo;
    Splitter: TSplitter;
    Pages: TPageControl;
    InfoLabel: TLabel;
    procedure FormResize(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    procedure ManualLayout;             // 手工布局：状态栏随宽度重排（自测可纯计算验证）
  end;

constructor TDemoForm.Create(AOwner: TComponent);
var
  page: TTabSheet;
begin
  inherited CreateNew(AOwner);
  Caption := '23 · 布局与锚定';
  Width := 600; Height := 420;
  OnResize := @FormResize;

  // ── Align 家族：top/bottom/left/client 的多米诺 ──
  TopPanel := TPanel.Create(Self);
  TopPanel.Parent := Self;
  TopPanel.Align := alTop;              // 顶条：横向占满，高度自持
  TopPanel.Height := 48;
  TopPanel.Caption := 'alTop 顶条（Height 归我管）';
  TopPanel.BevelOuter := bvNone;

  BottomBar := TPanel.Create(Self);
  BottomBar.Parent := Self;
  BottomBar.Align := alBottom;          // 底条
  BottomBar.Height := 32;
  BottomBar.Caption := 'alBottom 底条';
  BottomBar.BevelOuter := bvNone;

  LeftList := TListBox.Create(Self);
  LeftList.Parent := Self;
  LeftList.Align := alLeft;             // 左列：纵向占剩余，宽度自持
  LeftList.Width := 160;
  LeftList.Items.Add('对齐演示');
  LeftList.Items.Add('Anchors 演示');

  // ── TSplitter：夹在"占边控件"与"剩余区"之间，拖动改宽度 ──
  Splitter := TSplitter.Create(Self);
  Splitter.Parent := Self;
  Splitter.Align := alLeft;             // 与 LeftList 同侧：夹住它的右边缘
  Splitter.Width := 6;
  // LCL 的 Splitter 就近自动关联同侧控件（ResizeControl 属性在 LCL 不保真——实测）

  // ── 剩余区给 PageControl（alClient）──
  Pages := TPageControl.Create(Self);
  Pages.Parent := Self;
  Pages.Align := alClient;
  page := Pages.AddTabSheet;
  page.Caption := '手工布局页';

  RightMemo := TMemo.Create(page);      // 页内再演示 Anchors（相对父容器）
  RightMemo.Parent := page;
  RightMemo.SetBounds(12, 12, 300, 120);
  RightMemo.Lines.Add('我是 SetBounds 摆放的 Memo');
  RightMemo.Lines.Add('Anchors 见右侧按钮');

  InfoLabel := TLabel.Create(page);
  InfoLabel.Parent := page;
  InfoLabel.SetBounds(320, 12, 120, 60);
  InfoLabel.Anchors := [akTop, akRight];          // 锚右上：父变宽我只往右跟
  InfoLabel.Caption := 'akTop+akRight';

  with TButton.Create(page) do          // 四角全锚：跟随父容器伸缩
  begin
    Parent := page;
    SetBounds(320, 150, 120, 32);
    Anchors := [akTop, akLeft, akRight, akBottom];
    Caption := '四向锚定';
  end;
end;

procedure TDemoForm.ManualLayout;
var
  w: Integer;
begin
  // 手工布局示范：在底条里摆三段文字（宽度按 ClientWidth 比例切）
  // ——复杂布局（表格状/按内容测量）最终都回到这条路
  w := ClientWidth;
  BottomBar.Caption := Format('宽 %d：左 1/3=%d 中 1/3=%d 右 1/3=%d',
    [w, w div 3, w div 3, w - 2 * (w div 3)]);
end;

procedure TDemoForm.FormResize(Sender: TObject);
begin
  ManualLayout;
end;

procedure RunSelfTest;
var
  f: TDemoForm;
  Log: TextFile;
begin
  Application.Initialize;
  f := TDemoForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // —— Align 属性级断言（不依赖控件集布局时机）——
    if (f.TopPanel.Align <> alTop) or (f.BottomBar.Align <> alBottom) or
       (f.LeftList.Align <> alLeft) or (f.Pages.Align <> alClient) then
      raise Exception.Create('Align 设置异常');
    WriteLn(Log, 'Align: top/bottom/left/client + Splitter(就近关联) 就位');

    // —— Anchors 断言 ——
    if f.InfoLabel.Anchors <> [akTop, akRight] then
      raise Exception.Create('Anchors 设置异常');
    WriteLn(Log, 'Anchors: 标签=[akTop,akRight] 按钮=[akTop,akLeft,akRight,akBottom]');

    // —— PageControl 布局断言 ——
    if f.Pages.PageCount <> 1 then
      raise Exception.Create('分页数量异常');
    WriteLn(Log, 'Pages: PageCount=', f.Pages.PageCount);

    // —— 手工布局：纯计算，可直接断言 ——
    f.Width := 600;
    f.ManualLayout;
    if Pos('宽 ', f.BottomBar.Caption) <> 1 then
      raise Exception.Create('手工布局未更新底条');
    WriteLn(Log, 'ManualLayout(600) → ', f.BottomBar.Caption);
    f.Width := 900;
    f.ManualLayout;
    WriteLn(Log, 'ManualLayout(900) → ', f.BottomBar.Caption);

    // —— BorderSpacing 与 Margins：属性级 ——
    f.LeftList.BorderSpacing.Around := 4;
    if f.LeftList.BorderSpacing.Around <> 4 then
      raise Exception.Create('BorderSpacing 异常');
    WriteLn(Log, 'BorderSpacing.Around=4 就位（Align 的留白搭档）');

    // —— DPI 概念值：PixelsPerInch 与设计基准 ——
    WriteLn(Log, 'PixelsPerInch=', f.PixelsPerInch, '（96=设计基准；窗体缩放见正文）');
    if f.PixelsPerInch < 72 then
      raise Exception.Create('PixelsPerInch 异常');
    WriteLn(Log, '==== 23 selftest OK ====');
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
