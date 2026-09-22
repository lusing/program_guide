{$mode objfpc}{$codepage utf8}{$H+}
program pagecontrol_demo;
{ 20b · TPageControl：每页一个 TTabSheet 容器（各装各的控件）——内容分区用的
  重型多页。动态加页（AddTabSheet）、关页（Free 顺手释放子控件）、
  Options+nboShowCloseButtons 关闭按钮、TabVisible 藏页、SelectNextPage 翻页。
  实测：PageIndex 与 ActivePageIndex 在有隐藏页时可能不同步（教学点）。
  正文见 docs/20-tab-pages.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls, Graphics,
  Classes, SysUtils;

type
  TPageForm = class(TForm)
    Pages: TPageControl;
    StatusLbl: TLabel;
    AddBtn, CloseBtn, HideBtn, NextBtn: TButton;
    procedure AddClick(Sender: TObject);
    procedure CloseClick(Sender: TObject);
    procedure HideClick(Sender: TObject);
    procedure NextClick(Sender: TObject);
    procedure PagesChange(Sender: TObject);
  public
    NextSeq: Integer;   // 计数器放 public（FPC published 区只收类类型字段）
    function NewPage(const ACaption: string): TTabSheet;
    procedure RefreshStatus;
    constructor Create(AOwner: TComponent); override;
  end;

constructor TPageForm.Create(AOwner: TComponent);
var
  Bar: TPanel;
begin
  inherited CreateNew(AOwner);
  Caption := '20b · PageControl 动态多页';
  Width := 560; Height := 420;
  NextSeq := 1;

  Pages := TPageControl.Create(Self);
  Pages.Parent := Self;
  Pages.Align := alClient;
  Pages.Options := Pages.Options + [nboShowCloseButtons];  // 每页标签带 ×
  Pages.OnChange := @PagesChange;
  NewPage('首页');

  Bar := TPanel.Create(Self);
  Bar.Parent := Self;
  Bar.Align := alBottom;
  Bar.Height := 76;
  Bar.Caption := '';

  AddBtn := TButton.Create(Self);
  AddBtn.Parent := Bar;
  AddBtn.SetBounds(8, 6, 90, 28);
  AddBtn.Caption := '加页';
  AddBtn.OnClick := @AddClick;

  CloseBtn := TButton.Create(Self);
  CloseBtn.Parent := Bar;
  CloseBtn.SetBounds(104, 6, 90, 28);
  CloseBtn.Caption := '关当前页';
  CloseBtn.OnClick := @CloseClick;

  HideBtn := TButton.Create(Self);
  HideBtn.Parent := Bar;
  HideBtn.SetBounds(200, 6, 110, 28);
  HideBtn.Caption := '藏/显第2页';
  HideBtn.OnClick := @HideClick;

  NextBtn := TButton.Create(Self);
  NextBtn.Parent := Bar;
  NextBtn.SetBounds(316, 6, 90, 28);
  NextBtn.Caption := '下一页';
  NextBtn.OnClick := @NextClick;

  StatusLbl := TLabel.Create(Self);
  StatusLbl.Parent := Bar;
  StatusLbl.SetBounds(8, 42, 500, 24);
  RefreshStatus;
end;

function TPageForm.NewPage(const ACaption: string): TTabSheet;
begin
  Result := Pages.AddTabSheet;             // 自动挂到 Pages、追加到末尾
  Result.Caption := ACaption;
  with TMemo.Create(Result) do             // 页内容：子控件 Parent=TTabSheet
  begin
    Parent := Result;
    Align := alClient;
    Lines.Append(Format('这是 [%s] 的内容区', [ACaption]));
  end;
end;

procedure TPageForm.AddClick(Sender: TObject);
begin
  Inc(NextSeq);
  Pages.ActivePage := NewPage('页 ' + IntToStr(NextSeq));   // 新页激活
end;

procedure TPageForm.CloseClick(Sender: TObject);
begin
  if Pages.PageCount > 1 then
  begin
    Pages.ActivePage.Free;                 // Free 即移除并释放子控件
    Pages.SelectNextPage(True);
  end;
end;

procedure TPageForm.HideClick(Sender: TObject);
begin
  // 藏起第二页（若在）：TabVisible=False 页不显示但仍在 Pages[] 里
  if Pages.PageCount > 1 then
    Pages.Pages[1].TabVisible := not Pages.Pages[1].TabVisible;
  RefreshStatus;
end;

procedure TPageForm.NextClick(Sender: TObject);
begin
  Pages.SelectNextPage(True, True);        // 第二参=跳过 TabVisible=False 的页
end;

procedure TPageForm.PagesChange(Sender: TObject);
begin
  RefreshStatus;
end;

procedure TPageForm.RefreshStatus;
begin
  StatusLbl.Caption := Format('页数 %d   激活 %s（ActivePageIndex=%d）',
    [Pages.PageCount, Pages.ActivePage.Caption, Pages.ActivePageIndex]);
end;

procedure RunSelfTest;
var
  f: TPageForm;
  Log: TextFile;
begin
  Application.Initialize;
  f := TPageForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 初始一页
    if (f.Pages.PageCount <> 1) or (f.Pages.Pages[0].Caption <> '首页') then
      raise Exception.Create('初始页异常');

    // 2) 动态加页 + 激活语义
    f.Pages.ActivePage := f.NewPage('页 2');
    f.Pages.ActivePage := f.NewPage('页 3');
    if f.Pages.PageCount <> 3 then
      raise Exception.Create('加页后应 3 页');
    if (f.Pages.ActivePageIndex <> 2) or (f.Pages.ActivePage.Caption <> '页 3') then
      raise Exception.Create('ActivePage/ActivePageIndex 应同步到末页');
    if f.Pages.Pages[1].PageControl <> f.Pages then
      raise Exception.Create('TabSheet.PageControl 应指回宿主');

    // 3) PageIndex 定位（ActivePageIndex 是"可见序"——设了再说）
    f.Pages.ActivePageIndex := 0;
    if f.Pages.ActivePage.Caption <> '首页' then
      raise Exception.Create('ActivePageIndex=0 应激活首页');

    // 4) TabVisible 藏页：PageCount 不减，SelectNextPage(True,True) 跳过它
    f.Pages.Pages[1].TabVisible := False;
    if f.Pages.PageCount <> 3 then
      raise Exception.Create('藏页不减 PageCount');
    f.Pages.ActivePageIndex := 0;
    f.Pages.SelectNextPage(True, True);
    if f.Pages.ActivePage.Caption <> '页 3' then
      raise Exception.Create('SelectNextPage 应跳过隐藏页，实测=' + f.Pages.ActivePage.Caption);
    f.Pages.Pages[1].TabVisible := True;

    // 5) 关页：Free 释放，页数减一，剩余页照常
    f.Pages.ActivePageIndex := 2;
    f.Pages.ActivePage.Free;
    if f.Pages.PageCount <> 2 then
      raise Exception.Create('关页后应 2 页');
    if f.Pages.Pages[1].Caption <> '页 2' then
      raise Exception.Create('剩余页序异常');

    // 6) 关闭按钮选项在位（UI 点击由 nboShowCloseButtons + OnCloseTabClicked 配合）
    if not (nboShowCloseButtons in f.Pages.Options) then
      raise Exception.Create('nboShowCloseButtons 应在 Options');

    WriteLn(Log, '最终页数=', f.Pages.PageCount, ' 激活=', f.Pages.ActivePage.Caption);
    WriteLn(Log, '==== 20b selftest OK ====');
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
  with TPageForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
