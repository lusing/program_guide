{$mode objfpc}{$codepage utf8}{$H+}
program controls_demo;
{ 16 · 事件模型与基础控件：OnClick/OnChange/OnKeyDown、Sender、输入/按钮/选择/容器
  控件矩阵（纯代码创建——不写 .lfm，"每个控件怎么来"全在眼前）。
  正文见 docs/16-controls.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Buttons,
  Classes, SysUtils;

type
  TPlaygroundForm = class(TForm)
    Log: TMemo;                 // 事件日志：可视化验证事件流
    EdName: TEdit;
    LblLen: TLabel;
    BtnClear: TButton;
    SpeedDemo: TSpeedButton;
    ChkBold: TCheckBox;
    RadioLang: TRadioGroup;
    ComboFruit: TComboBox;
    Group: TGroupBox;
    Panel: TPanel;
    procedure BtnClearClick(Sender: TObject);
    procedure EdNameChange(Sender: TObject);
    procedure EdNameKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ChkBoldClick(Sender: TObject);
    procedure RadioLangSelectionChanged(Sender: TObject);
    procedure ComboFruitChange(Sender: TObject);
    procedure AnyClick(Sender: TObject);       // Sender 分辦演示：一个处理器接多个控件
  public
    constructor Create(AOwner: TComponent); override;
    procedure LogLine(const S: string);        // 追加一行事件日志
  end;

constructor TPlaygroundForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);            // 纯代码建窗体：CreateNew 跳过 lfm 流加载
  Caption := '16 · 控件与事件';
  Width := 520; Height := 480;

  // —— 容器层：TPanel 顶、TGroupBox 中、日志垫底 ——
  Panel := TPanel.Create(Self);
  Panel.Parent := Self;                   // Parent 决定"显示在哪"；Owner 决定"谁负责 Free"
  Panel.Align := alTop;
  Panel.Height := 64;
  Panel.Caption := '';

  EdName := TEdit.Create(Self);
  EdName.Parent := Panel;
  EdName.SetBounds(8, 8, 200, 28);
  EdName.TextHint := '输入名字（触发 OnChange/OnKeyDown）';
  EdName.OnChange := @EdNameChange;       // 事件 = 方法指针，objfpc 模式赋值带 @
  EdName.OnKeyDown := @EdNameKeyDown;

  LblLen := TLabel.Create(Self);
  LblLen.Parent := Panel;
  LblLen.SetBounds(216, 14, 200, 20);
  LblLen.Caption := '字节数：0';

  BtnClear := TButton.Create(Self);
  BtnClear.Parent := Panel;
  BtnClear.SetBounds(8, 36, 96, 24);
  BtnClear.Caption := '清空日志';
  BtnClear.OnClick := @BtnClearClick;

  SpeedDemo := TSpeedButton.Create(Self); // SpeedButton：不占 Tab、可按下不放
  SpeedDemo.Parent := Panel;
  SpeedDemo.SetBounds(112, 36, 96, 24);
  SpeedDemo.Caption := '速度键';
  SpeedDemo.OnClick := @AnyClick;

  Group := TGroupBox.Create(Self);        // GroupBox：带标题的容器，视觉分组
  Group.Parent := Self;
  Group.Align := alTop;
  Group.Height := 120;
  Group.Caption := '选择类控件';

  ChkBold := TCheckBox.Create(Self);
  ChkBold.Parent := Group;
  ChkBold.SetBounds(12, 24, 140, 24);
  ChkBold.Caption := '加粗（On/Off）';
  ChkBold.OnClick := @ChkBoldClick;

  RadioLang := TRadioGroup.Create(Self);  // RadioGroup：互斥单选，Items 填选项
  RadioLang.Parent := Group;
  RadioLang.SetBounds(160, 16, 170, 96);
  RadioLang.Caption := '语言';
  RadioLang.Items.Add('Pascal');
  RadioLang.Items.Add('C++');
  RadioLang.Items.Add('Rust');
  RadioLang.ItemIndex := 0;               // 默认选中第一项
  RadioLang.OnSelectionChanged := @RadioLangSelectionChanged;

  ComboFruit := TComboBox.Create(Self);   // ComboBox：下拉选择 + 可输入（csDropDown）
  ComboFruit.Parent := Group;
  ComboFruit.SetBounds(12, 60, 140, 28);
  ComboFruit.Items.Add('苹果');
  ComboFruit.Items.Add('香蕉');
  ComboFruit.Items.Add('橘子');
  ComboFruit.ItemIndex := -1;             // -1 = 无选择
  ComboFruit.OnChange := @ComboFruitChange;

  Log := TMemo.Create(Self);              // TMemo：多行文本（40 章记事本的主角）
  Log.Parent := Self;
  Log.Align := alClient;                  // 占满剩余空间（23 章布局细讲）
  Log.ReadOnly := True;
  Log.ScrollBars := ssAutoVertical;
