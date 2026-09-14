program PointersDemo;

var
  p: ^Integer;

begin
  New(p);
  p^ := 42;
  WriteLn('Value = ', p^);
  Dispose(p);
end.
