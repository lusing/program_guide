-- 子库单元：Ch26_Support.Stats
-- 文件名 = 父名 + "-" + 子名；看得见父包规范的 Int_Array。
-- 主程序 with 本单元即隐式 with 祖先 Ch26_Support（ARM 规则）。
package Ch26_Support.Stats is
   function Average (A : Int_Array) return Integer;   -- 截断平均
   function Max_Of (A : Int_Array) return Integer;
end Ch26_Support.Stats;
