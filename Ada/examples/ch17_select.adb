-- ============================================================
-- 第17章：任务深入——select 会合家族
-- 选择等待/哨兵、条件与定时入口调用、terminate、入口族、信号灯、
-- 周期任务无漂移延迟、任务属性/abort/任务异常
-- ============================================================
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Calendar;
with System;

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

   -- ---------------------------
   -- 7. 周期任务：无漂移延迟（刘炳文 §16.5 响铃任务）
   -- ---------------------------
   New_Line;
   Put_Line ("--- 7. 周期任务：无漂移延迟 ---");
   declare
      use Ada.Calendar;
      Period  : constant Duration := 0.05;
      Ticks   : constant := 3;
      Start   : Time;
      Elapsed : Duration;
   begin
      Start := Clock;
      declare
         task Ring;
         task body Ring is
            Next_Due : Time := Clock + Period;  -- 下一次该响的"绝对时刻"
         begin
            for K in 1 .. Ticks loop
               delay Next_Due - Clock;          -- 咬住绝对时刻：单轮误差不累积
               Next_Due := Next_Due + Period;
            end loop;
         end Ring;
      begin
         null;                                  -- 块结束处主人等 Ring 收尾
      end;
      Elapsed := Clock - Start;
      Put_Line ("  3 个周期名义时长 0.150s，实测 >= 名义: "
                & Boolean'Image (Elapsed >= Duration (Ticks) * Period));
      Put_Line ("  （对照 delay Period 写法：每轮的调度误差会逐轮叠进总时长）");
   end;

   -- ---------------------------
   -- 8. 任务异常与 abort（刘炳文 §16.7-16.9）
   -- ---------------------------
   New_Line;
   Put_Line ("--- 8. 任务异常与 abort ---");
   declare
      task Doomed is
         entry Ask;
         pragma Warnings                        -- 生来就是"调用已完结任务"演示的靶子
           (Off, "no accept for entry");
      end Doomed;
      task body Doomed is
      begin
         raise Constraint_Error;                -- 任务体内冒出的异常
      exception
         when Constraint_Error =>
            Put_Line ("  [将死任务] 异常被本地处理，任务随即""完成""");
         -- 即使不写处理段：异常也绝不传出任务体（任务静默完成）
      end Doomed;

      task Sleeper;
      task body Sleeper is
      begin
         delay 30.0;                            -- 卡在长延迟上
         Put_Line ("  不该走到这");
      end Sleeper;
   begin
      delay 0.05;                               -- 让 Doomed 先跑完
      Put_Line ("  Doomed'Terminated = " & Boolean'Image (Doomed'Terminated)
                & "（完成且无依赖任务 → 已彻底终止）");
      Put_Line ("  Doomed'Callable   = " & Boolean'Image (Doomed'Callable)
                & "（已完结，不再接单）");

      -- 调用已完结任务的入口：RM 9.5.3 明文规定引发 Tasking_Error
      begin
         Doomed.Ask;
      exception
         when Tasking_Error =>
            Put_Line ("  调用已完结任务的入口 → Tasking_Error（RM 9.5.3）");
      end;

      abort Sleeper;                            -- 打断 delay，强制作废
      declare
         Tries : Natural := 0;
      begin
         while not Sleeper'Terminated and Tries < 200 loop
            delay 0.005;                        -- abort 落地需要一点时间
            Tries := Tries + 1;
         end loop;
      end;
      Put_Line ("  abort Sleeper 后 Sleeper'Terminated = "
                & Boolean'Image (Sleeper'Terminated)
                & "（轮询等待作废生效，最多 1s）");
   end;

   -- ---------------------------
   -- 9. 任务优先级（何诚 §12.10）：静态指定的两个时代写法
   -- ---------------------------
   New_Line;
   Put_Line ("--- 9. 任务优先级 ---");
   declare
      -- 83 风格：杂注写在任务规范说明里（现代依然合法）
      task Urgent is
         pragma Priority (System.Default_Priority + 3);
         entry Ping;
      end Urgent;
      task body Urgent is
      begin
         accept Ping;
      end Urgent;

      -- 现代风格：方面（aspect）写在名字与 is 之间（Ada 2005 起）
      task type Background with Priority => System.Default_Priority - 3 is
         entry Ping;
      end Background;
      task body Background is
      begin
         accept Ping;
      end Background;
      Bg : Background;
   begin
      Put_Line ("  Default_Priority = " & Integer'Image (System.Default_Priority));
      Put_Line ("  Any_Priority 范围 = " & Integer'Image (System.Any_Priority'First)
                & " .. " & Integer'Image (System.Any_Priority'Last));
      Put_Line ("  Priority     范围 = " & Integer'Image (System.Priority'First)
                & " .. " & Integer'Image (System.Priority'Last));
      Urgent.Ping;                          -- 高优先级任务正常会合
      Bg.Ping;                              -- 低优先级任务正常会合
      Put_Line ("  高/低优先级任务均会合成功（何时分高下见正文）");
   end;

   -- 越界的优先级：编译器只警告，说明部分加工时才引爆
   begin
      declare
         task Bad_Prio is
            pragma Priority (Integer'Last); -- 远超 Any_Priority 上界
            pragma Warnings (Off, "value not in range of type");
            pragma Warnings (Off, """Priority"" will be raised");
            entry Ping;
         end Bad_Prio;
         task body Bad_Prio is
         begin
            accept Ping;                    -- 不会到达：加工即炸
         end Bad_Prio;
      begin
         Put_Line ("  不该走到这");
      end;
   exception
      when Constraint_Error =>
         Put_Line ("  Priority 越界：编译只警告，说明部分加工时 CONSTRAINT_ERROR");
   end;

   -- ---------------------------
   -- 10. 会合中的异常（何诚 §13.6）：accept 体传调用方
   -- ---------------------------
   New_Line;
   Put_Line ("--- 10. 会合中的异常 ---");
   declare
      Junk : Integer;
      task Server is
         entry Fetch (V : out Integer);
      end Server;
      task body Server is
      begin
         accept Fetch (V : out Integer) do
            raise Constraint_Error;         -- accept 语句体内冒异常
         end Fetch;
      end Server;
   begin
      Server.Fetch (Junk);                  -- 调用点收到！
      Put_Line ("  不该走到这");
   exception
      when Constraint_Error =>
         Put_Line ("  accept 体内的异常 → 调用者的入口调用处收到");
   end;

   declare
      Junk : Integer;
      task Crasher is
         entry Fetch (V : out Integer);
      end Crasher;
      task body Crasher is
      begin
         accept Fetch (V : out Integer) do
            raise Constraint_Error;
         end Fetch;
         -- 异常没处理：Crasher 自己随即静默"完成"
      end Crasher;
   begin
      begin
         Crasher.Fetch (Junk);              -- 调用点照样收到
      exception
         when Constraint_Error =>
            Put_Line ("  服务者没处理 → 自己静默完成，调用方仍收到异常");
      end;
      delay 0.02;
      Put_Line ("  Crasher'Terminated = " & Boolean'Image (Crasher'Terminated)
                & "（异常穿出 accept 后，任务体自身也终止）");
   end;
end Ch17_Select;
