# 13 · 文件 I/O

> 示例：[`examples/ch13_fileio.adb`](../examples/ch13_fileio.adb)
> 运行：`./run-all.sh 13`

## 13.1 写入文件

```ada
Create (File, Out_File, "test_output.txt");
Put_Line (File, "Hello, 这是写入文件的第一行.");
Close (File);
```

## 13.2 读取文件

```ada
Open (File, In_File, "test_output.txt");
while not End_Of_File (File) loop
   Get_Line (File, Line, Last);
   Put_Line (Line (1 .. Last));
end loop;
Close (File);
```

## 13.3 追加写入

```ada
Open (File, Append_File, "test_output.txt");
Put_Line (File, "这是追加的一行.");
Close (File);
```

## 13.4 文件模式

| 模式 | 说明 |
|------|------|
| `In_File` | 只读 |
| `Out_File` | 写入（覆盖） |
| `Append_File` | 追加写入 |

---
上一章：[12 Tasking](12-tasking.md) ｜ 下一章：[14 C 互操作](14-c-interop.md) ｜ 返回：[README](../README.md)

