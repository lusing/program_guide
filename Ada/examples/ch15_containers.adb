-- ============================================================
-- 第15章：标准容器库 (Ada Containers)
-- ============================================================
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Containers.Vectors;
with Ada.Containers.Doubly_Linked_Lists;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Containers.Ordered_Sets;
with Ada.Strings.Hash;

procedure Ch15_Containers is

   -- 实例化 Vector 容器
   package Int_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Integer);

   -- 实例化双向链表
   package Int_Lists is new Ada.Containers.Doubly_Linked_Lists
     (Element_Type => Integer);

   -- 实例化 Map (字符串 -> 整数) - 使用 Indefinite_Hashed_Maps 支持不定长键
   package String_Int_Maps is new Ada.Containers.Indefinite_Hashed_Maps
     (Key_Type        => String,
      Element_Type    => Integer,
      Hash            => Ada.Strings.Hash,
      Equivalent_Keys => "=");

   -- 实例化有序集合
   package Int_Sets is new Ada.Containers.Ordered_Sets
     (Element_Type => Integer);

begin
   Put_Line ("=== Ada 标准容器库示例 ===");
   New_Line;

   -- 1. Vector (动态数组)
   Put_Line ("--- 1. Vector (动态数组) ---");
   declare
      V : Int_Vectors.Vector;
   begin
      V.Append (10);
      V.Append (20);
      V.Append (30);
      V.Prepend (5);

      Put ("  Vector 内容: ");
      for I in V.First_Index .. V.Last_Index loop
         Put (V(I), Width => 0);
         if I < V.Last_Index then Put (", "); end if;
      end loop;
      New_Line;
      Put_Line ("  Length: " & Integer'Image(Integer(V.Length)));
      Put_Line ("  First element: " & Integer'Image(V.First_Element));
      Put_Line ("  Last element: " & Integer'Image(V.Last_Element));
   end;

   -- 2. Doubly_Linked_List (双向链表)
   New_Line;
   Put_Line ("--- 2. Doubly_Linked_List (双向链表) ---");
   declare
      L : Int_Lists.List;
   begin
      L.Append (100);
      L.Append (200);
      L.Prepend (50);

      Put ("  List 内容: ");
      for E of L loop
         Put (E, Width => 0);
         Put (" ");
      end loop;
      New_Line;
      Put_Line ("  Length: " & Integer'Image(Integer(L.Length)));
      Put_Line ("  Contains 100: " & Boolean'Image(L.Contains(100)));
      Put_Line ("  Contains 999: " & Boolean'Image(L.Contains(999)));
   end;

   -- 3. Hashed_Map (哈希表)
   New_Line;
   Put_Line ("--- 3. Hashed_Map (哈希表) ---");
   declare
      M : String_Int_Maps.Map;
   begin
      M.Insert ("Alice", 25);
      M.Insert ("Bob", 30);
      M.Insert ("Charlie", 35);

      Put_Line ("  Alice: " & Integer'Image(M("Alice")));
      Put_Line ("  Bob: " & Integer'Image(M("Bob")));
      Put_Line ("  Charlie: " & Integer'Image(M("Charlie")));
      Put_Line ("  Size: " & Integer'Image(Integer(M.Length)));
      Put_Line ("  Contains 'Alice': " & Boolean'Image(M.Contains("Alice")));
      Put_Line ("  Contains 'David': " & Boolean'Image(M.Contains("David")));
   end;

   -- 4. Ordered_Set (有序集合)
   New_Line;
   Put_Line ("--- 4. Ordered_Set (有序集合) ---");
   declare
      S : Int_Sets.Set;
   begin
      S.Insert (5);
      S.Insert (3);
      S.Insert (8);
      S.Insert (1);

      Put ("  Set 内容: ");
      for E of S loop
         Put (E, Width => 0);
         Put (" ");
      end loop;
      New_Line;
      Put_Line ("  Size: " & Integer'Image(Integer(S.Length)));
      Put_Line ("  Contains 3: " & Boolean'Image(S.Contains(3)));
      Put_Line ("  Contains 10: " & Boolean'Image(S.Contains(10)));
   end;
end Ch15_Containers;