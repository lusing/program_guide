{$mode objfpc}{$codepage utf8}{$H+}
unit uhelloform;
{ 15 · 主窗体单元——与 uhelloform.lfm 配对：{$R *.lfm} 把窗体描述链进程序，
  Create 时流机制按 lfm 建 Published 字段对应的控件。正文见 docs/15-lazarus.md。 }

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls;

type
  // 字段写在【默认可见性】（不写 private/public）——TForm 祖先带 {$M+}，
  // 默认段即 published，流机制靠 RTTI 找到它们并填充
  TMainForm = class(TForm)
    BtnHello: TButton;
    LblMessage: TLabel;
    procedure BtnHelloClick(Sender: TObject);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}                       // 窗体资源：lazbuild 自动把 .lfm 编译成资源挂到这里

procedure TMainForm.BtnHelloClick(Sender: TObject);
begin
  LblMessage.Caption := '你好，Lazarus！';
end;

end.
