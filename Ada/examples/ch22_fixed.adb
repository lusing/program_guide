-- ============================================================
-- 第22章：定点与十进制实数
-- 普通定点 / 十进制定点 / 通用定点、定点乘除的显式重定刻度、
-- 案例：三阶切比雪夫数字滤波器的定点实现（何诚 §16.5）
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure Ch22_Fixed is

   -- --------------------------------------------------------
   -- 22.2 普通定点：delta 是"绝对精度"的承诺
   -- --------------------------------------------------------
   type Volts is delta 0.25 range -100.0 .. 100.0;   -- 2 的幂刻度

   -- --------------------------------------------------------
   -- 22.3 十进制定点：delta 是 10 的幂（钱的最爱）
   -- --------------------------------------------------------
   type Money is delta 0.01 digits 8;                -- 0.01 精度，8 位数字

   -- --------------------------------------------------------
   -- 22.4 通用定点：跨类型乘除的"双倍长中转站"
   -- --------------------------------------------------------
   type Ohms      is delta 0.5 range 0.0 .. 1000.0;
   type Milliamps is delta 0.5 range 0.0 .. 5000.0;

   -- --------------------------------------------------------
   -- 22.5 案例：三阶切比雪夫低通滤波器（何诚原题）
   --   y(n) = C1*(x(n) + 3x(n-1) + 3x(n-2) + x(n-3))
   --          + C2a*y(n-1) - C2b*y(n-2) + C2c*y(n-3)
   -- --------------------------------------------------------
   type Xfix is delta 1.0        range -16384.0 .. 16383.0;  -- 输入样值
   type Yfix is delta 2#1.0#E-4  range -2048.0 .. 2047.0;    -- 输出：16 位内最精
   type Zfix is delta 2#1.0#E-17 range -8192.0 .. 8191.0;    -- 双倍长中间量
   type C1fix is delta 0.000001  range 0.0 .. 0.02;          -- 前馈系数
   type C2fix is delta 0.0001    range 0.0 .. 20.0;          -- 反馈系数

   C1  : constant C1fix := 0.011956;
   C2a : constant C2fix := 1.9749;
   C2b : constant C2fix := 1.5243;
   C2c : constant C2fix := 0.4538;

   package Y_IO is new Ada.Text_IO.Fixed_IO (Yfix);
   package V_IO is new Ada.Text_IO.Fixed_IO (Volts);

