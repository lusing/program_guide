-- ============================================================
-- 第10章：包 (Package) —— 包规范 (Specification)
--   演示：可见部分 / 私有部分 / 私有类型 /
--        延迟常量 / 运算符重载 / 异常作为接口的一部分
-- ============================================================
package Ch10_Math_Lib is

   -- 命名数字：无类型常量，任何数值类型均可采用
   Pi : constant := 3.14159_26535;

   -- 私有类型：外面只知道"有这个类型"，不知道它的结构
   type Fraction is private;

   -- 延迟常量：常量名现在可见，值推迟到私有部分给出
   Zero : constant Fraction;

   -- 构造与观察
   function Make (Num : Integer; Den : Integer) return Fraction;
   function Numerator   (X : Fraction) return Integer;
   function Denominator (X : Fraction) return Positive;

   -- 分数四则：运算符重载让分数运算保持数学写法
   function "+" (X, Y : Fraction) return Fraction;
   function "-" (X, Y : Fraction) return Fraction;
   function "*" (X, Y : Fraction) return Fraction;
   function "/" (X, Y : Fraction) return Fraction;

   -- 包接口的一部分：调用方要能捕获的异常在规范中声明
   Zero_Denominator : exception;

   -- 包体状态：统计已执行的运算次数
   function Op_Count return Natural;

private
   -- 私有部分：Fraction 的完整定义——包外不可见，包内（规范与体）可用
   type Fraction is
      record
         Num : Integer;    -- 分子（可负）
         Den : Positive;   -- 分母（化简后恒为正）
      end record;

   Zero : constant Fraction := (Num => 0, Den => 1);

end Ch10_Math_Lib;
