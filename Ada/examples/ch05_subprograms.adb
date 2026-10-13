-- ============================================================
-- 第5章：子程序 —— 过程与函数
--   —— 参数模式 / 缺省参数与指名调用 / 运算符重载 /
--      递归（汉诺塔）/ 牛顿法 / 最频值 / renames
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;
with Ada.Numerics.Elementary_Functions;

procedure Ch05_Subprograms is

   -- 参数模式：in（只读，可省略）、out、in out
   procedure Swap (A, B : in out Integer) is
      Temp : constant Integer := A;   -- in 形参相当于常量，不可赋值
   begin
      A := B;
      B := Temp;
   end Swap;

   -- 缺省参数：只有 in 模式的形参可以带缺省值
   function Sqrt_Newton
     (X   : Float;
      Eps : Float := 0.000_1) return Float
   is
      Old_Value : Float := 0.0;
      New_Value : Float := X / 2.0;
   begin
      while abs (New_Value - Old_Value) > Eps loop
         Old_Value := New_Value;
         New_Value := 0.5 * (Old_Value + X / Old_Value);
      end loop;
      return New_Value;
   end Sqrt_Newton;

   -- 运算符重载：为向量定义 "+"
   type Vector is array (Integer range <>) of Float;
   function "+" (X, Y : Vector) return Vector is
      Sum : Vector (X'Range);
   begin
      for I in X'Range loop
         Sum (I) := X (I) + Y (I);
      end loop;
      return Sum;
   end "+";

   -- 递归：汉诺塔
   procedure Hanoi (N : Natural; X, Y, Z : Character) is
   begin
      if N /= 0 then
         Hanoi (N - 1, X, Z, Y);
         Put_Line ("  盘" & Integer'Image (N) & " : " & X & " → " & Y);
         Hanoi (N - 1, Z, Y, X);
      end if;
   end Hanoi;

   -- 最频值（Griffiths 线性算法）：已排序数组中出现次数最多的值
   type Int_Vector is array (Integer range <>) of Integer;
   procedure Mode (A : Int_Vector; MF : out Integer; MV : out Integer) is
      L : constant Integer := A'First;
      U : constant Integer := A'Last;
      I : Integer;
   begin
      MV := A (L);          -- 最频值
      MF := 1;              -- 最频值的频率
      I := L + 1;
      while I <= U loop
         if A (I) = A (I - MF) then
            MF := MF + 1;
            MV := A (I);
         end if;
         I := I + 1;
      end loop;
   end Mode;

   -- 子程序重载：同名 Swap，按参数类型区分
   procedure Swap (A, B : in out Float) is
      Temp : constant Float := A;
   begin
      A := B;
      B := Temp;
   end Swap;

   -- renames：给长名字的子程序换个短名（不产生新代码）
   -- Put_Line 有多个重载，renames 必须写全形参剖面来消歧
   procedure Say (S : String) renames Ada.Text_IO.Put_Line;

begin
   Put_Line ("=== Ada 子程序 ===");
   New_Line;

   -- ---------------------------
   -- 1. 过程与三种参数模式
   -- ---------------------------
   Put_Line ("--- 1. 过程 Swap (in out) ---");
   declare
      X : Integer := 10;
      Y : Integer := 20;
   begin
      Put_Line ("  交换前: X =" & Integer'Image (X) & ", Y =" & Integer'Image (Y));
      Swap (X, Y);
      Put_Line ("  交换后: X =" & Integer'Image (X) & ", Y =" & Integer'Image (Y));
   end;

   -- ---------------------------
   -- 2. 函数与缺省参数、指名调用
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. 函数 Sqrt_Newton ---");
   declare
      X : Float := 2.0;
   begin
      Put ("  Sqrt_Newton (2.0)          = ");
      Put (Sqrt_Newton (X), Aft => 6, Exp => 0);  New_Line;
      Put ("  Sqrt_Newton (2.0, 1.0E-6)  = ");
      Put (Sqrt_Newton (X, Eps => 1.0E-6), Aft => 6, Exp => 0);  New_Line;
      Put ("  Sqrt (2.0)（标准库对照）  = ");
      Put (Ada.Numerics.Elementary_Functions.Sqrt (X), Aft => 6, Exp => 0);  New_Line;
   end;

   -- ---------------------------
   -- 3. 运算符重载
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 运算符重载 ""+"" ---");
   declare
      V1 : constant Vector (1 .. 3) := (1.0, 2.0, 3.0);
      V2 : constant Vector (1 .. 3) := (4.0, 5.0, 6.0);
      V3 : Vector (1 .. 3);
   begin
      V3 := V1 + V2;                    -- 调用我们定义的 "+"
      Put ("  (1,2,3) + (4,5,6) = (");
      for I in V3'Range loop
         Put (V3 (I), Aft => 1, Exp => 0);
         if I < V3'Last then Put (", "); end if;
      end loop;
      Put_Line (")");
   end;

   -- ---------------------------
   -- 4. 递归：汉诺塔（3 盘）
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. 递归：汉诺塔 N=3 ---");
   Hanoi (3, 'X', 'Y', 'Z');

   -- ---------------------------
   -- 5. 非约束数组形参 + out 模式：最频值
   -- ---------------------------
   New_Line;
   Put_Line ("--- 5. 最频值（Griffiths 算法） ---");
   declare
      Data : constant Int_Vector (1 .. 10) := (1, 1, 2, 3, 3, 3, 3, 8, 8, 9);
      MF : Integer;
      MV : Integer;
   begin
      Mode (Data, MF, MV);
      Put_Line ("  已排序数组中出现最多的是" & Integer'Image (MV)
                & "，共" & Integer'Image (MF) & " 次");
   end;

   -- ---------------------------
   -- 6. 重载与 renames
   -- ---------------------------
   New_Line;
   Put_Line ("--- 6. 重载与 renames ---");
   declare
      P : Float := 1.5;
      Q : Float := 4.5;
   begin
      Swap (P, Q);            -- 编译器按类型选择 Float 版 Swap
      Put_Line ("  Swap (Float) 后: P =" & Float'Image (P) & ", Q =" & Float'Image (Q));
      Say ("  Say 是 Ada.Text_IO.Put_Line 的换名（renames）。");
   end;

   -- ---------------------------
   -- 7. 嵌套过程与逐步求精：杨辉三角（何诚 §6.8）
   -- ---------------------------
   New_Line;
   Put_Line ("--- 7. 嵌套过程与逐步求精：杨辉三角 ---");
   declare
      Max_Row_Number : constant := 9;
      Field_Width    : constant := 4;
      subtype Index is Integer range 0 .. Max_Row_Number;

      -- 逐步求精第 1 步的骨架：每行两个动作——对齐、打值
      procedure Pascals_Triangle (Last_Row : Index) is

         -- 求精第 2 步之一：换行并打前导空格（左右对称形）
         procedure Align_Output (Row : Index) is
         begin
            New_Line;
            for S in 1 .. (Max_Row_Number - Row) * (Field_Width / 2) loop
               Put (" ");
            end loop;
         end Align_Output;

         -- 求精第 2 步之二：组合数递推打当前行——不用数组、不用递归
         procedure Print_Values (Row : Index) is
            Val : Integer := 1;            -- C(n,0) = 1
         begin
            Put (Val, Width => Field_Width);
            for Column in 1 .. Row loop
               -- C(n,k+1) = C(n,k) * (n-k+1) / (k+1)：
               -- 恒等式保证先乘后除必整除（见正文）
               Val := Val * (Row - Column + 1) / Column;
               Put (Val, Width => Field_Width);
            end loop;
         end Print_Values;

      begin
         for Row in Index range 0 .. Last_Row loop
            Align_Output (Row);
            Print_Values (Row);
         end loop;
      end Pascals_Triangle;

   begin
      Pascals_Triangle (Max_Row_Number);
      New_Line;
      New_Line;
      Put_Line ("  递推式 Val := Val*(Row-Column+1)/Column：组合数恒等式");
      Put_Line ("  C(n,k+1)=C(n,k)*(n-k+1)/(k+1) 保证先乘后除每步都整除。");
   end;
end Ch05_Subprograms;
