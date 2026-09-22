{$mode objfpc}{$codepage utf8}{$H+}
unit ubaseform;
{ 29 · 窗体继承的父窗体：.lfm 配对（{$R *.lfm}），子窗体声明 class(TBaseForm)
  再配 inherited .lfm。见 docs/29-form-lifecycle.md。 }

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls;

type
  TBaseForm = class(TForm)
    LblTitle: TLabel;
    BtnOk: TButton;
    BtnCancel: TButton;
  end;

implementation

{$R *.lfm}

end.
