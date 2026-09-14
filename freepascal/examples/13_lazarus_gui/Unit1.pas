unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  TMainForm = class(TForm)
    BtnHello: TButton;
    LblMessage: TLabel;
    procedure BtnHelloClick(Sender: TObject);
  private

  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

procedure TMainForm.BtnHelloClick(Sender: TObject);
begin
  LblMessage.Caption := 'Lazarus GUI works!';
end;

end.
