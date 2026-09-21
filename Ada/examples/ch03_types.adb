-- ============================================================
-- 第3章：基本数据类型与变量
-- ============================================================
with Ada.Text_IO;             use Ada.Text_IO;
with Ada.Integer_Text_IO;     use Ada.Integer_Text_IO;
with Ada.Float_Text_IO;       use Ada.Float_Text_IO;

procedure Ch03_Types is
   -- 整型
   A : Integer := 42;
   B : Natural := 100;          -- 非负整数 (0 .. 2^31-1)
   C : Positive := 1;           -- 正整数 (1 .. 2^31-1)

   -- 自定义整型范围
   type Age is range 0 .. 150;
   My_Age : Age := 30;

   -- 浮点型
   Pi : Float := 3.14159;
   D : Long_Float := 2.718281828;

   -- 布尔型
   Flag : Boolean := True;

   -- 字符型
   Ch : Character := 'A';

   -- 枚举类型
   type Color is (Red, Green, Blue);
   My_Color : Color := Green;

   -- 子类型（带约束）
   subtype Small_Int is Integer range -100 .. 100;
   S : Small_Int := 50;

   -- 常量
   Max_Value : constant Integer := 999;
begin
   Put_Line ("=== Ada 基本数据类型示例 ===");
   New_Line;

   Put_Line ("--- 整型 ---");
   Put ("A = ");  Put (A, Width => 0);  New_Line;
   Put ("B (Natural) = ");  Put (B, Width => 0);  New_Line;
   Put ("C (Positive) = ");  Put (C, Width => 0);  New_Line;
   Put ("My_Age (0..150) = ");  Put (Integer(My_Age), Width => 0);  New_Line;

   New_Line;
   Put_Line ("--- 浮点型 ---");
   Put ("Pi = ");  Put (Pi, Fore => 0, Aft => 5, Exp => 0);  New_Line;
   Put ("D (Long_Float) = ");  Put (Float(D), Fore => 0, Aft => 9, Exp => 0);  New_Line;

   New_Line;
   Put_Line ("--- 布尔与字符 ---");
   Put_Line ("Flag = " & Boolean'Image(Flag));
   Put_Line ("Ch = " & Character'Image(Ch));

   New_Line;
   Put_Line ("--- 枚举类型 ---");
   Put_Line ("My_Color = " & Color'Image(My_Color));
   Put_Line ("Color'First = " & Color'Image(Color'First));
   Put_Line ("Color'Last = " & Color'Image(Color'Last));

   New_Line;
   Put_Line ("--- 子类型 ---");
   Put ("S (Small_Int) = ");  Put (Integer(S), Width => 0);  New_Line;

   New_Line;
   Put_Line ("--- 常量 ---");
   Put ("Max_Value = ");  Put (Max_Value, Width => 0);  New_Line;
end Ch03_Types;