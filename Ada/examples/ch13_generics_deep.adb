-- ============================================================
-- 第13章：泛型进阶 (Generics, Part 2)
-- 类属形参全种类：对象/类型/子程序形参、默认实参、类属缓冲区
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure Ch13_Generics_Deep is

   -- --------------------------------------------------------
   -- 13.1 类属【对象】形参：编译期常量（老教材 RING_COUNTER）
   -- --------------------------------------------------------
   generic
      Period : Positive;                    -- 值形参（隐含 in 模式）
   package Ring_Counter is
      function Is_Zero return Boolean;
      procedure Increment;
      function Count return Natural;
   end Ring_Counter;

   package body Ring_Counter is
      C : Natural := 0;
      function Is_Zero return Boolean is (C = 0);
      function Count  return Natural is (C);
      procedure Increment is
      begin
         C := (C + 1) mod Period;           -- 数到 Period 归零
      end Increment;
   end Ring_Counter;

   -- --------------------------------------------------------
   -- 13.2 类属【离散类型】形参 <>：属性可用
   --     老教材 NEXT_OPERATION：循环后继
   -- --------------------------------------------------------
   generic
      type Discrete is (<>);                -- 任何离散类型
   function Cyclic_Next (X : Discrete) return Discrete;

   function Cyclic_Next (X : Discrete) return Discrete is
   begin
      if X = Discrete'Last then
         return Discrete'First;             -- 尾绕回头
      else
         return Discrete'Succ (X);
      end if;
   end Cyclic_Next;

   type Day is (Mon, Tue, Wed, Thu, Fri, Sat, Sun);

   function Next_Day is new Cyclic_Next (Day);
   function Next_Bool is new Cyclic_Next (Boolean);

   -- --------------------------------------------------------
   -- 13.3 类属【整数类型】形参 range <>：算术可用
   -- --------------------------------------------------------
   generic
      type Int is range <>;                 -- 任何整数类型（带算术）
   function Sum_Of (X, Y : Int) return Int;

   function Sum_Of (X, Y : Int) return Int is (X + Y);

   -- --------------------------------------------------------
   -- 13.4 类属【子程序】形参 + 默认 is <>
   --     老教材 QUICKSORT：任一分量类型的数组排序
   -- --------------------------------------------------------
   generic
      type Item  is private;                -- 只保证 := 和 =
      type Index is (<>);
      type Vector is array (Index range <>) of Item;
      with function "<" (X, Y : Item) return Boolean is <>;
   procedure Generic_Sort (V : in out Vector);

   procedure Generic_Sort (V : in out Vector) is
      -- 简洁起见用插入排序（教学重点在形参，不在算法）
      procedure Swap (A, B : in out Item) is
         T : constant Item := A;
      begin
         A := B;
         B := T;
      end Swap;
   begin
      if V'Length <= 1 then
         return;
      end if;
      for I in V'First .. Index'Pred (V'Last) loop
         declare
            J : Index := I;
         begin
            while J >= V'First and then V (Index'Succ (J)) < V (J) loop
               Swap (V (J), V (Index'Succ (J)));
               exit when J = V'First;
               J := Index'Pred (J);
            end loop;
         end;
      end loop;
   end Generic_Sort;

   -- 字符串排序：实参用默认的 "<"
   procedure Char_Sort is new Generic_Sort
     (Item => Character, Index => Positive, Vector => String);

   -- --------------------------------------------------------
   -- 13.5 案例：任务通信的类属 FIFO 缓冲区（何诚 §14.5）
   --     大小与分量类型都是类属形参；limited private 封装
   -- --------------------------------------------------------
   generic
      Size   : Positive := 100;             -- 类属形参可带默认值
      type Object is private;
   package Fifo is
      type Buffer is limited private;       -- 值语义/复制被禁用
      procedure Store    (B : in out Buffer; X : Object);
      procedure Retrieve (B : in out Buffer; X : out Object);
      function Empty (B : Buffer) return Boolean;
      function Full  (B : Buffer) return Boolean;
      Overflow  : exception;
      Underflow : exception;
   private
      type Object_Array is array (1 .. Size) of Object;  -- 记录分量必须是命名数组类型
      type Buffer is
         record
            Data : Object_Array;
            Inx  : Positive range 1 .. Size := 1;   -- 写指针
            Outx : Positive range 1 .. Size := 1;   -- 读指针
            Used : Natural range 0 .. Size := 0;
         end record;
   end Fifo;

   package body Fifo is
      procedure Store (B : in out Buffer; X : Object) is
      begin
         if B.Used = Size then
            raise Overflow;
         end if;
         B.Data (B.Inx) := X;
         B.Inx  := B.Inx mod Size + 1;      -- 环形前进
         B.Used := B.Used + 1;
      end Store;

      procedure Retrieve (B : in out Buffer; X : out Object) is
      begin
         if B.Used = 0 then
            raise Underflow;
         end if;
         X := B.Data (B.Outx);
         B.Outx := B.Outx mod Size + 1;
         B.Used := B.Used - 1;
      end Retrieve;

      function Empty (B : Buffer) return Boolean is (B.Used = 0);
      function Full  (B : Buffer) return Boolean is (B.Used = Size);
   end Fifo;

   -- 例化 1：字符缓冲（省略 Size，用默认 100 的演示用小值 4）
   package Char_Fifo is new Fifo (Size => 4, Object => Character);
   -- 例化 2：整数缓冲
   package Int_Fifo  is new Fifo (Size => 8, Object => Integer);

   -- 用类属缓冲实现"按 Person.Age 排序"的比较函数
   type Person is
      record
         Name : String (1 .. 6);
         Age  : Natural;
      end record;

   type Person_Array is array (Positive range <>) of Person;

   function Older (A, B : Person) return Boolean is (A.Age < B.Age);

   procedure Age_Sort is new Generic_Sort
     (Item => Person, Index => Positive,
      Vector => Person_Array, "<" => Older);

begin
   Put_Line ("=== Ada 泛型进阶示例 ===");
   New_Line;

   -- 1. 类属对象形参：环形计数器
   Put_Line ("--- 1. 类属对象形参：环形计数器 ---");
   declare
      package Mod6 is new Ring_Counter (Period => 6);
   begin
      for I in 1 .. 8 loop
         Mod6.Increment;
         Put ("  计数(" & Integer'Image (I) & ") = "
              & Integer'Image (Mod6.Count));
         if Mod6.Is_Zero then
            Put ("  <- 归零");
         end if;
         New_Line;
      end loop;
   end;

   -- 2. 离散类型形参：循环后继
   New_Line;
   Put_Line ("--- 2. 离散类型形参 <>：循环后继 ---");
   Put_Line ("  Next_Day(Sun)  = " & Day'Image (Next_Day (Sun)));
   Put_Line ("  Next_Bool(True) = " & Boolean'Image (Next_Bool (True)));

   -- 3. 整数类型形参：算术可用
   New_Line;
   Put_Line ("--- 3. 整数类型形参 range <> ---");
   declare
      type Small_Int is range -100 .. 100;  -- 自定义整数类型
      function Small_Sum is new Sum_Of (Small_Int);
   begin
      Put_Line ("  Small_Sum(40, 2) = "
                & Small_Int'Image (Small_Sum (40, 2)));
   end;

   -- 4. 类属子程序形参：排序
   New_Line;
   Put_Line ("--- 4. 子程序形参 + 默认 is <>：排序 ---");
   declare
      S : String := "STEVE";
   begin
      Char_Sort (S);
      Put_Line ("  排序 ""STEVE"" -> """ & S & """（默认 ""<""）");
   end;
   declare
      Team : Person_Array :=
        ((Name => "GEORGE", Age => 45),
         (Name => "ALICE ", Age => 30),
         (Name => "RITA  ", Age => 38));
   begin
      Age_Sort (Team);                      -- 用 Older 作 "<"
      Put_Line ("  按年龄排序:");
      for P of Team loop
         Put_Line ("    " & P.Name & " " & Integer'Image (P.Age));
      end loop;
   end;

   -- 5. 类属 FIFO 缓冲区：两个例化互不干扰
   New_Line;
   Put_Line ("--- 5. 案例：类属 FIFO 缓冲区 ---");
   declare
      use Char_Fifo;
      CB : Buffer;
      Ch : Character;
   begin
      for C in Character range 'a' .. 'd' loop
         Store (CB, C);
      end loop;
      Put_Line ("  字符缓冲已存 4 个（容量 4，Full = "
                & Boolean'Image (Full (CB)) & "）");
      begin
         Store (CB, 'x');                   -- 第 5 个 -> Overflow
      exception
         when Overflow => Put_Line ("  再存: Overflow 异常");
      end;
      Put ("  依次取出: ");
      while not Empty (CB) loop
         Retrieve (CB, Ch);
         Put (Ch & " ");
      end loop;
      New_Line;
   end;
   declare
      use Int_Fifo;
      IB : Buffer;
      N  : Integer;
   begin
      for I in 1 .. 5 loop
         Store (IB, I * 11);
      end loop;
      Retrieve (IB, N);
      Put_Line ("  整数缓冲取出一个: " & Integer'Image (N)
                & "（容量 8，独立于字符缓冲）");
   end;
end Ch13_Generics_Deep;
