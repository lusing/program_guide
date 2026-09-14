unit MainForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, StdCtrls;

type
  TMainWindow = class(TForm)
  private
    FMainMenu: TMainMenu;
    FMenuFile: TMenuItem;
    FMenuOpen: TMenuItem;
    FMenuExit: TMenuItem;
    FMenuHelp: TMenuItem;
    FMenuAbout: TMenuItem;
    FBtnOpenDialog: TButton;
    FMemoStatus: TMemo;
    FFileDialog: TOpenDialog;
    procedure MenuOpenClick(Sender: TObject);
    procedure MenuExitClick(Sender: TObject);
    procedure MenuAboutClick(Sender: TObject);
    procedure BtnOpenDialogClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  MainWindow: TMainWindow;

implementation

uses
  SecondForm;

constructor TMainWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Caption := 'Lazarus Menus and Dialogs';
  Width := 560;
  Height := 430;
  Position := poScreenCenter;
  BorderStyle := bsSizeable;

  FMemoStatus := TMemo.Create(Self);
  FMemoStatus.Parent := Self;
  FMemoStatus.Left := 24;
  FMemoStatus.Top := 72;
  FMemoStatus.Width := 500;
  FMemoStatus.Height := 240;
  FMemoStatus.ScrollBars := ssVertical;
  FMemoStatus.Text := 'Application started.' + LineEnding;

  FBtnOpenDialog := TButton.Create(Self);
  FBtnOpenDialog.Parent := Self;
  FBtnOpenDialog.Left := 24;
  FBtnOpenDialog.Top := 24;
  FBtnOpenDialog.Width := 160;
  FBtnOpenDialog.Caption := 'Choose file';
  FBtnOpenDialog.OnClick := @BtnOpenDialogClick;

  FMainMenu := TMainMenu.Create(Self);

  FMenuFile := TMenuItem.Create(FMainMenu);
  FMenuFile.Caption := '&File';

  FMenuOpen := TMenuItem.Create(FMainMenu);
  FMenuOpen.Caption := '&Open';
  FMenuOpen.OnClick := @MenuOpenClick;

  FMenuExit := TMenuItem.Create(FMainMenu);
  FMenuExit.Caption := 'E&xit';
  FMenuExit.OnClick := @MenuExitClick;

  FMenuHelp := TMenuItem.Create(FMainMenu);
  FMenuHelp.Caption := '&Help';

  FMenuAbout := TMenuItem.Create(FMainMenu);
  FMenuAbout.Caption := '&About';
  FMenuAbout.OnClick := @MenuAboutClick;

  FMenuFile.Add(FMenuOpen);
  FMenuFile.Add(FMenuExit);
  FMenuHelp.Add(FMenuAbout);

  FMainMenu.Items.Add(FMenuFile);
  FMainMenu.Items.Add(FMenuHelp);
  Menu := FMainMenu;

  FFileDialog := TOpenDialog.Create(Self);
  FFileDialog.Filter := 'All files|*.*';
  FFileDialog.Title := 'Select a file';
end;

procedure TMainWindow.MenuOpenClick(Sender: TObject);
begin
  FMemoStatus.Lines.Add('Menu: Open selected');
  with TSecondWindow.Create(nil) do
  begin
    ShowModal;
    Free;
  end;
end;

procedure TMainWindow.MenuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TMainWindow.MenuAboutClick(Sender: TObject);
begin
  ShowMessage('Free Pascal / Lazarus multi-window demo');
end;

procedure TMainWindow.BtnOpenDialogClick(Sender: TObject);
begin
  if FFileDialog.Execute then
    FMemoStatus.Lines.Add('Selected file: ' + FFileDialog.FileName)
  else
    FMemoStatus.Lines.Add('Dialog canceled.');
end;

end.
