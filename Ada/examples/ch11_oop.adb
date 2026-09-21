-- ============================================================
-- 第11章：面向对象编程 (Tagged Types / OOP)
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;
with Ada.Numerics;

procedure Ch11_OOP is

   -- 基类：Shape
   package Shape_Pkg is
      type Shape is tagged record
         Name : String (1 .. 20) := (others => ' ');
      end record;

      function Area (S : Shape) return Float is (0.0);
      procedure Print (S : Shape);
   end Shape_Pkg;

   package body Shape_Pkg is
      procedure Print (S : Shape) is
      begin
         Put_Line ("  Shape: " & S.Name);
      end Print;
   end Shape_Pkg;

   -- 派生类：Circle
   package Circle_Pkg is
      type Circle is new Shape_Pkg.Shape with record
         Radius : Float := 0.0;
      end record;

      overriding function Area (C : Circle) return Float;
      overriding procedure Print (C : Circle);
   end Circle_Pkg;

   package body Circle_Pkg is
      overriding function Area (C : Circle) return Float is
      begin
         return Ada.Numerics.Pi * C.Radius * C.Radius;
      end Area;

      overriding procedure Print (C : Circle) is
      begin
         Put_Line ("  Circle: " & C.Name);
         Put ("    Radius = "); Put (C.Radius, Fore => 0, Aft => 2, Exp => 0); New_Line;
         Put ("    Area   = "); Put (Area(C), Fore => 0, Aft => 2, Exp => 0); New_Line;
      end Print;
   end Circle_Pkg;

   -- 派生类：Rectangle
   package Rectangle_Pkg is
      type Rectangle is new Shape_Pkg.Shape with record
         Width  : Float := 0.0;
         Height : Float := 0.0;
      end record;

      overriding function Area (R : Rectangle) return Float;
      overriding procedure Print (R : Rectangle);
   end Rectangle_Pkg;

   package body Rectangle_Pkg is
      overriding function Area (R : Rectangle) return Float is
      begin
         return R.Width * R.Height;
      end Area;

      overriding procedure Print (R : Rectangle) is
      begin
         Put_Line ("  Rectangle: " & R.Name);
         Put ("    Width  = "); Put (R.Width, Fore => 0, Aft => 2, Exp => 0); New_Line;
         Put ("    Height = "); Put (R.Height, Fore => 0, Aft => 2, Exp => 0); New_Line;
         Put ("    Area   = "); Put (Area(R), Fore => 0, Aft => 2, Exp => 0); New_Line;
      end Print;
   end Rectangle_Pkg;

   -- 多态调度 (Class-wide)
   procedure Print_Shape_Info (S : Shape_Pkg.Shape'Class) is
   begin
      -- 动态分发调用 Print
      Shape_Pkg.Print (S);  -- dispatching call
   end Print_Shape_Info;

begin
   Put_Line ("=== Ada 面向对象编程示例 ===");
   New_Line;

   -- 1. 创建对象
   Put_Line ("--- 1. 创建并打印对象 ---");
   declare
      C : Circle_Pkg.Circle := (Name => "Circle_1            ", Radius => 5.0);
      R : Rectangle_Pkg.Rectangle := (Name => "Rectangle_1         ", Width => 3.0, Height => 4.0);
   begin
      Circle_Pkg.Print (C);
      New_Line;
      Rectangle_Pkg.Print (R);
   end;

   -- 2. 多态分发
   New_Line;
   Put_Line ("--- 2. 多态分发 (Dynamic Dispatch) ---");
   declare
      C : Circle_Pkg.Circle := (Name => "Circle_Poly         ", Radius => 2.5);
      R : Rectangle_Pkg.Rectangle := (Name => "Rect_Poly           ", Width => 6.0, Height => 3.0);
   begin
      Put_Line ("  通过 Class-wide 类型调用:");
      Print_Shape_Info (C);
      New_Line;
      Print_Shape_Info (R);
   end;
end Ch11_OOP;