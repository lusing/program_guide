# Fortran 编程指南

一份面向「会写别的语言，但没写过 Fortran」的人的教程。全书 32 章，配 31 个可运行示例（28 个现代 `.f90` + 3 个 FORTRAN 77 风格的固定格式 `.f`），每个示例都在 **LLVM flang 23** 和 **GNU Fortran 15** 两个编译器上实测通过。

学完你会明白：现代 Fortran 不是「老古董」，它是一门**为数值计算而生、但已经长出模块系统和面向对象**的语言。它所有看起来奇怪的地方 —— 列主序、1 起下标、传引用、`implicit none` 必须写、数组整体运算 —— 都是同一个前提的推论：**让科学家写的公式，能几乎一对一地敲进代码**。

> 本指南里所有的「实测」「报错」「差异」都不是从文档抄的，是在本机两个编译器上真的撞出来的。第 31、32 章是完整的坑清单。

---

## 目录

1. [语言概览：Fortran 到底在干什么](01-overview.md)
2. [工具链与运行方式](02-toolchain.md)
3. [算法与程序设计方法](03-methodology.md)
4. [程序结构、类型与 KIND](04-program-kinds.md)
5. [表达式、运算符与数值陷阱](05-expressions.md)
6. [控制流](06-control-flow.md)
7. [数组（一）：声明、构造、切片](07-arrays-basics.md)
8. [数组（二）：内建函数](08-arrays-intrinsics.md)
9. [数组在内存里的样子：存储顺序与隐 DO 循环](09-memory-layout.md)
10. [字符与字符串](10-strings.md)
11. [格式化 I/O：输出](11-formatted-output.md)
12. [格式化输入](12-formatted-input.md)
13. [文件与流 I/O](13-files.md)
14. [过程：子程序、函数与参数传递](14-procedures.md)
15. [模块、接口与模块目录](15-modules.md)
16. [派生类型](16-derived-types.md)
17. [面向对象与多态](17-oop.md)
18. [指针与可分配变量](18-pointers.md)
19. [老特性考古 II：DATA、语句函数与 alternate return](19-obsolescent.md)
20. [泛型、重载与 submodule](20-generics.md)
21. [经典算法](21-algorithms.md)
22. [数值计算](22-numeric.md)
23. [线性方程组专题：Gauss-Jordan 与矩阵求逆](23-gauss-jordan.md)
24. [常微分方程数值解](24-ode.md)
25. [随机数与统计](25-random.md)
26. [C 互操作](26-c-interop.md)
27. [并行计算：OpenMP 与 do concurrent](27-parallel.md)
28. [调试与查错方法](28-debugging.md)
29. [错误处理与单元测试](29-testing.md)
30. [读程序自测：谜题集](30-quiz.md)
31. [坑清单（与编译器无关）](31-pitfalls.md)
32. [双编译器差异清单与可移植写法](32-diffs.md)

---
