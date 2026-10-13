-- ============================================================
-- 第14章：面向对象编程 —— tagged 类型与动态分发
--   —— abstract 基类 / 派生与 overriding /
--      类范围类型 Shape'Class / 扩展聚集 /
--      异构容器（访问类范围）
--
--   注意：分发操作（原语操作）必须与 tagged 类型声明在同一个
--   包规范里——所以整个图形家族包在嵌套包 Shapes 中。
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;
with Ada.Numerics;

procedure Ch14_OOP is

   package Shapes is
      -- 抽象基类：只能被继承，不能直接说明对象
      type Shape is abstract tagged record
         Name : String (1 .. 12) := (others => ' ');
      end record;

      function Area (S : Shape) return Float is abstract;  -- 必须被覆盖
      procedure Print (S : Shape'Class);   -- 类范围参数：体内可分发调用 Area

      -- 派生一：圆
      type Circle is new Shape with
         record
            Radius : Float;
         end record;

      overriding                          -- 覆盖检查：签名错即编译错
      function Area (C : Circle) return Float;

      -- 派生二：矩形
      type Rectangle is new Shape with
         record
            Width, Height : Float;
         end record;

      overriding
      function Area (R : Rectangle) return Float;

      -- 类范围访问类型：指向家族任何成员
      type Shape_Access is access all Shape'Class;
   end Shapes;

   package body Shapes is
      procedure Print (S : Shape'Class) is
      begin
         Put ("  " & S.Name & "  面积 = ");
         Put (Area (S), Aft => 2, Exp => 0);  -- 分发：按实参 tag 选实现
         New_Line;
      end Print;

      function Area (C : Circle) return Float is
        (Ada.Numerics.Pi * C.Radius * C.Radius);

      function Area (R : Rectangle) return Float is (R.Width * R.Height);
   end Shapes;

   use Shapes;

   -- 定长 Name 的补齐工具：字面量长度不再需要手工数
   function Nm (S : String) return String is
      Pad : String (1 .. 12) := (others => ' ');
   begin
      Pad (1 .. S'Length) := S;
      return Pad;
   end Nm;

begin
   Put_Line ("=== Ada 面向对象编程 ===");
   New_Line;

   -- ---------------------------
   -- 1. 具体对象与扩展聚集
   -- ---------------------------
   Put_Line ("--- 1. 对象与扩展聚集 ---");
   declare
      -- 扩展聚集：祖先分量 + 新增分量一次写全
      C : Circle := (Name => Nm ("圆"),
                     Radius => 5.0);
      R : Rectangle := (Name => Nm ("矩形"),
                        Width  => 3.0,
                        Height => 4.0);
   begin
      Print (C);                       -- 静态调用点 → Circle.Area
      Print (R);                       -- → Rectangle.Area
      Put_Line ("  扩展聚集 = 祖先分量(名) + 派生分量(半径/宽高)。");
   end;

   -- ---------------------------
   -- 2. 类范围类型：一个名字，一族类型
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. 类范围与动态分发 ---");
   declare
      -- Shape'Class 覆盖 Shape 及其全部派生——可以直接当参数类型
      procedure Report (S : Shape'Class) is
      begin
         Put ("  [类范围参数] ");
         Print (S);                    -- 运行期按 S 的实际 tag 分发
      end Report;

      C : Circle     := (Name => Nm ("小圆"), Radius => 1.0);
      R : Rectangle  := (Name => Nm ("长方形"), Width => 6.0, Height => 2.0);
   begin
      Report (C);
      Report (R);
      Put_Line ("  同一个 Print 调用点，两种行为——这就是动态分发。");
   end;

   -- ---------------------------
   -- 3. 异构容器：装下整个家族
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 异构容器 ---");
   declare
      type Shape_List is array (1 .. 4) of Shape_Access;
      List : constant Shape_List :=
        (new Circle'(Name => Nm ("圆A"), Radius => 2.0),
         new Rectangle'(Name => Nm ("矩形A"), Width => 1.5, Height => 3.0),
         new Circle'(Name => Nm ("圆B"), Radius => 10.0),
         new Rectangle'(Name => Nm ("矩形B"), Width => 5.0, Height => 5.0));

      Total : Float := 0.0;
   begin
      for K in List'Range loop
         Print (List (K).all);         -- .all 解引用后分发
         Total := Total + Area (List (K).all);
      end loop;
      Put ("  四个图形总面积 = ");
      Put (Total, Aft => 2, Exp => 0);
      New_Line;
      Put_Line ("  数组元素是 Shape'Class 的访问值：圆和矩形同住一屋。");
   end;

   -- ---------------------------
   -- 4. 类型检查：abstract 与 overriding 的防护
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. 语言级防护 ---");
   Put_Line ("  Shape 是 abstract：直接说明 Shape 对象会编译错；");
   Put_Line ("  Area 是 abstract 函数：派生类不覆盖它就编译错；");
   Put_Line ("  overriding 标注：拼错函数名/签名不匹配会编译错；");
   Put_Line ("  分发操作必须与 tagged 类型同在包规范中——");
   Put_Line ("  这就是本示例把图形家族装进嵌套包 Shapes 的原因。");
end Ch14_OOP;
