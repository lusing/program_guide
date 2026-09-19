{$mode objfpc}{$codepage utf8}{$H+}
unit unotepad;
{ 24 · 实战记事本+ 主窗体单元——把 15–23 章串成一个完整应用：
  动态多标签（TPageControl+TMemo）、打开/保存/另存（编码选择）、查找/替换、
  修改跟踪（标签* + 关闭确认）、状态栏（行列/字数/编码）、字体/只读/换行（INI 持久化）。
  纯代码建窗体（与 16–23 章同风格）。 }

interface

uses
  Classes, SysUtils, StrUtils, Math, Forms, Controls, StdCtrls, ComCtrls,
  ActnList, Menus, Dialogs, ExtDlgs, IniFiles, Graphics;

type
  TDocEncoding = (encUtf8, encAnsi);

  { 一个标签页 = 一份文档：页 + Memo + 元数据 }
  TTabDoc = class
    Sheet: TTabSheet;
    Memo: TMemo;
    FileName: string;             // 空串 = 未命名
    Encoding: TDocEncoding;
    Dirty: Boolean;
    function DisplayName: string; // 标题：文件名 + 脏标记 *
    procedure MarkDirty;
  end;

  TMainForm = class(TForm)
  private
    FConfirmAnswer: TModalResult;         // 测试钩子：MessageDlg 的代答（mrNone=真弹）
    FDocs: TList;                         // TTabSheet 没有 Data 属性（TTreeNode 才有）——
                                          // Sheet→Doc 映射自己管：遍历比对
    function DocOfSheet(Sheet: TTabSheet): TTabDoc;
    procedure ApplyEditorOptions;         // 换行/只读 → 全部标签页
  public
    Pages: TPageControl;
    StatusBar: TStatusBar;
    Actions: TActionList;
    ActNew, ActOpen, ActSave, ActSaveAs, ActClose, ActAbout: TAction;
    ActFind, ActReplace, ActWordWrap, ActReadOnly: TAction;
    OpenDlg: TOpenDialog;
    SaveDlg: TSaveDialog;
    FindDlg: TFindDialog;
    ReplDlg: TReplaceDialog;
    FontDlg: TFontDialog;
    procedure ActNewExecute(Sender: TObject);
    procedure ActOpenExecute(Sender: TObject);
    procedure ActSaveExecute(Sender: TObject);
    procedure ActSaveAsExecute(Sender: TObject);
    procedure ActCloseExecute(Sender: TObject);
    procedure ActAboutExecute(Sender: TObject);
    procedure ActFindExecute(Sender: TObject);
    procedure ActReplaceExecute(Sender: TObject);
    procedure ActWordWrapExecute(Sender: TObject);
    procedure ActReadOnlyExecute(Sender: TObject);
    procedure FindDlgFind(Sender: TObject);
    procedure ReplDlgFind(Sender: TObject);
    procedure ReplDlgReplace(Sender: TObject);
    procedure MemoChange(Sender: TObject);
    procedure MemoClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    function NewDoc: TTabDoc;                     // 新建标签页
    function CurrentDoc: TTabDoc;                 // 当前活动文档（无页返回 nil）
    function DocCount: Integer;
    function OpenFile(const AFileName: string): TTabDoc;   // 载入到新页
    function SaveDoc(Doc: TTabDoc; AskName: Boolean): Boolean;
    function ConfirmCloseDoc(Doc: TTabDoc): Boolean;       // 脏则问（selftest 传代答）
    function CloseDoc(Doc: TTabDoc): Boolean;
    function FindNext(Doc: TTabDoc; const AText: string; FromPos: Integer): Integer;
    procedure ReplaceAll(Doc: TTabDoc; const AFind, ARepl: string; out Count: Integer);
    procedure UpdateStatus;                       // 行列/字数/编码 → 状态栏
    procedure LoadSettings(const AIniName: string);
    procedure SaveSettings(const AIniName: string);
    property ConfirmAnswer: TModalResult read FConfirmAnswer write FConfirmAnswer;
  end;
  // 坑（实测）：property 读的字段必须在声明点【之前】可见——objfpc 类内不留前向引用

implementation

{ TTabDoc }

function TTabDoc.DisplayName: string;
begin
  if FileName = '' then
    Result := '未命名'
  else
    Result := ExtractFileName(FileName);
  if Dirty then
    Result := '*' + Result;
