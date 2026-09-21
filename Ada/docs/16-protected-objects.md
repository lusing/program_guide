# 16 · 受保护对象

> 示例：[`examples/ch16_protected.adb`](../examples/ch16_protected.adb)
> 运行：`./run-all.sh 16`

## 16.1 线程安全的计数器

```ada
protected type Safe_Counter is
   procedure Increment;
   function Value return Integer;
private
   Count : Integer := 0;
end Safe_Counter;

protected body Safe_Counter is
   procedure Increment is
   begin
      Count := Count + 1;
   end Increment;
   function Value return Integer is (Count);
end Safe_Counter;
```

## 16.2 有界缓冲区（带守卫）

```ada
protected type Bounded_Buffer (Size : Positive) is
   entry Put (Item : Integer);
   entry Get (Item : out Integer);
private
   Data  : Buffer_Array;
   Count : Natural := 0;
end Bounded_Buffer;

protected body Bounded_Buffer is
   entry Put (Item : Integer) when Count < Size is
   begin
      Data (Tail) := Item;
      Count := Count + 1;
   end Put;

   entry Get (Item : out Integer) when Count > 0 is
   begin
      Item := Data (Head);
      Count := Count - 1;
   end Get;
end Bounded_Buffer;
```

## 16.3 关键概念

| 概念 | 说明 |
|------|------|
| `protected` | 受保护类型，提供互斥访问 |
| `entry` | 受保护入口，带守卫条件 |
| `when` 守卫 | 只有条件为真时 entry 才可用 |
| `function` (protected) | 只读，允许多个并发读取 |
| `procedure` (protected) | 读写，独占访问 |

---
上一章：[15 容器](15-containers.md) ｜ 下一章：[17 契约](17-contracts.md) ｜ 返回：[README](../README.md)

