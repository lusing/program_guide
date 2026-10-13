-- ============================================================
-- 第20章：与 C 语言互操作
--   —— Import 导入函数 / Export 导出 / Interfaces.C 类型 /
--      字符串互操作 (chars_ptr + strlen 实测)
--      （老教材 §10.4 编用 INTERFACE 的现代形态）
-- ============================================================
with Ada.Text_IO;     use Ada.Text_IO;
with Interfaces.C;
with Interfaces.C.Strings;
with Ch20_Capi;

procedure Ch20_C_Interop is

   -- ---------------------------
   -- 1. 导入 C 函数：aspect 形式（现代写法）
   --    等价的老式写法：pragma Import (C, C_Sqrt, "sqrtf");
   -- ---------------------------
   function C_Sqrt (X : Float) return Float
     with Import, Convention => C, External_Name => "sqrtf";

   function C_Abs (X : Integer) return Integer
     with Import, Convention => C, External_Name => "abs";

   -- 导入 C 的 strlen：演示真正的字符串级互操作
   function C_Strlen (S : Interfaces.C.Strings.chars_ptr)
      return Interfaces.C.size_t
     with Import, Convention => C, External_Name => "strlen";

   -- 导出 Ada 函数的完整实现在支撑包 Ch20_Capi 里：
   -- Export 只对库级单元有效，主过程内嵌套的子程序导不出。

   -- ---------------------------
   -- 4. C 兼容类型：自己定义（尺寸受检）
   -- ---------------------------
   type C_Int is range -(2 ** 31) .. (2 ** 31 - 1)
      with Size => 32;

   type C_Point is record
      X : C_Int;
      Y : C_Int;
   end record
      with Convention => C;

begin
   Put_Line ("=== Ada 与 C 互操作 ===");
   New_Line;

   -- ---------------------------
   -- 1. 调 C 标准库函数
   -- ---------------------------
   Put_Line ("--- 1. 导入 C 函数 ---");
   Put_Line ("  C_Sqrt (16.0) = " & Float'Image (C_Sqrt (16.0)));
   Put_Line ("  C_Abs (-42)   = " & Integer'Image (C_Abs (-42)));

   -- ---------------------------
   -- 2. 字符串互操作：To_C / chars_ptr / strlen
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. 字符串互操作 ---");
   declare
      use Interfaces.C.Strings;

      -- Ada 字符串 → C char 数组（自动加 NUL 终止符）
      Buf     : Interfaces.C.char_array := Interfaces.C.To_C ("Hello, C!");
      -- char 数组 → C 指针（chars_ptr），可以传给任何吃 char* 的函数
      C_Str   : constant chars_ptr := New_Char_Array (Buf);
      Len     : constant Interfaces.C.size_t := C_Strlen (C_Str);
      -- C 指针 → 回 Ada 字符串
      Back    : constant String := Value (C_Str);
   begin
      Put_Line ("  Ada 串 ""Hello, C!"" 交给 strlen → 长度 = "
                & Interfaces.C.size_t'Image (Len));
      Put_Line ("  chars_ptr 再转回 Ada 串 → """ & Back & """");
   end;

   -- ---------------------------
   -- 3. 导出的函数
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 导出函数 ---");
   Put_Line ("  Ch20_Capi.Ada_Add (2, 3) = " & Integer'Image (Ch20_Capi.Ada_Add (2, 3)));
   Put_Line ("  Ada_Add 以符号 ada_add 进入可执行文件符号表");
   Put_Line ("  链接 C 代码时直接 extern int ada_add(int, int); 即可调用。");

   -- ---------------------------
   -- 4. C 兼容类型与尺寸验证
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. C 兼容类型 ---");
   declare
      P : C_Point := (X => 10, Y => 20);
   begin
      Put_Line ("  C_Point: X =" & C_Int'Image (P.X) & ", Y =" & C_Int'Image (P.Y));
      Put_Line ("  C_Point'Size = " & Integer'Image (C_Point'Size) & " bits"
                & "（与 C 的 struct point {int32_t x, y;} 一致）");
      Put_Line ("  Interfaces.C 还提供现成的 int/long/size_t/double 等。");
   end;
end Ch20_C_Interop;
