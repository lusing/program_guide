-- 子单位：嵌套包 Helpers 的体
-- 展示"包体也能拆成子单位"（老教材 MAIN/SETS 模式）
separate (Ch26_Separate)
package body Helpers is
   function Squared (X : Integer) return Integer is (X * X);
end Helpers;
