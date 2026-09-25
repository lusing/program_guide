# 10 · 包与模块化编程

> 示例：[`ch10_math_lib.ads`](../examples/ch10_math_lib.ads)（包规范）/ [`ch10_math_lib.adb`](../examples/ch10_math_lib.adb)（包体）/ [`ch10_packages.adb`](../examples/ch10_packages.adb)（主程序）
> 运行：`./run-all.sh 08`

## 8.1 包规范 (.ads)

```ada
package Ch10_Math_Lib is
   Pi : constant Float := 3.14159265;

   type Vector is array (1 .. 3) of Float;

   function Add_Vectors (A, B : Vector) return Vector;
   function Dot_Product (A, B : Vector) return Float;
   function Magnitude (V : Vector) return Float;
   procedure Print_Vector (Label : String; V : Vector);
end Ch10_Math_Lib;
```

## 8.2 包体实现 (.adb)

```ada
package body Ch10_Math_Lib is
   function Add_Vectors (A, B : Vector) return Vector is
      Result : Vector;
   begin
      for I in Vector'Range loop
         Result (I) := A (I) + B (I);
      end loop;
      return Result;
   end Add_Vectors;
   -- ... 其他实现
end Ch10_Math_Lib;
```

## 8.3 使用包

```ada
with Ch10_Math_Lib; use Ch10_Math_Lib;
-- 然后可以直接调用包中的函数和过程
```

---
上一章：[09 访问类型](09-access-types.md) ｜ 下一章：[11 异常](11-exceptions.md) ｜ 返回：[README](../README.md)