end;

procedure TTabDoc.MarkDirty;
begin
  if not Dirty then
  begin
    Dirty := True;
    Sheet.Caption := DisplayName;
  end;
end;

{ TMainForm }

constructor TMainForm.Create(AOwner: TComponent);
var
  mFile, mEdit, mFmt, mHelp: TMenuItem;

  function AddAct(AParentMenu: TMenuItem; A: TAction): TMenuItem;
  begin
    Result := TMenuItem.Create(Self);
    Result.Action := A;
    AParentMenu.Add(Result);
  end;

begin
  inherited CreateNew(AOwner);
  Caption := '记事本+';
  Width := 780; Height := 560;
  FConfirmAnswer := mrNone;
  FDocs := TList.Create;

  Actions := TActionList.Create(Self);

  ActNew := TAction.Create(Self);
  ActNew.ActionList := Actions;
  ActNew.Caption := '新建(&N)';
  ActNew.ShortCut := ShortCut(Ord('N'), [ssCtrl]);
  ActNew.OnExecute := @ActNewExecute;

  ActOpen := TAction.Create(Self);
  ActOpen.ActionList := Actions;
  ActOpen.Caption := '打开(&O)...';
  ActOpen.ShortCut := ShortCut(Ord('O'), [ssCtrl]);
  ActOpen.OnExecute := @ActOpenExecute;

  ActSave := TAction.Create(Self);
  ActSave.ActionList := Actions;
  ActSave.Caption := '保存(&S)';
  ActSave.ShortCut := ShortCut(Ord('S'), [ssCtrl]);
  ActSave.OnExecute := @ActSaveExecute;

  ActSaveAs := TAction.Create(Self);
  ActSaveAs.ActionList := Actions;
  ActSaveAs.Caption := '另存为(&A)...';
  ActSaveAs.OnExecute := @ActSaveAsExecute;

  ActClose := TAction.Create(Self);
  ActClose.ActionList := Actions;
  ActClose.Caption := '关闭标签(&W)';
  ActClose.ShortCut := ShortCut(Ord('W'), [ssCtrl]);
  ActClose.OnExecute := @ActCloseExecute;

  ActFind := TAction.Create(Self);
  ActFind.ActionList := Actions;
  ActFind.Caption := '查找(&F)...';
  ActFind.ShortCut := ShortCut(Ord('F'), [ssCtrl]);
  ActFind.OnExecute := @ActFindExecute;

  ActReplace := TAction.Create(Self);
  ActReplace.ActionList := Actions;
  ActReplace.Caption := '替换(&R)...';
  ActReplace.ShortCut := ShortCut(Ord('H'), [ssCtrl]);
  ActReplace.OnExecute := @ActReplaceExecute;

  ActWordWrap := TAction.Create(Self);
  ActWordWrap.ActionList := Actions;
  ActWordWrap.Caption := '自动换行';
  ActWordWrap.OnExecute := @ActWordWrapExecute;

  ActReadOnly := TAction.Create(Self);
  ActReadOnly.ActionList := Actions;
  ActReadOnly.Caption := '只读';
  ActReadOnly.OnExecute := @ActReadOnlyExecute;

  ActAbout := TAction.Create(Self);
  ActAbout.ActionList := Actions;
  ActAbout.Caption := '关于(&A)';
  ActAbout.OnExecute := @ActAboutExecute;

  // 菜单栏（19 章套路：包一层面向 Action）
  with TMainMenu.Create(Self) do
  begin
    mFile := TMenuItem.Create(Self);
    mFile.Caption := '文件(&F)';
    AddAct(mFile, ActNew);
    AddAct(mFile, ActOpen);
    AddAct(mFile, ActSave);
    AddAct(mFile, ActSaveAs);
    AddAct(mFile, ActClose);
    Items.Add(mFile);

    mEdit := TMenuItem.Create(Self);
    mEdit.Caption := '编辑(&E)';
    AddAct(mEdit, ActFind);
    AddAct(mEdit, ActReplace);
    Items.Add(mEdit);

    mFmt := TMenuItem.Create(Self);
    mFmt.Caption := '格式(&O)';
    AddAct(mFmt, ActWordWrap);
    AddAct(mFmt, ActReadOnly);
    Items.Add(mFmt);

    mHelp := TMenuItem.Create(Self);
    mHelp.Caption := '帮助(&H)';
    AddAct(mHelp, ActAbout);
    Items.Add(mHelp);
  end;

  // 对话框组件（20 章）
  OpenDlg := TOpenDialog.Create(Self);
  OpenDlg.Filter := '文本文件 (*.txt;*.utf8)|*.txt;*.utf8|所有文件 (*.*)|*.*';

  SaveDlg := TSaveDialog.Create(Self);
  SaveDlg.Filter := '文本文件 (*.txt)|*.txt|UTF-8 文本 (*.utf8)|*.utf8';
  SaveDlg.DefaultExt := 'txt';

  FindDlg := TFindDialog.Create(Self);
  FindDlg.OnFind := @FindDlgFind;
  FindDlg.Options := FindDlg.Options + [frDown, frMatchCase];

  ReplDlg := TReplaceDialog.Create(Self);
  ReplDlg.OnFind := @ReplDlgFind;
  ReplDlg.OnReplace := @ReplDlgReplace;

  FontDlg := TFontDialog.Create(Self);
  FontDlg.Font.Name := 'Consolas';
  FontDlg.Font.Size := 11;

  // 多标签工作区（17 章 TPageControl）
  Pages := TPageControl.Create(Self);
  Pages.Parent := Self;
  Pages.Align := alClient;

  // 状态栏（19 章）：行列 | 字数 | 编码
  StatusBar := TStatusBar.Create(Self);
  StatusBar.Parent := Self;
  StatusBar.SimplePanel := False;
  StatusBar.Panels.Add.Width := 160;
  StatusBar.Panels.Add.Width := 160;
  StatusBar.Panels.Add;

  NewDoc;                                       // 开场给一页
