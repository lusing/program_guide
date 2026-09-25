-- 层级库的"父包"：共享类型放在这里，子单元挂在它的规范上
-- （子库单元看得见的是父包【规范】里的声明——这正是层级库的意义）
package Ch26_Support is
   type Int_Array is array (Positive range <>) of Integer;
end Ch26_Support;
