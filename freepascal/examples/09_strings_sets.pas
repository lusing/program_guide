program StringsSetsDemo;

var
  name: String;
  letters: set of Char;

begin
  name := 'Free Pascal';
  WriteLn('Name length = ', Length(name));
  WriteLn('First char = ', name[1]);

  letters := ['a', 'e', 'i', 'o', 'u'];
  if 'e' in letters then
    WriteLn('e is in the set')
  else
    WriteLn('e is missing');
end.
