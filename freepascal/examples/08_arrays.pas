program ArraysDemo;

var
  nums: array[0..4] of Integer;
  i: Integer;

begin
  for i := 0 to 4 do
    nums[i] := (i + 1) * 10;

  for i := 0 to 4 do
    WriteLn('nums[', i, '] = ', nums[i]);
end.
