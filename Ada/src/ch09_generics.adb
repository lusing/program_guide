-- ============================================================
-- 第9章：泛型编程 (Generic)
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;

procedure Ch09_Generics is

   -- 泛型交换过程
   generic
      type Element_Type is private;
   procedure Swap (A, B : in out Element_Type);

   procedure Swap (A, B : in out Element_Type) is
      Temp : constant Element_Type := A;
   begin
      A := B;
      B := Temp;
   end Swap;

   -- 泛型最大值函数
   generic
      type T is (<>);  -- 离散类型
   function Max (A, B : T) return T;

   function Max (A, B : T) return T is
   begin
      if A > B then return A; else return B; end if;
   end Max;

   -- 泛型栈包
   generic
      type Item_Type is private;
      Max_Size : Positive;
   package Generic_Stack is
      procedure Push (Item : Item_Type);
      function Pop return Item_Type;
      function Is_Empty return Boolean;
      Stack_Overflow : exception;
      Stack_Underflow : exception;
   private
      Stack : array (1 .. Max_Size) of Item_Type;
      Top   : Natural := 0;
   end Generic_Stack;

   package body Generic_Stack is
      procedure Push (Item : Item_Type) is
      begin
         if Top >= Max_Size then
            raise Stack_Overflow;
         end if;
         Top := Top + 1;
         Stack (Top) := Item;
      end Push;

      function Pop return Item_Type is
      begin
         if Top = 0 then
            raise Stack_Underflow;
         end if;
         declare
            Item : constant Item_Type := Stack (Top);
         begin
            Top := Top - 1;
            return Item;
         end;
      end Pop;

      function Is_Empty return Boolean is (Top = 0);
   end Generic_Stack;

   -- 实例化
   procedure Swap_Int is new Swap (Element_Type => Integer);
   function Max_Int is new Max (T => Integer);
   package Int_Stack is new Generic_Stack (Item_Type => Integer, Max_Size => 10);

begin
   Put_Line ("=== Ada 泛型编程示例 ===");
   New_Line;

   -- 1. 泛型过程
   Put_Line ("--- 1. 泛型过程 (Swap) ---");
   declare
      X, Y : Integer := 10;
   begin
      X := 10; Y := 20;
      Put_Line ("  交换前: X =" & Integer'Image(X) & ", Y =" & Integer'Image(Y));
      Swap_Int (X, Y);
      Put_Line ("  交换后: X =" & Integer'Image(X) & ", Y =" & Integer'Image(Y));
   end;

   -- 2. 泛型函数
   New_Line;
   Put_Line ("--- 2. 泛型函数 (Max) ---");
   Put_Line ("  Max(42, 17) = " & Integer'Image(Max_Int(42, 17)));

   -- 3. 泛型包（栈）
   New_Line;
   Put_Line ("--- 3. 泛型包 (Stack) ---");
   Int_Stack.Push (100);
   Int_Stack.Push (200);
   Int_Stack.Push (300);
   Put_Line ("  Pop: " & Integer'Image(Int_Stack.Pop));
   Put_Line ("  Pop: " & Integer'Image(Int_Stack.Pop));
   Put_Line ("  Pop: " & Integer'Image(Int_Stack.Pop));
   Put_Line ("  Is_Empty: " & Boolean'Image(Int_Stack.Is_Empty));
end Ch09_Generics;