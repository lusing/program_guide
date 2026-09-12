-- ============================================================
-- 第13章：与 C 语言互操作 (Interfacing with C)
-- ============================================================
with Ada.Text_IO; use Ada.Text_IO;

procedure Ch13_C_Interop is

   -- 导入 C 标准库函数
   function C_Sqrt (X : Float) return Float
      with Import, Convention => C, External_Name => "sqrtf";

   function C_Abs (X : Integer) return Integer
      with Import, Convention => C, External_Name => "abs";

   -- 与 C 兼容的类型定义
   type C_Int is range -(2 ** 31) .. (2 ** 31 - 1)
      with Size => 32;
   pragma Convention (C, C_Int);

   type C_Float is digits 6
      with Size => 32;
   pragma Convention (C, C_Float);

   -- 与 C 结构体兼容的记录
   type C_Point is record
      X : C_Int;
      Y : C_Int;
   end record;
   pragma Convention (C, C_Point);

begin
   Put_Line ("=== Ada 与 C 互操作示例 ===");
   New_Line;

   -- 1. 调用 C 标准库函数
   Put_Line ("--- 1. 调用 C 标准库函数 ---");
   Put_Line ("  C_Sqrt(16.0) = " & Float'Image(C_Sqrt(16.0)));
   Put_Line ("  C_Abs(-42)   = " & Integer'Image(C_Abs(-42)));

   -- 2. 导出 Ada 函数供 C 调用
   New_Line;
   Put_Line ("--- 2. 导出 Ada 函数供 C 调用 ---");
   Put_Line ("  使用 Export aspect 或 pragma Export 可将 Ada 函数导出为 C 符号");
   Put_Line ("  例如: function Ada_Add (A, B : Integer) return Integer");
   Put_Line ("        with Export, Convention => C, External_Name => ""ada_add"";");
   Put_Line ("  注意: 导出的函数必须是库级别的子程序");

   -- 3. C 兼容类型
   New_Line;
   Put_Line ("--- 3. C 兼容类型 ---");
   declare
      P : C_Point := (X => 10, Y => 20);
   begin
      Put_Line ("  C_Point: X =" & C_Int'Image(P.X) & ", Y =" & C_Int'Image(P.Y));
      Put_Line ("  C_Point'Size = " & Integer'Image(C_Point'Size) & " bits");
      Put_Line ("  C_Int'Size   = " & Integer'Image(C_Int'Size) & " bits");
      Put_Line ("  C_Float'Size = " & Integer'Image(C_Float'Size) & " bits");
   end;

   -- 4. Interfaces.C 包
   New_Line;
   Put_Line ("--- 4. Interfaces.C 包 ---");
   Put_Line ("  Interfaces.C 提供了与 C 兼容的类型:");
   Put_Line ("    int, short, long, unsigned, size_t 等");
   Put_Line ("    char_array, chars_ptr, To_C, To_Ada 等字符串操作");
   Put_Line ("  Interfaces.C.Strings 提供高级字符串互操作");
end Ch13_C_Interop;