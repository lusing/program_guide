# 12 · 泛型编程

> 示例：[`examples/ch12_generics.adb`](../examples/ch12_generics.adb)
> 运行：`./run-all.sh 10`

## 12.1 泛型过程

```ada
generic
   type Element_Type is private;
procedure Swap (A, B : in out Element_Type);

-- 实例化
procedure Swap_Int is new Swap (Element_Type => Integer);
```

## 12.2 泛型函数

```ada
generic
   type T is (<>);  -- 离散类型
function Max (A, B : T) return T;

-- 实例化
function Max_Int is new Max (T => Integer);
```

## 12.3 泛型包

```ada
generic
   type Item_Type is private;
   Max_Size : Positive;
package Generic_Stack is
   procedure Push (Item : Item_Type);
   function Pop return Item_Type;
   function Is_Empty return Boolean;
   Stack_Overflow : exception;
   Stack_Underflow : exception;
end Generic_Stack;

-- 实例化
package Int_Stack is new Generic_Stack (Item_Type => Integer, Max_Size => 10);
```

---
上一章：[11 异常](11-exceptions.md) ｜ 下一章：[13 泛型进阶](13-generics-deep.md) ｜ 返回：[README](../README.md)

