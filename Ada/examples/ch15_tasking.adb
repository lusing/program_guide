-- ============================================================
-- 第15章：并发编程 —— 任务 (Task) 与会合 (Rendezvous)
--   —— 任务说明与体 / accept 参数传递 / 入口队列 /
--      任务类型与任务数组 / 生产者-消费者管道
-- ============================================================
with Ada.Text_IO; use Ada.Text_IO;

procedure Ch15_Tasking is

   -- ---------------------------
   -- 1. 会合服务：入口 + accept
   --    （老教材 PRODUCER/CONSUMER 的无交互版本）
   -- ---------------------------
   task Upper is
      entry Send (C : in Character);   -- 入口：其他任务的调用接口
   end Upper;

   task body Upper is
   begin
      loop
         select                          -- 选择等待：见第 17 章
            accept Send (C : in Character) do
               -- 会合窗口：调用方挂起，直到 do...end 执行完
               if C in 'a' .. 'z' then
                  Put (Character'Val (Character'Pos (C)
                       - Character'Pos ('a') + Character'Pos ('A')));
               else
                  Put (C);
               end if;
            end Send;
         or
            terminate;                   -- 调用方都结束时自己也收摊
         end select;
      end loop;
   end Upper;

   -- ---------------------------
   -- 2. accept 的参数传递：in 拷入、out 拷回
   -- ---------------------------
   task Squarer is
      entry Compute (X : in Integer; Y : out Integer);
   end Squarer;

   task body Squarer is
   begin
      accept Compute (X : in Integer; Y : out Integer) do
         Y := X * X;                     -- out 参数在会合结束时拷回调用方
      end Compute;
   end Squarer;

   -- ---------------------------
   -- 3. 任务类型与任务数组（老教材 TAPE_DRIVE 磁带驱动器）
   -- ---------------------------
   task type Tape_Drive is
      entry Request;
      entry Release;
   end Tape_Drive;

   task body Tape_Drive is
      Busy : Boolean := False;
   begin
      loop
         select
            accept Request;
            Busy := True;
         or
            accept Release;
            Busy := False;
         or
            terminate;
         end select;
      end loop;
   end Tape_Drive;

begin
   Put_Line ("=== Ada 并发编程：任务与会合 ===");
   New_Line;

   -- ---------------------------
   -- 1. 主程序作为生产者：逐字符经会合送入 Upper 任务
   -- ---------------------------
   Put_Line ("--- 1. 生产者-消费者（大写转换） ---");
   declare
      Text : constant String := "Hello, concurrent Ada!";
   begin
      for K in Text'Range loop
         Upper.Send (Text (K));          -- 每个字符一次会合
      end loop;
      New_Line;
      Put_Line ("  每个字符一次会合：顺序确定，输出与输入一一对应。");
   end;

   -- ---------------------------
   -- 2. 会合中的参数传递
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. accept 的 in/out 参数 ---");
   declare
      Result : Integer;
   begin
      Squarer.Compute (12, Result);      -- 会合结束时 Result 拿到 144
      Put_Line ("  Squarer.Compute (12, Result) → Result ="
                & Integer'Image (Result));
   end;

   -- ---------------------------
   -- 3. 任务数组：一个任务类型，N 份拷贝
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. 任务数组 ---");
   declare
      Drives : array (1 .. 3) of Tape_Drive;   -- 三个任务对象
   begin
      for K in Drives'Range loop
         Drives (K).Request;             -- 依次申请三台驱动器
      end loop;
      Put_Line ("  3 台驱动器全部申请成功。");
      Drives (2).Release;                -- 释放中间那台
      Put_Line ("  释放 2 号驱动器。");
      Drives (2).Request;                -- 再次申请它
      Put_Line ("  再次申请 2 号成功——每台驱动器有独立状态。");
      for K in Drives'Range loop
         Drives (K).Release;
      end loop;
   end;
   -- 块结束：所有任务终止（terminate 备选）后才离开块

   New_Line;
   Put_Line ("  任务的激活：说明部分加工完、首句执行前；");
   Put_Line ("  任务的终止：块/主程序结束前，相关任务必须全部终止。");
   Put_Line ("=== 第 15 章演示结束 ===");
end Ch15_Tasking;
