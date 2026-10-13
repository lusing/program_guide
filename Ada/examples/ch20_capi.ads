-- ============================================================
-- 第20章附件：库级导出包
--   Export 只对库级单元有效——嵌套在主过程里的子程序
--   无法导出（其符号对 C 无意义）。本包独立编译，
--   把 Ada_Add 以 C 符号 ada_add 送进可执行文件。
-- ============================================================
package Ch20_Capi is

   function Ada_Add (A, B : Integer) return Integer
     with Export, Convention => C, External_Name => "ada_add";

end Ch20_Capi;
