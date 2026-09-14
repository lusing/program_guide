unit SecondForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type
  TSecondWindow = class(TForm)
  private
    FInfoLabel: TLabel;
    FCloseButton: TButton;
    procedure CloseButtonClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

constructor TSecondWindow.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Caption := 'Details';
  Width := 360;
  Height := 220;
  Position := poScreenCenter;

  FInfoLabel := TLabel.Create(Self);
  FInfoLabel.Parent := Self;
  FInfoLabel.Left := 24;
  FInfoLabel.Top := 30;
  FInfoLabel.Width := 300;
  FInfoLabel.Height := 80;
  FInfoLabel.Caption := 'This is the secondary window.' + LineEnding +
    'It demonstrates a multi-window Lazarus UI.';
  FInfoLabel.WordWrap := True;

  FCloseButton := TButton.Create(Self);
  FCloseButton.Parent := Self;
  FCloseButton.Left := 110;
  FCloseButton.Top := 130;
  FCloseButton.Width := 120;
  FCloseButton.Caption := 'Close';
  FCloseButton.OnClick := @CloseButtonClick;
end;

procedure TSecondWindow.CloseButtonClick(Sender: TObject);
begin
  Close;
end;

end.
