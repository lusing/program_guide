program ProceduresDemo;

procedure PrintMessage(msg: String);
begin
  WriteLn('Message: ', msg);
end;

function Square(x: Integer): Integer;
begin
  Square := x * x;
end;

begin
  PrintMessage('Hello from procedure');
  WriteLn('Square(9) = ', Square(9));
end.
