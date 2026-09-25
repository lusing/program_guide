-- ============================================================
-- 第17章：任务深入——select 会合家族
-- 选择等待/哨兵、条件与定时入口调用、terminate、入口族、信号灯
-- ============================================================
with Ada.Text_IO; use Ada.Text_IO;

procedure Ch17_Select is

   -- --------------------------------------------------------
   -- 17.1 选择等待 + 哨兵：有界缓冲任务（何诚 §12.5 BUFFER）
   -- --------------------------------------------------------
   task type Bounded_Buffer is
      entry Put (C : Character);
      entry Get (C : out Character);
   end Bounded_Buffer;

   task body Bounded_Buffer is
      Size : constant := 4;
      Data : array (1 .. Size) of Character;
      Used : Natural range 0 .. Size := 0;
      Inx  : Positive range 1 .. Size := 1;
      Outx : Positive range 1 .. Size := 1;
   begin
      loop
         select
            when Used < Size =>            -- 哨兵：未满才收 Put
               accept Put (C : Character) do
                  Data (Inx) := C;
               end Put;
               Inx  := Inx mod Size + 1;
               Used := Used + 1;
         or
            when Used > 0 =>               -- 哨兵：非空才收 Get
               accept Get (C : out Character) do
                  C := Data (Outx);
               end Get;
               Outx := Outx mod Size + 1;
               Used := Used - 1;
         or
            when Used = 0 =>               -- 空了才允许随主人终止
               terminate;
         end select;
      end loop;
   end Bounded_Buffer;

   -- --------------------------------------------------------
   -- 17.3 定时入口调用的对端：磨蹭的服务员
   -- --------------------------------------------------------
   task Slow_Server is
      entry Serve (N : Positive);
   end Slow_Server;

   task body Slow_Server is
      Done : Natural := 0;
   begin
      loop
         delay 0.2;                        -- 磨蹭：0.2 秒后才到 accept 站台
         select
            accept Serve (N : Positive) do
               Put_Line ("  [服务员] 完成第" & Integer'Image (N) & "单");
            end Serve;
            Done := Done + 1;
         or
            terminate;                     -- 主人收摊就收工
         end select;
         exit when Done = 1;               -- 服务一单收工
      end loop;
   end Slow_Server;

   -- --------------------------------------------------------
   -- 17.5 入口族：泊位调度
   -- --------------------------------------------------------
   task Harbor is
      entry Dock (1 .. 3) (Ship : String); -- 一个入口名，三张队列
   end Harbor;

   task body Harbor is
   begin
      loop
         select
            accept Dock (1) (Ship : String) do
               Put_Line ("  1 号泊位 <- " & Ship);
            end Dock;
         or
            accept Dock (2) (Ship : String) do
               Put_Line ("  2 号泊位 <- " & Ship);
            end Dock;
         or
            accept Dock (3) (Ship : String) do
               Put_Line ("  3 号泊位 <- " & Ship);
            end Dock;
         or
            terminate;
         end select;
      end loop;
   end Harbor;

   -- --------------------------------------------------------
   -- 17.6 信号灯：用会合实现二元信号量（张丽芬 §8.10）
   --    （声明与使用都在第 6 节的块内，见正文）
   -- --------------------------------------------------------

begin
   Put_Line ("=== Ada select 会合家族示例 ===");
   New_Line;

   -- 1. 选择等待：生产者-消费者（生产者只放货不出声）
   Put_Line ("--- 1. 选择等待 + 哨兵：有界缓冲 ---");
   declare
      Buf : Bounded_Buffer;                 -- 容量 4 的缓冲任务
      task Producer;
      task body Producer is
      begin
         for C in Character range 'a' .. 'f' loop
            Buf.Put (C);                    -- 满了就阻塞在会合外
         end loop;
      end Producer;
   begin
      delay 0.1;                            -- 让生产者先填满缓冲
      for I in 1 .. 6 loop
         declare
            C : Character;
         begin
            Buf.Get (C);
            Put_Line ("  取到第" & Integer'Image (I) & "件: " & C);
         end;
      end loop;
   end;                                     -- 块结束：缓冲随 terminate 归队
   Put_Line ("  缓冲区取空，块结束（任务经 terminate 终止）");

   -- 2. 条件入口调用：select ... else（调用方拒绝等）
   New_Line;
   Put_Line ("--- 2. 条件入口调用 ---");
   declare
      Buf  : Bounded_Buffer;
      Junk : Character;
   begin
      Buf.Put ('x');
      Buf.Put ('y');
      Buf.Put ('w');
      Buf.Put ('v');                        -- 4 件 = 满
      Put_Line ("  已放入 4 件（容量 4），条件式放入第 5 件:");
      select
         Buf.Put ('z');                     -- 能立即会合才会发生
         Put_Line ("  放入成功");
      else
         Put_Line ("  [调用方] 满仓不在眼前，转身走人");
      end select;
      Buf.Get (Junk);                       -- 腾出一个空位
      Put_Line ("  取走 1 件后再条件式放入:");
      select
         Buf.Put ('z');                     -- 哨兵已开，立即会合
         Put_Line ("  放入成功（有空位就立刻放进）");
      else
         Put_Line ("  不该走到这");
      end select;
      for I in 1 .. 4 loop                  -- 取空，块结束才能终止
         Buf.Get (Junk);
      end loop;
   end;

   -- 3. 定时入口调用：select ... or delay（调用方限时等待）
   New_Line;
   Put_Line ("--- 3. 定时入口调用 ---");
   begin
      select
         Slow_Server.Serve (1);
         Put_Line ("  第 1 单等到服务员了");
      or
         delay 0.05;                        -- 只等 0.05 秒
         Put_Line ("  [调用方] 0.05s 没等到，超时放弃");
      end select;
   end;
   begin
      select
         Slow_Server.Serve (2);
         Put_Line ("  第 2 单等到服务员了（等足 0.2s）");
      or
         delay 2.0;
         Put_Line ("  不该走到这");
      end select;
   end;

   -- 4. 服务端超时：accept 或 delay（何诚 WATCHDOG）
   New_Line;
   Put_Line ("--- 4. 服务端超时（看门狗） ---");
   declare
      task Watchdog is
         entry Ok;
      end Watchdog;
      task body Watchdog is
      begin
         select
            accept Ok;
            Put_Line ("  被监护任务还活着");
         or
            delay 0.2;                      -- 0.2 秒没等到 Ok
            Put_Line ("  [看门狗] 超时！被监护任务疑似死亡");
         end select;
      end Watchdog;
   begin
      null;                                 -- 故意不喂狗
   end;

   -- 5. 入口族
   New_Line;
   Put_Line ("--- 5. 入口族 ---");
   Harbor.Dock (2) ("东海号");
   Harbor.Dock (1) ("渤海号");
   Harbor.Dock (3) ("南海号");

   -- 6. 信号灯（限域声明：任务随块终止）
   New_Line;
   Put_Line ("--- 6. 信号灯（会合式二元信号量） ---");
   declare
      task Semaphore is
         entry P;                           -- 申请
         entry V;                           -- 释放
      end Semaphore;

      task body Semaphore is
      begin
         loop
            select
               accept P;                    -- 第一次会合：获得
               accept V;                    -- 第二次会合：归还
            or
               terminate;
            end select;
         end loop;
      end Semaphore;

      task User;                            -- 与主任务争用信号灯

      task body User is
      begin
         delay 0.05;                        -- 让主任务先进入
         Semaphore.P;
         Put_Line ("  用户任务进入临界区");
         Semaphore.V;
      end User;
   begin
      Semaphore.P;
      Put_Line ("  主任务进入临界区");
      Semaphore.V;                          -- 释放后用户任务才进得去
      -- 块结束前主人会等依赖任务收尾
   end;
   Put_Line ("  块结束：信号灯任务已终止");
end Ch17_Select;
