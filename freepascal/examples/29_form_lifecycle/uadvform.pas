{$mode objfpc}{$codepage utf8}{$H+}
unit uadvform;
{ 29 · 窗体继承的子窗体：class(TBaseForm) + inherited .lfm（根级差异）。
  22 章 Frame 继承同款机制与同款坑：子控件属性覆盖写代码（inherited 子块运行时会炸）。 }

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls,
  ubaseform { TBaseForm };

type
  TAdvForm = class(TBaseForm)
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

{$R *.lfm}

constructor TAdvForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);      // 父资源（ubaseform.lfm）先装配，再叠本单元 lfm 差异
  LblTitle.Caption := '高级设置（子窗体改的）';   // 子控件覆盖走代码
end;

end.
