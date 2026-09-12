-- ============================================================
-- 第11章：并发编程 (Tasking)
-- ============================================================
with Ada.Text_IO; use Ada.Text_IO;

procedure Ch11_Tasking is

   -- 简单任务类型
   task type Worker (Id : Integer);

   task body Worker is
      Delay_Time : constant Duration := 0.5;
   begin
      Put_Line ("  Worker" & Integer'Image(Id) & " 开始工作...");
      delay Delay_Time;  -- 模拟工作
      Put_Line ("  Worker" & Integer'Image(Id) & " 完成工作。");
   end Worker;

   -- 与主程序同步的任务
   task Printer is
      entry Print_Message (Msg : String);
   end Printer;

   task body Printer is
   begin
      accept Print_Message (Msg : String) do
         Put_Line ("  Printer 收到消息: " & Msg);
      end Print_Message;

      accept Print_Message (Msg : String) do
         Put_Line ("  Printer 收到消息: " & Msg);
      end Print_Message;
   end Printer;

   -- 生产者-消费者
   task type Producer (Id : Integer);
   task Consumer is
      entry Deliver (Item : Integer);
   end Consumer;

   task body Producer is
   begin
      for I in 1 .. 3 loop
         Put_Line ("  Producer" & Integer'Image(Id) & " 生产: " & Integer'Image(I));
         Consumer.Deliver (I);
      end loop;
   end Producer;

   task body Consumer is
   begin
      for I in 1 .. 6 loop
         accept Deliver (Item : Integer) do
            Put_Line ("  Consumer 消费: " & Integer'Image(Item));
         end Deliver;
      end loop;
   end Consumer;

   P1 : Producer (1);
   P2 : Producer (2);

begin
   Put_Line ("=== Ada 并发编程 (Tasking) 示例 ===");
   New_Line;

   -- 1. 并行 Worker
   Put_Line ("--- 1. 并行任务 ---");
   declare
      W1 : Worker (1);
      W2 : Worker (2);
      W3 : Worker (3);
   begin
      null;  -- 等待所有 Worker 结束
   end;

   -- 2. Rendezvous (同步入口)
   New_Line;
   Put_Line ("--- 2. Rendezvous (同步入口) ---");
   Printer.Print_Message ("Hello from main!");
   Printer.Print_Message ("第二条消息");

   -- 3. 生产者-消费者已经随声明启动
   New_Line;
   Put_Line ("--- 3. 生产者-消费者模式 ---");
   Put_Line ("  (See output above for Producer/Consumer messages)");

   Put_Line ("  所有任务已完成。");
end Ch11_Tasking;