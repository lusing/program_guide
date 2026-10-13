-- ============================================================
-- 第27章：标准库拾遗——时间（Calendar/Real_Time）、随机数、
--         命令行
--   （刘炳文 §7.9 预定义程序包 / §6.5 手写随机数 / 附录2
--     STANDARD 的现代对应物）
-- ============================================================
with Ada.Text_IO;     use Ada.Text_IO;
with Ada.Calendar;
with Ada.Calendar.Formatting;
with Ada.Calendar.Time_Zones;
with Ada.Real_Time;
with Ada.Numerics.Float_Random;
with Ada.Numerics.Discrete_Random;
with Ada.Command_Line;

procedure Ch27_Stdlib is

   -- 可读的时间常量（刘炳文 §16.5 的习惯写法）
   Seconds : constant := 1.0;
   Minutes : constant := 60.0;
   Hours   : constant := 3600.0;

   -- 骰子面：离散随机要具名子类型（匿名子界不能直接当泛型实参）
   subtype Die_Face is Integer range 1 .. 6;

   -- Integer'Image 的正数带前导空格，去掉它拼日期
   function Trim (S : String) return String is (S (S'First + 1 .. S'Last));

begin
   Put_Line ("=== 标准库拾遗：时间 / 随机数 / 命令行 ===");
   New_Line;

   -- ---------------------------
   -- 1. Ada.Calendar：墙上时钟（年月日时分秒）
   -- ---------------------------
   Put_Line ("--- 1. Ada.Calendar ---");
   declare
      use Ada.Calendar;
      use type Ada.Calendar.Time;
      Now  : constant Time := Clock;
      Y    : Year_Number;
      M    : Month_Number;
      D    : Day_Number;
      Secs : Day_Duration;
   begin
      Split (Now, Y, M, D, Secs);            -- 拆成日历字段（本地时区）
      Put_Line ("  Split 拆解: " & Trim (Integer'Image (Y)) & "-"
                & (if M < 10 then "0" else "") & Trim (Integer'Image (M))
                & "-" & (if D < 10 then "0" else "") & Trim (Integer'Image (D))
                & "（墙上钟，可被系统对时拨动）");
      -- Formatting.Image 缺省按 UTC 显示，要本地时刻得显式给时区偏移
      Put_Line ("  Image 本地时刻: "
                & Ada.Calendar.Formatting.Image
                     (Now, Time_Zone => Ada.Calendar.Time_Zones.UTC_Time_Offset (Now)));
   end;

   -- 固定日期：Time_Of 组装 + 差值 + 星期几
   declare
      use Ada.Calendar;
      Dawn : constant Time := Time_Of (2026, 10, 13);            -- 零点
      Dusk : constant Time := Time_Of (2026, 10, 13, 12 * Hours); -- 正午
      Gap  : constant Duration := Dusk - Dawn;  -- Time 相减 = Duration
   begin
      Put_Line ("  2026-10-13 正午 - 零点 = " & Duration'Image (Gap) & " 秒");
      Put_Line ("  2026-10-13 是星期"
                & Ada.Calendar.Formatting.Day_Name'Image
                     (Ada.Calendar.Formatting.Day_Of_Week (Dawn)));
      Put_Line ("  Duration 习惯写法: 3*Hours+25*Minutes+8*Seconds = "
                & Duration'Image (3 * Hours + 25 * Minutes + 8 * Seconds));
   end;

   -- TIME_Error：日历合法性检查
   declare
      use Ada.Calendar;
      T : Time;
   begin
      T := Time_Of (2026, 2, 30);            -- 2 月没有 30 日
      Put_Line ("  不该走到这: " & Duration'Image (T - T));
   exception
      when Time_Error =>
         Put_Line ("  Time_Of (2026, 2, 30) → TIME_Error（日历不合法）");
   end;

   -- ---------------------------
   -- 2. Ada.Real_Time：单调钟（测耗时、做节拍）
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. Ada.Real_Time ---");
   declare
      use Ada.Real_Time;
      Start : Time;
   begin
      Start := Clock;                        -- 单调钟：只增不减、不受对时影响
      delay 0.02;                            -- 干一小段活
      Put_Line ("  测得耗时 >= 20ms : "
                & Boolean'Image (Clock - Start >= Milliseconds (20)));
      Put_Line ("  Time_Span 单位族: "
                & "Microseconds(1000) = "
                & Duration'Image (To_Duration (Microseconds (1000)))
                & " 秒");
   end;

   -- ---------------------------
   -- 3. 随机数：Ada.Numerics（老书只能手写线性同余）
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 随机数 ---");
   declare
      -- 浮点均匀分布 [0, 1)：Float_Random 是普通包（非泛型），直接用
      package FR renames Ada.Numerics.Float_Random;
      G : FR.Generator;
   begin
      FR.Reset (G, 42);                      -- 带种子：序列可复现（测试友好）
      Put ("  Float_Random (种子 42) 前 5 个: ");
      for I in 1 .. 5 loop
         Put (Float'Image (FR.Random (G)) & " ");
      end loop;
      New_Line;
   end;

   declare
      -- 整数子界离散分布：掷骰子
      package Dice is new Ada.Numerics.Discrete_Random (Die_Face);
      G : Dice.Generator;
   begin
      Dice.Reset (G, 42);
      Put ("  掷骰子 (种子 42) 10 次: ");
      for I in 1 .. 10 loop
         Put (Integer'Image (Dice.Random (G)));
      end loop;
      New_Line;
   end;

   declare
      -- 枚举类型也能随机（83 时代不可想象）
      type Color is (Red, Green, Blue);
      package CR is new Ada.Numerics.Discrete_Random (Color);
      G : CR.Generator;
   begin
      CR.Reset (G, 7);
      Put ("  随机颜色 (种子 7) 5 次: ");
      for I in 1 .. 5 loop
         Put (Color'Image (CR.Random (G)) & " ");
      end loop;
      New_Line;
   end;

   -- 蒙特卡洛估 π：固定种子 → 输出可复现
   declare
      package FR renames Ada.Numerics.Float_Random;
      G      : FR.Generator;
      Inside : Natural := 0;
      Total  : constant := 20_000;
   begin
      FR.Reset (G, 2026);
      for I in 1 .. Total loop
         if FR.Random (G) ** 2 + FR.Random (G) ** 2 <= 1.0 then
            Inside := Inside + 1;
         end if;
      end loop;
      Put_Line ("  蒙特卡洛 π ≈ "
                & Float'Image (4.0 * Float (Inside) / Float (Total))
                & "（20000 点，种子 2026，跨运行可复现）");
   end;

   -- ---------------------------
   -- 4. Ada.Command_Line：main 的参数
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. Ada.Command_Line ---");
   Put_Line ("  Argument_Count = "
             & Integer'Image (Ada.Command_Line.Argument_Count)
             & "（run-all 不带参数；命令名走 Command_Name）");
   for I in 1 .. Ada.Command_Line.Argument_Count loop
      Put_Line ("    参数" & Integer'Image (I) & ": "
                & Ada.Command_Line.Argument (I));
   end loop;

   New_Line;
   Put_Line ("标准库拾遗演示完成。");
end Ch27_Stdlib;
