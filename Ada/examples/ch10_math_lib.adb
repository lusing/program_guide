-- ============================================================
-- 第10章：包 (Package) —— 包体 (Body)
--   演示：包体私有子程序 (GCD/Reduce) / 包体状态 /
--        包体加工语句 (begin 后的初始化段)
-- ============================================================
package body Ch10_Math_Lib is

   -- 包体状态：只在包内可见，外部只能通过 Op_Count 读
   Operations : Natural := 0;

   -- 欧几里得算法求最大公约数（老教材 FRACTION_PACKAGE 的私有子程序）
   function GCD (A : Natural; B : Positive) return Positive is
      X : Natural  := A;
      Y : Positive := B;
      Old_Y : Positive;
   begin
      while X /= 0 loop
         Old_Y := Y;
         Y := X;
         X := Old_Y mod X;
      end loop;
      return Y;
   end GCD;

   -- 约分：分子分母同除以最大公约数（私有过程，外部无法调用）
   procedure Reduce (F : in out Fraction) is
      G : constant Positive := GCD (abs F.Num, F.Den);
   begin
      F.Num := F.Num / G;
      F.Den := F.Den / G;
   end Reduce;

   -- 构造：负分母一律规范化（2/-4 → -1/2）
   function Make (Num : Integer; Den : Integer) return Fraction is
      F : Fraction;
   begin
      Operations := Operations + 1;
      if Den = 0 then
         raise Zero_Denominator with "分母不能为零";
      end if;
      if Den > 0 then
         F := (Num => Num, Den => Den);
      else
         F := (Num => -Num, Den => -Den);
      end if;
      Reduce (F);
      return F;
   end Make;

   function Numerator (X : Fraction) return Integer is (X.Num);
   function Denominator (X : Fraction) return Positive is (X.Den);

   function "+" (X, Y : Fraction) return Fraction is
      R : Fraction;
   begin
      Operations := Operations + 1;
      R.Num := X.Num * Y.Den + Y.Num * X.Den;
      R.Den := X.Den * Y.Den;
      Reduce (R);
      return R;
   end "+";

   function "-" (X, Y : Fraction) return Fraction is
      R : Fraction;
   begin
      Operations := Operations + 1;
      R.Num := X.Num * Y.Den - Y.Num * X.Den;
      R.Den := X.Den * Y.Den;
      Reduce (R);
      return R;
   end "-";

   function "*" (X, Y : Fraction) return Fraction is
      R : Fraction;
   begin
      Operations := Operations + 1;
      R.Num := X.Num * Y.Num;
      R.Den := X.Den * Y.Den;
      Reduce (R);
      return R;
   end "*";

   function "/" (X, Y : Fraction) return Fraction is
      R : Fraction;
   begin
      Operations := Operations + 1;
      if Y.Num = 0 then
         raise Zero_Denominator with "除以零分数";
      end if;
      R.Num := X.Num * Y.Den;
      R.Den := X.Den * Y.Num;
      if R.Den < 0 then              -- 结果分母为负：分子分母同时变号
         R.Num := -R.Num;
         R.Den := -R.Den;
      end if;
      Reduce (R);
      return R;
   end "/";

   function Op_Count return Natural is (Operations);

begin
   -- 包体加工语句：包第一次被使用时执行一次（初始化段）
   Operations := 0;
end Ch10_Math_Lib;
