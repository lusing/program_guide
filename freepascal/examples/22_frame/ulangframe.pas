{$mode objfpc}{$codepage utf8}{$H+}
unit ulangframe;
{ 22 · Frame 继承：子 Frame 声明为 class(TAddressFrame)、配自己的 .lfm
  （首行 inherited AddressFrame: TLangFrame——流装载器先装父再叠加差异）。
  子类可覆盖 lfm 属性（这里把姓名标签改成"收件人"）+ 代码加新控件（国家下拉）。
  见 docs/22-frames.md。 }

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls,
  uaddressframe { TAddressFrame };

type
  TLangFrame = class(TAddressFrame)
    CbCountry: TComboBox;      // 代码加的新控件（不在 .lfm 里——inherited 流之后创建）
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.lfm}

constructor TLangFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);           // 先走父级流装配（含本单元 lfm 的根级差异）
  Height := 92;
  // 坑（实测）：inherited .lfm 里写 "inherited LblName: TLabel" 子块，
  // 运行时报 Duplicate name——子控件属性覆盖放代码里最稳（根级属性覆盖没问题）
  LblName.Caption := '收件人';
  CbCountry := TComboBox.Create(Self);
  CbCountry.Parent := Self;
  CbCountry.SetBounds(56, 40, 120, 25);
  CbCountry.Items.Add('中国');
  CbCountry.Items.Add('日本');
  CbCountry.ItemIndex := 0;
end;

end.