end;

function TMainForm.DocOfSheet(Sheet: TTabSheet): TTabDoc;
var
  i: Integer;
begin
  // 坑（实测）：TTabSheet 没有 Data 属性（TTreeNode/TListItem 才有）——
  // Sheet→Doc 映射自己维护：遍历比对
  Result := nil;
  for i := 0 to FDocs.Count - 1 do
    if TTabDoc(FDocs[i]).Sheet = Sheet then
      Exit(TTabDoc(FDocs[i]));
end;

function TMainForm.NewDoc: TTabDoc;
begin
  Result := TTabDoc.Create;
  Result.Sheet := Pages.AddTabSheet;
  FDocs.Add(Result);
  Result.Encoding := encUtf8;
  Result.FileName := '';
  Result.Dirty := False;
  Result.Sheet.Caption := Result.DisplayName;

  Result.Memo := TMemo.Create(Result.Sheet);
  Result.Memo.Parent := Result.Sheet;
  Result.Memo.Align := alClient;
  Result.Memo.Font.Assign(FontDlg.Font);
  Result.Memo.ScrollBars := ssAutoBoth;
  Result.Memo.OnChange := @MemoChange;
  Result.Memo.OnClick := @MemoClick;

  Pages.ActivePage := Result.Sheet;
end;

function TMainForm.CurrentDoc: TTabDoc;
begin
  Result := DocOfSheet(Pages.ActivePage);
end;

function TMainForm.DocCount: Integer;
begin
  Result := Pages.PageCount;
end;

function TMainForm.OpenFile(const AFileName: string): TTabDoc;
begin
  Result := NewDoc;
  Result.FileName := AFileName;
  Result.Encoding := encUtf8;
  // 编码坑（20 章）：显式 UTF-8 读，默认走系统 ANSI 会乱中文
  Result.Memo.Lines.LoadFromFile(AFileName, TEncoding.UTF8);
  Result.Dirty := False;
  Result.Sheet.Caption := Result.DisplayName;
  UpdateStatus;
end;

function TMainForm.SaveDoc(Doc: TTabDoc; AskName: Boolean): Boolean;
begin
  Result := False;
  if Doc = nil then Exit;
  if (Doc.FileName = '') or AskName then
  begin
    if not SaveDlg.Execute then Exit;           // selftest 不会走这（先设好 FileName）
    Doc.FileName := SaveDlg.FileName;
  end;
  if Doc.Encoding = encUtf8 then
    Doc.Memo.Lines.SaveToFile(Doc.FileName, TEncoding.UTF8)
  else
    Doc.Memo.Lines.SaveToFile(Doc.FileName, TEncoding.Default);   // 系统 ANSI
  Doc.Dirty := False;
  Doc.Sheet.Caption := Doc.DisplayName;
  Result := True;
