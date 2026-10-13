-- ============================================================
-- 第2章：Hello World 与 Ada 程序的基本面貌
--   —— 程序结构 / with 与 use / 词法单元 / 直接量
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;

procedure Ch02_Hello is
begin
   Put_Line ("Hello, Ada!");
   Put_Line ("GNAT (GCC) 16 · Windows / Linux 通用 · 默认标准 Ada 2012");
   New_Line;

   -- ---------------------------
   -- 1. 数值直接量：十进制、下划线、基数、指数
   -- ---------------------------
   Put_Line ("--- 1. 数值直接量 ---");
   declare
      Million   : constant := 1_000_000;    -- 下划线只为可读，编译器忽略
      Hex_FF    : constant := 16#FF#;       -- 基于 16：255
      Bin_Ten   : constant := 2#1010#;      -- 基于 2：10
      Oct_Thou  : constant := 8#1750#;      -- 基于 8：1000
      Exp_Form  : constant := 1E6;          -- 指数形式：1000000
      Pi        : constant := 3.14159_26;   -- 实数：小数点两边都必须有数字
   begin
      Put ("  1_000_000   = ");  Put (Million,  Width => 0);  New_Line;
      Put ("  16#FF#      = ");  Put (Hex_FF,   Width => 0);  New_Line;
      Put ("  2#1010#     = ");  Put (Bin_Ten,  Width => 0);  New_Line;
      Put ("  8#1750#     = ");  Put (Oct_Thou, Width => 0);  New_Line;
      Put ("  1E6         = ");  Put (Exp_Form, Width => 0);  New_Line;
      Put ("  3.14159_26  = ");  Put (Pi, Aft => 5, Exp => 0); New_Line;
   end;

   -- ---------------------------
   -- 2. 字符、字符串与拼接 &
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. 字符与字符串 ---");
   declare
      Ch      : constant Character := 'A';       -- 字符直接量：单引号
      Greeting : constant String := "Hello";     -- 字符串直接量：双引号
      Long_Text : constant String :=
        "字符串太长时可用 & " & "跨行拼接成一体。";
   begin
      Put_Line ("  Character'Pos ('A') = " & Integer'Image (Character'Pos (Ch)));
      Put_Line ("  Greeting & "", Ada"" = " & Greeting & ", Ada");
      Put_Line ("  " & Long_Text);
   end;

   -- ---------------------------
   -- 3. 标识符与大小写：Ada 标识符不区分大小写
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 标识符不区分大小写 ---");
   declare
      Count : Integer := 1;      -- 说明时写作 Count
   begin
      COUNT := Count + 1;        -- 引用时写作 COUNT，同一个变量
      put_line ("  Count 与 COUNT 是同一个标识符，值 = "
                & Integer'Image (count));
   end;

   -- ---------------------------
   -- 4. 注释与编译器打点
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. 注释 ---");
   Put_Line ("  从 -- 到行尾都是注释，Ada 没有块注释。");
   Put_Line ("  嵌套子程序/包体里同样适用。");
end Ch02_Hello;
