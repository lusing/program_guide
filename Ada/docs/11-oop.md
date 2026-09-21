# 11 · 面向对象编程

> 示例：[`examples/ch11_oop.adb`](../examples/ch11_oop.adb)
> 运行：`./run-all.sh 11`

## 11.1 基类 (Tagged Type)

```ada
type Shape is tagged record
   Name : String (1 .. 20) := (others => ' ');
end record;

function Area (S : Shape) return Float is (0.0);
procedure Print (S : Shape);
```

## 11.2 派生类

```ada
type Circle is new Shape with record
   Radius : Float := 0.0;
end record;

overriding function Area (C : Circle) return Float;
overriding procedure Print (C : Circle);
```

## 11.3 多态分发 (Dynamic Dispatch)

```ada
-- Class-wide 类型参数实现动态分发
procedure Print_Shape_Info (S : Shape'Class) is
begin
   Print (S);  -- dispatching call
end Print_Shape_Info;
```

## 11.4 关键概念

| 关键字 | 说明 |
|--------|------|
| `tagged record` | 标记记录，支持继承和多态 |
| `overriding` | 显式覆盖父类方法 |
| `Shape'Class` | 类范围类型，包含 Shape 及其所有派生类 |

---
上一章：[10 泛型](10-generics.md) ｜ 下一章：[12 Tasking](12-tasking.md) ｜ 返回：[README](../README.md)

