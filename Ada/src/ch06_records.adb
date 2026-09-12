-- ============================================================
-- 第6章：记录类型 (Record)
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;

procedure Ch06_Records is

   -- 简单记录
   type Person is record
      Name : String (1 .. 20);
      Age  : Integer;
   end record;

   -- 带默认值的记录
   type Point is record
      X, Y : Float := 0.0;
   end record;

   -- 带判别式的记录 (变体记录)
   type Shape_Kind is (Circle, Rectangle);
   type Shape (Kind : Shape_Kind) is record
      case Kind is
         when Circle =>
            Radius : Float;
         when Rectangle =>
            Width  : Float;
            Height : Float;
      end case;
   end record;

   -- 空记录
   type Null_Record is null record;

   -- 记录嵌套
   type Address is record
      Street : String (1 .. 30);
      City   : String (1 .. 12);
   end record;

   type Employee is record
      Name    : String (1 .. 12);
      Age     : Integer;
      Addr    : Address;
      Salary  : Float;
   end record;

begin
   Put_Line ("=== Ada 记录类型示例 ===");
   New_Line;

   -- 1. 简单记录
   Put_Line ("--- 1. 简单记录 ---");
   declare
      P : Person := (Name => "Ada Lovelace        ", Age => 36);
   begin
      Put_Line ("  Name: " & P.Name);
      Put_Line ("  Age: " & Integer'Image(P.Age));
   end;

   -- 2. 带默认值
   New_Line;
   Put_Line ("--- 2. 带默认值的记录 ---");
   declare
      P1 : Point;  -- 使用默认值
      P2 : Point := (X => 3.0, Y => 4.0);
   begin
      Put_Line ("  P1 (默认): X =" & Float'Image(P1.X) & ", Y =" & Float'Image(P1.Y));
      Put_Line ("  P2: X =" & Float'Image(P2.X) & ", Y =" & Float'Image(P2.Y));
   end;

   -- 3. 变体记录
   New_Line;
   Put_Line ("--- 3. 变体记录 (Discriminated Record) ---");
   declare
      C : Shape (Circle) := (Kind => Circle, Radius => 5.0);
      R : Shape (Rectangle) := (Kind => Rectangle, Width => 3.0, Height => 4.0);
   begin
      Put_Line ("  Circle: Radius =" & Float'Image(C.Radius));
      Put_Line ("  Rectangle: Width =" & Float'Image(R.Width) & ", Height =" & Float'Image(R.Height));
   end;

   -- 4. 记录嵌套
   New_Line;
   Put_Line ("--- 4. 记录嵌套 ---");
   declare
      Emp : Employee := (
         Name   => "Ada Byron   ",
         Age    => 28,
         Addr   => (Street => "1600 Pennsylvania Avenue NW   ",
                    City   => "Washington  "),
         Salary => 15000.0
      );
   begin
      Put_Line ("  Name: " & Emp.Name);
      Put_Line ("  Age: " & Integer'Image(Emp.Age));
      Put_Line ("  Address: " & Emp.Addr.Street & ", " & Emp.Addr.City);
      Put ("  Salary: "); Put (Emp.Salary, Fore => 0, Aft => 2, Exp => 0); New_Line;
   end;
end Ch06_Records;