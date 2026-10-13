-- ============================================================
-- 第23章：标准容器库 (Ada.Containers)
--   —— Vector / Doubly_Linked_List / Hashed_Map /
--      Ordered_Set：值遍历、游标遍历、泛型实例化
--      （老教材通用堆栈/集合思想的标准库化）
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Containers.Vectors;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Containers.Ordered_Sets;
with Ada.Strings.Hash;

procedure Ch23_Containers is

   -- 容器都是泛型：先实例化（第 12 章的知识在这里兑现）
   package Int_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Integer);

   package Int_Lists is new Ada.Containers.Doubly_Linked_Lists
     (Element_Type => Integer);

   package String_Int_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type        => String,
      Element_Type    => Integer,
      Hash            => Ada.Strings.Hash,
      Equivalent_Keys => "=");

   package Int_Sets is new Ada.Containers.Ordered_Sets
     (Element_Type => Integer);

begin
   Put_Line ("=== Ada 标准容器库 ===");
   New_Line;

   -- ---------------------------
   -- 1. Vector：动态数组（尾部 O(1) 追加）
   -- ---------------------------
   Put_Line ("--- 1. Vector ---");
   declare
      V : Int_Vectors.Vector;
   begin
      V.Append (10);
      V.Append (30);
      V.Append (40);
      V.Insert (Before => 2, New_Item => 20);   -- 中间插入
      V.Prepend (5);                            -- 头部插入

      Put ("  内容 (for of 值遍历): ");
      for E of V loop                           -- 值遍历：Ada 2012
         Put (E, Width => 0);
         Put (" ");
      end loop;
      New_Line;

      Put ("  游标遍历（带下标）  : ");
      for C in V.Iterate loop                   -- 游标遍历：能查位置
         Put (Int_Vectors.Element (C), Width => 0);
         Put ("@");
         Put (Int_Vectors.To_Index (C), Width => 0);
         Put (" ");
      end loop;
      New_Line;

      V.Delete_Last;                            -- 删除尾部
      Put_Line ("  Delete_Last 后 Length ="
                & Integer'Image (Integer (V.Length)));
      Put_Line ("  First/Last ="
                & Integer'Image (V.First_Element) & "/"
                & Integer'Image (V.Last_Element));
   end;

   -- ---------------------------
   -- 2. Doubly_Linked_List：双向链表（两端 O(1)）
   -- ---------------------------
   New_Line;
   Put_Line ("--- 2. Doubly_Linked_List ---");
   declare
      L : Int_Lists.List;
   begin
      L.Append (100);
      L.Append (200);
      L.Prepend (50);                           -- 链表头部也是 O(1)
      L.Append (300);

      Put ("  正向: ");
      for E of L loop
         Put (E, Width => 0);
         Put (" ");
      end loop;
      New_Line;

      Put ("  逆向: ");
      for C in reverse L.Iterate loop           -- 链表的天然强项
         Put (Int_Lists.Element (C), Width => 0);
         Put (" ");
      end loop;
      New_Line;

      Put_Line ("  Contains 200 :" & Boolean'Image (L.Contains (200)));
      declare
         -- Delete 的游标参数是 in out：必须先存进变量
         Pos : Int_Lists.Cursor := L.Find (200);
      begin
         L.Delete (Pos);                        -- 删除后 Pos 变 No_Element
      end;
      Put_Line ("  Delete (Find (200)) 后 Contains 200 :"
                & Boolean'Image (L.Contains (200)));
   end;

   -- ---------------------------
   -- 3. Hashed_Map：键 → 值（平均 O(1)）
   -- ---------------------------
   New_Line;
   Put_Line ("--- 3. Hashed_Map ---");
   declare
      M : String_Int_Maps.Map;
      C : String_Int_Maps.Cursor;
   begin
      M.Insert ("Alice", 25);
      M.Insert ("Bob", 30);
      M.Insert ("Carol", 35);

      Put_Line ("  M (""Bob"") = " & Integer'Image (M ("Bob")));
      Put_Line ("  Contains ""Dan"" : " & Boolean'Image (M.Contains ("Dan")));

      M.Include ("Bob", 31);                    -- 键存在则覆盖
      Put_Line ("  Include (""Bob"", 31) 后 M (""Bob"") ="
                & Integer'Image (M ("Bob")));

      Put_Line ("  游标遍历（哈希序，与插入序无关）:");
      C := M.First;
      while String_Int_Maps.Has_Element (C) loop
         Put_Line ("    " & String_Int_Maps.Key (C) & " → "
                   & Integer'Image (String_Int_Maps.Element (C)));
         String_Int_Maps.Next (C);
      end loop;
   end;

   -- ---------------------------
   -- 4. Ordered_Set：有序集合（遍历即有序）
   -- ---------------------------
   New_Line;
   Put_Line ("--- 4. Ordered_Set ---");
   declare
      S : Int_Sets.Set;
   begin
      S.Insert (5);
      S.Insert (3);
      S.Insert (8);
      S.Insert (1);
      -- 注意：Insert 重复元素会引发 Constraint_Error！
      -- Include 才是"键在则替代、不在则插入"的宽容版本
      S.Include (3);                            -- 已在集合中：静默无事

      Put ("  插入 5,3,8,1 + Include (3) 后（有序去重）: ");
      for E of S loop                           -- 遍历顺序 = 升序
         Put (E, Width => 0);
         Put (" ");
      end loop;
      New_Line;

      Put_Line ("  Length =" & Integer'Image (Integer (S.Length))
                & "（3 只算一次）");
      declare
         Lower : constant Int_Sets.Cursor := S.Ceiling (4);
      begin
         Put_Line ("  Ceiling (4) ="
                   & Integer'Image (Int_Sets.Element (Lower))
                   & "（第一个 >= 4 的元素）");
      end;
   end;

   New_Line;
   Put_Line ("  这些容器正是老教材泛型栈 STACK_G/集合思想的");
   Put_Line ("  标准库化：实例化一次，得到一整套经过验证的操作。");
end Ch23_Containers;
