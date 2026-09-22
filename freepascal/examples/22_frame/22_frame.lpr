{$mode objfpc}{$codepage utf8}{$H+}
program frame_demo;
{ 22 · TFrame 与界面复用：同一 Frame 类实例化两次（状态互不干扰）、
  嵌进不同容器（窗体 / TPanel）、Frame 继承（TLangFrame = class(TAddressFrame)
  配 inherited .lfm）。坑：Frame 没有 CreateNew——Create 必须找到同名 .lfm 资源。
  正文见 docs/22-frames.md。 }

uses
  Interfaces, Forms, Controls, StdCtrls, ExtCtrls, Graphics,
  uaddressframe { TAddressFrame },
  ulangframe { TLangFrame },
  Classes, SysUtils;

type
  TFrameForm = class(TForm)
    FrameA, FrameB: TAddressFrame;
    Lang: TLangFrame;
    Log: TMemo;
  public
    constructor Create(AOwner: TComponent); override;
  end;

constructor TFrameForm.Create(AOwner: TComponent);
var
  HostPanel: TPanel;
begin
  inherited CreateNew(AOwner);
  Caption := '22 · TFrame 复用与继承';
  Width := 700; Height := 420;

  // 实例 A：直接挂窗体
  FrameA := TAddressFrame.Create(Self);     // Create 里完成 .lfm 流装配
  FrameA.Parent := Self;
  FrameA.SetBounds(16, 12, 320, 56);
  FrameA.SetAddress('张三', '北京');

  // 实例 B：挂进 Panel——同一类、独立状态
  HostPanel := TPanel.Create(Self);
  HostPanel.Parent := Self;
  HostPanel.SetBounds(16, 76, 340, 76);
  HostPanel.Caption := '';
  FrameB := TAddressFrame.Create(Self);
  FrameB.Parent := HostPanel;               // Frame 嵌 Panel：Parent 指容器
  FrameB.SetBounds(8, 8, 320, 56);
  FrameB.SetAddress('李四', '上海');

  // 子类 Frame：inherited .lfm + 代码追加的国家下拉
  Lang := TLangFrame.Create(Self);
  Lang.Parent := Self;
  Lang.SetBounds(16, 168, 320, 92);

  Log := TMemo.Create(Self);
  Log.Parent := Self;
  Log.Align := alBottom;
  Log.Height := 120;
  Log.ReadOnly := True;
  Log.Lines.Append('A=' + FrameA.FullAddress);
  Log.Lines.Append('B=' + FrameB.FullAddress);
  Log.Lines.Append('Lang 收件人标签=' + Lang.LblName.Caption);
end;

procedure RunSelfTest;
var
  f: TFrameForm;
  Log: TextFile;
begin
  Application.Initialize;
  f := TFrameForm.Create(nil);
  AssignFile(Log, 'selftest.log');
  Rewrite(Log);
  try
    // 1) 两实例状态独立
    if (f.FrameA.EdName.Text <> '张三') or (f.FrameB.EdName.Text <> '李四') then
      raise Exception.Create('两 Frame 实例应各自持有状态');
    f.FrameB.SetAddress('王五', '广州');
    if f.FrameA.EdName.Text <> '张三' then
      raise Exception.Create('改 B 不应影响 A');

    // 2) 公共 API 与事件（TEdit 程序赋值触发 OnChange——16 章实测过）
    f.FrameA.EdNameChangeCount := 0;
    f.FrameA.SetAddress('赵六', '深圳');
    if f.FrameA.EdNameChangeCount < 1 then
      raise Exception.Create('TEdit 程序赋值应触发 Frame 内 OnChange');
    if f.FrameA.FullAddress <> '赵六 @ 深圳' then
      raise Exception.Create('FullAddress 拼接异常');

    // 3) Clear 语义
    f.FrameB.ClearAddress;
    if (f.FrameB.EdName.Text <> '') or (f.FrameB.EdCity.Text <> '') then
      raise Exception.Create('ClearAddress 未清空');

    // 4) Frame 继承：既是子类也是父类；lfm 差异生效；代码追加控件在位
    if not (f.Lang is TAddressFrame) then
      raise Exception.Create('TLangFrame 应 is TAddressFrame');
    if f.Lang.LblName.Caption <> '收件人' then
      raise Exception.Create('inherited lfm 应改掉姓名标签，实测=' + f.Lang.LblName.Caption);
    if f.Lang.CbCountry = nil then
      raise Exception.Create('子类代码追加控件缺失');
    if (f.Lang.CbCountry.Items.Count <> 2) or (f.Lang.CbCountry.ItemIndex <> 0) then
      raise Exception.Create('国家下拉内容异常');

    // 5) 子类继承父级行为（事件处理器同一路径）
    f.Lang.EdNameChangeCount := 0;
    f.Lang.SetAddress('钱七', '杭州');
    if f.Lang.EdNameChangeCount < 1 then
      raise Exception.Create('子类应沿用父级事件');

    // 6) 嵌套容器核对（FrameB 的父是 Panel 不是窗体）
    if f.FrameB.Parent = f then
      raise Exception.Create('FrameB 应嵌在 Panel 里');

    WriteLn(Log, 'A=', f.FrameA.FullAddress, ' Lang=', f.Lang.FullAddress,
      ' 国家=', f.Lang.CbCountry.Items[f.Lang.CbCountry.ItemIndex]);
    WriteLn(Log, '==== 22 selftest OK ====');
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
  with TFrameForm.Create(nil) do
  begin
    Show;
    Application.Run;
    Free;
  end;
end.
