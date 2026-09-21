-- ============================================================
-- 第8章：包 (Package) —— 主程序测试
-- ============================================================
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Numerics.Elementary_Functions;
with Ch08_Math_Lib; use Ch08_Math_Lib;

procedure Ch08_Packages is
   V1 : Vector := (1.0, 2.0, 3.0);
   V2 : Vector := (4.0, 5.0, 6.0);
begin
   Put_Line ("=== Ada 包 (Package) 示例 ===");
   New_Line;

   Put_Line ("--- 向量运算 ---");
   Print_Vector ("V1", V1);
   Print_Vector ("V2", V2);

   declare
      Sum : Vector := Add_Vectors (V1, V2);
   begin
      Print_Vector ("V1 + V2", Sum);
   end;

   Put_Line ("V1 . V2 (点积) = " & Float'Image(Dot_Product(V1, V2)));
   Put_Line ("|V1| (模长)    = " & Float'Image(Magnitude(V1)));
   Put_Line ("Pi (从包中引用) = " & Float'Image(Pi));

   -- 使用子包 (Ada 标准库)
   New_Line;
   Put_Line ("--- 使用 Ada.Numerics.Elementary_Functions 子包 ---");
   Put_Line ("sqrt(16.0) = " & Float'Image(Ada.Numerics.Elementary_Functions.Sqrt(16.0)));
   Put_Line ("sin(Pi/2)  = " & Float'Image(Ada.Numerics.Elementary_Functions.Sin(Pi / 2.0)));
end Ch08_Packages;