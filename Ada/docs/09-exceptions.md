# 09 · 异常处理

> 示例：[`examples/ch09_exceptions.adb`](../examples/ch09_exceptions.adb)
> 运行：`./run-all.sh 09`

## 9.1 自定义异常

```ada
My_Error : exception;
```

## 9.2 抛出异常

```ada
raise Constraint_Error with "除数不能为零";
raise My_Error with "自定义错误信息";
```

## 9.3 捕获异常

```ada
begin
   -- 可能出错的代码
exception
   when Constraint_Error =>
      Put_Line ("捕获 Constraint_Error!");
   when E : others =>
      Put_Line ("异常名称: " & Ada.Exceptions.Exception_Name (E));
      Put_Line ("异常信息: " & Ada.Exceptions.Exception_Message (E));
end;
```

## 9.4 异常传播

```ada
exception
   when My_Error =>
      Put_Line ("捕获到异常，重新抛出");
      raise;  -- 重新抛出当前异常
```

---
上一章：[08 包](08-packages.md) ｜ 下一章：[10 泛型](10-generics.md) ｜ 返回：[README](../README.md)

