unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls;

type
  TMainForm = class(TForm)
    BtnAdd: TButton;
    BtnClear: TButton;
    CbEnable: TCheckBox;
    CbTheme: TComboBox;
    EdName: TEdit;
    LblStatus: TLabel;
    LstItems: TListBox;
    MemoLog: TMemo;
    RadioGroup: TRadioGroup;
    procedure BtnAddClick(Sender: TObject);
    procedure BtnClearClick(Sender: TObject);
    procedure CbEnableChange(Sender: TObject);
    procedure CbThemeChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RadioGroupClick(Sender: TObject);
  private
    procedure RefreshStatus;
  public
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  CbTheme.Items.Add('Classic');
  CbTheme.Items.Add('Dark');
  CbTheme.Items.Add('Modern');
  CbTheme.ItemIndex := 0;

  RadioGroup.Items.Clear;
  RadioGroup.Items.Add('Beginner');
  RadioGroup.Items.Add('Intermediate');
  RadioGroup.Items.Add('Advanced');
  RadioGroup.ItemIndex := 1;

  MemoLog.Clear;
  MemoLog.Lines.Add('Advanced controls demo ready.');
  RefreshStatus;
end;

procedure TMainForm.RefreshStatus;
begin
  if CbEnable.Checked then
    LblStatus.Caption := 'Controls enabled: ' + CbTheme.Text + ' / ' + RadioGroup.Items[RadioGroup.ItemIndex]
  else
    LblStatus.Caption := 'Controls disabled';
end;

procedure TMainForm.BtnAddClick(Sender: TObject);
begin
  if Trim(EdName.Text) = '' then
  begin
    MemoLog.Lines.Add('Name is empty.');
    Exit;
  end;

  LstItems.Items.Add(EdName.Text);
  MemoLog.Lines.Add('Added: ' + EdName.Text);
  EdName.Clear;
  RefreshStatus;
end;

procedure TMainForm.BtnClearClick(Sender: TObject);
begin
  LstItems.Clear;
  MemoLog.Lines.Add('List cleared.');
  RefreshStatus;
end;

procedure TMainForm.CbEnableChange(Sender: TObject);
begin
  EdName.Enabled := CbEnable.Checked;
  BtnAdd.Enabled := CbEnable.Checked;
  BtnClear.Enabled := CbEnable.Checked;
  CbTheme.Enabled := CbEnable.Checked;
  RadioGroup.Enabled := CbEnable.Checked;
  RefreshStatus;
end;

procedure TMainForm.CbThemeChange(Sender: TObject);
begin
  MemoLog.Lines.Add('Theme changed to: ' + CbTheme.Text);
  RefreshStatus;
end;

procedure TMainForm.RadioGroupClick(Sender: TObject);
begin
  MemoLog.Lines.Add('Selected level: ' + RadioGroup.Items[RadioGroup.ItemIndex]);
  RefreshStatus;
end;

end.
