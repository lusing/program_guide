-- ============================================================
-- 第6章：数组与字符串
--   —— 约束/非约束数组 / 聚集 / 属性 / 分片 /
--      String 与 Bounded_String
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Strings.Bounded;

procedure Ch06_Arrays is

   -- 非约束数组形参：界由实参决定，体内用属性适配
   type Int_Vector is array (Integer range <>) of Integer;

   function Sum (A : Int_Vector) return Integer is
      Total : Integer := 0;
   begin
      for I in A'Range loop            -- 不写 1..N，写 A'Range
         Total := Total + A (I);
      end loop;
      return Total;
   end Sum;

begin
   Put_Line ("=== Ada 数组与字符串 ===");
   New_Line;

   -- ---------------------------
   -- 1. 约束数组与数组聚集
   -- ---------------------------
   Put_Line ("--- 1. 约束数组与聚集 ---");
   declare
      type Int_Array is array (1 .. 5) of Integer;
      A  : Int_Array := (10, 20, 30, 40, 50);        -- 位置聚集
      B  : Int_Array := (1 => 10, 3 => 30, 2 => 20,  -- 指名聚集：顺序任意
                         4 => 40, 5 => 50);
      C  : Int_Array := (1 .. 3 => 7, others => 0);  -- 范围 + others
      D  : Int_Array := (others => 1);               -- 全部同一值
   begin
      Put ("  A (位置) = [");
      for I in A'Range loop
         Put (A (I), Width => 0);
         if I < A'Last then Put (", "); end if;
      end loop;
      Put_Line ("]");
      Put_Line ("  B (指名) 与 A 相同：" & Boolean'Image (A = B));
      Put ("  C (others) = [");
      for I in C'Range loop
         Put (C (I), Width => 0);
         if I < C'Last then Put (", "); end if;
      end loop;
      Put_Line ("]");
      Put_Line ("  D (others=>1) = [" & Integer'Image (D (1)) & ",...]");
      Put_Line ("  聚集必须完整：所有分量都要有值，缺一个即编译错。");
   end;

   -- ---------------------------
   -- 2. 非约束数组：界推迟到对象说明
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. 非约束数组 ---");
   declare
      type Vector is array (Integer range <>) of Float;
      V1 : Vector (1 .. 3)  := (1.0, 2.0, 3.0);   -- 界在对象说明时给定
      V2 : Vector (-2 .. 2) := (others => 0.0);   -- 下界可以任意，含负数
   begin
      Put_Line ("  V1'First =" & Integer'Image (V1'First)
                & "  V1'Last =" & Integer'Image (V1'Last)
                & "  V1'Length =" & Integer'Image (V1'Length));
      Put_Line ("  V2'First =" & Integer'Image (V2'First)
                & "  V2'Length =" & Integer'Image (V2'Length));
      Put_Line ("  同一类型，不同界——这就是子程序能接受任意长度数组的原因。");
   end;

   -- ---------------------------
   -- 3. 多维数组与带编号的属性
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 多维数组 ---");
   declare
      type Matrix is array (1 .. 3, 1 .. 3) of Integer;
      M : Matrix := ((1, 2, 3),
                     (4, 5, 6),
                     (7, 8, 9));
   begin
      Put_Line ("  3x3 矩阵（嵌套聚集，外层每行一个括号）:");
      for I in M'Range (1) loop
         Put ("    ");
         for J in M'Range (2) loop
            Put (M (I, J), Width => 3);
         end loop;
         New_Line;
      end loop;
      Put_Line ("  M'First (1) =" & Integer'Image (M'First (1))
                & "  M'Last (2) =" & Integer'Image (M'Last (2)));
   end;

   -- ---------------------------
   -- 4. 分片：整体赋值与别名语义
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. 数组分片 ---");
   declare
      A : array (1 .. 10) of Integer := (1, 2, 3, 4, 5, 6, 7, 8, 9, 10);
   begin
      A (1 .. 3) := A (8 .. 10);        -- 分片整体赋值：尾部三个 → 头部三个
      Put ("  赋值后 A (1..10) = ");
      for I in A'Range loop
         Put (A (I), Width => 0);
         Put (" ");
      end loop;
      New_Line;
      A (2 .. 3) := (0, 0);             -- 分片也可以用聚集赋值
      Put_Line ("  A (2..3) := (0,0) 后 A (2) =" & Integer'Image (A (2))
                & "，A (3) =" & Integer'Image (A (3)));
      Put_Line ("  分片作为 in out 实参传递时是""窗口""而非副本——");
      Put_Line ("  在子程序里改分片元素，就是改原数组元素（无拷贝）。");
   end;

   -- ---------------------------
   -- 5. 非约束形参与 Sum
   -- ---------------------------
   New_Line;
   Put_Line ("--- 5. 非约束数组形参 ---");
   declare
      X : Int_Vector (1 .. 4) := (5, 10, 15, 20);
      Y : Int_Vector (0 .. 2) := (100, 200, 300);   -- 下界 0 也无妨
   begin
      Put_Line ("  Sum (X) =" & Integer'Image (Sum (X)));
      Put_Line ("  Sum (Y) =" & Integer'Image (Sum (Y)));
      Put_Line ("  同一个 Sum 适配任意界的实参：靠 A'Range 属性。");
   end;

   -- ---------------------------
   -- 6. 字符串：预定义的非约束数组
   -- ---------------------------
   New_Line;
   Put_Line ("--- 6. 字符串 ---");
   declare
      S1 : String (1 .. 12) := "Hello, World";   -- 定长：必须恰好 12 字符
      S3 : constant String := "Hello" & " " & "Ada";  -- 常量：长度由初值定
   begin
      Put_Line ("  S1 = " & S1);
      Put_Line ("  S3 = " & S3 & "（& 拼接出的常量串，长度自动确定）");
      Put_Line ("  S1'Length =" & Integer'Image (S1'Length));
      Put_Line ("  S1 (1..5) = " & S1 (1 .. 5));           -- 切片
      Put_Line ("  S1 (8..12) = " & S1 (8 .. 12));
   end;

   -- ---------------------------
   -- 7. 有界字符串：运行期可变长
   -- ---------------------------
   New_Line;
   Put_Line ("--- 7. 有界字符串 (Bounded) ---");
   declare
      package BS is new Ada.Strings.Bounded.Generic_Bounded_Length (Max => 64);
      use BS;
      B : Bounded_String := To_Bounded_String ("Hello");
   begin
      B := B & To_Bounded_String (" Ada!");  -- 拼接
      Put_Line ("  Bounded_String = " & To_String (B));
      Put_Line ("  Length =" & Integer'Image (Length (B))
                & " / Max = 64（超限会异常，但无堆分配）");
   end;
end Ch06_Arrays;
