-- 子单位：Report 的体
-- 文件名规则：父单元名 + "-" + 单元名（GNAT 约定）
-- 可见性 = 存根处的可见性（父单元 with/use 过的这里直接用）
separate (Ch26_Separate)
procedure Report (Title : String; Data : Ch26_Support.Int_Array) is
begin
   Put_Line ("  [Report 子单位] " & Title);
   for V of Data loop
      Put (Integer'Image (V * V));
   end loop;
   New_Line;
end Report;
