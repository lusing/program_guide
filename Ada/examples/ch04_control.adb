-- ============================================================
-- 第4章：控制结构
--   —— 表达式与短路 / rem 与 mod / if 与 case / 三种循环
--      exit 四形态与命名循环 / goto / 块结构
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;

procedure Ch04_Control is

   -- 短路操作符演示：Y = 0 时右侧 X / Y 不会被求值
   function Safe_Big_Ratio (X, Y : Float) return Boolean is
   begin
      return Y /= 0.0 and then X / Y > 5.0;
      -- 若写成 and：Y = 0 时两个操作数都求值，除零引发异常
   end Safe_Big_Ratio;

begin
   Put_Line ("=== Ada 控制结构 ===");
   New_Line;

   -- ---------------------------
   -- 1. 短路逻辑：and then / or else
   -- ---------------------------
   Put_Line ("--- 1. 短路逻辑 ---");
   Put_Line ("  Safe_Big_Ratio (30.0, 0.0) = "
             & Boolean'Image (Safe_Big_Ratio (30.0, 0.0))
             & "  （除零未发生，右侧被短路）");
   Put_Line ("  Safe_Big_Ratio (30.0, 5.0) = "
             & Boolean'Image (Safe_Big_Ratio (30.0, 5.0)));

   -- ---------------------------
   -- 2. rem 与 mod：负数上的差异
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. rem 与 mod（除数 3） ---");
   Put_Line ("     X     X rem 3     X mod 3");
   for X in -7 .. 7 loop
      if X rem 3 /= X mod 3 then
         Put ("  ");
         Put (X, Width => 4);
         Put (X rem 3, Width => 10);
         Put (X mod 3, Width => 10);
         Put_Line ("   ← 负数时两者不同");
      end if;
   end loop;
   Put_Line ("  恒等式：X = (X/Y)*Y + (X rem Y)；mod 结果与除数同号。");

   -- ---------------------------
   -- 3. if - elsif - else：成绩分级
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. if 分级 ---");
   declare
      Scores : constant array (1 .. 5) of Integer := (97, 85, 76, 65, 40);
   begin
      for K in Scores'Range loop
         declare
            Score : constant Integer := Scores (K);
            Grade : Character;
         begin
            if Score >= 95 then
               Grade := 'A';
            elsif Score >= 85 then
               Grade := 'B';
            elsif Score >= 75 then
               Grade := 'C';
            elsif Score >= 65 then
               Grade := 'D';
            else
               Grade := 'F';
            end if;
            Put ("  分数" & Integer'Image (Score) & " → 等级 ");
            Put (Grade);
            New_Line;
         end;
      end loop;
   end;

   -- ---------------------------
   -- 4. case：值集合与 others
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. case 语句 ---");
   for Grade in Character range 'A' .. 'F' loop
      case Grade is
         when 'A' | 'B' =>
            Put_Line ("  " & Grade & " → 优良");
         when 'C' =>
            Put_Line ("  C → 中等");
         when 'D' =>
            Put_Line ("  D → 及格");
         when 'E' =>
            Put_Line ("  E → 未使用");
         when others =>
            Put_Line ("  F → 不及格");
      end case;
   end loop;

   -- ---------------------------
   -- 5. 三种循环形态
   -- ---------------------------
   New_Line;
   Put_Line ("--- 5. 三种循环 ---");
   Put ("  for 正序 1..5 : ");
   for I in 1 .. 5 loop
      Put (I, Width => 0);
      Put (" ");
   end loop;
   New_Line;

   Put ("  for 逆序 reverse : ");
   for I in reverse 1 .. 5 loop
      Put (I, Width => 0);
      Put (" ");
   end loop;
   New_Line;

   Put_Line ("  for 的循环变量是隐式常量，循环体内不可赋值；");
   Put_Line ("  枚举类型同样可以做循环范围。");

   declare
      Counter : Integer := 3;
   begin
      Put ("  while 倒计时 :");
      while Counter > 0 loop
         Put (" T-" & Integer'Image (Counter));
         Counter := Counter - 1;
      end loop;
      Put_Line (" 发射!");
   end;

   declare
      N : Integer := 1;
   begin
      Put ("  loop + exit when :");
      loop
         Put (N, Width => 0);
         Put (" ");
         exit when N >= 5;         -- 出口语句：条件满足即离开本层循环
         N := N + 1;
      end loop;
      New_Line;
   end;

   -- ---------------------------
   -- 6. 循环嵌套与剪枝：百鸡问题（刘炳文 §5.6 例 5-24）
   --    鸡翁一值钱五，鸡母一值钱三，鸡雏三值钱一；百钱买百鸡，问各几何
   -- ---------------------------
   New_Line;
   Put_Line ("--- 6. 百鸡问题：三重循环 → 两重循环 ---");
   declare
      Count_Triple : Natural := 0;          -- 版本 A 实际判定次数
      Count_Double : Natural := 0;          -- 版本 B 实际判定次数
   begin
      -- 版本 A：三重暴力循环，101*101*101 = 1030301 次判定
      for X in 0 .. 100 loop                -- 公鸡数
         for Y in 0 .. 100 loop             -- 母鸡数
            for Z in 0 .. 100 loop          -- 雏鸡数
               Count_Triple := Count_Triple + 1;
               -- 雏鸡三只一钱：先验整除，再算钱。老书原版漏了这条，
               -- 实测会多打 4 行伪解（X=3/7/11、Z=77/80/83 不整除 3，
               -- 靠 Z/3 截断除法"凑"出 100 钱）
               if X + Y + Z = 100
                 and then Z mod 3 = 0
                 and then 5 * X + 3 * Y + Z / 3 = 100
               then
                  Put_Line ("    解：公鸡" & Integer'Image (X)
                            & "  母鸡" & Integer'Image (Y)
                            & "  雏鸡" & Integer'Image (Z));
               end if;
            end loop;
         end loop;
      end loop;

      -- 版本 B：约束传播——鸡总数十守恒推出 Z = 100 - X - Y，
      -- 公鸡钱数十界把 X 压到 0..20，母鸡压到 0..33
      for X in 0 .. 20 loop
         for Y in 0 .. 33 loop
            Count_Double := Count_Double + 1;
            declare
               Z : constant Integer := 100 - X - Y;   -- 白送的第三个变量
            begin
               if Z >= 0 and then Z mod 3 = 0
                 and then 5 * X + 3 * Y + Z / 3 = 100
               then
                  null;                    -- 解已在上面列全，这里只对账
               end if;
            end;
         end loop;
      end loop;
      Put_Line ("  三重循环判定" & Integer'Image (Count_Triple)
                & " 次；两重循环仅" & Integer'Image (Count_Double)
                & " 次（相差约 "
                & Integer'Image (Count_Triple / Count_Double) & " 倍）");
   end;

   -- ---------------------------
   -- 7. 命名循环：exit 循环名 直接跳出多重循环
   -- ---------------------------
   New_Line;
   Put_Line ("--- 7. 命名循环 ---");
   declare
      type Grid is array (1 .. 4, 1 .. 5) of Integer;
      M : constant Grid :=
        ((3, 1, 4, 1, 5),
         (9, 2, 6, 5, 3),
         (5, 8, 9, 0, 9),
         (7, 9, 3, 2, 3));
   begin
      Search :
      for I in M'Range (1) loop
         for J in M'Range (2) loop
            if M (I, J) = 0 then
               Put_Line ("  在 M ("
                         & Integer'Image (I) & ","
                         & Integer'Image (J) & ") 找到 0");
               exit Search;        -- 一步跳出两重循环
            end if;
         end loop;
      end loop Search;
      Put_Line ("  命名循环的 end loop 后必须重复循环名。");
   end;

   -- ---------------------------
   -- 8. goto：受限的无条件转移
   -- ---------------------------
   New_Line;
   Put_Line ("--- 8. goto 与气泡分类 ---");
   declare
      A : array (1 .. 6) of Integer := (5, 2, 8, 1, 9, 3);
      Temp : Integer;
   begin
      <<Sort>>                        -- 语句标号：双尖括号
      for I in 1 .. 5 loop
         if A (I) > A (I + 1) then
            Temp := A (I);
            A (I) := A (I + 1);
            A (I + 1) := Temp;
            goto Sort;                -- 本趟有交换：从头再来
         end if;
      end loop;

      Put ("  排序结果 :");
      for I in A'Range loop
         Put (A (I), Width => 0);
         Put (" ");
      end loop;
      New_Line;
      Put_Line ("  goto 只能在同一单元体内转移，不得转入 if/case/循环内部。");
   end;

   -- ---------------------------
   -- 9. 块结构 declare：把临时变量的作用域压到最小
   -- ---------------------------
   New_Line;
   Put_Line ("--- 9. 块结构 ---");
   declare
      X : Integer := 10;
      Y : Integer := 20;
   begin
      Swap_Block :
      declare
         Temp : Integer;             -- Temp 只在本块可见
      begin
         Temp := X;
         X := Y;
         Y := Temp;
      end Swap_Block;
      Put_Line ("  块内交换后：X =" & Integer'Image (X)
                & "，Y =" & Integer'Image (Y));
   end;
   Put_Line ("  块可以有名字（如 Swap_Block），还可带自己的 exception 部分。");
end Ch04_Control;
