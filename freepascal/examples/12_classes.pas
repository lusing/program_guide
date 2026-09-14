program ClassesDemo;

type
  TPerson = class
  private
    FName: String;
  public
    constructor Create(name: String);
    procedure Show;
  end;

constructor TPerson.Create(name: String);
begin
  FName := name;
end;

procedure TPerson.Show;
begin
  WriteLn('Person: ', FName);
end;

var
  p: TPerson;

begin
  p := TPerson.Create('Ada');
  p.Show;
  p.Free;
end.
