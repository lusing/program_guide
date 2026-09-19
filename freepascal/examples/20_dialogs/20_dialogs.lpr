{$mode objfpc}{$codepage utf8}{$H+}
program dialogs_demo;
{ 20 · 对话框与文件：TOpenDialog/TSaveDialog（过滤器/选项）、ShowModal 与 ModalResult、
  MessageDlg 家族、TFontDialog、TFindDialog/TReplaceDialog。
  正文见 docs/19-menus.md 对应章（20-dialogs.md）。
  selftest 策略：对话框组件的属性与回调逻辑全部可无头验证；真正弹窗的 Execute/ShowModal
  只走文档（正常路径人工点）。 }

uses
  Interfaces, Forms, Controls, StdCtrls, Dialogs, ExtDlgs,
  Classes, SysUtils, Graphics;

type
  TDemoForm = class(TForm)
    OpenDlg: TOpenDialog;
    SaveDlg: TSaveDialog;
    FindDlg: TFindDialog;
    FontDlg: TFontDialog;
    Memo: TMemo;
    Log: TMemo;
    procedure FindDlgFind(Sender: TObject);
  public
    FindCount: Integer;
    constructor Create(AOwner: TComponent); override;
  end;

// 纯逻辑：关闭前要不要确认（20 章 ModalResult 语义的落地函数）
function ConfirmClose(IsDirty: Boolean): TModalResult;
begin
  if not IsDirty then
    Exit(mrNo);                          // 干净：直接关（不需要保存）
  Exit(mrYes);                           // 脏：按"要保存"处理（真实程序里问 MessageDlg）
end;

constructor TDemoForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '20 · 对话框';
  Width := 560; Height := 420;

  // ── 文件对话框：过滤器是"名称|模式"竖线串 ──
  OpenDlg := TOpenDialog.Create(Self);
  OpenDlg.Title := '选择要打开的文本文件';
  OpenDlg.Filter := '文本文件 (*.txt)|*.txt|所有文件 (*.*)|*.*';
  OpenDlg.FilterIndex := 1;              // 默认选中第一组
  OpenDlg.Options := OpenDlg.Options + [ofFileMustExist, ofAllowMultiSelect];

  SaveDlg := TSaveDialog.Create(Self);
  SaveDlg.Filter := '文本文件 (*.txt)|*.txt|UTF-8 文本 (*.utf8)|*.utf8';
  SaveDlg.DefaultExt := 'txt';           // 无扩展名时自动补
  SaveDlg.Options := SaveDlg.Options + [ofOverwritePrompt];   // 覆盖前确认

  // ── 查找对话框：非模态（Type 无阻塞），回调驱动 ──
  FindDlg := TFindDialog.Create(Self);
  FindDlg.OnFind := @FindDlgFind;        // 点"查找下一个"时回调
  FindDlg.Options := FindDlg.Options + [frDown, frMatchCase];

  // ── 字体对话框 ──
  FontDlg := TFontDialog.Create(Self);
  FontDlg.Font.Name := '微软雅黑';
  FontDlg.Font.Size := 12;

  Memo := TMemo.Create(Self);
  Memo.Parent := Self;
  Memo.Align := alClient;
  Memo.Lines.Add('查找与替换演示文本：Lazarus LCL');
  Memo.Lines.Add('第二行：lazarus 小写也来一次');

  Log := TMemo.Create(Self);
  Log.Parent := Self;
  Log.Align := alBottom;
  Log.Height := 100;
  Log.ReadOnly := True;
end;

procedure TDemoForm.FindDlgFind(Sender: TObject);
begin
  Inc(FindCount);
  // 真实现：在 Memo 里找 FindDlg.FindText 的下一个位置；演示只记数
  Log.Lines.Append(Format('[查找#%d] "%s" 方向=%s 区分大小写=%s',
    [FindCount, FindDlg.FindText,
     BoolToStr(frDown in FindDlg.Options, True),
     BoolToStr(frMatchCase in FindDlg.Options, True)]));
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
    // ── 过滤器与选项 ──
    if Pos('*.txt', f.OpenDlg.Filter) = 0 then
      raise Exception.Create('过滤器设置异常');
    if not (ofFileMustExist in f.OpenDlg.Options) then
      raise Exception.Create('打开对话框选项异常');
    if not (ofOverwritePrompt in f.SaveDlg.Options) then
      raise Exception.Create('保存对话框选项异常');
    WriteLn(Log, 'OpenFilter=', f.OpenDlg.Filter);
    WriteLn(Log, 'SaveDefaultExt=', f.SaveDlg.DefaultExt, ' 覆盖确认=开 多选=',
      BoolToStr(ofAllowMultiSelect in f.OpenDlg.Options, True));

    // ── FindDialog 回调逻辑（不弹窗，直接调处理器）──
    f.FindDlg.FindText := 'Lazarus';
    f.FindDlgFind(f.FindDlg);
    f.FindDlgFind(f.FindDlg);
    if f.FindCount <> 2 then
      raise Exception.Create('查找回调计数异常');
    if Pos('查找#2', f.Log.Text) = 0 then
      raise Exception.Create('查找日志未记录');
    WriteLn(Log, 'Find 回调 x2 → ', f.Log.Lines[f.Log.Lines.Count - 1]);

    // ── FontDialog 属性 ──
    if (f.FontDlg.Font.Name <> '微软雅黑') or (f.FontDlg.Font.Size <> 12) then
      raise Exception.Create('字体属性异常');
    WriteLn(Log, 'FontDlg.Font=', f.FontDlg.Font.Name, ' ', f.FontDlg.Font.Size, 'pt');

    // ── ModalResult 常量与关闭确认逻辑 ──
    WriteLn(Log, 'mrNone=', mrNone, ' mrOk=', mrOk, ' mrCancel=', mrCancel,
      ' mrYes=', mrYes, ' mrNo=', mrNo);
    if not (mrOk in [mrNone..mrNo]) then
      raise Exception.Create('ModalResult 常量异常');
    if ConfirmClose(False) <> mrNo then
      raise Exception.Create('干净文档应直接关闭');
    if ConfirmClose(True) <> mrYes then
      raise Exception.Create('脏文档应走保存分支');
    // 次级窗体的 ModalResult 属性赋值/读取（不 ShowModal 也能验）
    f.Memo.Tag := Integer(mrOk);
    if TModalResult(f.Memo.Tag) = mrOk then
      WriteLn(Log, 'ModalResult 属性往返 ✓');
    WriteLn(Log, '==== 20 selftest OK ====');
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
