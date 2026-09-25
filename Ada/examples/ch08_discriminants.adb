-- ============================================================
-- 第8章：判别类型 (Discriminated Types)
-- 变体记录、变长数组、判别式约束与 'Constrained 属性
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;

procedure Ch08_Discriminants is

   -- --------------------------------------------------------
   -- 8.1 经典可变记录：车辆（老教材 VEHICLE 一族案例）
   --     公共部分 + 随判别式变化的变体部分
   -- --------------------------------------------------------
   type Vehicle_Kind is (Car, Van);
   type Paint_Color  is (Red, Blue, Black);

   type Vehicle (Kind : Vehicle_Kind := Car) is
      record
         Serial : Positive;          -- 公共分量：与判别式无关
         Paint  : Paint_Color;
         case Kind is                -- 变体部分：依赖判别式
            when Car =>
               Doors : Positive;
            when Van =>
               Capacity : Integer;   -- 立方米
               Load     : Integer;   -- 吨
         end case;
      end record;

   -- 判别式约束子类型：判别式被钉死，不能再变
   subtype Van_Only is Vehicle (Kind => Van);

   -- --------------------------------------------------------
   -- 8.3 变长数组：有界变长正文（老教材 TEXT 案例）
   --     数组分量上下界由判别式给出
   -- --------------------------------------------------------
   Max_Text : constant := 40;
   subtype Length_Range is Integer range 0 .. Max_Text;

   type Text (Max_Len : Length_Range := 20) is
      record
         Len  : Length_Range := 0;
         Data : String (1 .. Max_Len);
      end record;

   -- --------------------------------------------------------
   -- 8.6 案例：几何图形面积（张丽芬《Ada 程序设计导论》）
   --     用 case 对变体记录"静态分发"
   -- --------------------------------------------------------
   type Shape_Kind is (Circle_S, Rectangle_S, Triangle_S);

   -- 判别式带默认值 => 类型是 definite 的，才能做数组元素
   type Shape (Kind : Shape_Kind := Circle_S) is
      record
         case Kind is
            when Circle_S =>
               Radius : Float;
            when Rectangle_S =>
               Width, Height : Float;
            when Triangle_S =>
               Base, Altitude : Float;  -- 分量名跨变体不能重复
         end case;
      end record;

   function Area (S : Shape) return Float is
   begin
      case S.Kind is                     -- 必须覆盖所有变体
         when Circle_S =>
            return 3.14159_26535_89793 * S.Radius ** 2;
         when Rectangle_S =>
            return S.Width * S.Height;
         when Triangle_S =>
            return 0.5 * S.Base * S.Altitude;
      end case;
   end Area;

   procedure Put_Area (S : Shape) is
   begin
      case S.Kind is
         when Circle_S =>
            Put ("  圆     r=");
            Put (S.Radius,  Fore => 0, Aft => 1, Exp => 0);
         when Rectangle_S =>
            Put ("  矩形   w=");
            Put (S.Width,   Fore => 0, Aft => 1, Exp => 0);
            Put (" h=");
            Put (S.Height,  Fore => 0, Aft => 1, Exp => 0);
         when Triangle_S =>
            Put ("  三角形 b=");
            Put (S.Base,     Fore => 0, Aft => 1, Exp => 0);
            Put (" h=");
            Put (S.Altitude, Fore => 0, Aft => 1, Exp => 0);
      end case;
      Put ("  面积=");
      Put (Area (S), Fore => 0, Aft => 2, Exp => 0);
      New_Line;
   end Put_Area;

