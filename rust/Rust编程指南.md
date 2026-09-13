# Rust 编程指南（Windows）

本教程按 `guide` 统一标准组织：**Markdown 文档 + 独立示例 + build 脚本 + 可执行验证**。  
示例目录：`examples/`，验证入口：`build.ps1`。

## 目录

1. [环境准备](#环境准备)
2. [Hello World](#hello-world)
3. [变量与类型](#变量与类型)
4. [流程控制](#流程控制)
5. [函数与表达式](#函数与表达式)
6. [所有权与借用](#所有权与借用)
7. [结构体与实现](#结构体与实现)
8. [枚举与匹配](#枚举与匹配)
9. [集合类型](#集合类型)
10. [字符串处理](#字符串处理)
11. [错误处理](#错误处理)
12. [泛型与 Trait](#泛型与-trait)
13. [生命周期](#生命周期)
14. [模块系统](#模块系统)
15. [迭代器](#迭代器)
16. [闭包](#闭包)
17. [并发线程](#并发线程)
18. [消息通道](#消息通道)
19. [文件 I/O](#文件-io)
20. [测试风格](#测试风格)
21. [宏与模式](#宏与模式)
22. [统一验证](#统一验证)

---

## 环境准备

- Rust 目录：`G:\scoop\apps\rust\current`
- 编译器：`G:\scoop\apps\rust\current\bin\rustc.exe`
- 教程目录：`G:\code\guide\rust`

检查版本：

```powershell
G:\scoop\apps\rust\current\bin\rustc.exe --version
```

---

## Hello World

源码：`examples/01_hello.rs`  
展示最小 Rust 程序与格式化输出。

## 变量与类型

源码：`examples/02_variables_types.rs`  
展示不可变/可变变量、类型标注与数组/元组。

## 流程控制

源码：`examples/03_control_flow.rs`  
展示 `if`、`loop`、`while`、`for`。

## 函数与表达式

源码：`examples/04_functions.rs`  
展示函数参数、返回值、表达式返回与解构元组。

## 所有权与借用

源码：`examples/05_ownership_borrowing.rs`  
展示 move、clone、不可变借用和可变借用。

## 结构体与实现

源码：`examples/06_structs_impl.rs`  
展示 `struct`、关联函数和方法。

## 枚举与匹配

源码：`examples/07_enums_match.rs`  
展示 `enum`、`match`、`if let`。

## 集合类型

源码：`examples/08_collections.rs`  
展示 `Vec`、`HashMap`、`BTreeSet`。

## 字符串处理

源码：`examples/09_strings.rs`  
展示 UTF-8 字符串拼接、`chars`/`bytes` 遍历。

## 错误处理

源码：`examples/10_error_handling.rs`  
展示 `Result`、`Option` 与 `?` 运算符。

## 泛型与 Trait

源码：`examples/11_generics_traits.rs`  
展示泛型函数与 trait 约束。

## 生命周期

源码：`examples/12_lifetimes.rs`  
展示显式生命周期注解。

## 模块系统

源码：`examples/13_modules.rs`  
展示 `mod`、`pub`、`use`。

## 迭代器

源码：`examples/14_iterators.rs`  
展示 `map/filter/fold` 链式处理。

## 闭包

源码：`examples/15_closures.rs`  
展示闭包捕获环境和作为参数传递。

## 并发线程

源码：`examples/16_concurrency_threads.rs`  
展示 `thread::spawn` 与 `Arc<Mutex<T>>`。

## 消息通道

源码：`examples/17_channels.rs`  
展示 `mpsc` 多生产者单消费者。

## 文件 I/O

源码：`examples/18_file_io.rs`  
展示创建、写入、读取和清理文件。

## 测试风格

源码：`examples/19_tests_style.rs`  
展示 `#[cfg(test)]`、`#[test]` 和断言。

## 宏与模式

源码：`examples/20_macro_pattern.rs`  
展示 `macro_rules!` 和模式匹配守卫。

---

## 统一验证

全量验证：

```powershell
cd G:\code\guide\rust
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File 16_concurrency_threads.rs
```

清理：

```powershell
.\build.ps1 -Clean
```