begin
   Put_Line ("=== Ada 定点与十进制实数示例 ===");
   New_Line;

   -- 1. 浮点精度回顾：digits 约束与模型属性
   Put_Line ("--- 1. 浮点精度回顾 ---");
   Put_Line ("  Float'Digits        = "
             & Integer'Image (Float'Digits) & " 位十进制有效数字");
   Put_Line ("  Long_Float'Digits   = "
             & Integer'Image (Long_Float'Digits) & " 位");
   Put_Line ("  Float'Machine_Mantissa = "
             & Integer'Image (Float'Machine_Mantissa) & " 位尾数(二进制)");
   declare
      F1 : Long_Float := 0.1;
      F2 : Long_Float := 0.2;
      F3 : Long_Float := 0.3;
   begin
      Put_Line ("  Long_Float: 0.1 + 0.2 = 0.3 ?  "
                & Boolean'Image (F1 + F2 = F3)
                & "   （二进制存不准 0.1）");
      Put ("  实际值: " & Long_Float'Image (F1 + F2));
      Put_Line ("  vs  " & Long_Float'Image (F3));
   end;

   -- 2. 普通定点：绝对精度 + 可判等
   New_Line;
   Put_Line ("--- 2. 普通定点（delta 0.25） ---");
   Put_Line ("  Volts'Delta = " & Float'Image (Volts'Delta)
             & "（请求的精度）");
   Put_Line ("  Volts'Small = " & Float'Image (Volts'Small)
             & "（实际刻度 = 2 的幂）");
   Put_Line ("  Volts'Size  = " & Integer'Image (Volts'Size) & " 位");
   declare
      A : Volts := 1.25;                 -- 恰好可精确表示
      B : Volts := 0.5;
   begin
      Put ("  1.25 + 0.5 = ");
      V_IO.Put (A + B, Fore => 4, Aft => 2, Exp => 0);
      Put_Line (" —— 可精确判等: "
                & Boolean'Image (A + B = 1.75));
      A := A + 0.1;                      -- 0.1 不在刻度上 -> 舍入到 0.25 的倍数
      Put ("  1.25 + 0.1  => ");
      V_IO.Put (A, Fore => 4, Aft => 2, Exp => 0);
      Put_Line ("   （0.1 被舍入到最近刻度）");
   end;

   -- 3. 十进制定点：钱永远算得准
   New_Line;
   Put_Line ("--- 3. 十进制定点（delta 0.01 digits 8） ---");
   declare
      Price : Money := 0.10;
      Tax   : Money := 0.20;
      Total : Money := 0.30;
   begin
      Put_Line ("  0.10 + 0.20 = 0.30 ?  "
                & Boolean'Image (Price + Tax = Total)
                & "   （十进制刻度，精确）");
      Put_Line ("  Money'Small = " & Float'Image (Money'Small)
                & "（= 0.01，10 的幂）");
      -- 分账：三分摊 1.00 元
      declare
         Sum    : Money := 1.00;
         Split  : constant Money := 0.33;
         Remain : constant Money := Sum - 3 * Split;
      begin
         Put_Line ("  3 x 0.33 摊 1.00，余" & Money'Image (Remain)
                   & " 元 —— 精确可追溯");
      end;
   end;

   -- 4. 通用定点：乘除必须显式重定刻度
   New_Line;
   Put_Line ("--- 4. 通用定点与单位常量 ---");
   declare
      V   : Volts     := 5.0;
      R   : Ohms      := 2.5;
      Amp : constant Milliamps := 1000.0;   -- 单位常量：1 安培 = 1000 毫安
      I   : Milliamps;
   begin
      -- V / R -> 通用定点（双倍长、精度任意好），
      -- 必须显式转换成具体类型才能落地（= 重定刻度）。
      -- 再乘单位常量换算单位：F * F 仍是通用定点，再转一次。
      -- 注意：1000.0 这样的实数字面量不能与定点直接相乘——
      -- 比例因子必须做成"定型的单位常量"（老教材惯用法）。
      I := Milliamps (Milliamps (V / R) * Amp);
      Put ("  5.0V / 2.5 欧姆 = ");
      declare
         package MA_IO is new Ada.Text_IO.Fixed_IO (Milliamps);
      begin
         MA_IO.Put (I, Fore => 5, Aft => 1, Exp => 0);
      end;
      Put_Line (" mA");
      Put_Line ("  （V/R、F*F 都是通用定点；每一步落地都要类型转换）");
   end;

   -- 5. 案例：数字滤波器定点实现（激励 = 幅度 1000 的冲激）
   New_Line;
   Put_Line ("--- 5. 三阶切比雪夫滤波器（定点冲激响应） ---");
   declare
      Xn, Xn1, Xn2, Xn3 : Xfix := 0.0;
      Yn, Yn1, Yn2, Yn3 : Yfix := 0.0;
      Z                 : Zfix;

      -- 输入信号：n=0 时幅度 1000，之后为 0（冲激）
      type Sample_Array is array (0 .. 11) of Integer;
      Samples : constant Sample_Array :=
                  (0 => 1000, others => 0);
   begin
      Put_Line ("  n      x(n)      y(n)（前 12 拍，全定点运算）");
      for N in Samples'Range loop
         Xn := Xfix (Samples (N));
         -- 前馈：C1 * (x(n) + 3*(x(n-1)+x(n-2)) + x(n-3))
         Z := Zfix (C1 * (Xn + 3 * (Xn1 + Xn2) + Xn3));
         -- 反馈：+ C2a*y(n-1) - C2b*y(n-2) + C2c*y(n-3)
         Yn := Yfix (Z + Zfix (C2a * Yn1)
                        - Zfix (C2b * Yn2)
                        + Zfix (C2c * Yn3));
         -- 移位历史
         Xn3 := Xn2; Xn2 := Xn1; Xn1 := Xn;
         Yn3 := Yn2; Yn2 := Yn1; Yn1 := Yn;

         Put (" " & Integer'Image (N));
         Put (Samples (N), Width => 9);
         Put ("  ");
         Y_IO.Put (Yn, Fore => 6, Aft => 4, Exp => 0);
         New_Line;
      end loop;
      Put_Line ("  （Yfix delta=2#1.0#E-4 即 1/16：16 位里能给的");
      Put_Line ("   最大精度；中间量 Zfix 双倍长保精度——类型即文档）");
   end;
end Ch22_Fixed;