begin
   Put_Line ("=== Ada 判别类型示例 ===");
   New_Line;

   -- 1. 受约束对象：判别式在说明时钉死
   Put_Line ("--- 1. 判别式约束：受约束对象 ---");
   declare
      V      : Van_Only := (Kind     => Van,
                            Serial   => 1001,
                            Paint    => Blue,
                            Capacity => 8,
                            Load     => 5);
      Family : Vehicle (Car) := (Kind   => Car,
                                 Serial => 1002,
                                 Paint  => Red,
                                 Doors  => 4);
   begin
      Put_Line ("  货车: 载容" & Integer'Image (V.Capacity)
                & " m3, 载重" & Integer'Image (V.Load) & " t");
      Put_Line ("  轿车: " & Positive'Image (Family.Doors) & " 门");
      Put_Line ("  V'Constrained      = " & Boolean'Image (V'Constrained));
      Put_Line ("  Family'Constrained = " & Boolean'Image (Family'Constrained));
   end;

   -- 2. 无约束对象：默认判别式，整体赋值可换变体
   New_Line;
   Put_Line ("--- 2. 默认判别式：无约束对象与变体切换 ---");
   declare
      M : Vehicle := (Kind => Car, Serial => 2001,
                      Paint => Black, Doors => 2);
   begin
      Put_Line ("  初始: " & Vehicle_Kind'Image (M.Kind)
                & ", " & Positive'Image (M.Doors) & " 门");
      Put_Line ("  M'Constrained = " & Boolean'Image (M'Constrained));

      -- 判别式不能单独赋值（M.Kind := Van; 编译不过），
      -- 只能通过【整个记录赋值】改变结构
      M := (Kind     => Van,
            Serial   => M.Serial,        -- 保留公共分量
            Paint    => M.Paint,
            Capacity => 12,
            Load     => 2);
      Put_Line ("  改判别式后: " & Vehicle_Kind'Image (M.Kind)
                & ", 载容" & Integer'Image (M.Capacity) & " m3");
   end;

   -- 3. 访问"不存在"的变体分量 → 运行期 Constraint_Error
   New_Line;
   Put_Line ("--- 3. 变体分量访问的运行期保护 ---");
   declare
      M : Vehicle := (Kind => Van, Serial => 3001, Paint => Red,
                      Capacity => 8, Load => 3);
   begin
      Put_Line ("  尝试读取 Van 对象的 Doors 分量...");
      Put_Line ("  Doors =" & Positive'Image (M.Doors));
   exception
      when Constraint_Error =>
         Put_Line ("  Constraint_Error: 当前变体是 Van，没有 Doors 分量");
   end;

   -- 4. 变长数组：变长正文记录
   New_Line;
   Put_Line ("--- 4. 变长数组分量（有界正文） ---");
   declare
      T1 : Text (10);                       -- 容量 10，钉死
      T2 : Text := (Max_Len => 30,          -- 无约束：容量 30
                    Len     => 5,
                    Data    => (others => ' '));
   begin
      T1.Len := 5;
      T1.Data (1 .. 5) := "Hello";
      T2.Data (1 .. 5) := "World";

      Put_Line ("  T1 容量" & Integer'Image (T1.Max_Len)
                & ", 内容: " & T1.Data (1 .. T1.Len));
      Put_Line ("  T2 容量" & Integer'Image (T2.Max_Len)
                & ", 内容: " & T2.Data (1 .. T2.Len));
      Put_Line ("  T1'Constrained = " & Boolean'Image (T1'Constrained)
                & ", T2'Constrained = " & Boolean'Image (T2'Constrained));

      -- 容量小的对象不能整体塞进容量更小的对象
      begin
         Put_Line ("  把容量 30 的 T2 整体赋给容量 10 的 T1...");
         T1 := T2;
         Put_Line ("  成功(不应到达)");
      exception
         when Constraint_Error =>
            Put_Line ("  Constraint_Error: 30 > 10，装不下");
      end;
   end;

   -- 5. 嵌套判别：内层判别式只能依赖外层判别式
   New_Line;
   Put_Line ("--- 5. 嵌套判别类型 ---");
   declare
      -- 报文分组：数据分组自带变长负载
      type Packet_Kind is (Ctrl, Data_P);
      type Byte is mod 256;
      subtype Size_Range is Integer range 0 .. 8;

      type Payload (Size : Size_Range) is
         record
            Bytes : String (1 .. Size);
         end record;

      type Packet (Kind : Packet_Kind; Size : Size_Range) is
         record
            Seq : Natural;
            case Kind is
               when Ctrl =>
                  Code : Natural;
               when Data_P =>
                  Data : Payload (Size);   -- 内层判别式 = 外层判别式
            end case;
         end record;

      P : Packet (Kind => Data_P, Size => 4) :=
            (Kind => Data_P, Size => 4, Seq => 7,
             Data => (Size => 4, Bytes => "ABCD"));
   begin
      Put_Line ("  数据分组: Seq =" & Integer'Image (P.Seq)
                & ", 负载: " & P.Data.Bytes);
   end;

   -- 6. 几何图形面积：case 分发的完备性保护
   New_Line;
   Put_Line ("--- 6. 案例：变体记录几何面积 ---");
   declare
      Figures : array (1 .. 3) of Shape :=
        ((Kind => Circle_S,     Radius => 2.0),
         (Kind => Rectangle_S,  Width => 3.0, Height => 4.0),
         (Kind => Triangle_S,   Base  => 6.0, Altitude => 5.0));
   begin
      for F of Figures loop
         Put_Area (F);
      end loop;
      Put_Line ("  （给 Shape_Kind 增加新字面量时，");
      Put_Line ("   Area/Put_Area 里的 case 会编译报错提醒补分支——");
      Put_Line ("   这就是变体记录 + case 的完备性保护）");
   end;
end Ch08_Discriminants;
