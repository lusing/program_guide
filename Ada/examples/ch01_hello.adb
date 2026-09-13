-- ============================================================
-- 第1章：Hello World —— 第一个 Ada 程序
-- ============================================================
with Ada.Text_IO; use Ada.Text_IO;

procedure Ch01_Hello is
begin
   Put_Line ("Hello, Ada on Windows!");
   Put_Line ("GNAT 编译器: GCC 16.1.0 (MSYS2 UCRT64)");
   Put_Line ("Ada 2012/2022 语言标准");
end Ch01_Hello;