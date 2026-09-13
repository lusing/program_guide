-- ============================================================
-- 第8章：异常处理 (Exception Handling)
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Exceptions;

procedure Ch08_Exceptions is

   -- 自定义异常
   My_Error : exception;

   -- 一个可能抛出异常的函数
   function Safe_Divide (A, B : Integer) return Integer is
   begin
      if B = 0 then
         raise Constraint_Error with "除数不能为零";
      end if;
      return A / B;
   end Safe_Divide;

   -- 演示嵌套异常
   procedure Level_3 is
   begin
      raise My_Error with "从 Level_3 抛出的错误";
   end Level_3;

   procedure Level_2 is
   begin
      Level_3;
   exception
      when My_Error =>
         Put_Line ("  Level_2 捕获到异常，重新抛出");
         raise;
   end Level_2;

begin
   Put_Line ("=== Ada 异常处理示例 ===");
   New_Line;

   -- 1. 基本异常处理
   Put_Line ("--- 1. 基本异常处理 ---");
   begin
      Put_Line ("  尝试除以零...");
      declare
         Result : Integer := Safe_Divide (10, 0);
      begin
         Put_Line ("  结果: " & Integer'Image(Result));
      end;
   exception
      when Constraint_Error =>
         Put_Line ("  捕获 Constraint_Error!");
      when others =>
         Put_Line ("  捕获其他异常");
   end;

   -- 2. 正常除法
   New_Line;
   Put_Line ("--- 2. 正常除法 ---");
   begin
      declare
         Result : Integer := Safe_Divide (100, 7);
      begin
         Put_Line ("  100 / 7 = " & Integer'Image(Result));
      end;
   exception
      when others =>
         Put_Line ("  不应该到这里");
   end;

   -- 3. 异常传播
   New_Line;
   Put_Line ("--- 3. 异常传播 (Nested Exception) ---");
   begin
      Level_2;
   exception
      when My_Error =>
         Put_Line ("  最外层捕获到 My_Error");
   end;

   -- 4. 获取异常信息
   New_Line;
   Put_Line ("--- 4. 异常信息 ---");
   begin
      raise Program_Error with "演示异常信息";
   exception
      when E : others =>
         Put_Line ("  异常名称: " & Ada.Exceptions.Exception_Name (E));
         Put_Line ("  异常信息: " & Ada.Exceptions.Exception_Message (E));
   end;
end Ch08_Exceptions;