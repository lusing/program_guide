program FileIODemo;

uses
  SysUtils;

var
  f: TextFile;
  s: String;

begin
  AssignFile(f, 'demo_output.txt');
  Rewrite(f);
  WriteLn(f, 'Hello from Pascal file output');
  CloseFile(f);

  AssignFile(f, 'demo_output.txt');
  Reset(f);
  ReadLn(f, s);
  CloseFile(f);

  WriteLn('Read from file: ', s);
  DeleteFile('demo_output.txt');
end.
