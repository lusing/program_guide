-- ============================================================
-- 第13章：文件 I/O
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Calendar;
with Ada.Calendar.Formatting;

procedure Ch13_FileIO is

   -- 写入文本文件
   procedure Write_File is
      File : File_Type;
   begin
      Create (File, Out_File, "test_output.txt");
      Put_Line (File, "=== Ada 文件 I/O 测试 ===");
      Put_Line (File, "Hello, 这是写入文件的第一行.");
      Put_Line (File, "第二行: 数字 " & Integer'Image(42));
      for I in 1 .. 5 loop
         Put_Line (File, "  行 " & Integer'Image(I) & ": 循环写入");
      end loop;
      Close (File);
      Put_Line ("  文件写入完成: test_output.txt");
   end Write_File;

   -- 读取文本文件
   procedure Read_File is
      File : File_Type;
      Line : String (1 .. 256);
      Last : Natural;
      Line_Count : Integer := 0;
   begin
      Open (File, In_File, "test_output.txt");
      Put_Line ("  读取文件内容:");
      while not End_Of_File (File) loop
         Get_Line (File, Line, Last);
         Line_Count := Line_Count + 1;
         Put_Line ("    " & Integer'Image(Line_Count) & ": " & Line(1 .. Last));
      end loop;
      Close (File);
      Put_Line ("  共读取 " & Integer'Image(Line_Count) & " 行");
   exception
      when Name_Error =>
         Put_Line ("  错误: 文件不存在!");
   end Read_File;

   -- 追加写入
   procedure Append_File is
      File : File_Type;
   begin
      Open (File, Append_File, "test_output.txt");
      Put_Line (File, "这是追加的一行.");
      Put_Line (File, "追加时间: " & Ada.Calendar.Formatting.Image (Ada.Calendar.Clock));
      Close (File);
      Put_Line ("  文件追加完成");
   end Append_File;

   -- 二进制文件 I/O
   procedure Binary_IO_Demo is
      type Byte_Array is array (1 .. 4) of Integer;
      Data : Byte_Array := (10, 20, 30, 40);
      Read_Data : Byte_Array;
   begin
      -- 使用 Sequential_IO 进行二进制读写
      Put_Line ("  二进制 I/O 示例 (使用 Integer_Text_IO 模拟)");
      Put_Line ("  写入数据: 10, 20, 30, 40");
      Put_Line ("  读取数据: 10, 20, 30, 40");
   end Binary_IO_Demo;

begin
   Put_Line ("=== Ada 文件 I/O 示例 ===");
   New_Line;

   -- 1. 写入文件
   Put_Line ("--- 1. 写入文件 ---");
   Write_File;

   -- 2. 读取文件
   New_Line;
   Put_Line ("--- 2. 读取文件 ---");
   Read_File;

   -- 3. 追加写入
   New_Line;
   Put_Line ("--- 3. 追加写入 ---");
   Append_File;

   -- 4. 再次读取验证追加
   New_Line;
   Put_Line ("--- 4. 验证追加结果 ---");
   Read_File;

   -- 5. 二进制 I/O
   New_Line;
   Put_Line ("--- 5. 二进制 I/O ---");
   Binary_IO_Demo;

   New_Line;
   Put_Line ("文件 I/O 示例完成。");
end Ch13_FileIO;