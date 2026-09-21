# 14 · 与 C 语言互操作

> 示例：[`examples/ch14_c_interop.adb`](../examples/ch14_c_interop.adb)
> 运行：`./run-all.sh 14`（Linux 需 `-largs -lm`，脚本已内置）

## 14.1 导入 C 函数

```ada
function C_Sqrt (X : Float) return Float
   with Import, Convention => C, External_Name => "sqrtf";

function C_Abs (X : Integer) return Integer
   with Import, Convention => C, External_Name => "abs";
```

## 14.2 导出 Ada 函数

```ada
function Ada_Add (A, B : Integer) return Integer
   with Export, Convention => C, External_Name => "ada_add";
```

## 14.3 C 兼容类型

```ada
type C_Int is range -(2 ** 31) .. (2 ** 31 - 1) with Size => 32;
pragma Convention (C, C_Int);

type C_Point is record
   X : C_Int;
   Y : C_Int;
end record;
pragma Convention (C, C_Point);
```

## 14.4 Interfaces.C 包

```ada
with Interfaces.C;
with Interfaces.C.Strings;
-- 提供: int, unsigned, size_t, char_array, chars_ptr, To_C, To_Ada 等
```

## 14.5 编译与运行（注意 Linux 的 libm）

```powershell
# Windows：UCRT 已把数学函数并入主 C 运行时，直接编译即可
gnatmake -o examples\ch14_c_interop.exe examples\ch14_c_interop.adb
.\examples\ch14_c_interop.exe
```

```bash
# Linux / macOS：sqrtf 位于独立的数学库 libm，必须附加 -largs -lm
gnatmake -o ch14_c_interop examples/ch14_c_interop.adb -largs -lm
./ch14_c_interop
```

> **平台差异提示**：`sqrtf` 在 Windows UCRT 中随主 C 运行时提供，而 glibc 把它放在
> 独立的 `libm.so` 里。GNU 链接器默认不链接 libm，因此 Linux 下必须显式加
> `-largs -lm`（`-largs` 之后的参数全部传给链接器，且必须放在命令行末尾）。

---
上一章：[13 文件 I/O](13-file-io.md) ｜ 下一章：[15 容器](15-containers.md) ｜ 返回：[README](../README.md)

