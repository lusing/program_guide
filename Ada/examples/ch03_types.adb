-- ============================================================
-- 第3章：基本数据类型与变量
--   —— 整型范围 / 枚举与属性 / 实型精度 / 子类型与派生
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;

procedure Ch03_Types is
begin
   Put_Line ("=== Ada 基本数据类型与变量 ===");
   New_Line;

   -- ---------------------------
   -- 1. 整型：预定义类型与自定义范围
   -- ---------------------------
   Put_Line ("--- 1. 整型 ---");
   declare
      A      : Integer := 42;         -- 预定义：实现定义的完整范围
      B      : Natural := 100;        -- Integer 的子类型：0 .. Integer'Last
      C      : Positive := 1;         -- Integer 的子类型：1 .. Integer'Last
      type Age  is range 0 .. 150;    -- 自定义整型：范围写进类型
      type Byte is range 0 .. 255;
      My_Age : Age := 30;
      T_Byte : Byte := 16#FF#;        -- 直接量与基于表示配合使用
   begin
      Put_Line ("  Integer'First  =" & Integer'Image (Integer'First));
      Put_Line ("  Natural 范围   = 0 .." & Integer'Image (Natural'Last));
      Put_Line ("  Positive 范围  = 1 .." & Integer'Image (Positive'Last));
      Put_Line ("  My_Age (Age 0..150)   =" & Age'Image (My_Age));
      Put_Line ("  T_Byte (Byte 0..255)  =" & Byte'Image (T_Byte));

      -- 范围检查是语言保证的：越界赋值在运行期引发异常
      -- （值从字符串运行期解析而来，编译器无法静态预判；
      --   若直接写字面量 200，GNAT 在编译期就会警告甚至拒绝）
      declare
         Bad : constant Integer := Integer'Value ("200");
      begin
         My_Age := Age (Bad);         -- 200 超出 Age 的 0..150
         Put_Line ("  不应到达这里");
      exception
         when Constraint_Error =>
            Put_Line ("  My_Age := Age (200) 引发 Constraint_Error（运行期范围检查）");
      end;
   end;

   -- ---------------------------
   -- 2. 枚举类型：位置号、属性、重载与限定
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. 枚举类型 ---");
   declare
      type Color is (White, Red, Yellow, Green, Blue);
      type Light is (Red, Amber, Green);        -- Red/Green 与 Color 重载
      My_Color : Color := Green;
   begin
      Put_Line ("  My_Color          = " & Color'Image (My_Color));
      Put_Line ("  Color'First       = " & Color'Image (Color'First));
      Put_Line ("  Color'Last        = " & Color'Image (Color'Last));
      Put_Line ("  Color'Pos (Blue)  =" & Integer'Image (Color'Pos (Blue)));
      Put_Line ("  Color'Val (2)     = " & Color'Image (Color'Val (2)));
      Put_Line ("  Color'Succ (Green) = " & Color'Image (Color'Succ (Green)));
      Put_Line ("  Color'Pred (Green) = " & Color'Image (Color'Pred (Green)));

      -- 重载的直接量用限定表达式消歧
      Put_Line ("  Color'(Red) = " & Color'Image (Color'(Red)));
      Put_Line ("  Light'(Red) = " & Light'Image (Light'(Red)));

      -- 属性越界同样引发 Constraint_Error（值在运行期解析，编译器无法静态判定）
      declare
         Last_One : Color := Color'Value ("Blue");
      begin
         Put_Line ("  Color'Succ (Last_One) = " & Color'Image (Color'Succ (Last_One)));
      exception
         when Constraint_Error =>
            Put_Line ("  对 Color'Last 求 Succ 引发 Constraint_Error（已到尽头）");
      end;
   end;

   -- ---------------------------
   -- 3. 实型：digits（浮点）与 delta（定点）
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 实型 ---");
   declare
      Pi : Float := 3.14159;
      D  : Long_Float := 2.718281828;
      type Coef is digits 7;              -- 至少 7 位十进制精度
      K  : Coef := 1.0 / 3.0;
   begin
      Put ("  Pi (Float)       = ");  Put (Pi, Fore => 0, Aft => 6, Exp => 0);  New_Line;
      Put ("  D (Long_Float)   = ");  Put (Float (D), Fore => 0, Aft => 9, Exp => 0);  New_Line;
      Put ("  Coef'Digits      =" & Integer'Image (Coef'Digits));
      New_Line;
      Put ("  K (Coef 1.0/3.0) = ");  Put (Float (K), Fore => 0, Aft => 9, Exp => 0);  New_Line;
      Put_Line ("  定点类型 delta 在第 22 章专门讨论（嵌入式/货币场景）。");
   end;

   -- ---------------------------
   -- 4. 布尔与字符：预定义的枚举类型
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. 布尔与字符 ---");
   declare
      Flag : Boolean := True;
      Ch   : Character := 'A';
   begin
      Put_Line ("  Boolean 是 (False, True) 枚举：Flag = " & Boolean'Image (Flag));
      Put_Line ("  Boolean'Pos (True) =" & Integer'Image (Boolean'Pos (True)));
      Put_Line ("  Character 也是枚举：Ch = " & Character'Image (Ch));
      Put_Line ("  Character'Val (97) = " & Character'Image (Character'Val (97)));
   end;

   -- ---------------------------
   -- 5. 子类型与派生类型：两种"缩小范围"
   -- ---------------------------
   New_Line;
   Put_Line ("--- 5. 子类型 vs 派生类型 ---");
   declare
      -- 子类型：同一种类型，加约束，与 Integer 自由互通
      subtype Small_Int is Integer range -100 .. 100;
      -- 派生类型：全新类型，继承操作，但与 Integer 之间必须显式转换
      type Age is new Natural range 0 .. 150;

      S : Small_Int := 50;
      N : Integer   := 60;
      A : Age       := 30;
   begin
      S := N;              -- 子类型与基类型直接赋值（带运行期范围检查）
      Put_Line ("  S := N 合法：Small_Int 与 Integer 是同一类型，S =" & Integer'Image (S));

      -- A := N;          -- 编译错！Age 与 Integer 类型不同（文档中详述）
      A := Age (N);       -- 派生类型之间必须显式转换
      Put_Line ("  A := Age (N) 显式转换后 A =" & Age'Image (A));

      -- 'Base：剥掉约束后的基类型
      Put_Line ("  Small_Int'Base'First =" & Integer'Image (Small_Int'Base'First));
      Put_Line ("  Small_Int'First      =" & Integer'Image (Small_Int'First));
   end;

   -- ---------------------------
   -- 6. 常量与命名数字
   -- ---------------------------
   New_Line;
   Put_Line ("--- 6. 常量与命名数字 ---");
   declare
      Max_Value  : constant Integer := 999;   -- 类型化常量
      Dozen      : constant := 12;            -- 命名数字：类型由上下文决定
      Max_Count  : constant := Max_Value * 2; -- 常量表达式，编译期求值
   begin
      Put_Line ("  Max_Value : constant Integer := 999  →" & Integer'Image (Max_Value));
      Put_Line ("  Dozen     : constant := 12          →" & Integer'Image (Dozen));
      Put_Line ("  Max_Count : constant := Max_Value*2 →" & Integer'Image (Max_Count));
   end;
end Ch03_Types;
