# 18 · 文件 I/O

> 示例：[`examples/ch18_fileio.adb`](../examples/ch18_fileio.adb)
> 运行：`./run-all.sh 13`

## 18.1 写入文件

```ada
Create (File, Out_File, "test_output.txt");
Put_Line (File, "Hello, 这是写入文件的第一行.");
Close (File);
```

## 18.2 读取文件

```ada
Open (File, In_File, "test_output.txt");
while not End_Of_File (File) loop
   Get_Line (File, Line, Last);
   Put_Line (Line (1 .. Last));
end loop;
Close (File);
```

## 18.3 追加写入

```ada
Open (File, Append_File, "test_output.txt");
Put_Line (File, "这是追加的一行.");
Close (File);
```

## 18.4 文件模式

| 模式 | 说明 |
|------|------|
| `In_File` | 只读 |
| `Out_File` | 写入（覆盖） |
| `Append_File` | 追加写入 |

---
上一章：[17 任务深入](17-select-family.md) ｜ 下一章：[19 文件 I/O 全景](19-file-io-full.md) ｜ 返回：[README](../README.md)

