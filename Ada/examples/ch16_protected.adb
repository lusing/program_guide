-- ============================================================
-- 第16章：受保护对象 (Protected Objects)
-- ============================================================
with Ada.Text_IO; use Ada.Text_IO;

procedure Ch16_Protected is

   -- 受保护类型：线程安全的计数器
   protected type Safe_Counter is
      procedure Increment;
      procedure Decrement;
      function Value return Integer;
   private
      Count : Integer := 0;
   end Safe_Counter;

   protected body Safe_Counter is
      procedure Increment is
      begin
         Count := Count + 1;
         Put_Line ("    Counter incremented to" & Integer'Image(Count));
      end Increment;

      procedure Decrement is
      begin
         Count := Count - 1;
         Put_Line ("    Counter decremented to" & Integer'Image(Count));
      end Decrement;

      function Value return Integer is
      begin
         return Count;
      end Value;
   end Safe_Counter;

   -- 受保护的有界缓冲区
   Max_Buffer_Size : constant := 16;
   type Buffer_Array is array (1 .. Max_Buffer_Size) of Integer;

   protected type Bounded_Buffer (Size : Positive) is
      entry Put (Item : Integer);
      entry Get (Item : out Integer);
      function Is_Empty return Boolean;
      function Is_Full return Boolean;
   private
      Data   : Buffer_Array;
      Head   : Natural := 1;
      Tail   : Natural := 1;
      Count  : Natural := 0;
   end Bounded_Buffer;

   protected body Bounded_Buffer is
      entry Put (Item : Integer) when Count < Size is
      begin
         Data (Tail) := Item;
         Tail := (Tail mod Size) + 1;
         Count := Count + 1;
         Put_Line ("    Buffer: put" & Integer'Image(Item) & " (count=" & Integer'Image(Count) & ")");
      end Put;

      entry Get (Item : out Integer) when Count > 0 is
      begin
         Item := Data (Head);
         Head := (Head mod Size) + 1;
         Count := Count - 1;
         Put_Line ("    Buffer: got" & Integer'Image(Item) & " (count=" & Integer'Image(Count) & ")");
      end Get;

      function Is_Empty return Boolean is (Count = 0);
      function Is_Full return Boolean is (Count = Size);
   end Bounded_Buffer;

   -- 使用受保护对象的任务
   Counter : Safe_Counter;

   task type Worker_Task (Id : Integer);
   task body Worker_Task is
   begin
      for I in 1 .. 3 loop
         Counter.Increment;
         delay 0.1;
      end loop;
   end Worker_Task;

   W1 : Worker_Task (1);
   W2 : Worker_Task (2);

begin
   Put_Line ("=== Ada 受保护对象 (Protected Objects) 示例 ===");
   New_Line;

   -- 1. 线程安全的计数器
   Put_Line ("--- 1. 线程安全计数器 (Safe_Counter) ---");
   Put_Line ("  (多个任务并发访问安全计数器)");
   -- 等待 Worker 任务完成
   delay 0.5;
   Put_Line ("  Final counter value: " & Integer'Image(Counter.Value));

   -- 2. 有界缓冲区
   New_Line;
   Put_Line ("--- 2. 有界缓冲区 (Bounded_Buffer) ---");
   declare
      Buffer : Bounded_Buffer (Size => 3);
      Item   : Integer;
   begin
      Put_Line ("  Buffer size: 3");
      Buffer.Put (10);
      Buffer.Put (20);
      Buffer.Put (30);
      Put_Line ("  Is_Full: " & Boolean'Image(Buffer.Is_Full));

      Buffer.Get (Item);
      Buffer.Get (Item);
      Put_Line ("  Is_Empty: " & Boolean'Image(Buffer.Is_Empty));

      Buffer.Get (Item);
      Put_Line ("  Is_Empty: " & Boolean'Image(Buffer.Is_Empty));
   end;
end Ch16_Protected;