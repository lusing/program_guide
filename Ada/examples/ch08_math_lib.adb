-- ============================================================
-- 第8章：包 (Package) —— 包体实现 (Body)
-- ============================================================
with Ada.Text_IO;       use Ada.Text_IO;
with Ada.Float_Text_IO; use Ada.Float_Text_IO;
with Ada.Numerics.Elementary_Functions;

package body Ch08_Math_Lib is

   -- 向量加法
   function Add_Vectors (A, B : Vector) return Vector is
      Result : Vector;
   begin
      for I in Vector'Range loop
         Result (I) := A (I) + B (I);
      end loop;
      return Result;
   end Add_Vectors;

   -- 点积
   function Dot_Product (A, B : Vector) return Float is
      Sum : Float := 0.0;
   begin
      for I in Vector'Range loop
         Sum := Sum + A (I) * B (I);
      end loop;
      return Sum;
   end Dot_Product;

   -- 向量模长
   function Magnitude (V : Vector) return Float is
   begin
      return Ada.Numerics.Elementary_Functions.Sqrt (Dot_Product (V, V));
   end Magnitude;

   -- 打印向量
   procedure Print_Vector (Label : String; V : Vector) is
   begin
      Put (Label & " = (");
      for I in V'Range loop
         Put (V (I), Fore => 0, Aft => 2, Exp => 0);
         if I < V'Last then Put (", "); end if;
      end loop;
      Put_Line (")");
   end Print_Vector;

end Ch08_Math_Lib;