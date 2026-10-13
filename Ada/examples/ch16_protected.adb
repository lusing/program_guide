-- ============================================================
-- 第16章：受保护对象 (Protected Objects)
--   —— 无锁互斥 / 函数只读并发 / 入口屏障 /
--      有界缓冲区 / 信号灯 (老教材 SEMAPHORE 的现代实现)
-- ============================================================
with Ada.Text_IO; use Ada.Text_IO;

procedure Ch16_Protected is

   -- ---------------------------
   -- 1. 受保护计数器：过程独占、函数并发
   -- ---------------------------
   protected type Safe_Counter is
      procedure Increment;               -- 过程：读写，独占执行
      procedure Decrement;
      function Value return Integer;     -- 函数：只读，可多读者并发
   private
      Count : Integer := 0;              -- 状态：外部永远摸不到
   end Safe_Counter;

   protected body Safe_Counter is
      procedure Increment is
      begin
         Count := Count + 1;
      end Increment;

      procedure Decrement is
      begin
         Count := Count - 1;
      end Decrement;

      function Value return Integer is (Count);
   end Safe_Counter;

   -- ---------------------------
   -- 2. 有界缓冲区：入口屏障 (when 条件)
   -- ---------------------------
   Max_Buffer_Size : constant := 8;
   type Buffer_Array is array (1 .. Max_Buffer_Size) of Integer;

   protected type Bounded_Buffer (Size : Positive) is
      entry Put (Item : in Integer);     -- when Count < Size 才开
      entry Get (Item : out Integer);    -- when Count > 0 才开
      function Is_Empty return Boolean;
      function Is_Full return Boolean;
   private
      Data  : Buffer_Array;
      Head  : Natural := 1;
      Tail  : Natural := 1;
      Count : Natural := 0;
   end Bounded_Buffer;

   protected body Bounded_Buffer is
      entry Put (Item : in Integer) when Count < Size is
      begin
         Data (Tail) := Item;
         Tail := (Tail mod Size) + 1;    -- 环形推进
         Count := Count + 1;
      end Put;

      entry Get (Item : out Integer) when Count > 0 is
      begin
         Item := Data (Head);
         Head := (Head mod Size) + 1;
         Count := Count - 1;
      end Get;

      function Is_Empty return Boolean is (Count = 0);
      function Is_Full return Boolean is (Count = Size);
   end Bounded_Buffer;

   -- ---------------------------
   -- 3. 信号灯：老教材用任务+accept 实现，如今一个受保护对象
   -- ---------------------------
   protected type Semaphore (Initial : Positive) is
      entry P;                           -- 申请（信号量减一，0 则排队）
      procedure V;                       -- 释放（信号量加一，唤醒队首）
      function Tokens return Natural;
   private
      Available : Natural := Initial;
   end Semaphore;

   protected body Semaphore is
      entry P when Available > 0 is
      begin
         Available := Available - 1;
      end P;

      procedure V is
      begin
         Available := Available + 1;
      end V;

      function Tokens return Natural is (Available);
   end Semaphore;

   -- 互斥演示的两个协作任务
   Counter : Safe_Counter;
   Mutex   : Semaphore (1);              -- 初值 1 = 互斥信号灯

   task type Worker (Id : Integer);
   task body Worker is               -- 体不重复判别式（可见性来自规范）
   begin
      for I in 1 .. 3 loop
         Mutex.P;                        -- 进临界区（老教材 S1.P;）
         Counter.Increment;              -- 临界区：受保护操作
         Mutex.V;                        -- 出临界区（老教材 S1.V;）
      end loop;
   end Worker;

begin
   Put_Line ("=== Ada 受保护对象 ===");
   New_Line;

   -- ---------------------------
   -- 1. 计数器：并发任务自增，结果必须是 6
   -- ---------------------------
   Put_Line ("--- 1. 并发自增 ---");
   declare
      W1 : Worker (1);
      W2 : Worker (2);
   begin
      null;   -- 块结束即等待两个任务终止
   end;
   Put_Line ("  两个任务各增 3 次，Counter.Value = "
             & Integer'Image (Counter.Value) & "（必为 6，不多不少）");
   Put_Line ("  Mutex.P/V 夹住临界区——这正是老教材信号灯的用法。");

   -- ---------------------------
   -- 2. 有界缓冲区：满则阻塞、空则阻塞
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. 有界缓冲区 ---");
   declare
      Buffer : Bounded_Buffer (Size => 3);
      Item   : Integer;
   begin
      Buffer.Put (10);
      Buffer.Put (20);
      Buffer.Put (30);
      Put_Line ("  放入 10/20/30 后 Is_Full = "
                & Boolean'Image (Buffer.Is_Full));
      Buffer.Get (Item);
      Put_Line ("  取出" & Integer'Image (Item)
                & "（FIFO：先入先出）");
      Put_Line ("  再放入 40：满时 Put 入口关闭，调用方自动排队。");
      Buffer.Put (40);
      loop
         exit when Buffer.Is_Empty;
         Buffer.Get (Item);
         Put_Line ("  排空：取出" & Integer'Image (Item));
      end loop;
   end;

   -- ---------------------------
   -- 3. 信号灯：容量 2 的资源池
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 信号灯 (容量 2) ---");
   declare
      Pool : Semaphore (2);
   begin
      Pool.P;                            -- 剩 1
      Pool.P;                            -- 剩 0
      Put_Line ("  两次 P 后剩余令牌 ="
                & Integer'Image (Pool.Tokens));
      Pool.V;                            -- 剩 1
      Put_Line ("  一次 V 后剩余令牌 ="
                & Integer'Image (Pool.Tokens));
      Put_Line ("  再 P 时若令牌为 0，调用任务会在入口队列排队等待。");
   end;
end Ch16_Protected;
