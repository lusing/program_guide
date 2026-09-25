-- ============================================================
-- 第21章：低级程序设计与表示子句
-- Size/Pack/记录表示/枚举表示/地址覆盖/Unchecked_Conversion/
-- Storage_Size 存储池配额
-- ============================================================
with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Integer_Text_IO;      use Ada.Integer_Text_IO;
with Interfaces;               use Interfaces;
with System;                   use System;
with System.Storage_Elements;  use System.Storage_Elements;
with Ada.Unchecked_Conversion;

procedure Ch21_Lowlevel is

   -- --------------------------------------------------------
   -- 21.3 设备寄存器：记录表示子句（何诚 ADC_CSR 案例的现代版）
   -- --------------------------------------------------------
   type Bits_2 is mod 2 ** 2;
   type Bits_6 is mod 2 ** 6;
   type U16    is mod 2 ** 16;

   -- 一个 16 位控制/状态寄存器的位级布局
   type CSR is
      record
         Enable  : Boolean;     -- 位 0
         Mode    : Bits_2;      -- 位 1..2
         Channel : Bits_6;      -- 位 3..8
         Error   : Boolean;     -- 位 9
      end record
      with Size => 16;

   for CSR use
      record
         Enable  at 0 range 0 .. 0;
         Mode    at 0 range 1 .. 2;
         Channel at 0 range 3 .. 8;
         Error   at 0 range 9 .. 9;
      end record;

   -- 记录 <-> 位模式 的桥梁：两个 16 位类型间的非检查转换
   function To_U16 is new Ada.Unchecked_Conversion (CSR, U16);
   function To_CSR is new Ada.Unchecked_Conversion (U16, CSR);

   -- --------------------------------------------------------
   -- 21.4 枚举表示子句：操作码（老教材 for BIT use (OFF=>0, ON=>1)）
   -- --------------------------------------------------------
   type Opcode is (Halt, Load, Store, Add, Sub, Jump);
   for Opcode use
     (Halt  => 16#00#, Load  => 16#10#, Store => 16#20#,
      Add   => 16#30#, Sub   => 16#31#, Jump  => 16#F0#);

   -- --------------------------------------------------------
   -- 21.5 字节序：地址覆盖（同一地址两种视图）
   -- --------------------------------------------------------
   type Byte_Array is array (0 .. 3) of Unsigned_8;

   -- --------------------------------------------------------
   -- 21.6 存储池配额：给访问类型限粮（老教材 STORAGE_SIZE 长度子句）
   -- --------------------------------------------------------
   type Node is
      record
         A, B : Integer;
      end record;                          -- 8 字节

   type Node_Ptr is access Node;
   for Node_Ptr'Storage_Size use 24;       -- 只给 3 个节点的量

begin
   Put_Line ("=== Ada 低级程序设计示例 ===");
   New_Line;

   -- 1. Size 与 Pack：压缩表示
   Put_Line ("--- 1. Size 与 Pack ---");
   declare
      type Small is range 0 .. 15 with Size => 4;
      type Packed_Bits is array (1 .. 16) of Boolean with Pack;
      type Rec_Normal is
         record
            Flag : Boolean;
            Val  : Integer;
         end record;
      type Rec_Packed is
         record
            Flag : Boolean;
            Val  : Integer;
         end record
         with Pack;
   begin
      Put_Line ("  Small (0..15, Size=>4): Size ="
                & Integer'Image (Small'Size) & " 位");
      Put_Line ("  16 个 Boolean 打包: Size ="
                & Integer'Image (Packed_Bits'Size) & " 位 (未打包则 16x8)");
      Put_Line ("  普通记录 Boolean+Integer: Size ="
                & Integer'Image (Rec_Normal'Size) & " 位");
      Put_Line ("  打包记录 Pack:           Size ="
                & Integer'Image (Rec_Packed'Size) & " 位");
   end;

   -- 2. 记录表示子句：位级布局验证
   New_Line;
   Put_Line ("--- 2. 记录表示子句（寄存器布局） ---");
   declare
      package U16_IO is new Ada.Text_IO.Modular_IO (U16);
      use U16_IO;
      R : CSR := (Enable  => True,
                  Mode    => 2,
                  Channel => 16#15#,
                  Error   => False);
   begin
      Put_Line ("  CSR'Size = " & Integer'Image (CSR'Size) & " 位");
      Put ("  Enable=True Mode=2 Channel=16#15#  =>  位模式 = ");
      Put (To_U16 (R), Base => 16, Width => 6);
      Put_Line ("   （位 0 起小端编号: 1 + 2*2 + 16#15#*8 = 173）");
      Put ("  反向转换 173 => ");
      declare
         Back : constant CSR := To_CSR (173);
      begin
         Put_Line ("Enable=" & Boolean'Image (Back.Enable)
                   & ", Mode=" & Bits_2'Image (Back.Mode)
                   & ", Channel=" & Bits_6'Image (Back.Channel));
      end;
   end;

   -- 3. 枚举表示子句：'Pos 与 'Enum_Rep 的分野
   New_Line;
   Put_Line ("--- 3. 枚举表示子句 ---");
   Put_Line ("  字面量   Pos  Enum_Rep");
   for Op in Opcode loop
      Put ("  " & Opcode'Image (Op));
      Put (Opcode'Pos (Op), Width => 5);
      Put (Integer (Opcode'Enum_Rep (Op)), Width => 6);
      New_Line;
   end loop;
   Put_Line ("  'Enum_Val (16#31#) = " & Opcode'Image
               (Opcode'Enum_Val (16#31#)));

   -- 4. 地址覆盖：同一块内存的两种视图（验证字节序）
   New_Line;
   Put_Line ("--- 4. 地址覆盖与字节序 ---");
   declare
      I : aliased Integer := 16#1234_5678#;
      B : Byte_Array with Address => I'Address, Import;   -- 覆盖在 I 上
   begin
      Put ("  Integer 16#1234_5678# 的字节序: ");
      for K in B'Range loop
         Put (Unsigned_8'Image (B (K)) & " ");
      end loop;
      New_Line;
      Put_Line ("  (本机 x86-64 为小端：低字节 16#78# 存在低地址)");
      B (0) := 16#00#;                    -- 改一个字节
      Put_Line ("  改 B(0)=0 后 I ="
                & Integer'Image (I) & " = 16#1234_5600#");
   end;

   -- 5. System 常量：机器的"身份证"
   New_Line;
   Put_Line ("--- 5. System 常量 ---");
   Put_Line ("  Storage_Unit       = "
             & Integer'Image (System.Storage_Unit) & " 位/存储单元");
   Put_Line ("  Word_Size          = "
             & Integer'Image (System.Word_Size) & " 位/字");
   Put_Line ("  Default_Bit_Order  = "
             & System.Bit_Order'Image (System.Default_Bit_Order));
   Put_Line ("  Max_Integer_Size   = "
             & Integer'Image (Standard'Max_Integer_Size)
             & " 位（System.Min_Int/Max_Int 即按此宽度定义，");
   Put_Line ("  属 128 位 universal 常量，不能直接塞进 64 位 Integer）");

   -- 6. 存储池配额：Storage_Error 兜底
   New_Line;
   Put_Line ("--- 6. 访问类型存储池配额 ---");
   declare
      Ptrs    : array (1 .. 8) of Node_Ptr;
      Allocated : Natural := 0;
   begin
      Put_Line ("  Node_Ptr'Storage_Size = "
                & Integer'Image (Node_Ptr'Storage_Size) & " 字节"
                & "（Node 本体 8 字节 x 3）");
      for K in Ptrs'Range loop
         Ptrs (K) := new Node'(A => K, B => 0);
         Allocated := K;
      end loop;
      Put_Line ("  全部装下（未触顶）: " & Integer'Image (Allocated));
   exception
      when Storage_Error =>
         Put_Line ("  装到第 " & Integer'Image (Allocated + 1)
                   & " 个触发 Storage_Error —— 池满了");
   end;
end Ch21_Lowlevel;