end;

function TMainForm.ConfirmCloseDoc(Doc: TTabDoc): Boolean;
var
  R: TModalResult;
begin
  // 脏文档问一句；干净直接关（20 章 ModalResult 语义的纯逻辑核）
  if (Doc = nil) or (not Doc.Dirty) then
    Exit(True);
  if FConfirmAnswer <> mrNone then
    R := FConfirmAnswer                          // 测试钩子：代答
  else
    R := MessageDlg(Format('"%s" 已修改，保存吗？', [Doc.DisplayName]),
      mtConfirmation, mbYesNoCancel, 0);
  case R of
    mrYes:    Exit(SaveDoc(Doc, False));
    mrNo:     Exit(True);
  else
    Exit(False);                                 // 取消：不关
  end;
end;

function TMainForm.CloseDoc(Doc: TTabDoc): Boolean;
var
  idx: Integer;
begin
  Result := False;
  if not ConfirmCloseDoc(Doc) then Exit;
  idx := Doc.Sheet.PageIndex;
  FDocs.Remove(Doc);
  Doc.Sheet.Free;                                // Owner 是 Pages，连带释放
  Doc.Free;                                      // TTabDoc 是纯对象，自己放
  if Pages.PageCount > 0 then
    Pages.PageIndex := Min(idx, Pages.PageCount - 1);
  UpdateStatus;
  Result := True;
end;

function TMainForm.FindNext(Doc: TTabDoc; const AText: string; FromPos: Integer): Integer;
var
  s: string;
begin
  // 返回找到位置（0 基）；找不到 -1。查找逻辑独立成函数——可测核心
  Result := -1;
  if (Doc = nil) or (AText = '') then Exit;
  s := Doc.Memo.Text;
  Result := PosEx(AText, s, FromPos + 1) - 1;    // PosEx 1 基 → 0 基
  if Result >= 0 then
  begin
    Doc.Memo.SelStart := Result;
    Doc.Memo.SelLength := Length(AText);
  end;
end;

procedure TMainForm.ReplaceAll(Doc: TTabDoc; const AFind, ARepl: string; out Count: Integer);
var
  s: string;
  p: Integer;
begin
  Count := 0;
  if (Doc = nil) or (AFind = '') then Exit;
  s := Doc.Memo.Text;
  p := Pos(AFind, s);
  while p > 0 do
  begin
    Delete(s, p, Length(AFind));
    Insert(ARepl, s, p);
    Inc(Count);
    p := PosEx(AFind, s, p + Length(ARepl));     // 从替换结果之后继续
  end;
  if Count > 0 then
  begin
    Doc.Memo.Text := s;                          // 实测：TMemo.Text 赋值【不】触发 OnChange
    Doc.MarkDirty;                               //（TEdit 才触发）——程序化修改一律显式标脏
  end;
end;

procedure TMainForm.UpdateStatus;
var
  Doc: TTabDoc;
  line, col, cnt: Integer;
  encName: string;
begin
  Doc := CurrentDoc;
  if Doc = nil then
  begin
    StatusBar.Panels[0].Text := '无文档';
    StatusBar.Panels[1].Text := '';
    StatusBar.Panels[2].Text := '';
    Exit;
  end;
  // 行列：SelStart 换算（CaretPos 在部分控件集上不可靠，自己算最稳）。
  // 必须【从左往右】扫到 SelStart——从右往左会把行号列号算串（实测初版之坑）
  line := 1; col := 1;
  for cnt := 1 to Doc.Memo.SelStart do
    if Doc.Memo.Text[cnt] = #10 then
    begin
      Inc(line);
      col := 1;
    end
    else
      Inc(col);
  StatusBar.Panels[0].Text := Format('行 %d，列 %d', [line, col]);
  StatusBar.Panels[1].Text := Format('字符 %d', [Length(Doc.Memo.Text)]);
  case Doc.Encoding of
    encUtf8: encName := 'UTF-8';
  else
    encName := 'ANSI';
  end;
  StatusBar.Panels[2].Text := encName;
end;

