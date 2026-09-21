-- ============================================================
-- 第5章：子程序 —— 过程 (Procedure) 与函数 (Function)
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure Ch05_Subprograms is

   -- 过程：无返回值，可有 in/out/in out 参数
   procedure Swap (A, B : in out Integer) is
      Temp : constant Integer := A;
   begin
      A := B;
      B := Temp;
   end Swap;

   -- 函数：有返回值
   function Factorial (N : Natural) return Positive is
   begin
      if N = 0 then
         return 1;
      else
         return N * Factorial (N - 1);
      end if;
   end Factorial;

   -- 函数：带默认参数
   function Add (X : Integer; Y : Integer := 10) return Integer is
   begin
      return X + Y;
   end Add;

   -- 嵌套子程序
   procedure Outer is
      Inner_Count : Integer := 0;

      procedure Inner is
      begin
         Inner_Count := Inner_Count + 1;
         Put_Line ("   内部过程被调用，Inner_Count = " & Integer'Image(Inner_Count));
      end Inner;
   begin
      Put_Line ("  进入外部过程");
      Inner;
      Inner;
   end Outer;

   -- 带命名参数的过程
   procedure Print_Info (Name : String; Age : Integer; City : String := "未知") is
   begin
      Put_Line ("  姓名: " & Name & ", 年龄:" & Integer'Image(Age) & ", 城市: " & City);
   end Print_Info;

begin
   Put_Line ("=== Ada 子程序示例 ===");
   New_Line;

   -- 1. 过程调用
   Put_Line ("--- 1. 过程 (Swap) ---");
   declare
      X, Y : Integer := 10;
   begin
      X := 10; Y := 20;
      Put_Line ("  交换前: X =" & Integer'Image(X) & ", Y =" & Integer'Image(Y));
      Swap (X, Y);
      Put_Line ("  交换后: X =" & Integer'Image(X) & ", Y =" & Integer'Image(Y));
   end;

   -- 2. 递归函数
   New_Line;
   Put_Line ("--- 2. 递归函数 (Factorial) ---");
   Put_Line ("  5! = " & Integer'Image(Factorial(5)));

   -- 3. 默认参数
   New_Line;
   Put_Line ("--- 3. 默认参数 (Add) ---");
   Put_Line ("  Add(5, 3) = " & Integer'Image(Add(5, 3)));
   Put_Line ("  Add(5)    = " & Integer'Image(Add(5)));  -- Y 使用默认值 10

   -- 4. 嵌套子程序
   New_Line;
   Put_Line ("--- 4. 嵌套子程序 ---");
   Outer;

   -- 5. 命名参数
   New_Line;
   Put_Line ("--- 5. 命名参数 ---");
   Print_Info (Name => "张三", Age => 25, City => "上海");
   Print_Info (Name => "李四", Age => 30);  -- City 使用默认值
end Ch05_Subprograms;