-- ============================================================
-- 第6章：数组与字符串
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Strings.Bounded;

procedure Ch06_Arrays is

begin
   Put_Line ("=== Ada 数组与字符串示例 ===");
   New_Line;

   -- ---------------------------
   -- 1. 约束数组
   -- ---------------------------
   Put_Line ("--- 1. 约束数组 (Constrained Array) ---");
   declare
      type Int_Array is array (1 .. 5) of Integer;
      A : Int_Array := (10, 20, 30, 40, 50);
   begin
      Put ("  A = [");
      for I in A'Range loop
         Put (A(I), Width => 0);
         if I < A'Last then Put (", "); end if;
      end loop;
      Put_Line ("]");
      Put_Line ("  A'First = " & Integer'Image(A'First));
      Put_Line ("  A'Last  = " & Integer'Image(A'Last));
      Put_Line ("  A'Length = " & Integer'Image(A'Length));
   end;

   -- ---------------------------
   -- 2. 无约束数组
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. 无约束数组 (Unconstrained Array) ---");
   declare
      type Vector is array (Positive range <>) of Float;
      V1 : Vector (1 .. 3) := (1.0, 2.0, 3.0);
      V2 : Vector (1 .. 4) := (others => 0.0);
   begin
      Put_Line ("  V1'Length = " & Integer'Image(V1'Length));
      Put_Line ("  V2'Length = " & Integer'Image(V2'Length));
   end;

   -- ---------------------------
   -- 3. 多维数组
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 多维数组 ---");
   declare
      type Matrix is array (1 .. 3, 1 .. 3) of Integer;
      M : Matrix := ((1, 2, 3),
                     (4, 5, 6),
                     (7, 8, 9));
   begin
      Put_Line ("  3x3 矩阵:");
      for I in M'Range(1) loop
         Put ("  ");
         for J in M'Range(2) loop
            Put (M(I, J), Width => 3);
         end loop;
         New_Line;
      end loop;
   end;

   -- ---------------------------
   -- 4. 字符串
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. 字符串 (String) ---");
   declare
      S1 : String (1 .. 12) := "Hello, World";
      S2 : String := "Ada编程";
      S3 : constant String := "Hello" & " " & "Ada";  -- 拼接
   begin
      Put_Line ("  S1 = " & S1);
      Put_Line ("  S2 = " & S2);
      Put_Line ("  S3 = " & S3);
      Put_Line ("  S1'Length = " & Integer'Image(S1'Length));

      -- 字符串切片
      Put_Line ("  S1(1..5) = " & S1(1..5));
   end;

   -- ---------------------------
   -- 5. Bounded String (有界字符串)
   -- ---------------------------
   New_Line;
   Put_Line ("--- 5. 有界字符串 (Bounded String) ---");
   declare
      package BS is new Ada.Strings.Bounded.Generic_Bounded_Length (Max => 64);
      use BS;
      B : Bounded_String := To_Bounded_String ("Hello");
   begin
      B := B & To_Bounded_String (" Ada!");  -- 拼接
      Put_Line ("  Bounded_String = " & To_String(B));
      Put_Line ("  Length = " & Integer'Image(Length(B)));
   end;
end Ch06_Arrays;