# 07 · 记录类型

> 示例：[`examples/ch07_records.adb`](../examples/ch07_records.adb)
> 运行：`./run-all.sh 07`

## 7.1 简单记录

```ada
type Person is record
   Name : String (1 .. 20);
   Age  : Integer;
end record;
```

## 7.2 带默认值的记录

```ada
type Point is record
   X, Y : Float := 0.0;
end record;
```

## 7.3 变体记录（带判别式）

```ada
type Shape_Kind is (Circle, Rectangle);
type Shape (Kind : Shape_Kind) is record
   case Kind is
      when Circle    => Radius : Float;
      when Rectangle => Width, Height : Float;
   end case;
end record;
```

## 7.4 空记录

```ada
type Null_Record is null record;
```

## 7.5 记录嵌套

```ada
type Address is record
   Street : String (1 .. 30);
   City   : String (1 .. 12);
end record;

type Employee is record
   Name   : String (1 .. 12);
   Age    : Integer;
   Addr   : Address;
   Salary : Float;
end record;
```

---
上一章：[06 数组与字符串](06-arrays-strings.md) ｜ 下一章：[08 包](08-packages.md) ｜ 返回：[README](../README.md)

