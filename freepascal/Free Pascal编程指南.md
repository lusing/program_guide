# Free Pascal 编程教程

Free Pascal（FPC）是一种现代、跨平台的 Pascal 实现。它继承了 Pascal 的结构化设计思想，同时支持过程式编程、面向对象编程以及丰富的运行库。

本教程的目标是帮助读者在本地工具链中快速建立起 Pascal 代码的编写与验证能力，并把示例整理为独立文件，以便逐步练习。

## 1. Pascal 与 Free Pascal 简介

Pascal 是一种强调清晰结构和强类型语法的语言，最早由 Niklaus Wirth 设计。Free Pascal 则把它扩展为更现代的编程语言，适合：

- 命令行工具开发
- 学习算法和数据结构
- 面向对象编程
- 经典教学场景
- 跨平台编译

## 2. 编译与运行模型

Free Pascal 使用最常见的编译流程：

```powershell
G:\scoop\apps\freepascal\current\bin\i386-win32\fpc.exe -MObjFPC -Sc hello.pas
```

编译后，会生成可执行文件。通常可以直接运行：

```powershell
.\hello.exe
```

本仓库中的 `build.ps1` 会自动完成这一过程，并对每个示例执行最小运行验证。

## 3. 基础语法：程序结构

最小 Pascal 程序如下：

```pascal
program Hello;

begin
  WriteLn('Hello, Free Pascal!');
end.
```

关键点：

- `program` 语句声明程序名
- `begin ... end.` 代表程序体
- `WriteLn` 输出文本
- `.` 是程序结束符

## 4. 变量、类型与算术

Pascal 中变量需要先声明：

```pascal
var
  a, b, c: Integer;
  name: String;
begin
  a := 10;
  b := 20;
  c := a + b;
  name := 'guide';
  WriteLn(name, ' = ', c);
end.
```

常见类型包括：

- Integer
- Real
- Boolean
- Char
- String
- Array
- Record

## 5. 条件分支与选择结构

Pascal 中使用 `if`、`case` 来进行分支处理：

```pascal
if score >= 90 then
  WriteLn('A')
else if score >= 80 then
  WriteLn('B')
else
  WriteLn('C');
```

`case` 更适合对离散值进行判断：

```pascal
case ch of
  'a': WriteLn('A');
  'b': WriteLn('B');
  else WriteLn('Other');
end;
```

## 6. 循环结构

常见循环包括：

- `for ... to ... do`
- `for ... downto ... do`
- `while ... do`
- `repeat ... until`

例如：

```pascal
for i := 1 to 5 do
  WriteLn(i);
```

## 7. 过程、函数与模块化

Pascal 非常适合结构化拆分：

```pascal
procedure PrintMessage(msg: String);
begin
  WriteLn(msg);
end;

function Square(x: Integer): Integer;
begin
  Square := x * x;
end;
```

模块化思维在 Pascal 中尤其重要，因为它天然鼓励清晰的程序结构。

## 8. Array、Record 与集合

数组和记录是数据组织的基本手段：

```pascal
type
  TPoint = record
    X, Y: Integer;
  end;

var p: TPoint;
begin
  p.X := 3;
  p.Y := 4;
  WriteLn(p.X, ',', p.Y);
end.
```

数组则用于同类元素的批量处理：

```pascal
var nums: array[0..4] of Integer;
```

## 9. 字符串、集合与指针

Free Pascal 同样支持：

- 字符串拼接
- 字符索引访问
- 集合类型
- 指针和动态分配

例如：

```pascal
var p: ^Integer;
New(p);
p^ := 42;
WriteLn(p^);
Dispose(p);
```

## 10. 文件 I/O 与数据保存

基础的文件读写非常适合学习：

```pascal
var f: TextFile;
begin
  AssignFile(f, 'demo.txt');
  Rewrite(f);
  WriteLn(f, 'hello from Pascal');
  CloseFile(f);
end.
```

这样可以帮助读者理解程序与外部数据的交互。

## 11. 面向对象编程

Free Pascal 完整支持类和对象：

```pascal
type
  TPerson = class
  private
    FName: String;
  public
    constructor Create(name: String);
    procedure Show;
  end;
```

这一部分让学生对传统 Pascal 和面向对象范式之间的衔接更加容易理解。

## 12. 学习路径建议

建议按下面顺序学习：

1. 程序结构和输出
2. 变量与基本类型
3. 条件判断和循环
4. 过程/函数
5. 数组/记录
6. 文件 I/O
7. 指针与动态内存
8. 类与面向对象编程

## 13. 本目录示例清单

本目录中的示例文件都已保存到 `examples/` 下，并经过本地 Free Pascal 编译器验证。

- `01_hello.pas`：Hello World
- `02_variables.pas`：变量声明与赋值
- `03_arithmetic.pas`：算术运算
- `04_if_case.pas`：if 与 case
- `05_loops.pas`：循环控制
- `06_procedures.pas`：过程与函数
- `07_records.pas`：record 结构
- `08_arrays.pas`：数组处理
- `09_strings_sets.pas`：字符串与集合
- `10_pointers.pas`：指针和动态分配
- `11_file_io.pas`：文件读写
- `12_classes.pas`：类与对象

## 14. 本地验证方式

在当前环境中，编译器位于：

```text
G:\scoop\apps\freepascal\current\bin\i386-win32\fpc.exe
```

可直接执行：

```powershell
cd G:\code\guide\freepascal
.\build.ps1 -All
```

本仓库统一采用“编译 + 运行”的方式验证示例，确保每个例子都是真实可执行的。

## 15. 使用 Lazarus 的建议

Lazarus 是 Free Pascal 的 IDE，适合开发 GUI 应用和面向组件的桌面程序：

- 窗口设计器
- 组件属性面板
- 事件处理习惯
- 更适合教学与桌面应用原型

但本教程仍以 Free Pascal 语法和命令行验证为主，便于在任何环境下复现和学习。
