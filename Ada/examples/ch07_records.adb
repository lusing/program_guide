-- ============================================================
-- 第7章：记录类型
--   —— 分量说明 / 两种聚集 / 缺省初值 / 嵌套 /
--      变体记录（判别式）预告
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;

procedure Ch07_Records is

   -- 嵌套记录：老教材 CPU_FLAG / CPU_STATE 例子
   type CPU_Flag is
      record
         Carry     : Boolean;
         Interrupt : Boolean;
         Negative  : Boolean;
         Zero      : Boolean;
      end record;

   type CPU_State is
      record
         Priority : Integer range 0 .. 7;
         Flag     : CPU_Flag;
      end record;

begin
   Put_Line ("=== Ada 记录类型 ===");
   New_Line;

   -- ---------------------------
   -- 1. 简单记录与两种聚集
   -- ---------------------------
   Put_Line ("--- 1. 简单记录与聚集 ---");
   declare
      type Person is
         record
            Name : String (1 .. 20);
            Age  : Integer;
         end record;

      P1 : Person := (Name => "Ada Lovelace        ", Age => 36);  -- 指名
      P2 : Person := ("Charles Babbage     ", 44);                 -- 位置
   begin
      Put_Line ("  P1.Name = " & P1.Name);
      Put_Line ("  P1.Age  =" & Integer'Image (P1.Age));
      Put_Line ("  P2.Name = " & P2.Name);
      Put_Line ("  P2.Age  =" & Integer'Image (P2.Age));
      Put_Line ("  两种聚集等价；指名法顺序任意，位置法必须按分量顺序。");
   end;

   -- ---------------------------
   -- 2. 分量缺省初值
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. 分量缺省初值 ---");
   declare
      type Position is
         record
            X, Y : Float := 0.0;       -- 缺省初值：说明时不必显式初始化
         end record;

      P1 : Position;                   -- 用缺省：(0.0, 0.0)
      P2 : Position := (X => 3.0, Y => 4.0);  -- 显式初值取代缺省
   begin
      Put_Line ("  P1 (缺省): X =" & Float'Image (P1.X) & ", Y =" & Float'Image (P1.Y));
      Put_Line ("  P2 (显式): X =" & Float'Image (P2.X) & ", Y =" & Float'Image (P2.Y));
   end;

   -- ---------------------------
   -- 3. 嵌套记录与选择分量
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 嵌套记录 ---");
   declare
      PSW : CPU_State :=
        (Priority => 5,
         Flag     => (Carry     => False,
                      Interrupt => True,
                      Negative  => False,
                      Zero      => False));
   begin
      Put_Line ("  PSW.Priority =" & Integer'Image (PSW.Priority));
      Put_Line ("  PSW.Flag.Interrupt = " & Boolean'Image (PSW.Flag.Interrupt));
      PSW.Flag.Zero := True;           -- 逐层点记法赋值
      Put_Line ("  PSW.Flag.Zero := True 后 = " & Boolean'Image (PSW.Flag.Zero));
      PSW.Flag := (others => False);   -- 整个内层记录一次赋值
      Put_Line ("  PSW.Flag := (others => False) 后 Interrupt = "
                & Boolean'Image (PSW.Flag.Interrupt));
   end;

   -- ---------------------------
   -- 4. 记录整体赋值 = 值拷贝
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. 记录赋值与相等 ---");
   declare
      type Point is
         record
            X, Y : Float := 0.0;
         end record;

      A : Point := (X => 1.0, Y => 2.0);
      B : Point;
   begin
      B := A;                 -- 整体赋值：复制全部分量
      B.X := 9.0;             -- 改 B 不影响 A
      Put_Line ("  A.X =" & Float'Image (A.X) & "（未被 B 的修改波及）");
      Put_Line ("  B.X =" & Float'Image (B.X));
      Put_Line ("  A = B 的结果 = " & Boolean'Image (A = B));
   end;

   -- ---------------------------
   -- 5. 变体记录：判别式决定分量集
   -- ---------------------------
   New_Line;
   Put_Line ("--- 5. 变体记录（判别式） ---");
   declare
      type Shape_Kind is (Circle, Rectangle);
      type Shape (Kind : Shape_Kind) is          -- Kind 是判别式
         record
            case Kind is
               when Circle =>
                  Radius : Float;
               when Rectangle =>
                  Width, Height : Float;
            end case;
         end record;

      C : Shape (Circle)    := (Kind => Circle, Radius => 5.0);
      R : Shape (Rectangle) := (Kind => Rectangle, Width => 3.0, Height => 4.0);
   begin
      Put_Line ("  C.Kind =" & Shape_Kind'Image (C.Kind)
                & "，C.Radius =" & Float'Image (C.Radius));
      Put_Line ("  R.Kind =" & Shape_Kind'Image (R.Kind)
                & "，R.Width =" & Float'Image (R.Width)
                & "，R.Height =" & Float'Image (R.Height));
      Put_Line ("  C.Radius 合法、C.Width 不存在——分量集由判别式决定。");
      Put_Line ("  判别式的完整机制（变体记录/约束/越界检查）见下一章。");
   end;

   -- ---------------------------
   -- 6. 空记录与限定聚集
   -- ---------------------------
   New_Line;
   Put_Line ("--- 6. 空记录与限定聚集 ---");
   declare
      type Null_Record is null record;           -- 无分量：占位/标记类型

      type Date is
         record
            Day   : Integer range 1 .. 31;
            Month : Integer range 1 .. 12;
            Year  : Integer range 1901 .. 2099;
         end record;

      D : Date := Date'(4, 7, 1987);   -- 限定聚集：类型名 ' (聚集)
   begin
      Put_Line ("  Null_Record 占 " & Integer'Image (Null_Record'Size) & " 位");
      Put_Line ("  D = " & Integer'Image (D.Day) & "/"
                & Integer'Image (D.Month) & "/"
                & Integer'Image (D.Year));
      Put_Line ("  Date'(...) 限定让聚集类型一锤定音，消除上下文二义。");
   end;
end Ch07_Records;
