-- ============================================================
-- 第12章：泛型编程
--   —— 泛型形参种类 / 实例化 / 泛型栈 (书 STACK_G) /
--      第 N 个后继 (书 After_N) / 子程序形参 (书 GSORT 精神)
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure Ch12_Generics is

   -- ---------------------------
   -- 泛型过程：private 形参（任何可赋值类型）
   -- ---------------------------
   generic
      type Element_Type is private;
   procedure Swap (A, B : in out Element_Type);

   procedure Swap (A, B : in out Element_Type) is
      Temp : constant Element_Type := A;
   begin
      A := B;
      B := Temp;
   end Swap;

   -- ---------------------------
   -- 泛型函数：离散形参 (<>)
   -- ---------------------------
   generic
      type T is (<>);          -- 任何离散类型：整型/枚举/字符
   function Max (A, B : T) return T;

   function Max (A, B : T) return T is
   begin
      if A > B then
         return A;
      else
         return B;
      end if;
   end Max;

   -- ---------------------------
   -- 泛型函数：枚举的第 N 个后继（环绕，老教材 After_N）
   -- ---------------------------
   generic
      type Enum is (<>);
      N : Integer := 2;        -- 值形参可带缺省
   function After_N (E : Enum) return Enum;

   function After_N (E : Enum) return Enum is
      G : Enum := E;
   begin
      for I in 1 .. N loop
         if G = Enum'Last then
            G := Enum'First;      -- 到头环绕
         else
            G := Enum'Succ (G);
         end if;
      end loop;
      return G;
   end After_N;

   -- ---------------------------
   -- 泛型包：通用栈（老教材 STACK_G）
   -- ---------------------------
   generic
      Size : Positive;                 -- 值形参
      type Elem is private;            -- 类型形参
   package Stack_G is
      procedure Push (E : in Elem);
      procedure Pop  (E : out Elem);
      function Is_Empty return Boolean;
      Stack_Overflow, Stack_Underflow : exception;   -- 异常也是接口
   end Stack_G;

   package body Stack_G is
      Space : array (1 .. Size) of Elem;
      Index : Integer range 0 .. Size := 0;

      procedure Push (E : in Elem) is
      begin
         if Index = Size then
            raise Stack_Overflow;
         end if;
         Index := Index + 1;
         Space (Index) := E;
      end Push;

      procedure Pop (E : out Elem) is
      begin
         if Index = 0 then
            raise Stack_Underflow;
         end if;
         E := Space (Index);
         Index := Index - 1;
      end Pop;

      function Is_Empty return Boolean is (Index = 0);
   end Stack_G;

   -- ---------------------------
   -- 泛型排序：带子程序形参（老教材 GSORT 的精神内核）
   --   排序逻辑一份，"小于"与打印各由实参子程序注入
   -- ---------------------------
   generic
      type Index is (<>);                              -- 下标：离散类型
      type Elem  is private;                           -- 元素：可赋值即可
      type Arr   is array (Index range <>) of Elem;    -- 数组：非约束
      with function Lt (X, Y : Elem) return Boolean;   -- 注入比较
      with procedure Put_Elem (X : Elem);              -- 注入打印
   package Sort_G is
      procedure Put (V : Arr);
      procedure Sort (V : in out Arr);
   end Sort_G;

   package body Sort_G is
      procedure Put (V : Arr) is
      begin
         Put ("  [");
         for I in V'Range loop
            if I /= V'First then
               Put (", ");
            end if;
            Put_Elem (V (I));
         end loop;
         Put_Line ("]");
      end Put;

      -- 插入分类：对任何 Elem 排序，全靠注入的 Lt
      procedure Sort (V : in out Arr) is
         I, J : Index;
         M, T : Elem;
      begin
         I := Index'Succ (V'First);
         while I <= V'Last loop
            M := V (I);
            J := I;
            while J > V'First and then Lt (M, V (Index'Pred (J))) loop
               V (J) := V (Index'Pred (J));
               J := Index'Pred (J);
            end loop;
            V (J) := M;
            I := Index'Succ (I);
         end loop;
      end Sort;
   end Sort_G;

begin
   Put_Line ("=== Ada 泛型编程 ===");
   New_Line;

   -- ---------------------------
   -- 1. 实例化泛型过程与函数
   -- ---------------------------
   Put_Line ("--- 1. 实例化 ---");
   declare
      procedure Swap_Int is new Swap (Element_Type => Integer);
      function  Max_Int  is new Max  (T => Integer);

      X, Y : Integer := 0;
   begin
      X := 10; Y := 20;
      Swap_Int (X, Y);
      Put_Line ("  Swap_Int 后 X =" & Integer'Image (X) & ", Y =" & Integer'Image (Y));
      Put_Line ("  Max_Int (42, 17) =" & Integer'Image (Max_Int (42, 17)));
      Put_Line ("  实例化是编译期动作：生成一份针对 Integer 的代码。");
   end;

   -- ---------------------------
   -- 2. 枚举 + 缺省值形参：After_N
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. 第 N 个后继 ---");
   declare
      type Day is (Mon, Tue, Wed, Thu, Fri, Sat, Sun);
      function Next2 is new After_N (Day, 2);    -- N = 2
      function Next5 is new After_N (Day, 5);    -- N = 5
   begin
      Put_Line ("  Next2 (Fri) = " & Day'Image (Next2 (Fri)));   -- Sun
      Put_Line ("  Next2 (Sat) = " & Day'Image (Next2 (Sat)));   -- Mon（环绕）
      Put_Line ("  Next5 (Thu) = " & Day'Image (Next5 (Thu)));   -- Tue（环绕）
   end;

   -- ---------------------------
   -- 3. 泛型包：两个栈实例（同一模板，不同类型与容量）
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 泛型栈 ---");
   declare
      package Int_Stack  is new Stack_G (Size => 10, Elem => Integer);
      package Bool_Stack is new Stack_G (Size => 4,  Elem => Boolean);

      V : Integer;
      B : Boolean;
   begin
      Int_Stack.Push (100);
      Int_Stack.Push (200);
      Int_Stack.Push (300);
      Int_Stack.Pop (V);
      Put_Line ("  Int_Stack.Pop  →" & Integer'Image (V));

      Bool_Stack.Push (True);
      Bool_Stack.Pop (B);
      Put_Line ("  Bool_Stack.Pop → " & Boolean'Image (B));

      Put_Line ("  同一模板生成两套独立代码：容量、元素类型都不同。");
   end;

   -- ---------------------------
   -- 4. 子程序形参：一份排序，注入比较与打印
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. 子程序形参排序 ---");
   declare
      type Chars is array (Integer range <>) of Character;

      function Lt_Ch (X, Y : Character) return Boolean is (X < Y);

      procedure Put_Ch (X : Character) is
      begin
         Put (X);
      end Put_Ch;

      package Ch_Sort is new Sort_G
        (Index   => Integer,
         Elem    => Character,
         Arr     => Chars,
         Lt      => Lt_Ch,
         Put_Elem => Put_Ch);

      Data : Chars (1 .. 8) := ('a', 'd', 'c', 'b', 'h', 'e', 'f', 'g');
   begin
      Put ("  排序前 ");
      Ch_Sort.Put (Data);
      Ch_Sort.Sort (Data);
      Put ("  排序后 ");
      Ch_Sort.Put (Data);
      Put_Line ("  换一种元素类型/比较规则，只要再实例化一份 Sort_G。");
   end;
end Ch12_Generics;
