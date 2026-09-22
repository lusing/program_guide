{$mode objfpc}{$codepage utf8}{$H+}
program component_stream_demo;
{ 35 · 组件流与对象持久化：.lfm 的真相——WriteComponentAsTextToStream 把
  组件树写成文本流（.lfm 就是它）；ReadComponentFromTextStream 读回重建；
  TWriter/TReader 二进制通道；default 指令的存储语义（=默认值不落流）。
  正文见 docs/35-component-stream.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Graphics, LResources,
  Classes, SysUtils;

type
  TStreamForm = class(TForm)
    SrcPanel: TPanel;
    Info: TLabel;
    // 坑（实测）：ReadComponentFromBinaryStream 直呼 OnFindComponentClass
    // 而不查 nil——不传 handler = AV。自备一个走 RegisterClass 表：
    procedure FindClass(Reader: TReader; const AClassName: string;
      var AClass: TComponentClass);
  public
    constructor Create(AOwner: TComponent); override;
  end;

  { 非视觉组件走同一套流：用它实证 default 指令的存储语义 }
  TMiniCfg = class(TComponent)
  private
    FX: Integer;
    FY: Integer;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property X: Integer read FX write FX default 7;    // 声明默认 7
    property Y: Integer read FY write FY;              // 无 default
  end;

constructor TMiniCfg.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FX := 7;                       // ★ default 只是"存储约定"——初值仍要手工给
end;

procedure TStreamForm.FindClass(Reader: TReader; const AClassName: string;
  var AClass: TComponentClass);
begin
  AClass := TComponentClass(GetClass(AClassName));   // RegisterClass 注册过的都能建
end;

constructor TStreamForm.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner);
  Caption := '35 · 组件流';
  Width := 520; Height := 300;

  SrcPanel := TPanel.Create(Self);
  SrcPanel.Parent := Self;
  SrcPanel.SetBounds(16, 12, 300, 80);
  SrcPanel.Name := 'SrcPanel';          // 实测：无名 root 落流后读回 AV——
  SrcPanel.Caption := '源面板';          // root 也要有 Name（IDE 窗体从来都有）

  with TButton.Create(SrcPanel) do      // 子控件（组件树=流的作用域）
  begin
    Parent := SrcPanel;
    SetBounds(8, 8, 120, 28);
    Name := 'InnerBtn';                 // 要进流必须有 Name（无名的直接丢）
    Caption := '内部按钮';
  end;

  Info := TLabel.Create(Self);
  Info.Parent := Self;
  Info.SetBounds(16, 104, 480, 170);
  Info.Caption := 'selftest：写出→读回→逐属性对照（详见 selftest.log）';
end;

procedure RunSelfTest;
var
  f: TStreamForm;
  Log: TextFile;
  Txt: TStringStream;
  Restored: TPanel;
  Btn: TComponent;
  Cfg, Cfg2: TMiniCfg;
  Bin: TMemoryStream;
  Round: TPanel;
begin
  Application.Initialize;
  RegisterClass(TPanel);       // 流读回时的类解析表（无 OnFindComponent 时走这）
  RegisterClass(TButton);
  RegisterClass(TMiniCfg);
  f := TStreamForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 写出：组件树 → 文本流（.lfm 的机器生成版）
    Txt := TStringStream.Create('');
    try
      WriteComponentAsTextToStream(Txt, f.SrcPanel);
      if Pos('object', Txt.DataString) = 0 then
        raise Exception.Create('文本流应含 object 行');
      if Pos('Caption = ''源面板''', Txt.DataString) = 0 then
        raise Exception.Create('属性应按 .lfm 语法落流');
      WriteLn(Log, '── 流文本（截选）──');
      WriteLn(Log, Copy(Txt.DataString, 1, 260));

      // 2) 读回：文本流 → 新组件树（RegisterClass 表解析 TPanel/TButton）
      Txt.Position := 0;
      Restored := TPanel.Create(nil);
      ReadComponentFromTextStream(Txt, TComponent(Restored), @f.FindClass, nil, nil);
      if Restored.Caption <> f.SrcPanel.Caption then
        raise Exception.Create('读回根属性异常');
      Btn := Restored.FindComponent('InnerBtn');
      if (Btn = nil) or not (Btn is TButton) then
        raise Exception.Create('子控件未随流重建');
      if TButton(Btn).Caption <> '内部按钮' then
        raise Exception.Create('子控件属性异常');
      WriteLn(Log, '读回: Panel.Caption=', Restored.Caption,
        ' 子数=', Restored.ComponentCount);

      // 3) default 指令实证：等于默认值的属性不落流
      Txt.Clear;  Txt.Position := 0;
      Cfg := TMiniCfg.Create(f);
      WriteComponentAsTextToStream(Txt, Cfg);
      if Pos('X =', Txt.DataString) > 0 then
        raise Exception.Create('X=7（等于 default）不应落流');
      Cfg.Y := 42;
      Txt.Clear;  Txt.Position := 0;
      WriteComponentAsTextToStream(Txt, Cfg);
      if Pos('Y = 42', Txt.DataString) = 0 then
        raise Exception.Create('Y=42（无默认）应落流');
      WriteLn(Log, 'default 语义: X=7 省略；Y=42 落流');

      // 4) 二进制通道（.res 里就是它）：LResources 的封装函数
      //    （实测：裸 TWriter/TReader 缺"根组件头"仪式直接 AV——
      //     裸用还得 Driver.BeginRootComponent 配对，初学别碰，用封装）
      Bin := TMemoryStream.Create;
      try
        WriteComponentAsBinaryToStream(Bin, Cfg);
        Bin.Position := 0;
        Cfg2 := TMiniCfg.Create(f);
        try
          ReadComponentFromBinaryStream(Bin, TComponent(Cfg2), @f.FindClass, nil, nil);
          if (Cfg2.X <> 7) or (Cfg2.Y <> 42) then
            raise Exception.Create('二进制往返异常');
        finally
          Cfg2.Free;
        end;
      finally
        Bin.Free;
      end;

      // 5) 再来一轮文本读回（同一流可多次装新对象）
      Txt.Clear;  Txt.Position := 0;
      WriteComponentAsTextToStream(Txt, f.SrcPanel);
      Txt.Position := 0;
      Round := TPanel.Create(nil);
      ReadComponentFromTextStream(Txt, TComponent(Round), @f.FindClass, nil, nil);
      if Round.ComponentCount <> f.SrcPanel.ComponentCount then
        raise Exception.Create('多轮往返子组件数不一致');
      Round.Free;
    finally
      Txt.Free;
    end;

    WriteLn(Log, '==== 35 selftest OK ====');
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
  with TStreamForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
