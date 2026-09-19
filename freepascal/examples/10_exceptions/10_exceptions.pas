{$mode objfpc}{$codepage utf8}{$H+}
program exceptions_demo;
{ 10 · 异常与资源保护：try/except/finally、类型化捕获、raise/re-raise、
  Exception 家族、自定义异常、Assert。正文见 docs/10-exceptions.md。 }
uses SysUtils, Classes;

type
  // ═══ 10.5 自定义异常：继承 Exception，名字以 E 开头是惯例
  ESalaryError = class(Exception);
  ETooYoung = class(ESalaryError);

procedure CheckAge(age: Integer);
begin
  if age < 18 then
    raise ETooYoung.Create(Format('年龄 %d 未满 18，不能入职', [age]));
end;

// ═══ 10.1 try/finally：资源保护——无论成败都执行（不是二选一！）
procedure ShowTryFinally;
var
  sl: TStringList;
begin
  sl := TStringList.Create;                // 拿到资源
  try
    sl.Add('第一行');
    sl.Add('第二行');
    Assert(sl.Count = 2);
    WriteLn('  try 块正常跑完，Count=', sl.Count);
  finally
    sl.Free;                               // 就算 try 里抛异常，这里也保证执行
  end;
  WriteLn('  finally 块执行完毕（资源已释放）');
end;

const
  ZeroVal = 0;

// ═══ 10.2 try/except + on 类型 do：类型化捕获
procedure ShowTryExcept;
var
  n, z: Integer;
  caught: string;
begin
  caught := '';
  try
    n := StrToInt('12x');                  // 抛 EConvertError
    WriteLn('  不会到达：', n);
  except
    on E: EConvertError do
      caught := 'EConvertError：' + E.Message;
    on E: EDivByZero do                    // 多条 on 按顺序匹配（先具体后宽泛）
      caught := 'EDivByZero';
  else
    caught := '其他异常';                  // else 兜底（相当于 catch(...)）
  end;
  Assert(Pos('EConvertError', caught) > 0);
  WriteLn('  捕获 ', caught);

  // 整除零：uses SysUtils 后除零是异常（不 uses 则是运行时错误 200——历史包袱）
  // 坑（实测）：除数是编译期常量 0 时直接【编译期】Division by zero 报错——
  // 要演示运行期异常，除数得是变量
  z := ZeroVal;
  try
    n := 1 div z;
    WriteLn('  不会到达：', n);
  except
    on EDivByZero do caught := 'EDivByZero';
  end;
  Assert(caught = 'EDivByZero');
  WriteLn('  捕获 ', caught);
end;

// ═══ 10.3 raise 与 re-raise：抛新的 / 转发旧的
procedure Level3;
begin
  raise Exception.Create('源头错误（Level3）');
end;

procedure Level2;
begin
  try
    Level3;
  except
    on E: Exception do
      raise ESalaryError.Create('Level2 包装后转发：' + E.Message);   // 换类型转发
  end;
end;

procedure ShowRaise;
begin
  try
    Level2;
  except
    on E: ESalaryError do
      WriteLn('  捕获 ', E.Message);
  end;
  WriteLn('  （裸 raise; 则原样重抛当前异常——包装与重抛的区别见正文）');
end;

// ═══ 10.4/10.5 家族与自定义
procedure ShowCustomException;
begin
  try
    CheckAge(16);
    Assert(False, '不会到达');
  except
    on E: ETooYoung do
      WriteLn('  捕获自定义 ETooYoung：', E.Message);
    on E: ESalaryError do                  // 父类分支排在后面也能兜住子类
      WriteLn('  不会到达（子类分支已截获）');
  end;
end;

// ═══ 10.6 完整形态：try..except 里嵌 try..finally（资源 + 错误双保险）
procedure ShowFullPattern;
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  try
    try
      sl.Add('数据行');
      raise Exception.Create('处理中途失败');
    except
      on E: Exception do
        WriteLn('  处理错误但资源已护住：', E.Message);
    end;
  finally
    sl.Free;
  end;
  WriteLn('  双保险收尾：except 处理错误，finally 释放资源');
end;

// ═══ 10.7 Assert：开发期检查，发布期蒸发
procedure ShowAssert;
begin
  {$C+}                                   // 等价命令行 -Sa；本工程检查通道已开
  Assert(1 + 1 = 2, '数学崩了');
  WriteLn('  Assert 通过时静默；触发时抛 EAssertionFailed——发布构建（{$C-}）整段蒸发');
end;

begin
  WriteLn('═══ 10.1 try/finally');
  ShowTryFinally;
  WriteLn('═══ 10.2 try/except');
  ShowTryExcept;
  WriteLn('═══ 10.3 raise 与转发');
  ShowRaise;
  WriteLn('═══ 10.5 自定义异常');
  ShowCustomException;
  WriteLn('═══ 10.6 完整形态');
  ShowFullPattern;
  WriteLn('═══ 10.7 Assert');
  ShowAssert;
  WriteLn;
  WriteLn('==== 10 结束 ====');
end.
