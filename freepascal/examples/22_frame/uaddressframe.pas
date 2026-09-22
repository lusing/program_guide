{$mode objfpc}{$codepage utf8}{$H+}
unit uaddressframe;
{ 22 · TFrame 基础单元：Frame = 可嵌入窗体/面板的迷你窗体，天生与 .lfm 配对
  （{$R *.lfm}，Create 从流装配——没有 CreateNew 逃生门）。
  Frame 是真类：公共 API（SetAddress/Clear/计数器）与事件一样不少。
  见 docs/22-frames.md。 }

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls;

type
  TAddressFrame = class(TFrame)
    LblName: TLabel;
    EdName: TEdit;
    LblCity: TLabel;
    EdCity: TEdit;
    procedure EdNameChange(Sender: TObject);
  public
    EdNameChangeCount: Integer;
    function FullAddress: string;
    procedure SetAddress(const AName, ACity: string);
    procedure ClearAddress;
  end;

implementation

{$R *.lfm}

procedure TAddressFrame.EdNameChange(Sender: TObject);
begin
  Inc(EdNameChangeCount);      // TEdit 程序赋值也触发（与 TMemo 相反——16 章实测）
end;

function TAddressFrame.FullAddress: string;
begin
  Result := EdName.Text + ' @ ' + EdCity.Text;
end;

procedure TAddressFrame.SetAddress(const AName, ACity: string);
begin
  EdName.Text := AName;
  EdCity.Text := ACity;
end;

procedure TAddressFrame.ClearAddress;
begin
  EdName.Clear;
  EdCity.Clear;
end;

end.
