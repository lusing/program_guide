program LazarusGuiDemo;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Forms,
  Unit1;

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
