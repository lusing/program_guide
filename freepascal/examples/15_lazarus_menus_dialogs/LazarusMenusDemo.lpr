program LazarusMenusDemo;

{$mode objfpc}{$H+}

uses
  Interfaces,
  Forms,
  MainForm;

begin
  Application.Initialize;
  Application.CreateForm(TMainWindow, MainWindow);
  Application.Run;
end.
