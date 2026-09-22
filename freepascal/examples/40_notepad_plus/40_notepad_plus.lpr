{$mode objfpc}{$codepage utf8}{$H+}
program notepad_plus;
{ 40 · 实战记事本+：多标签文本编辑器（15–28 章集大成）。
  --selftest：无头全功能自检（开-改-存-比对 + 查找替换 + 关闭确认 + INI 往返），
  断言走 uchecks（Check/CheckEqInt/CheckEqStr + 汇总）。 }

uses
  Interfaces, Forms, Controls, Classes, SysUtils,
  unotepad { TMainForm },
  uchecks { Check/CheckEqInt/CheckEqStr };

procedure RunSelfTest;
var
  f: TMainForm;
  Log: TextFile;
  doc, doc2: TTabDoc;
  tmp, ini1, ini2: string;
  expLine: string;                 // 07 章坑：中文字面量先入 string 变量（Length 才按字节）
  sl: TStringList;
  n: Integer;
begin
  Application.Initialize;
  f := TMainForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // ── 1. 多标签 ──
    CheckEqInt(f.DocCount, 1, '开场应有一页');
    doc := f.NewDoc;
    CheckEqInt(f.DocCount, 2, '新建后两页');
    Check(f.CurrentDoc = doc, '新页应为当前页');
    CheckEqStr(doc.DisplayName, '未命名', '空文件名显示');
    WriteLn(Log, '1 多标签：DocCount=', f.DocCount, ' 当前="', f.CurrentDoc.DisplayName, '"');

    // ── 2. 打开（临时文件 → UTF-8 载入）──
    tmp := 'selftest_temp.txt';
    sl := TStringList.Create;
    sl.Add('第一行：你好，世界');
    sl.Add('第二行：Free Pascal');
    sl.Add('第三行：Lazarus');
    sl.SaveToFile(tmp, TEncoding.UTF8);
    sl.Free;
    expLine := '第一行：你好，世界';
    doc2 := f.OpenFile(tmp);
    CheckEqStr(doc2.FileName, tmp, '打开后文件名');
    CheckEqInt(Length(doc2.Memo.Lines[0]), Length(expLine),
      'UTF-8 中文行按字节（27）——期望值先入 string 变量再取 Length');
    CheckEqStr(doc2.DisplayName, 'selftest_temp.txt', '标签标题=文件名（无脏标记）');
    WriteLn(Log, '2 打开：', doc2.DisplayName, ' 首行字节数=', Length(doc2.Memo.Lines[0]));

    // ── 3. 修改跟踪 ──
    f.Pages.ActivePage := doc2.Sheet;
    // 实测：Memo.Lines.Add 不触发 OnChange（键入才触发）——程序化修改须显式标脏
    doc2.Memo.Lines.Add('第四行：新加的');
    doc2.MarkDirty;
    Check(doc2.Dirty, '编辑后应置脏');
    CheckEqStr(doc2.DisplayName, '*selftest_temp.txt', '脏标记进标签标题');
    WriteLn(Log, '3 修改跟踪：', doc2.DisplayName);

    // ── 4. 保存与重读比对 ──
    Check(f.SaveDoc(doc2, False), '保存应成功（文件名已定）');
    Check(not doc2.Dirty, '保存后脏标记应清');
    CheckEqStr(doc2.DisplayName, 'selftest_temp.txt', '保存后标题复原');
    sl := TStringList.Create;
    sl.LoadFromFile(tmp, TEncoding.UTF8);
    CheckEqInt(sl.Count, 4, '保存后 4 行');
    CheckEqStr(sl[3], '第四行：新加的', 'UTF-8 往返内容一致');
    sl.Free;
    WriteLn(Log, '4 保存：4 行 UTF-8 往返一致');

    // ── 5. 查找与替换 ──
    n := f.FindNext(doc2, 'Lazarus', 0);
    Check(n > 0, '应找到 Lazarus');
    CheckEqInt(doc2.Memo.SelLength, Length('Lazarus'), '找到后选中长度');
    n := f.FindNext(doc2, '不存在的词', 0);
    CheckEqInt(n, -1, '找不到返回 -1');
    f.ReplaceAll(doc2, '行：', '行-', n);
    CheckEqInt(f.FindNext(doc2, '行：', 0), -1, '替换后原词应清零');
    Check(Pos('第一行-你好', doc2.Memo.Text) > 0, '替换结果正确');
    WriteLn(Log, '5 查找替换：FindNext 命中/未中，ReplaceAll 全换');

    // ── 6. 关闭确认（ConfirmAnswer 代答钩子）──
    f.ConfirmAnswer := mrCancel;
    Check(not f.CloseDoc(doc2), '脏文档 + 取消 → 不关闭');
    CheckEqInt(f.DocCount, 3, '页数不变（开场+新建+打开=3）');
    f.ConfirmAnswer := mrYes;                 // 脏 + 是 → 保存并关
    Check(f.CloseDoc(doc2), '脏文档 + 是 → 保存关闭');
    CheckEqInt(f.DocCount, 2, '关闭后剩两页');
    f.ConfirmAnswer := mrNone;                // 恢复真实弹窗（正常路径用）
    WriteLn(Log, '6 关闭确认：取消不关 / 是=保存并关');

    // ── 7. 状态栏 ──
    doc := f.CurrentDoc;
    doc.Memo.Text := 'ab' + #13#10 + 'cd';    // Windows 文本行尾 CRLF（实测）
    doc.Memo.SelStart := 4;                   // 光标落在第二行行首前（0 基）
    f.UpdateStatus;
    CheckEqStr(f.StatusBar.Panels[0].Text, '行 2，列 1', '行列换算（CRLF 计入）');
    CheckEqStr(f.StatusBar.Panels[1].Text, '字符 6', '字符数=字节数（含 CRLF）');
    CheckEqStr(f.StatusBar.Panels[2].Text, 'UTF-8', '编码窗格');
    WriteLn(Log, '7 状态栏：', f.StatusBar.Panels[0].Text, ' | ',
      f.StatusBar.Panels[1].Text, ' | ', f.StatusBar.Panels[2].Text);

    // ── 8. INI 设置往返（11 章坑：ASCII 键）──
    ini1 := 'selftest_ini1.ini';
    ini2 := 'selftest_ini2.ini';
    f.ActWordWrap.Checked := True;
    f.ActReadOnly.Checked := True;
    f.SaveSettings(ini1);
    f.ActWordWrap.Checked := False;
    f.ActReadOnly.Checked := False;
    f.LoadSettings(ini1);
    Check(f.ActWordWrap.Checked, 'INI 往返：wordwrap');
    Check(f.ActReadOnly.Checked, 'INI 往返：readonly');
    Check(f.CurrentDoc.Memo.WordWrap, '选项已应用到编辑器');
    WriteLn(Log, '8 INI 往返：wordwrap/readonly 保存重载一致');

    // ── 9. 清理 ──
    DeleteFile(tmp);
    DeleteFile(ini1);
    DeleteFile(ini2);
    WriteLn(Log, '9 清理临时文件完成');

    WriteLn(Log, CheckSummary);
    WriteLn(Log, '==== 40 selftest OK ====');
  finally
    CloseFile(Log);
    f.Free;
  end;
end;

var
  ErrLog: TextFile;
  MainForm: TMainForm;

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
  MainForm := TMainForm.Create(nil);
  MainForm.Show;
  Application.Run;
  MainForm.Free;
end.
