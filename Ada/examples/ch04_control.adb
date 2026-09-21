-- ============================================================
-- 第4章：控制结构 —— if / case / loop
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure Ch04_Control is
   X : Integer := 15;
   Y : Integer := 20;
begin
   Put_Line ("=== Ada 控制结构示例 ===");
   New_Line;

   -- ---------------------------
   -- 1. if-then-else
   -- ---------------------------
   Put_Line ("--- 1. if-then-elsif-else ---");
   if X > Y then
      Put_Line ("X 大于 Y");
   elsif X = Y then
      Put_Line ("X 等于 Y");
   else
      Put_Line ("X 小于 Y");
   end if;

   -- ---------------------------
   -- 2. case 语句
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. case 语句 ---");
   declare
      Grade : constant Character := 'B';
   begin
      case Grade is
         when 'A' =>
            Put_Line ("优秀 (Excellent)");
         when 'B' =>
            Put_Line ("良好 (Good)");
         when 'C' =>
            Put_Line ("中等 (Average)");
         when 'D' =>
            Put_Line ("及格 (Pass)");
         when 'F' =>
            Put_Line ("不及格 (Fail)");
         when others =>
            Put_Line ("无效等级");
      end case;
   end;

   -- ---------------------------
   -- 3. for 循环
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. for 循环 ---");
   Put ("正序: ");
   for I in 1 .. 5 loop
      Put (I, Width => 0);
      if I < 5 then
         Put (", ");
      end if;
   end loop;
   New_Line;

   Put ("逆序: ");
   for I in reverse 1 .. 5 loop
      Put (I, Width => 0);
      if I > 1 then
         Put (", ");
      end if;
   end loop;
   New_Line;

   -- ---------------------------
   -- 4. while 循环
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. while 循环 ---");
   declare
      Counter : Integer := 3;
   begin
      while Counter > 0 loop
         Put_Line ("倒计时: " & Integer'Image(Counter));
         Counter := Counter - 1;
      end loop;
      Put_Line ("发射!");
   end;

   -- ---------------------------
   -- 5. 无限循环 + exit
   -- ---------------------------
   New_Line;
   Put_Line ("--- 5. loop + exit ---");
   declare
      N : Integer := 1;
   begin
      loop
         Put (N, Width => 0);
         exit when N >= 5;
         Put (", ");
         N := N + 1;
      end loop;
      New_Line;
   end;
end Ch04_Control;