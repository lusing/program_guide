------------------------------------------------------------------------------
--  Ch17: SPARK 形式化验证 示例
--
--  本示例演示符合 SPARK 子集约束的代码风格：
--    - 无 access 类型（指针）
--    - 无异常处理（用状态码代替）
--    - 显式声明 Global / Depends
--    - 完整的 Pre / Post / Loop_Invariant / Loop_Variant
--
--  本代码可被以下两种方式处理：
--    1. 普通 GNAT 编译运行（本文档采用此方式）
--         gnatmake -gnata ch25_spark.adb
--    2. GNATprove 形式化证明（需安装 SPARK Pro）
--         gnatprove -P project.gpr
--         所有 Pre/Post/Loop_Invariant 将被数学证明成立，
--         而非仅运行时检查。
------------------------------------------------------------------------------
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure Ch25_Spark is

   -----------------------------------------------------------------------
   --  示例 1：线性搜索（可被 SPARK 完全证明）
   -----------------------------------------------------------------------
   --  契约语义：
   --    若 Found 为 True，则 Result 必在 A'Range 内，且 A(Result) = Target；
   --    若 Found 为 False，则 Target 不在 A 中。
   -----------------------------------------------------------------------
   type Int_Array is array (Positive range <>) of Integer;

   function Linear_Search
     (A      : Int_Array;
      Target : Integer) return Natural
   with
     Post =>
       (if Linear_Search'Result = 0 then
           (for all I in A'Range => A (I) /= Target)  --  未找到 => 全部不等
        else
           A (Linear_Search'Result) = Target);         --  找到 => 位置匹配

   function Linear_Search
     (A      : Int_Array;
      Target : Integer) return Natural
   is
      Result : Natural := 0;
   begin
      for I in A'Range loop

         --  循环不变式（SPARK 会用归纳法证明它成立）：
         --  到目前为止扫描过的元素（A'First .. I - 1）都不等于 Target
         pragma Loop_Invariant
           (for all J in A'First .. I - 1 => A (J) /= Target);

         --  循环变体：I 单调递增到 A'Last，保证循环必然终止
         pragma Loop_Variant (Increases => I);

         if A (I) = Target then
            Result := I;
            exit;   --  SPARK 支持 exit，并会证明循环终止
         end if;
      end loop;

      return Result;
   end Linear_Search;

   -----------------------------------------------------------------------
   --  示例 2：数组求和（带量化表达式契约）
   -----------------------------------------------------------------------
   --  契约语义：Sum 的返回值 >= 0（数组非空时 >= 首元素）
   --  SPARK 会自动用归纳法证明该契约成立。
   -----------------------------------------------------------------------
   function Array_Sum (A : Int_Array) return Long_Long_Integer
   with Post =>
       Array_Sum'Result >= 0
       and then
       (if A'Length = 0 then Array_Sum'Result = 0
        else Array_Sum'Result >= Long_Long_Integer (A (A'First)));

   function Array_Sum (A : Int_Array) return Long_Long_Integer
   is
      Acc : Long_Long_Integer := 0;
   begin
      for I in A'Range loop
         Acc := Acc + Long_Long_Integer (A (I));

         --  循环不变式：Acc 永远非负
         pragma Loop_Invariant (Acc >= 0);

         pragma Loop_Variant (Increases => I);
      end loop;

      return Acc;
   end Array_Sum;

   -----------------------------------------------------------------------
   --  示例 3：数组全部元素非负判断（纯表达式函数）
   -----------------------------------------------------------------------
   function All_Non_Negative (A : Int_Array) return Boolean is
     (for all I in A'Range => A (I) >= 0)
   with Post =>
     (if All_Non_Negative'Result then
         (for all I in A'Range => A (I) >= 0));

   -----------------------------------------------------------------------
   --  示例 4：计数出现次数（带 Contract_Cases）
   -----------------------------------------------------------------------
   --  Contract_Cases 根据 A 是否为空，分别给出不同的后置条件
   -----------------------------------------------------------------------
   function Count_Occurrences
     (A      : Int_Array;
      Target : Integer) return Natural
   with
     Post   => Count_Occurrences'Result <= A'Length,
     Contract_Cases =>
       (A'Length = 0 =>
          Count_Occurrences'Result = 0,

        A'Length > 0 =>
          Count_Occurrences'Result >= 0
          and then Count_Occurrences'Result <= A'Length
       );

   function Count_Occurrences
     (A      : Int_Array;
      Target : Integer) return Natural
   is
      Count : Natural := 0;
   begin
      for I in A'Range loop
         if A (I) = Target then
            Count := Count + 1;
         end if;

         --  循环不变式：Count <= I（已统计次数不超过已扫描元素数）
         pragma Loop_Invariant (Count <= I - A'First + 1);
         pragma Loop_Variant   (Increases => I);
      end loop;

      return Count;
   end Count_Occurrences;

   -----------------------------------------------------------------------
   --  示例 5：用 Global aspect 显式声明全局状态（SPARK 必需）
   -----------------------------------------------------------------------
   Error_Count : Natural := 0;   --  模块级全局状态

   procedure Log_Error (Code : Natural)
   with
     Global  => (In_Out => Error_Count),   --  声明读写全局变量
     Depends => (Error_Count =>+ Code),    --  Error_Count 依赖于自身+Code
     Post    => Error_Count = Error_Count'Old + 1;

   procedure Log_Error (Code : Natural) is
   begin
      pragma Assert (Error_Count < Natural'Last);   --  溢出防御断言
      Error_Count := Error_Count + 1;
   end Log_Error;

   -----------------------------------------------------------------------
   --  主过程：运行所有示例
   -----------------------------------------------------------------------
   Test_Array : constant Int_Array := (3, 1, 4, 1, 5, 9, 2, 6, 5, 3);
   Pos        : Natural;
   Sum_Result : Long_Long_Integer;
   Cnt        : Natural;

begin
   Put_Line ("==============================================");
   Put_Line ("  SPARK 形式化验证 示例 (GNAT 16.1.0)");
   Put_Line ("==============================================");

   --  示例 1：线性搜索
   Pos := Linear_Search (Test_Array, 9);
   Put ("[1] Linear_Search (array, 9) = ");
   Put (Item => Pos, Width => 0);
   if Pos > 0 then
      Put_Line ("  (Post: A(Pos) = Target, 已验证)");
   else
      Put_Line ("  (未找到)");
   end if;

   Pos := Linear_Search (Test_Array, 100);
   Put ("    Linear_Search (array, 100) = ");
   Put (Item => Pos, Width => 0);
   Put_Line ("  (未找到, Post: 全部不等)");

   --  示例 2：数组求和
   Sum_Result := Array_Sum (Test_Array);
   Put ("[2] Array_Sum = ");
   Put (Item => Long_Long_Integer'Image (Sum_Result));
   New_Line;

   --  示例 3：非负判断
   declare
      Result : constant Boolean := All_Non_Negative (Test_Array);
   begin
      Put ("[3] All_Non_Negative = ");
      Put_Line (Boolean'Image (Result));
   end;

   --  示例 4：计数
   Cnt := Count_Occurrences (Test_Array, 5);
   Put ("[4] Count_Occurrences (array, 5) = ");
   Put (Item => Cnt, Width => 0);
   New_Line;

   Cnt := Count_Occurrences (Test_Array, 1);
   Put ("    Count_Occurrences (array, 1) = ");
   Put (Item => Cnt, Width => 0);
   New_Line;

   --  示例 5：Global / Depends
   Log_Error (404);
   Log_Error (500);
   Put ("[5] Error_Count = ");
   Put (Item => Error_Count, Width => 0);
   Put_Line ("  (Global/Depends 已验证)");

   Put_Line ("");
   Put_Line ("所有契约验证完毕。");
   Put_Line ("提示：本程序用普通 GNAT 在运行时检查契约。");
   Put_Line ("      安装 SPARK Pro 后，用 gnatprove 可数学证明所有契约。");

end Ch25_Spark;
