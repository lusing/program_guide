-- ============================================================
-- 第2章：Hello World —— 第一个 Ada 程序
-- ============================================================
with Ada.Text_IO; use Ada.Text_IO;

procedure Ch02_Hello is
begin
   Put_Line ("Hello, Ada!");
   Put_Line ("GNAT 编译器 (GCC) — Windows / Linux 通用");
   Put_Line ("Ada 2012/2022 语言标准");
end Ch02_Hello;
