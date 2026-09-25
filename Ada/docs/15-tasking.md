# 15 · 并发编程：Tasking

> 示例：[`examples/ch15_tasking.adb`](../examples/ch15_tasking.adb)
> 运行：`./run-all.sh 12`

## 15.1 任务类型

```ada
task type Worker (Id : Integer);
task body Worker is
begin
   Put_Line ("Worker" & Integer'Image(Id) & " 开始工作...");
   delay 0.5;  -- 模拟工作
   Put_Line ("Worker" & Integer'Image(Id) & " 完成工作。");
end Worker;
```

## 15.2 Rendezvous（同步入口）

```ada
task Printer is
   entry Print_Message (Msg : String);
end Printer;

task body Printer is
begin
   accept Print_Message (Msg : String) do
      Put_Line ("收到消息: " & Msg);
   end Print_Message;
end Printer;

-- 调用
Printer.Print_Message ("Hello from main!");
```

## 15.3 生产者-消费者模式

```ada
task Consumer is
   entry Deliver (Item : Integer);
end Consumer;

task body Producer is
begin
   for I in 1 .. 3 loop
      Consumer.Deliver (I);
   end loop;
end Producer;
```

## 15.4 关键概念

| 概念 | 说明 |
|------|------|
| `task` | 并发执行单元 |
| `entry` | 任务入口，用于同步 |
| `accept ... do` | Rendezvous 接受 |
| `delay` | 延迟指定时间 |
| `select` | 条件接受/选择入口 |

---
上一章：[14 OOP](14-oop.md) ｜ 下一章：[16 受保护对象](16-protected-objects.md) ｜ 返回：[README](../README.md)