end;

procedure TPlaygroundForm.LogLine(const S: string);
begin
  Log.Lines.Add(S);
end;

procedure TPlaygroundForm.BtnClearClick(Sender: TObject);
begin
  Log.Clear;
end;

procedure TPlaygroundForm.EdNameChange(Sender: TObject);
begin
  // Sender 就是事件的"肇事者"——同一处理器可服务多个控件
  LblLen.Caption := Format('字节数：%d', [Length((Sender as TEdit).Text)]);
  LogLine(Format('[OnChange] EdName.Text="%s"（%d 字节）', [EdName.Text, Length(EdName.Text)]));
end;

procedure TPlaygroundForm.EdNameKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = 13 then                        // 13 = Enter；命名常量 VK_RETURN 需 LCLType
    LogLine('[OnKeyDown] 按下 Enter');
end;

procedure TPlaygroundForm.ChkBoldClick(Sender: TObject);
begin
  LogLine(Format('[OnClick] ChkBold.Checked=%s', [BoolToStr(ChkBold.Checked, True)]));
end;

procedure TPlaygroundForm.RadioLangSelectionChanged(Sender: TObject);
begin
  LogLine(Format('[OnSelectionChanged] 语言=%s', [RadioLang.Items[RadioLang.ItemIndex]]));
end;

procedure TPlaygroundForm.ComboFruitChange(Sender: TObject);
begin
  if ComboFruit.ItemIndex >= 0 then
    LogLine(Format('[OnChange] 水果=%s', [ComboFruit.Items[ComboFruit.ItemIndex]]));
end;

procedure TPlaygroundForm.AnyClick(Sender: TObject);
begin
  LogLine(Format('[OnClick] Sender=%s', [(Sender as TControl).Caption]));
end;

procedure RunSelfTest;
var
  f: TPlaygroundForm;
  Log: TextFile;
  k: Word;
begin
  Application.Initialize;
  f := TPlaygroundForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    WriteLn(Log, '控件数=', f.ControlCount, '（Panel/Group/Log 三个顶层）');
    if f.ControlCount <> 3 then
      raise Exception.Create('顶层控件数量异常');

    // 程序内赋值 Text 会触发 OnChange（LCL 行为）——日志应记到 Change
    f.EdName.Text := '中文abc';
    if f.Log.Lines.Count < 1 then
      raise Exception.Create('OnChange 未随 Text 赋值触发');
    if f.LblLen.Caption <> '字节数：9' then   // 中文 6 字节 + abc 3 字节
      raise Exception.Create('字节数标签未更新: ' + f.LblLen.Caption);

    k := 13;
    f.EdNameKeyDown(nil, k, []);            // 直接调 key 处理器（var 参数须传变量）
    // 实测：程序化赋值触发事件【因控件而异】——
    //   TCheckBox.Checked := True      → OnClick ✓
    //   TRadioGroup.ItemIndex := 1     → OnSelectionChanged ✓
    //   TComboBox.ItemIndex := 2       → OnChange ✗（不触发，须手动调处理器）
    f.ChkBold.Checked := True;
    f.RadioLang.ItemIndex := 1;
    f.ComboFruit.ItemIndex := 2;
    f.ComboFruitChange(f.ComboFruit);      // 不触发的那类：显式调用，保证确定性
    f.AnyClick(f.BtnClear);

    WriteLn(Log, '日志行数=', f.Log.Lines.Count);
    WriteLn(Log, '首行=', f.Log.Lines[0]);
    WriteLn(Log, '末行=', f.Log.Lines[f.Log.Lines.Count - 1]);
    if f.Log.Lines.Count < 5 then
      raise Exception.Create('事件触发次数不足');
    if Pos('语言=C++', f.Log.Text) = 0 then
      raise Exception.Create('RadioGroup 事件未记录');
    if Pos('水果=橘子', f.Log.Text) = 0 then
      raise Exception.Create('ComboBox 事件未记录');
    if Pos('Sender=清空日志', f.Log.Text) = 0 then
      raise Exception.Create('Sender 分辦失败');
    WriteLn(Log, '==== 16 selftest OK ====');
  finally
    CloseFile(Log);
    f.Free;
  end;
end;

var
  MainForm: TPlaygroundForm;

var
  ErrLog: TextFile;

begin
  if ParamStr(1) = '--selftest' then
  begin
    try
      RunSelfTest;
    except
      // GUI 程序未捕获异常会弹 LCL 消息框（无头环境挂死）——selftest 必须自捕获
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
  MainForm := TPlaygroundForm.Create(nil);   // 纯代码窗体：手动创建/释放（不走流加载）
  MainForm.Show;
  Application.Run;
  MainForm.Free;
end.
