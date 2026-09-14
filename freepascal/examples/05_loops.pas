program LoopsDemo;

var
  i: Integer;

begin
  WriteLn('for loop:');
  for i := 1 to 5 do
    WriteLn(i);

  WriteLn('while loop:');
  i := 1;
  while i <= 3 do
  begin
    WriteLn(i * 10);
    Inc(i);
  end;

  WriteLn('repeat loop:');
  i := 5;
  repeat
    WriteLn(i);
    Dec(i);
  until i = 0;
end.
