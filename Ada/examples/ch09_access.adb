-- ============================================================
-- 第9章：访问类型 (Access Types)
-- 动态分配、链表、二叉查找树、手动回收与访问子程序
-- ============================================================
with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Unchecked_Deallocation;

procedure Ch09_Access is

   -- --------------------------------------------------------
   -- 9.1 单链表：不完整类型说明 + access 类型（老教材 ITEM 例）
   -- --------------------------------------------------------
   type Node;                      -- 不完整类型说明（前向引用）
   type Node_Ptr is access Node;   -- 指向 Node 的访问类型

   type Node is
      record
         Name : String (1 .. 6);
         Next : Node_Ptr;          -- 隐含初值 null
      end record;

   -- 手动回收：实例化泛型 Unchecked_Deallocation
   procedure Free is new Ada.Unchecked_Deallocation
     (Object => Node, Name => Node_Ptr);

   -- 尾插法建表（老教材 BUILD_LIST 的现代化版本）
   procedure Append (Head, Tail : in out Node_Ptr; Name : String) is
      Temp : constant Node_Ptr :=
        new Node'(Name (Name'First .. Name'First + 5), null);
   begin
      if Head = null then
         Head := Temp;
      else
         Tail.Next := Temp;        -- Tail.all.Next 的简写
      end if;
      Tail := Temp;
   end Append;

   procedure Print_List (Head : Node_Ptr) is
      P : Node_Ptr := Head;
   begin
      while P /= null loop
         Put ("  [" & P.Name & "]");
         if P.Next /= null then
            Put (" -> ");
         end if;
         P := P.Next;              -- 沿链接前进
      end loop;
      New_Line;
   end Print_List;

   procedure Free_List (Head : in out Node_Ptr) is
      P : Node_Ptr := Head;
   begin
      while P /= null loop
         declare
            Next : constant Node_Ptr := P.Next;
         begin
            Free (P);              -- P 变为 null
            P := Next;
         end;
      end loop;
      Head := null;
   end Free_List;

   -- --------------------------------------------------------
   -- 9.4 二叉查找树（刘炳文《程序设计语言 Ada》树一节）
   -- --------------------------------------------------------
   type Tree;
   type Tree_Ptr is access Tree;

   type Tree is
      record
         Value : Integer;
         Left  : Tree_Ptr;
         Right : Tree_Ptr;
      end record;

   procedure Insert (T : in out Tree_Ptr; V : Integer) is
   begin
      if T = null then
         T := new Tree'(Value => V, Left => null, Right => null);
      elsif V < T.Value then
         Insert (T.Left, V);
      elsif V > T.Value then
         Insert (T.Right, V);
      end if;                      -- 相等则忽略（集合语义）
   end Insert;

   procedure Inorder (T : Tree_Ptr) is
   begin
      if T /= null then
         Inorder (T.Left);
         Put (Integer'Image (T.Value) & " ");
         Inorder (T.Right);
      end if;
   end Inorder;

   procedure Free_Tree (T : in out Tree_Ptr) is
   begin
      if T /= null then
         Free_Tree (T.Left);
         Free_Tree (T.Right);
         declare
            procedure Kill is new Ada.Unchecked_Deallocation
              (Object => Tree, Name => Tree_Ptr);
         begin
            Kill (T);
         end;
      end if;
   end Free_Tree;

   -- --------------------------------------------------------
   -- 9.5 访问子程序：函数指针
   -- --------------------------------------------------------
   type Binary_Op is access function (L, R : Integer) return Integer;

   function Add (L, R : Integer) return Integer is (L + R);
   function Mul (L, R : Integer) return Integer is (L * R);

   -- --------------------------------------------------------
   -- 9.6 一般访问类型：access all + 'Access 别名
   --    （类型与对象必须同级声明，否则可访问性规则拒绝）
   -- --------------------------------------------------------

begin
   Put_Line ("=== Ada 访问类型示例 ===");
   New_Line;

   -- 1. new / null / .all 基本面
   Put_Line ("--- 1. 分配符 new 与解引用 .all ---");
   declare
      P  : Node_Ptr;                       -- 初值 null
      Q  : Node_Ptr;
   begin
      Put_Line ("  未初始化的访问对象 = null: "
                & Boolean'Image (P = null));
      P := new Node'("GEORGE", null);      -- 分配 + 聚集初始化
      Q := P;                              -- P、Q 指向同一对象
      Q.Name := "RUPERT";                  -- 经 Q 改
      Put_Line ("  经 Q 改名后 P.Name = " & P.Name
                & "  (P、Q 是同一对象)");
      P.all := ("ALICE ", null);           -- .all：整对象赋值
      Put_Line ("  P.all 整体赋值后 P.Name = " & P.Name);
      Free (P);                            -- 手动回收
      Q := null;                           -- Q 已悬空，置空防误用
      Put_Line ("  Free 后 P = null: " & Boolean'Image (P = null));
   end;

   -- 2. 建表、遍历、"首项移到尾部"（老教材原题）
   New_Line;
   Put_Line ("--- 2. 单链表：建表与重排 ---");
   declare
      Head, Tail : Node_Ptr := null;
   begin
      Append (Head, Tail, "GEORGE");
      Append (Head, Tail, "FRED  ");
      Append (Head, Tail, "RITA  ");
      Put ("  原表:   ");
      Print_List (Head);

      -- 把第一项移到表尾：三条指针操作，零数据复制
      declare
         Temp : constant Node_Ptr := Head;
      begin
         Head       := Head.Next;
         Temp.Next  := null;
         Tail.Next  := Temp;
         Tail       := Temp;
      end;
      Put ("  重排后: ");
      Print_List (Head);
      Free_List (Head);
      Put_Line ("  回收后 Head = null: "
                & Boolean'Image (Head = null));
   end;

   -- 3. 访问判别记录：new 时钉死判别式
   New_Line;
   Put_Line ("--- 3. new 判别记录：分配即定形 ---");
   declare
      type Kind is (Car, Van);
      type Vehicle (K : Kind := Car) is
         record
            Serial : Positive;
            case K is
               when Car  => Doors : Positive;
               when Van  => Load  : Natural;
            end case;
         end record;
      type V_Ptr is access Vehicle;
      type VC_Ptr is access Vehicle (K => Van);  -- 受约束访问类型
      C : V_Ptr := new Vehicle'(K      => Car,
                                Serial => 101,
                                Doors  => 4);
      V : V_Ptr := new Vehicle'(K      => Van,
                                Serial => 102,
                                Load   => 5);
      W : VC_Ptr := new Vehicle'(K => Van, Serial => 103, Load => 8);
   begin
      Put_Line ("  C: " & Kind'Image (C.K) & ", "
                & Positive'Image (C.Doors) & " 门");
      Put_Line ("  V: " & Kind'Image (V.K) & ", 载重"
                & Integer'Image (V.Load) & " t");
      C := V;                     -- V_Ptr 无约束：可改指 Van 对象
      Put_Line ("  C 改指 V 后: " & Kind'Image (C.K));
      -- W := C;                  -- 编译错误：C 可能指 Car 对象
      Put_Line ("  W(受约束访问类型): " & Kind'Image (W.K));
   end;

   -- 4. 二叉查找树：插入 + 中序遍历 = 有序输出
   New_Line;
   Put_Line ("--- 4. 二叉查找树 ---");
   declare
      Root   : Tree_Ptr := null;
      Values : constant array (1 .. 7) of Integer :=
                 (50, 30, 70, 20, 40, 60, 80);
   begin
      for V of Values loop
         Insert (Root, V);
      end loop;
      Put ("  中序遍历: ");
      Inorder (Root);
      New_Line;
      Free_Tree (Root);
      Put_Line ("  回收后 Root = null: "
                & Boolean'Image (Root = null));
   end;

   -- 5. 访问子程序
   New_Line;
   Put_Line ("--- 5. 访问子程序（函数指针） ---");
   declare
      Ops : array (1 .. 2) of Binary_Op := (Add'Access, Mul'Access);
   begin
      for I in Ops'Range loop
         Put_Line ("  Op(" & Integer'Image (I) & ")(6, 7) = "
                   & Integer'Image (Ops (I) (6, 7)));
      end loop;
   end;

   -- 6. access all + 'Access：指向静态对象的别名
   New_Line;
   Put_Line ("--- 6. access all 与 'Access ---");
   declare
      type Int_Access is access all Integer;
      X : aliased Integer := 5;      -- aliased：允许取访问值
      P : Int_Access := X'Access;    -- 指向已存在对象（非堆）
   begin
      Put_Line ("  X =" & Integer'Image (X));
      P.all := 42;                   -- 经别名改静态对象
      Put_Line ("  P.all := 42 后 X =" & Integer'Image (X));
   end;
end Ch09_Access;
