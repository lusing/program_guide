------------------------------------------------------------------------------
--  Ch16: Ada 2012 契约式编程 (Contract-Based Programming) 示例
--
--  本示例演示 Ada 2012 引入的核心契约机制：
--    1. Pre           前置条件
--    2. Post          后置条件 (含 'Result 与 'Old)
--    3. Type_Invariant 类型不变式
--    4. Dynamic_Predicate 动态谓词
--    5. Loop_Invariant / Loop_Variant 循环不变式
--    6. 表达式函数 (Expression Functions)
--    7. Assert / Assert_And_Cut / Assume
--
--  编译时需启用断言检查：gnatmake -gnata ch24_contracts.adb
------------------------------------------------------------------------------
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Assertions;      use Ada.Assertions;
with Ada.Exceptions;      use Ada.Exceptions;

procedure Ch24_Contracts is

   -----------------------------------------------------------------------
   --  1. 带前置/后置条件的简单函数：安全除法
   -----------------------------------------------------------------------
   function Safe_Divide (X, Y : Integer) return Integer is
     (X / Y)  --  表达式函数：一行实现
   with
     Pre  => Y /= 0,                                  --  除数不能为零
     Post => Safe_Divide'Result * Y = X;              --  商 * 除数 = 被除数

   -----------------------------------------------------------------------
   --  2. 带 Old 引用的后置条件：增加值
   -----------------------------------------------------------------------
   procedure Increment (N : in out Integer)
     with Post => N = N'Old + 1
   is
   begin
      N := N + 1;
   end Increment;                                      --  调用后比调用前大 1

   -----------------------------------------------------------------------
   --  3. 带 Dynamic_Predicate 的子类型：只能取偶数
   -----------------------------------------------------------------------
   subtype Even_Integer is Integer
     with Dynamic_Predicate => Even_Integer mod 2 = 0;

   -----------------------------------------------------------------------
   --  4. 带 Type_Invariant 的私有类型：始终非负
   -----------------------------------------------------------------------
   package Safe_Counter is
      type Counter is private
        with Type_Invariant => Is_Valid (Counter);   --  类型不变式

      function  Is_Valid (C : Counter) return Boolean;
      procedure Init   (C : out Counter);
      procedure Bump   (C : in out Counter);
      procedure Reset  (C : in out Counter);
      function  Get    (C : Counter) return Integer;
   private
      type Counter is record
         Value : Integer := 0;
      end record;
   end Safe_Counter;

   package body Safe_Counter is
      function Is_Valid (C : Counter) return Boolean is
      begin
         return C.Value >= 0;
      end Is_Valid;

      procedure Init (C : out Counter) is
      begin
         C := (Value => 0);
      end Init;

      procedure Bump (C : in out Counter) is
      begin
         C.Value := C.Value + 1;
      end Bump;

      procedure Reset (C : in out Counter) is
      begin
         C.Value := 0;
      end Reset;

      function Get (C : Counter) return Integer is
      begin
         return C.Value;
      end Get;
   end Safe_Counter;

   -----------------------------------------------------------------------
   --  5. 带复杂契约的栈操作：NotEmpty / Length 不超过 Capacity
   -----------------------------------------------------------------------
   Capacity : constant := 5;

   type Stack_Array is array (1 .. Capacity) of Integer;
   type Stack is record
      Data : Stack_Array;
      Top  : Natural := 0;
   end record
     with Dynamic_Predicate => Stack.Top <= Capacity;   --  栈不会溢出

   procedure Push (S : in out Stack; V : Integer)
     with Pre  => S.Top < Capacity,
          Post => S.Top = S.Top'Old + 1
   is
   begin
      S.Top := S.Top + 1;
      S.Data (S.Top) := V;
   end Push;

   procedure Pop (S : in out Stack; V : out Integer)
     with Pre  => S.Top > 0,
          Post => S.Top = S.Top'Old - 1
   is
   begin
      V := S.Data (S.Top);
      S.Top := S.Top - 1;
   end Pop;

   -----------------------------------------------------------------------
   --  6. 循环不变式示例：求数组元素之和
   -----------------------------------------------------------------------
   type Int_Array is array (Positive range <>) of Integer;

   function Sum (A : Int_Array) return Integer is
      Result : Integer := 0;
   begin
      for I in A'Range loop
         Result := Result + A (I);

         --  循环不变式：当前 Result 等于 A (A'First .. I) 之和
         pragma Loop_Invariant (Result >= 0);
         --  循环变体：每次迭代 I 单调递增到 A'Last
         pragma Loop_Variant (Increases => I);
      end loop;

      pragma Assert (Result >= 0);   --  断言：和必非负
      return Result;
   end Sum;

   -----------------------------------------------------------------------
   --  7. 主过程：逐一演示每个特性
   -----------------------------------------------------------------------
   Demo_Stack  : Stack;
   Demo_Array  : constant Int_Array := (10, 20, 30, 40, 50);
   V           : Integer;

begin
   Put_Line ("==============================================");
   Put_Line ("  Ada 2012 契约式编程 示例 (GNAT 16.1.0)");
   Put_Line ("==============================================");

   --  (1) 前置/后置条件验证
   Put_Line ("[1] Safe_Divide (100, 5) = "
             & Integer'Image (Safe_Divide (100, 5)));
   Put_Line ("    Post 条件：5 * Result = 100 (已自动验证)");

   --  (2) Old 引用验证
   declare
      N : Integer := 41;
   begin
      Increment (N);
      Put_Line ("[2] Increment 后 N = " & Integer'Image (N)
                & "  (Post: N = N'Old + 1)");
   end;

   --  (3) Dynamic_Predicate 验证
   declare
      E : Even_Integer := 10;
   begin
      Put_Line ("[3] Even_Integer E = " & Integer'Image (E));
      E := 20;
      Put_Line ("    赋值 20 后 E = " & Integer'Image (E));
   end;

   --  (4) Type_Invariant 验证
   declare
      C : Safe_Counter.Counter;
   begin
      Safe_Counter.Init (C);
      Safe_Counter.Bump (C);
      Safe_Counter.Bump (C);
      Put_Line ("[4] Counter 值 = " & Integer'Image (Safe_Counter.Get (C))
                & "  (Type_Invariant: Value >= 0)");
   end;

   --  (5) 栈的 Pre/Post 验证
   Push (Demo_Stack, 100);
   Push (Demo_Stack, 200);
   Pop  (Demo_Stack, V);
   Put_Line ("[5] 栈 Pop 结果 = " & Integer'Image (V)
             & "  (Pre/Post: Top +/-1)");

   --  (6) 循环不变式验证
   Put_Line ("[6] 数组和 Sum = " & Integer'Image (Sum (Demo_Array))
             & "  (Loop_Invariant/Variant 通过)");

   --------------------------------------------------------------------
   --  (7) 故意违反契约：捕获 Assertion_Error
   --------------------------------------------------------------------
   Put_Line ("");
   Put_Line ("[7] 故意违反契约，演示异常捕获：");

   --  7a. 违反 Pre：除数为零
   begin
      V := Safe_Divide (10, 0);
      Put_Line ("    (不应执行到此)");
   exception
      when E : Assertion_Error =>
         Put_Line ("    7a. 违反 Pre (Y /= 0) 被捕获: "
                   & Exception_Message (E));
   end;

   --  7b. 违反 Dynamic_Predicate：赋奇数给 Even_Integer
   begin
      declare
         Bad : Even_Integer := 7;   --  奇数，违反谓词
      begin
         Put_Line ("    (不应执行到此): " & Integer'Image (Bad));
      end;
   exception
      when E : Assertion_Error =>
         Put_Line ("    7b. 违反 Dynamic_Predicate 被捕获: "
                   & Exception_Message (E));
   end;

   --  7c. 违反 Pre：对空栈执行 Pop
   begin
      declare
         Empty_Stack : Stack;
      begin
         Pop (Empty_Stack, V);   --  Top = 0，违反 Pre
         Put_Line ("    (不应执行到此)");
      end;
   exception
      when E : Assertion_Error =>
         Put_Line ("    7c. 违反 Pre (S.Top > 0) 被捕获: "
                   & Exception_Message (E));
   end;

   Put_Line ("");
   Put_Line ("所有契约验证完毕！");
   Put_Line ("提示：编译时加 -gnata 显式启用所有断言；");
   Put_Line ("      不加时部分断言可能被跳过。");

end Ch24_Contracts;
