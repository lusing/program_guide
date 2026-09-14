program RecordsDemo;

type
  TPoint = record
    X, Y: Integer;
  end;

var
  p: TPoint;

begin
  p.X := 3;
  p.Y := 4;
  WriteLn('Point: (', p.X, ', ', p.Y, ')');
end.
