-- ============================================================
-- 第26章：独立编译、子单位与可见性
-- 主程序：with/use、use type、renames、体存根（子单位）与子库单元
-- 配套文件：
--   ch26_separate-report.adb      子单位：Report 过程体
--   ch26_separate-helpers.adb     子单位：嵌套包 Helpers 的体
--   ch26_support.ads              层级库父包（共享类型 Int_Array）
--   ch26_support-stats.ads/.adb   子库单元 Ch26_Support.Stats
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ch26_Support.Stats;                  -- with 子包即隐式 with 父包

procedure Ch26_Separate is

   -- --------------------------------------------------------
   -- 26.1 use type 演示包：只有用 use type 才能中缀使用其算符
   -- --------------------------------------------------------
   package Dist is
      type Meters is range 0 .. 1_000_000;
      function "+" (L, R : Meters) return Meters;
   end Dist;

   package body Dist is
      function "+" (L, R : Meters) return Meters is
        (Meters (Integer (L) + Integer (R)));   -- 借 Integer 完成实算
   end Dist;

   -- --------------------------------------------------------
   -- 26.2 renames：给名字改"别名"（不产生新实体）
   -- --------------------------------------------------------
   procedure Say (S : String) renames Put_Line;    -- 子程序改名
   package TIO renames Ada.Text_IO;                -- 包改名（长名缩短）

   -- --------------------------------------------------------
   -- 26.3 体存根：把实现拆去子单位
   -- --------------------------------------------------------
   procedure Report (Title : String; Data : Ch26_Support.Int_Array)
     is separate;

   package Helpers is                             -- 规范留下，体拆走
      function Squared (X : Integer) return Integer;
   end Helpers;
   package body Helpers is separate;

begin
   Put_Line ("=== Ada 独立编译与可见性示例 ===");
   New_Line;

   -- 1. 三种访问方式：限定名 / use / use type
   Put_Line ("--- 1. 限定名、use 与 use type ---");
   declare
      use type Dist.Meters;                       -- 只让算符可见
      A : Dist.Meters := 300;
      B : Dist.Meters := 120;
   begin
      Put_Line ("  限定名: Dist.""+'(300,120) = "
                & Dist.Meters'Image (Dist."+" (A, B)));
      Put_Line ("  use type 后中缀写法 A + B = "
                & Dist.Meters'Image (A + B));
      Put_Line ("  （use type 只放行算符，类型名仍须限定/可见）");
   end;

   -- 2. renames
   New_Line;
   Put_Line ("--- 2. renames 三连 ---");
   declare
      Arr : Ch26_Support.Int_Array (1 .. 5) := (10, 20, 30, 40, 50);
      Middle : Integer renames Arr (3);           -- 对象改名：零拷贝别名
   begin
      Say ("  过程改名: Say 就是 Put_Line");
      TIO.Put_Line ("  包改名: TIO.Put_Line 照常工作");
      Put_Line ("  对象改名: Arr(3) 现在是" & Integer'Image (Middle));
      Middle := 99;                               -- 改别名 = 改原对象
      Put_Line ("  改别名后 Arr(3) =" & Integer'Image (Arr (3)));
   end;

   -- 3. 子单位：体存根的实现住在别的文件里
   New_Line;
   Put_Line ("--- 3. 子单位 (separate) ---");
   declare
      Data : Ch26_Support.Int_Array := (3, 1, 4, 1, 5, 9, 2, 6);
   begin
      Put_Line ("  Helpers.Squared(7) = "
                & Integer'Image (Helpers.Squared (7))
                & "   （体在 ch26_separate-helpers.adb）");
      Report ("平方表", Data);                    -- 体在 ch26_separate-report.adb
   end;

   -- 4. 子库单元（child unit）：层级库的正统形态
   New_Line;
   Put_Line ("--- 4. 子库单元 (child unit) ---");
   declare
      use Ch26_Support.Stats;                     -- with 已在文件头给出
      Data : constant Ch26_Support.Int_Array :=
               (3, 1, 4, 1, 5, 9, 2, 6);
   begin
      Put_Line ("  子库单元 Ch26_Support.Stats（ch26_support-stats.*）");
      Put_Line ("  Average =" & Integer'Image (Average (Data)));
      Put_Line ("  Max_Of  =" & Integer'Image (Max_Of (Data)));
      Put_Line ("  （子包看得见父包规范的 Int_Array；with 子包");
      Put_Line ("   即隐式 with 祖先——标准库 Ada.Containers.Vectors");
      Put_Line ("   就是三层这样的层级库）");
   end;

   -- 5. 同名遮蔽与"扩展名"消歧
   New_Line;
   Put_Line ("--- 5. 遮蔽与块标签消歧 ---");
   Outer :
   declare
      X : Integer := 1;
   begin
   Inner :
      declare
         X : Integer := 2;                        -- 遮蔽外层 X
      begin
         Put_Line ("  内层 X =" & Integer'Image (X)
                   & "，块标签消歧: Outer.X =" & Integer'Image (Outer.X));
      end Inner;
      Put_Line ("  内层块结束后 X =" & Integer'Image (X));
   end Outer;
end Ch26_Separate;
