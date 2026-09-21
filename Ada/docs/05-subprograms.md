# 05 · 子程序：过程与函数

> 示例：[`examples/ch05_subprograms.adb`](../examples/ch05_subprograms.adb)
> 运行：`./run-all.sh 05`

## 5.1 过程 (Procedure)

```ada
procedure Swap (A, B : in out Integer) is
   Temp : constant Integer := A;
begin
   A := B;
   B := Temp;
end Swap;
```

参数模式：
- `in` — 只读输入（默认）
- `out` — 只写输出
- `in out` — 读写

## 5.2 函数 (Function)

```ada
function Factorial (N : Natural) return Positive is
begin
   if N = 0 then return 1;
   else return N * Factorial (N - 1);
   end if;
end Factorial;
```

## 5.3 默认参数

```ada
function Add (X : Integer; Y : Integer := 10) return Integer is
begin
   return X + Y;
end Add;
```

## 5.4 嵌套子程序

```ada
procedure Outer is
   Inner_Count : Integer := 0;
   procedure Inner is
   begin
      Inner_Count := Inner_Count + 1;
   end Inner;
begin
   Inner;
   Inner;
end Outer;
```

## 5.5 命名参数

```ada
Print_Info (Name => "张三", Age => 25, City => "上海");
```

---
上一章：[04 控制结构](04-control.md) ｜ 下一章：[06 数组与字符串](06-arrays-strings.md) ｜ 返回：[README](../README.md)

