-- ============================================================
-- 第10章：包 (Package) —— 主程序
--   使用 Ch10_Math_Lib 的分数类型演示：
--   私有类型 / 延迟常量 / 运算符重载 / 异常接口 / 包体状态
-- ============================================================
with Ada.Text_IO;    use Ada.Text_IO;
with Ada.Exceptions;
with Ch10_Math_Lib; use Ch10_Math_Lib;

procedure Ch10_Packages is

   -- 分数的可读形式：Integer'Image 带前导空格，切掉
   function Img (N : Integer) return String is
      S : constant String := Integer'Image (N);
   begin
      if S (S'First) = ' ' then
         return S (S'First + 1 .. S'Last);
      else
         return S;
      end if;
   end Img;

   function Img (F : Fraction) return String is
     (Img (Numerator (F)) & "/" & Img (Denominator (F)));

begin
   Put_Line ("=== Ada 包 (Package)：分数运算 ===");
   New_Line;

   -- ---------------------------
   -- 1. 构造分数：自动约分与符号规范化
   -- ---------------------------
   Put_Line ("--- 1. 构造与约分 ---");
   declare
      F1 : constant Fraction := Make (1, 2);
      F2 : constant Fraction := Make (2, 4);     -- 约分 → 1/2
      F3 : constant Fraction := Make (2, -4);    -- 负分母规范化 → -1/2
   begin
      Put_Line ("  Make (1, 2)  = " & Img (F1));
      Put_Line ("  Make (2, 4)  = " & Img (F2) & "   （自动约分）");
      Put_Line ("  Make (2, -4) = " & Img (F3) & "  （负分母规范化）");
   end;

   -- ---------------------------
   -- 2. 四则运算：运算符重载保持数学写法
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. 四则运算 ---");
   declare
      A : constant Fraction := Make (1, 2);
      B : constant Fraction := Make (1, 3);
   begin
      Put_Line ("  1/2 + 1/3 = " & Img (A + B));
      Put_Line ("  1/2 - 1/3 = " & Img (A - B));
      Put_Line ("  1/2 * 1/3 = " & Img (A * B));
      Put_Line ("  1/2 / 1/3 = " & Img (A / B));
      Put_Line ("  Zero 是规范里的延迟常量：A + Zero = " & Img (A + Zero));
   end;

   -- ---------------------------
   -- 3. 异常是接口的一部分
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 异常接口 ---");
   begin
      Put_Line ("  准备用 1/2 除以 Zero ...");
      declare
         X : constant Fraction := Make (1, 2) / Zero;
      begin
         Put_Line ("  不应到达：" & Img (X));
      end;
   exception
      when E : Zero_Denominator =>
         Put_Line ("  捕获 Zero_Denominator："
                   & Ada.Exceptions.Exception_Message (E));
   end;

   -- ---------------------------
   -- 4. 包体状态：外部只能通过公开函数读
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. 包体状态 ---");
   Put_Line ("  Op_Count（含 1 次失败的除法）="
             & Integer'Image (Op_Count));
   Put_Line ("  Operations 变量本身在包体里，外部不可见。");

   -- ---------------------------
   -- 5. 命名数字 Pi：任何数值类型直接可用
   -- ---------------------------
   New_Line;
   Put_Line ("--- 5. 命名数字 ---");
   Put_Line ("  Pi (Float)      = " & Float'Image (Pi));
   Put_Line ("  Pi * 2 (实数字面量可直接乘) = " & Float'Image (2.0 * Pi));
end Ch10_Packages;
