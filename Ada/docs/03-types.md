# 03 · 基本数据类型与变量

> 示例：[`examples/ch03_types.adb`](../examples/ch03_types.adb)
> 运行：`./run-all.sh 03`

## 3.1 整型

```ada
A : Integer := 42;
B : Natural := 100;          -- 非负整数 (0 .. 2^31-1)
C : Positive := 1;           -- 正整数 (1 .. 2^31-1)

-- 自定义整型范围
type Age is range 0 .. 150;
My_Age : Age := 30;
```

## 3.2 浮点型

```ada
Pi : Float := 3.14159;
D : Long_Float := 2.718281828;
```

## 3.3 布尔型与字符型

```ada
Flag : Boolean := True;
Ch : Character := 'A';
```

## 3.4 枚举类型

```ada
type Color is (Red, Green, Blue);
My_Color : Color := Green;
```

## 3.5 子类型（带约束）

```ada
subtype Small_Int is Integer range -100 .. 100;
S : Small_Int := 50;
```

## 3.6 常量

```ada
Max_Value : constant Integer := 999;
```

---
上一章：[02 Hello World](02-hello.md) ｜ 下一章：[04 控制结构](04-control.md) ｜ 返回：[README](../README.md)

