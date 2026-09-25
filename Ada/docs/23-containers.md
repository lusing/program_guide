# 23 · 标准容器库

> 示例：[`examples/ch23_containers.adb`](../examples/ch23_containers.adb)
> 运行：`./run-all.sh 15`

## 23.1 Vector（动态数组）

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

## 23.2 Doubly_Linked_List（双向链表）

```ada
package Int_Lists is new Ada.Containers.Doubly_Linked_Lists
  (Element_Type => Integer);

L : Int_Lists.List;
L.Append (100);
for E of L loop
   Put (E, Width => 0);
end loop;
```

## 23.3 Hashed_Map（哈希表）

```ada
package String_Int_Maps is new Ada.Containers.Indefinite_Hashed_Maps
  (Key_Type => String, Element_Type => Integer,
   Hash => Ada.Strings.Hash, Equivalent_Keys => "=");

M : String_Int_Maps.Map;
M.Insert ("Alice", 25);
Put_Line (Integer'Image(M("Alice")));
```

## 23.4 Ordered_Set（有序集合）

```ada
package Int_Sets is new Ada.Containers.Ordered_Sets
  (Element_Type => Integer);

S : Int_Sets.Set;
S.Insert (5);
S.Insert (3);
S.Insert (8);
```

---
上一章：[22 定点与十进制实数](22-fixed-point.md) ｜ 下一章：[24 契约](24-contracts.md) ｜ 返回：[README](../README.md)

