-- ============================================================
-- 第18章：文件 I/O
--   —— Text_IO 正文文件 / Sequential_IO 顺序二进制 /
--      Direct_IO 随机访问 / 文件异常 / 缺省文件重定向
--      （老教材第 3 章三件套的现代版）
-- ============================================================
with Ada.Text_IO;          use Ada.Text_IO;
with Ada.Sequential_IO;
with Ada.Direct_IO;
with Ada.Calendar;
with Ada.Calendar.Formatting;

procedure Ch18_FileIO is

   -- 正文文件三步曲：写 → 读 → 追加
   procedure Write_Text is
      File : File_Type;
   begin
      Create (File, Out_File, "report.txt");     -- 建立并关联外部文件
      Put_Line (File, "=== Ada 文件 I/O 测试 ===");
      Put_Line (File, "第一行：正文文件按行读写。");
      for I in 1 .. 3 loop
         Put_Line (File, "  循环行" & Integer'Image (I));
      end loop;
      Close (File);                              -- 解除关联
      Put_Line ("  写入完成：report.txt");
   end Write_Text;

   procedure Read_Text is
      File  : File_Type;
      Line  : String (1 .. 256);
      Last  : Natural;                            -- 实际读到的长度
      Count : Natural := 0;
   begin
      Open (File, In_File, "report.txt");        -- 打开已存在的文件
      while not End_Of_File (File) loop
         Get_Line (File, Line, Last);            -- 变长行：Last 告诉我们截到哪
         Count := Count + 1;
         Put_Line ("    行" & Integer'Image (Count) & ": "
                   & Line (1 .. Last));
      end loop;
      Close (File);
   end Read_Text;

   procedure Append_Text is
      File : File_Type;
   begin
      Open (File, Append_File, "report.txt");    -- 追加模式：写在文件尾
      Put_Line (File, "追加时间: "
                & Ada.Calendar.Formatting.Image (Ada.Calendar.Clock));
      Close (File);
      Put_Line ("  追加完成（带时间戳）");
   end Append_Text;

   -- ---------------------------
   -- 顺序二进制文件：元素类型任意，整块读写
   -- ---------------------------
   type Sensor_Sample is
      record
         Id    : Integer;
         Value : Float;
      end record;

   package Sample_IO is new Ada.Sequential_IO (Sensor_Sample);

   procedure Write_Sequential is
      File  : Sample_IO.File_Type;
      Data  : constant array (1 .. 3) of Sensor_Sample :=
        ((1, 21.5), (2, 22.0), (3, 19.8));
   begin
      Sample_IO.Create (File, Sample_IO.Out_File, "samples.bin");
      for K in Data'Range loop
         Sample_IO.Write (File, Data (K));
      end loop;
      Sample_IO.Close (File);
      Put_Line ("  顺序写入 3 条记录：samples.bin");
   end Write_Sequential;

   procedure Read_Sequential is
      -- 多个 IO 包都有 File_Type/In_File 等同名：实例化后绝不 use，
      -- 全部限定调用（Sample_IO.Open 而不是 Open）
      File : Sample_IO.File_Type;
      S    : Sensor_Sample;
   begin
      Sample_IO.Open (File, Sample_IO.In_File, "samples.bin");
      while not Sample_IO.End_Of_File (File) loop   -- 二进制文件同样有 EOF
         Sample_IO.Read (File, S);
         Put_Line ("    读回: Id =" & Integer'Image (S.Id)
                   & "  Value =" & Float'Image (S.Value));
      end loop;
      Sample_IO.Close (File);
   end Read_Sequential;

   -- ---------------------------
   -- 直接文件：按索引随机访问（老教材 POWER_OF_TEN）
   -- ---------------------------
   package Nat_IO is new Ada.Direct_IO (Integer);

   procedure Direct_Demo is
      -- 同上：Nat_IO 的 File_Type/Inout_File 全限定
      File : Nat_IO.File_Type;
      V    : Integer;
   begin
      Nat_IO.Create (File, Nat_IO.Inout_File, "powers.bin");  -- 可读写一体
      for P in 0 .. 5 loop
         Nat_IO.Write (File, 10 ** P);           -- 顺序写 6 条
      end loop;
      Nat_IO.Reset (File, Nat_IO.Inout_File);    -- 复位到文件头，保持读写一体
                                                  -- （若 Reset 成 In_File，
                                                  --   再 Write 会引发 MODE_ERROR）

      Nat_IO.Read (File, V, 3);                  -- 直接读第 3 条（索引从 1 起）
      Put_Line ("  直接读第 3 条（10**2）→" & Integer'Image (V));

      Nat_IO.Read (File, V, 6);
      Put_Line ("  直接读第 6 条（10**5）→" & Integer'Image (V));

      Nat_IO.Write (File, 999_999, 2);           -- 原地改写第 2 条
      Nat_IO.Read (File, V, 2);
      Put_Line ("  改写第 2 条后读回 →" & Integer'Image (V));
      Nat_IO.Close (File);
   end Direct_Demo;

begin
   Put_Line ("=== Ada 文件 I/O ===");
   New_Line;

   Put_Line ("--- 1. 正文文件 ---");
   Write_Text;
   Read_Text;

   New_Line;
   Put_Line ("--- 2. 追加 ---");
   Append_Text;
   Read_Text;

   New_Line;
   Put_Line ("--- 3. 顺序二进制 (Sequential_IO) ---");
   Write_Sequential;
   Read_Sequential;

   New_Line;
   Put_Line ("--- 4. 直接文件 (Direct_IO) ---");
   Direct_Demo;

   -- ---------------------------
   -- 5. 文件异常：Name_Error / Use_Error / End_Error
   -- ---------------------------
   New_Line;
   Put_Line ("--- 5. 文件异常 ---");
   declare
      File : File_Type;
   begin
      Open (File, In_File, "不存在 的 文件.txt");
      Put_Line ("  不应到达这里");
   exception
      when Name_Error =>
         Put_Line ("  捕获 Name_Error：文件名不存在/不可访问。");
   end;

   -- ---------------------------
   -- 6. 缺省输出重定向：Set_Output / Standard_Output
   -- ---------------------------
   New_Line;
   Put_Line ("--- 6. 缺省文件重定向 ---");
   declare
      Log : File_Type;
   begin
      Create (Log, Out_File, "trace.log");
      Set_Output (Log);                          -- 此后无文件参数的 Put 都进日志
      Put_Line ("这行进了 trace.log，而不是屏幕。");
      Set_Output (Standard_Output);              -- 切回标准输出
      Close (Log);

      Open (Log, In_File, "trace.log");
      declare
         Line : String (1 .. 64);
         Last : Natural;
      begin
         Get_Line (Log, Line, Last);
         Put_Line ("  从 trace.log 读回: " & Line (1 .. Last));
      end;
      Close (Log);
   end;

   New_Line;
   Put_Line ("文件 I/O 演示完成。");
end Ch18_FileIO;
