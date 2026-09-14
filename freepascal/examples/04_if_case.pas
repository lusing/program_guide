program IfCaseDemo;

var
  x: Integer;
  ch: Char;

begin
  x := 8;
  if x > 10 then
    WriteLn('x > 10')
  else if x = 8 then
    WriteLn('x = 8')
  else
    WriteLn('x < 8');

  ch := 'b';
  case ch of
    'a': WriteLn('A');
    'b': WriteLn('B');
    'c': WriteLn('C');
    else WriteLn('Other');
  end;
end.
