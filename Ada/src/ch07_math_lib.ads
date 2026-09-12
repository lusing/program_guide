-- ============================================================
-- 第7章：包 (Package) —— 模块化编程
-- 包规范 (Specification)
-- ============================================================
package Ch07_Math_Lib is

   -- 常量
   Pi : constant Float := 3.14159265;

   -- 类型
   type Vector is array (1 .. 3) of Float;

   -- 函数声明
   function Add_Vectors (A, B : Vector) return Vector;
   function Dot_Product (A, B : Vector) return Float;
   function Magnitude (V : Vector) return Float;

   -- 过程声明
   procedure Print_Vector (Label : String; V : Vector);

end Ch07_Math_Lib;