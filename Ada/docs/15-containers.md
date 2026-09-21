# 15 · 标准容器库

> 示例：[`examples/ch15_containers.adb`](../examples/ch15_containers.adb)
> 运行：`./run-all.sh 15`

## 15.1 Vector（动态数组）

```ada
package Int_Vectors is new Ada.Containers.Vectors
  (Index_Type => Positive, Element_Type => Integer);

V : Int_Vectors.Vector;
V.Append (10);
V.Prepend (5);
for I in V.First_Index .. V.Last_Index loop
   Put (V(I), Width => 0);
end loop;
```

## 15.2 Doubly_Linked_List（双向链表）

```ada
package Int_Lists is new Ada.Containers.Doubly_Linked_Lists
  (Element_Type => Integer);

L : Int_Lists.List;
L.Append (100);
for E of L loop
   Put (E, Width => 0);
end loop;
```

## 15.3 Hashed_Map（哈希表）

```ada
package String_Int_Maps is new Ada.Containers.Indefinite_Hashed_Maps
  (Key_Type => String, Element_Type => Integer,
   Hash => Ada.Strings.Hash, Equivalent_Keys => "=");

M : String_Int_Maps.Map;
M.Insert ("Alice", 25);
Put_Line (Integer'Image(M("Alice")));
```

## 15.4 Ordered_Set（有序集合）

```ada
package Int_Sets is new Ada.Containers.Ordered_Sets
  (Element_Type => Integer);

S : Int_Sets.Set;
S.Insert (5);
S.Insert (3);
S.Insert (8);
```

---
上一章：[14 C 互操作](14-c-interop.md) ｜ 下一章：[16 受保护对象](16-protected-objects.md) ｜ 返回：[README](../README.md)

