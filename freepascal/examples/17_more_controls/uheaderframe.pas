{$mode objfpc}{$codepage utf8}{$H+}
unit uheaderframe;
{ 17 · TFrame 单元：Frame 与 .lfm 配对（{$R *.lfm}），像窗体一样被流加载。
  实测：TFrame.Create 必须找到同名资源——纯代码建 Frame 没有 CreateNew 可逃，
  "Resource THeaderFrame not found" 就是没配 .lfm 的症状。 }

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls;

type
  THeaderFrame = class(TFrame)
    LblTitle: TLabel;
    BtnPing: TButton;
    procedure BtnPingClick(Sender: TObject);
  public
    ClickCount: Integer;
  end;

implementation

{$R *.lfm}

procedure THeaderFrame.BtnPingClick(Sender: TObject);
begin
  Inc(ClickCount);
  LblTitle.Caption := Format('Frame 点击 %d 次', [ClickCount]);
end;

end.
