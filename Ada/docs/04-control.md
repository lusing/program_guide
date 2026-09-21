# 04 · 控制结构

> 示例：[`examples/ch04_control.adb`](../examples/ch04_control.adb)
> 运行：`./run-all.sh 04`

## 4.1 if-then-elsif-else

```ada
if X > Y then
   Put_Line ("X 大于 Y");
elsif X = Y then
   Put_Line ("X 等于 Y");
else
   Put_Line ("X 小于 Y");
end if;
```

## 4.2 case 语句

```ada
case Grade is
   when 'A' => Put_Line ("优秀");
   when 'B' => Put_Line ("良好");
   when 'C' => Put_Line ("中等");
   when others => Put_Line ("其他");
end case;
```

## 4.3 for 循环

```ada
-- 正序
for I in 1 .. 5 loop
   Put (I, Width => 0);
end loop;

-- 逆序
for I in reverse 1 .. 5 loop
   Put (I, Width => 0);
end loop;
```

## 4.4 while 循环

```ada
while Counter > 0 loop
   Counter := Counter - 1;
end loop;
```

## 4.5 无限循环 + exit

```ada
loop
   exit when N >= 5;
   N := N + 1;
end loop;
```

---
上一章：[03 类型](03-types.md) ｜ 下一章：[05 子程序](05-subprograms.md) ｜ 返回：[README](../README.md)

