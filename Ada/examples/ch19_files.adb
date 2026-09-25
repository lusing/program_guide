-- ============================================================
-- 第19章：文件 I/O 全景——顺序、直接与流
-- Sequential_IO / Direct_IO / Stream_IO 与流属性、文件合并
--
-- 注意：各 IO 包都有 File_Type/Count 等同名类型，多个 use 会撞名，
--      本示例一律用"实例名.操作"的限定写法（这也是惯用法）。
-- ============================================================
with Ada.Text_IO;       use Ada.Text_IO;
with Ada.Sequential_IO;
with Ada.Direct_IO;
with Ada.Streams.Stream_IO;

procedure Ch19_Files is

   -- --------------------------------------------------------
   -- 记录类型：员工档案（机器格式存储的典型元素类型）
   -- --------------------------------------------------------
   type Employee is
      record
         Id     : Positive range 1 .. 999;
         Name   : String (1 .. 8);
         Salary : Integer;
      end record;

   package Employee_IO  is new Ada.Sequential_IO (Employee);
   package Employee_DIO is new Ada.Direct_IO (Employee);

   procedure Put_Emp (E : Employee) is
   begin
      Put_Line ("    #" & Integer'Image (E.Id) & " "
                & E.Name & " 工资" & Integer'Image (E.Salary));
   end Put_Emp;

begin
   Put_Line ("=== Ada 文件 I/O 全景示例 ===");
   New_Line;

   -- 1. Sequential_IO：定长元素的顺序文件
   Put_Line ("--- 1. Sequential_IO（顺序文件） ---");
   declare
      package Int_IO is new Ada.Sequential_IO (Integer);
      F : Int_IO.File_Type;
      V : Integer;
   begin
      Int_IO.Create (F, Int_IO.Out_File, "ch19_seq.bin");
      for I in 1 .. 5 loop
         Int_IO.Write (F, I * I);
      end loop;
      Int_IO.Close (F);

      Int_IO.Open (F, Int_IO.In_File, "ch19_seq.bin");
      Put ("  读回平方数: ");
      while not Int_IO.End_Of_File (F) loop
         Int_IO.Read (F, V);
         Put (Integer'Image (V) & " ");
      end loop;
      New_Line;
      Int_IO.Close (F);
   end;

   -- 2. Sequential_IO：记录文件
   New_Line;
   Put_Line ("--- 2. 记录顺序文件 ---");
   declare
      F : Employee_IO.File_Type;
      E : Employee;
   begin
      Employee_IO.Create (F, Employee_IO.Out_File, "ch19_emp.bin");
      Employee_IO.Write (F, (1, "Ada     ", 5000));
      Employee_IO.Write (F, (2, "Grace   ", 6500));
      Employee_IO.Write (F, (3, "Barbara ", 5800));
      Employee_IO.Close (F);

      Employee_IO.Open (F, Employee_IO.In_File, "ch19_emp.bin");
      Put_Line ("  全部记录:");
      while not Employee_IO.End_Of_File (F) loop
         Employee_IO.Read (F, E);
         Put_Emp (E);
      end loop;
      Employee_IO.Close (F);
   end;

   -- 3. Direct_IO：随机存取（老教材 SET_READ/SET_WRITE 的现代形态）
   New_Line;
   Put_Line ("--- 3. Direct_IO（随机存取文件） ---");
   declare
      F    : Employee_DIO.File_Type;
      E    : Employee;
      Last : Employee_DIO.Count;
   begin
      Employee_DIO.Create (F, Employee_DIO.Inout_File, "ch19_direct.bin"); -- 读写两用
      Employee_DIO.Write (F, (1, "Ada     ", 5000), To => 1);
      Employee_DIO.Write (F, (2, "Grace   ", 6500), To => 2);
      Employee_DIO.Write (F, (3, "Barbara ", 5800), To => 3);

      Put_Line ("  直接读第 2 号记录（不经顺序扫描）:");
      Employee_DIO.Read (F, E, From => 2);
      Put_Emp (E);

      Put_Line ("  改写第 2 号记录再读回:");
      Employee_DIO.Write (F, (2, "Grace   ", 7000), To => 2);
      Employee_DIO.Read (F, E, From => 2);
      Put_Emp (E);

      Last := Employee_DIO.Size (F);
      Put_Line ("  文件共" & Employee_DIO.Count'Image (Last)
                & " 条记录；当前位置 = "
                & Employee_DIO.Count'Image (Employee_DIO.Index (F)));
      Employee_DIO.Close (F);
   end;

   -- 4. Stream_IO + 流属性：一个文件混装多种类型
   New_Line;
   Put_Line ("--- 4. Stream_IO 与流属性 ---");
   declare
      package SIO renames Ada.Streams.Stream_IO;
      F   : SIO.File_Type;
      Str : aliased String := "Ada 2022";
      N   : Integer;
      Got : String (1 .. 8);
      R   : Employee;
   begin
      SIO.Create (F, SIO.Out_File, "ch19_stream.bin");
      Integer'Output (SIO.Stream (F), 42);     -- 写一个整数
      String'Output  (SIO.Stream (F), Str);    -- 'Output 连界带内容
      Employee'Output (SIO.Stream (F), (7, "Lovelace", 9000));
      SIO.Close (F);

      SIO.Open (F, SIO.In_File, "ch19_stream.bin");
      N   := Integer'Input (SIO.Stream (F));
      Got := String'Input (SIO.Stream (F));
      R   := Employee'Input (SIO.Stream (F));
      SIO.Close (F);
      Put_Line ("  混装读回: 整数 =" & Integer'Image (N)
                & ", 串 = """ & Got & """");
      Put_Emp (R);
      Put_Line ("  （'Input/'Output 自带边界与标签，");
      Put_Line ("   同一文件可混装异构数据——与 Sequential_IO 的本质区别）");
   end;

   -- 5. 案例：有序文件合并（张丽芬《导论》文件合并）
   New_Line;
   Put_Line ("--- 5. 案例：二路归并有序文件 ---");
   declare
      package Int_IO is new Ada.Sequential_IO (Integer);
      A, B, C : Int_IO.File_Type;
      Xa, Xb  : Integer;

      procedure Put_All (Name : String) is
         F : Int_IO.File_Type;
         V : Integer;
      begin
         Int_IO.Open (F, Int_IO.In_File, Name);
         Put ("  " & Name & ":");
         while not Int_IO.End_Of_File (F) loop
            Int_IO.Read (F, V);
            Put (Integer'Image (V) & " ");
         end loop;
         New_Line;
         Int_IO.Close (F);
      end Put_All;

      A_Data : constant array (1 .. 5) of Integer := (1, 4, 7, 9, 13);
      B_Data : constant array (1 .. 4) of Integer := (2, 3, 8, 15);
   begin
      -- 建两个有序输入文件
      Int_IO.Create (A, Int_IO.Out_File, "ch19_a.bin");
      for V of A_Data loop Int_IO.Write (A, V); end loop;
      Int_IO.Close (A);
      Int_IO.Create (B, Int_IO.Out_File, "ch19_b.bin");
      for V of B_Data loop Int_IO.Write (B, V); end loop;
      Int_IO.Close (B);

      Put_All ("ch19_a.bin");
      Put_All ("ch19_b.bin");

      -- 经典二路归并：谁小谁出队；一方到底时，另一方手中元素
      -- 先落盘，残余再整体倾泻（注意手上元素只能写一次）
      Int_IO.Open (A, Int_IO.In_File, "ch19_a.bin");
      Int_IO.Open (B, Int_IO.In_File, "ch19_b.bin");
      Int_IO.Create (C, Int_IO.Out_File, "ch19_merged.bin");
      Int_IO.Read (A, Xa);
      Int_IO.Read (B, Xb);
      loop
         if Xa <= Xb then
            Int_IO.Write (C, Xa);
            if Int_IO.End_Of_File (A) then
               Int_IO.Write (C, Xb);   -- B 手上的元素先落盘
               exit;                   -- B 的残余由下面统一倾泻
            end if;
            Int_IO.Read (A, Xa);
         else
            Int_IO.Write (C, Xb);
            if Int_IO.End_Of_File (B) then
               Int_IO.Write (C, Xa);   -- A 手上的元素先落盘
               exit;
            end if;
            Int_IO.Read (B, Xb);
         end if;
      end loop;
      while not Int_IO.End_Of_File (A) loop
         Int_IO.Read (A, Xa);
         Int_IO.Write (C, Xa);
      end loop;
      while not Int_IO.End_Of_File (B) loop
         Int_IO.Read (B, Xb);
         Int_IO.Write (C, Xb);
      end loop;
      Int_IO.Close (A);
      Int_IO.Close (B);
      Int_IO.Close (C);

      Put_All ("ch19_merged.bin");
   end;
end Ch19_Files;
