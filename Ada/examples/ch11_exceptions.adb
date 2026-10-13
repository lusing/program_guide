-- ============================================================
-- 第11章：异常处理
--   —— 异常说明与 raise / 捕获与 others / 传播与再抛 /
--      块内重试 / 偶发故障重现 / Suppress 抑制
-- ============================================================
with Ada.Text_IO;     use Ada.Text_IO;
with Ada.Exceptions;

procedure Ch11_Exceptions is

   -- 自定义异常：异常说明
   My_Error      : exception;
   Sensor_Failed : exception;

   -- 可能出错的除法
   function Safe_Divide (A, B : Integer) return Integer is
   begin
      if B = 0 then
         raise Constraint_Error with "除数不能为零";
      end if;
      return A / B;
   end Safe_Divide;

   -- 嵌套传播：Level_3 抛出，Level_2 捕获后再抛出
   procedure Level_3 is
   begin
      raise My_Error with "从 Level_3 抛出的错误";
   end Level_3;

   procedure Level_2 is
   begin
      Level_3;
   exception
      when My_Error =>
         Put_Line ("  Level_2 捕获到异常，重新抛出（raise;）");
         raise;                            -- 裸 raise：再抛当前异常
   end Level_2;

   -- 偶发故障重试（老教材"磁带驱动器重读 10 次"的模式）
   -- 故障计数器模拟：前 3 次调用失败，第 4 次成功
   Flaky_Count : Natural := 0;
   procedure Read_Tape (Ok : out Boolean) is
   begin
      Flaky_Count := Flaky_Count + 1;
      Ok := (Flaky_Count >= 4);
   end Read_Tape;

begin
   Put_Line ("=== Ada 异常处理 ===");
   New_Line;

   -- ---------------------------
   -- 1. 基本捕获：when 名字 => 处理
   -- ---------------------------
   Put_Line ("--- 1. 基本捕获 ---");
   begin
      Put_Line ("  尝试 10 / 0 ...");
      declare
         Result : constant Integer := Safe_Divide (10, 0);
      begin
         Put_Line ("  结果:" & Integer'Image (Result));
      end;
   exception
      when Constraint_Error =>
         Put_Line ("  捕获 Constraint_Error！");
      when others =>
         Put_Line ("  捕获其他异常");
   end;

   -- ---------------------------
   -- 2. 异常的三件套信息
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. 异常信息 ---");
   begin
      raise Program_Error with "演示异常信息";
   exception
      when E : others =>
         Put_Line ("  异常名称: " & Ada.Exceptions.Exception_Name (E));
         Put_Line ("  异常信息: " & Ada.Exceptions.Exception_Message (E));
   end;

   -- ---------------------------
   -- 3. 传播：异常沿调用链上抛
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 传播与再抛 ---");
   begin
      Level_2;
   exception
      when My_Error =>
         Put_Line ("  最外层捕获到 My_Error（经 Level_2 转发）");
   end;

   -- ---------------------------
   -- 4. 块结构 + 循环 = 就地重试
   --    （老教材交互输入 PROCESS_ONLINE 模式的无交互版本）
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. 块内重试 ---");
   declare
      Bad_Inputs : constant array (1 .. 3) of String (1 .. 4) :=
        ("12ab", "x78y", "3456");
      Parsed : Integer := 0;
   begin
      for K in Bad_Inputs'Range loop
         begin
            Parsed := Integer'Value (Bad_Inputs (K));
            Put_Line ("  第" & Integer'Image (K) & " 个输入解析成功:"
                      & Integer'Image (Parsed));
         exception
            when Constraint_Error =>
               Put_Line ("  第" & Integer'Image (K) & " 个输入 """
                         & Bad_Inputs (K) & """ 不是数字，跳过");
         end;
      end loop;
      Put_Line ("  异常被限制在块内，循环继续——这就是块结构的核心用途。");
   end;

   -- ---------------------------
   -- 5. 偶发故障：重试到成功为止
   -- ---------------------------
   New_Line;
   Put_Line ("--- 5. 偶发故障重试 ---");
   begin
      for I in 1 .. 10 loop
         declare
            Ok : Boolean;
         begin
            Read_Tape (Ok);
            if not Ok then
               raise Sensor_Failed;
            end if;
            Put_Line ("  第" & Integer'Image (I) & " 次尝试成功。");
            exit;
         exception
            when Sensor_Failed =>
               Put_Line ("  第" & Integer'Image (I) & " 次读失败，反绕重试...");
               if I = 10 then
                  raise Sensor_Failed with "重试 10 次仍失败，放弃";
               end if;
         end;
      end loop;
   exception
      when E : Sensor_Failed =>
         Put_Line ("  最终放弃：" & Ada.Exceptions.Exception_Message (E));
   end;

   -- ---------------------------
   -- 6. 阶乘：出错时给出极端安全值
   -- ---------------------------
   New_Line;
   Put_Line ("--- 6. 出错时返回安全值 ---");
   declare
      -- 溢出在 Ada 95+ 归入 Constraint_Error（Ada 83 的 NUMERIC_ERROR 已并轨）
      function Factorial (N : Natural) return Integer is
         Fact : Integer := 1;
      begin
         for I in 2 .. N loop
            Fact := Fact * I;
         end loop;
         return Fact;
      exception
         when Constraint_Error =>
            return Integer'Last;      -- 上限兜底：调用方看得懂的含义
      end Factorial;
   begin
      Put_Line ("  12! =" & Integer'Image (Factorial (12)));
      Put_Line ("  99! 溢出 → 返回 Integer'Last ="
                & Integer'Image (Factorial (99)));
   end;

   -- ---------------------------
   -- 7. Suppress：在确信安全处关闭检查
   -- ---------------------------
   New_Line;
   Put_Line ("--- 7. 抑制检查 (Suppress) ---");
   declare
      pragma Suppress (Range_Check);   -- 仅本块生效
      A : Integer range 1 .. 10 := 5;
   begin
      A := A + 1;                      -- 确信不会越界：免检提速
      Put_Line ("  本块内 Range_Check 已抑制：A =" & Integer'Image (A));
      Put_Line ("  出了块，检查恢复——抑制范围被块结构限死。");
   end;
end Ch11_Exceptions;
