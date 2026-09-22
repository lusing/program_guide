{$mode objfpc}{$codepage utf8}{$H+}
program clipboard_dnd_demo;
{ 33 · 剪贴板与拖放：Clipboard.AsText 读写与 HasFormat（测试须保存/还原——
  剪贴板是系统共享资源）、控件间拖放（OnDragOver 的 var Accept、OnDragDrop、
  DragMode）、Explorer 文件拖入（TForm.OnDropFiles）。无头 selftest 直呼
  处理器模拟拖放流。正文见 docs/33-clipboard-dnd.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Clipbrd, Graphics,
  Classes, SysUtils;

type
  TClipForm = class(TForm)
    SrcList, DstList: TListBox;
    DropLog: TMemo;
    procedure DstDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure DstDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
  public
    constructor Create(AOwner: TComponent); override;
  end;

constructor TClipForm.Create(AOwner: TComponent);
var
  I: Integer;
begin
  inherited CreateNew(AOwner);
  Caption := '33 · 剪贴板与拖放';
  Width := 620; Height := 400;

  SrcList := TListBox.Create(Self);
  SrcList.Parent := Self;
  SrcList.SetBounds(16, 12, 200, 200);
  for I := 1 to 5 do
    SrcList.Items.Add('项目 ' + IntToStr(I));
  SrcList.DragMode := dmAutomatic;      // 按住即拖（dmManual=代码里 BeginDrag）

  DstList := TListBox.Create(Self);
  DstList.Parent := Self;
  DstList.SetBounds(240, 12, 200, 200);
  DstList.OnDragOver := @DstDragOver;   // 悬停判定：要不要收
  DstList.OnDragDrop := @DstDragDrop;   // 松手落地

  DropLog := TMemo.Create(Self);
  DropLog.Parent := Self;
  DropLog.SetBounds(16, 224, 430, 130);
  DropLog.ReadOnly := True;

  // Explorer 文件拖入：窗体级事件（AcceptFiles 默认 True）
  OnDropFiles := @FormDropFiles;
end;

procedure TClipForm.DstDragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
  // 只收来自 SrcList 的拖动（Source=发起拖的控件）
  Accept := (Source = SrcList);
end;

procedure TClipForm.DstDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  I: Integer;
begin
  if Source = SrcList then
    for I := 0 to SrcList.Items.Count - 1 do
      if SrcList.Selected[I] then       // 多选拖：逐项搬运
        DstList.Items.Add(SrcList.Items[I]);
end;

procedure TClipForm.FormDropFiles(Sender: TObject; const FileNames: array of string);
var
  I: Integer;
begin
  for I := 0 to High(FileNames) do
    DropLog.Lines.Append('[文件] ' + FileNames[I]);
end;

procedure RunSelfTest;
var
  f: TClipForm;
  Log: TextFile;
  Saved: string;
  Accept: Boolean;
  St: TDragState;
begin
  Application.Initialize;
  f := TClipForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 剪贴板往返（先保存原值——系统共享资源，测完必须还原！）
    Saved := Clipboard.AsText;
    Clipboard.AsText := 'LCL 剪贴板测试 33';
    if Clipboard.AsText <> 'LCL 剪贴板测试 33' then
      raise Exception.Create('剪贴板往返异常');
    if not Clipboard.HasFormat(CF_TEXT) then
      raise Exception.Create('写入后应含 CF_TEXT 格式');
    Clipboard.AsText := Saved;          // 还原（公德）
    if Clipboard.AsText <> Saved then
      raise Exception.Create('还原失败');

    // 2) 拖放悬停判定（直呼 OnDragOver：var Accept 的语义核）
    St := dsDragEnter;
    f.DstDragOver(f.DstList, f.SrcList, 10, 10, St, Accept);
    if not Accept then
      raise Exception.Create('来自 SrcList 应 Accept');
    f.DstDragOver(f.DstList, f.DropLog, 10, 10, St, Accept);
    if Accept then
      raise Exception.Create('来自别的控件应拒收');

    // 3) 拖放落地（模拟选中两个再松手：数据搬运逻辑）
    //    坑（实测）：MultiSelect 默认 False——Selected[2]:=True 会清掉 [0]（单选语义）
    f.SrcList.MultiSelect := True;
    f.SrcList.Selected[0] := True;
    f.SrcList.Selected[2] := True;
    f.DstDragDrop(f.DstList, f.SrcList, 5, 5);
    if (f.DstList.Items.Count <> 2) or (f.DstList.Items[0] <> '项目 1')
      or (f.DstList.Items[1] <> '项目 3') then
      raise Exception.Create('拖放搬运结果异常');

    // 4) 文件拖入（直呼 OnDropFiles：open array 参数天然可测）
    f.FormDropFiles(f, ['G:\a.txt', 'G:\b\c.pas']);
    if (f.DropLog.Lines.Count <> 2) or (f.DropLog.Lines[1] <> '[文件] G:\b\c.pas') then
      raise Exception.Create('文件拖入记录异常');

    // 5) DragMode 语义
    if f.SrcList.DragMode <> dmAutomatic then
      raise Exception.Create('DragMode 回环异常');

    WriteLn(Log, '剪贴板往返+还原 OK；拖2项；文件2个');
    WriteLn(Log, '==== 33 selftest OK ====');
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
  with TClipForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
