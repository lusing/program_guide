# 06 · 数组与字符串

> 示例：[`examples/ch06_arrays.adb`](../examples/ch06_arrays.adb)
> 运行：`./run-all.sh 06`

## 6.1 约束数组

```ada
type Int_Array is array (1 .. 5) of Integer;
A : Int_Array := (10, 20, 30, 40, 50);
```

## 6.2 无约束数组

```ada
type Vector is array (Positive range <>) of Float;
V1 : Vector (1 .. 3) := (1.0, 2.0, 3.0);
```

## 6.3 多维数组

```ada
type Matrix is array (1 .. 3, 1 .. 3) of Integer;
M : Matrix := ((1, 2, 3), (4, 5, 6), (7, 8, 9));
```

## 6.4 属性查询

```ada
A'First   -- 第一个索引
A'Last    -- 最后一个索引
A'Length  -- 元素个数
A'Range   -- 索引范围
```

## 6.5 字符串

```ada
S1 : String (1 .. 12) := "Hello, World";
S2 : String := "Ada编程";
S3 : constant String := "Hello" & " " & "Ada";  -- 拼接
S1 (1 .. 5)  -- 切片: "Hello"
```

## 6.6 有界字符串

```ada
package BS is new Ada.Strings.Bounded.Generic_Bounded_Length (Max => 64);
B : Bounded_String := To_Bounded_String ("Hello");
B := B & To_Bounded_String (" Ada!");  -- 拼接
```

---
上一章：[05 子程序](05-subprograms.md) ｜ 下一章：[07 记录](07-records.md) ｜ 返回：[README](../README.md)