procedure TMainForm.LoadSettings(const AIniName: string);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AIniName);              // 11 章坑：节/键一律 ASCII
  try
    Width := ini.ReadInteger('window', 'width', 780);
    Height := ini.ReadInteger('window', 'height', 560);
    ActWordWrap.Checked := ini.ReadBool('editor', 'wordwrap', False);
    ActReadOnly.Checked := ini.ReadBool('editor', 'readonly', False);
    ApplyEditorOptions;
  finally
    ini.Free;
  end;
end;

procedure TMainForm.SaveSettings(const AIniName: string);
var
  ini: TIniFile;
begin
  ini := TIniFile.Create(AIniName);
  try
    ini.WriteInteger('window', 'width', Width);
    ini.WriteInteger('window', 'height', Height);
    ini.WriteBool('editor', 'wordwrap', ActWordWrap.Checked);
    ini.WriteBool('editor', 'readonly', ActReadOnly.Checked);
  finally
    ini.Free;
  end;
end;

procedure TMainForm.ApplyEditorOptions;
var
  i: Integer;
  Doc: TTabDoc;
begin
  for i := 0 to Pages.PageCount - 1 do
  begin
    Doc := DocOfSheet(Pages.Pages[i]);
    if Doc <> nil then
    begin
      Doc.Memo.WordWrap := ActWordWrap.Checked;
      Doc.Memo.ReadOnly := ActReadOnly.Checked;
    end;
  end;
end;

{ 事件处理器 }

procedure TMainForm.ActNewExecute(Sender: TObject);
begin
  NewDoc;
  UpdateStatus;
end;

procedure TMainForm.ActOpenExecute(Sender: TObject);
begin
  if OpenDlg.Execute then
    OpenFile(OpenDlg.FileName);
end;

procedure TMainForm.ActSaveExecute(Sender: TObject);
begin
  SaveDoc(CurrentDoc, False);
  UpdateStatus;
end;

procedure TMainForm.ActSaveAsExecute(Sender: TObject);
begin
  SaveDoc(CurrentDoc, True);
  UpdateStatus;
end;

procedure TMainForm.ActCloseExecute(Sender: TObject);
begin
  CloseDoc(CurrentDoc);
end;

procedure TMainForm.ActAboutExecute(Sender: TObject);
begin
  MessageDlg('记事本+' + #10 + 'FreePascal/Lazarus 教程第 24 章实战', mtInformation, [mbOk], 0);
end;

procedure TMainForm.ActFindExecute(Sender: TObject);
begin
  FindDlg.Execute;                               // 非模态（20 章）：回调驱动
end;

procedure TMainForm.ActReplaceExecute(Sender: TObject);
begin
  ReplDlg.Execute;
end;

procedure TMainForm.ActWordWrapExecute(Sender: TObject);
begin
  ActWordWrap.Checked := not ActWordWrap.Checked;
  ApplyEditorOptions;
end;

procedure TMainForm.ActReadOnlyExecute(Sender: TObject);
begin
  ActReadOnly.Checked := not ActReadOnly.Checked;
  ApplyEditorOptions;
end;

procedure TMainForm.FindDlgFind(Sender: TObject);
begin
  if FindNext(CurrentDoc, FindDlg.FindText, CurrentDoc.Memo.SelStart +
    CurrentDoc.Memo.SelLength) < 0 then
    MessageDlg('找不到：" ' + FindDlg.FindText, mtInformation, [mbOk], 0);
end;

procedure TMainForm.ReplDlgFind(Sender: TObject);
begin
  FindDlgFind(Sender);                           // 查找按钮同查找对话框
end;

procedure TMainForm.ReplDlgReplace(Sender: TObject);
var
  n: Integer;
begin
  ReplaceAll(CurrentDoc, ReplDlg.FindText, ReplDlg.ReplaceText, n);
  MessageDlg(Format('替换了 %d 处', [n]), mtInformation, [mbOk], 0);
end;

procedure TMainForm.MemoChange(Sender: TObject);
begin
  // TMemo 的 OnChange（16 章实测：Text 赋值/键入都触发）
  if (Sender is TMemo) and ((Sender as TMemo).Parent is TTabSheet) then
    DocOfSheet((Sender as TMemo).Parent as TTabSheet).MarkDirty;
  UpdateStatus;
end;

procedure TMainForm.MemoClick(Sender: TObject);
begin
  UpdateStatus;
end;

end.
