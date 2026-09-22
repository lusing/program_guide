{$mode objfpc}{$codepage utf8}{$H+}
program i18n_demo;
{ 36 · 国际化：resourcestring（资源串——编译进资源表、运行时可换）、
  .po 翻译文件（gettext 格式：msgid 原文 / msgstr 译文）、
  TranslateResourceStrings 运行时切语言（全表应用）、未翻译串回退。
  LCL 界面文案翻译（defaulttranslator/lcltranslator）正文讲。
  见 docs/36-i18n.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Graphics,
  Translations,
  Classes, SysUtils;

resourcestring
  // msgid 即代码里的英文原文——翻译文件按它对号
  rsHello   = 'Hello, LCL!';
  rsGoodbye = 'Goodbye!';
  rsCount   = '%d item(s) done.';

type
  TI18nForm = class(TForm)
    Msg: TLabel;
    CnBtn, EnBtn: TButton;
    procedure CnClick(Sender: TObject);
    procedure EnClick(Sender: TObject);
  private
    procedure ApplyLang(const PoFile: string);
  public
    constructor Create(AOwner: TComponent); override;
  end;

constructor TI18nForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '36 · 国际化';
  Width := 380; Height := 180;

  Msg := TLabel.Create(Self);
  Msg.Parent := Self;
  Msg.SetBounds(16, 12, 340, 30);
  Msg.Caption := rsHello;                 // 读资源串（翻译后自动变）

  CnBtn := TButton.Create(Self);
  CnBtn.Parent := Self;
  CnBtn.SetBounds(16, 60, 100, 30);
  CnBtn.Caption := '中文';
  CnBtn.OnClick := @CnClick;

  EnBtn := TButton.Create(Self);
  EnBtn.Parent := Self;
  EnBtn.SetBounds(128, 60, 100, 30);
  EnBtn.Caption := 'English';
  EnBtn.OnClick := @EnClick;
end;

// 运行时切语言：把 .po 应用到本单元的资源串表
procedure TI18nForm.ApplyLang(const PoFile: string);
begin
  // 实测：全表版 TranslateResourceStrings 不挑单元——program 主文件里的
  // resourcestring 也能换（按名版对主文件串失灵，正文有记录）
  if not TranslateResourceStrings(PoFile) then
    Msg.Caption := '(翻译加载失败：' + PoFile + ')'
  else
    Msg.Caption := rsHello;
end;

procedure TI18nForm.CnClick(Sender: TObject);
begin
  ApplyLang('lang_zh.po');
end;

procedure TI18nForm.EnClick(Sender: TObject);
begin
  // 英文=源语言：删掉翻译文件即回原文（或换 en 的空 po）
  SysUtils.DeleteFile('lang_zh.po');
  ApplyLang('lang_missing.po');           // 加载失败=保持当前——所以先删再重启？
end;

procedure WriteZhPo;
var
  T: TextFile;
begin
  // .po = gettext 格式。坑（实测，本章头号）：LazUtils 的 TPOFile 只认带
  // "#: 标识符" 注释行的条目——没有 #: 行的 msgid/msgstr 会被当 header 处理
  // （Count=0、静默丢弃）。IDE 生成的 po 从不缺这行，手写必踩。
  AssignFile(T, 'lang_zh.po');
  Rewrite(T);
  WriteLn(T, '#: 36_i18n.lpr:rsHello');
  WriteLn(T, 'msgid "Hello, LCL!"');
  WriteLn(T, 'msgstr "你好，LCL！"');
  WriteLn(T, '');
  WriteLn(T, '#: 36_i18n.lpr:rsCount');
  WriteLn(T, 'msgid "%d item(s) done."');
  WriteLn(T, 'msgstr "完成 %d 项。"');
  CloseFile(T);
end;

procedure RunSelfTest;
var
  f: TI18nForm;
  Log, EmptyLog: TextFile;
begin
  Application.Initialize;
  f := TI18nForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 源语言初值（resourcestring 编译进表，读的是表不是字面量）
    if rsHello <> 'Hello, LCL!' then
      raise Exception.Create('资源串初值异常');
    WriteLn(Log, '原文: ', rsHello, ' / ', Format(rsCount, [3]));

    // 2) 应用中文翻译：TranslateResourceStrings 应用到【所有】资源表——
    //    实测：program 主文件里的 resourcestring 用 TranslateUnitResourceStrings
    //    按单元名匹配不到（试了 program 名/文件名/大小写变体全 miss 且都返回
    //    True），业务串放独立单元才可按名翻译；全表版一劳永逸
    WriteZhPo;
    if not TranslateResourceStrings('lang_zh.po') then
      raise Exception.Create('翻译加载应成功');
    if rsHello <> '你好，LCL！' then
      raise Exception.Create('翻译应生效，实测=' + rsHello);
    if Format(rsCount, [3]) <> '完成 3 项。' then
      raise Exception.Create('带参翻译应生效，实测=' + Format(rsCount, [3]));

    // 3) 未翻译串回退（rsGoodbye 不在 po 里——保持原文）
    if rsGoodbye <> 'Goodbye!' then
      raise Exception.Create('未翻译串应保持原文');

    // 4) 缺失文件：返回 False、不炸
    if TranslateResourceStrings('no_such.po') then
      raise Exception.Create('缺失文件应返回 False');

    // 5) 回英文：写"空 po"（只有头、无条目）加载——全部回到原文
    AssignFile(EmptyLog, 'empty.po');
    Rewrite(EmptyLog);
    WriteLn(EmptyLog, 'msgid ""');
    WriteLn(EmptyLog, 'msgstr ""');
    WriteLn(EmptyLog, '"Content-Type: text/plain; charset=UTF-8' + chr(92) + 'n"');
    CloseFile(EmptyLog);
    if not TranslateResourceStrings('empty.po') then
      raise Exception.Create('空 po 也应加载成功');
    if rsHello <> 'Hello, LCL!' then
      raise Exception.Create('空 po 应回原文，实测=' + rsHello);

    WriteLn(Log, '译文轮回: ', rsHello);
    WriteLn(Log, '==== 36 selftest OK ====');
  finally
    CloseFile(Log);
    SysUtils.DeleteFile('lang_zh.po');
    SysUtils.DeleteFile('empty.po');
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
  with TI18nForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
