# 第 2 章 · 工具链与运行方式

### 两个编译器

| 工具 | 路径 | 版本 | 定位 |
|---|---|---|---|
| `flang-mp-23` | `/opt/local/bin/flang-mp-23` | flang 23.1.0（LLVM 23） | 主通道 |
| `gfortran-mp-15` | `/opt/local/bin/gfortran-mp-15` | GNU Fortran 15.2.0 | 对照通道 |

为什么要两个？因为在 macOS 上它们各有硬伤，**互补**才能把示例写全：

- flang 缺 `real128`、参数化派生类型、共数组、`-fcheck`，**尤其缺 `omp_lib` 模块**（于是 `use omp_lib` 编译不过）。
- gfortran 在 F2018 语法上更保守：`forall` 带类型声明它会拒绝，`pure function` 带 `intent(inout)` 它按标准报错。

只用其中一个，你会误以为某些特性「Fortran 不支持」。用两个，你才知道边界在哪 —— 这也正是第 32 章那份差异清单的来源。

### 编译命令

```bash
flang-mp-23 -std=f2018 -pedantic -O2 -J build/mod/flang examples/01-basics.f90 -o build/01-basics.flang
gfortran-mp-15 -std=f2018 -pedantic -O2 -J build/mod/gfortran examples/01-basics.f90 -o build/01-basics.gfortran
```

逐条解释：

| 参数 | 作用 | 为什么这么选 |
|---|---|---|
| `-std=f2018` | 按 Fortran 2018 标准检查 | 不写的话编译器会接受一堆历史遗留语法，学不到正确的写法 |
| `-pedantic` | 对标准之外的扩展报诊断 | **本仓库把警告当错误**：stderr 非空即判失败 |
| `-O2` | 开优化 | 能暴露出「未初始化变量」「别名假设」这类只有优化时才显形的问题 |
| `-J <dir>` | 指定 `.mod` 模块文件目录 | 两个编译器共用一个目录会互相覆盖，必须分开 |
| `-fopenmp` | 开 OpenMP | 只在源码含 `!$omp` 时加，脚本自动判断 |

单文件示例一条命令就完成编译 + 链接。多文件工程才需要 `-c` 分步编译再链接。

### 三条通道与结束标记

每个示例都跑三条通道：flang 编译运行、gfortran 编译运行、两边的 stdout 逐字节 `cmp`。

每个示例的最后一行一定是：

```fortran
write (*, '(a)') '==== 01 结束 ===='
```

这个标记是判定「程序真的跑完了」的依据。没有它的话，一个中途 `stop` 掉的程序也可能退出码 0、stderr 干净 —— 看起来「通过」了。

所以判定标准是四条同时满足：

1. 退出码 0
2. stderr 为空（`-pedantic` 下警告也算问题）
3. stdout 无多余控制字符（见第 11 章的「格式重现」）
4. stdout 有 `==== NN 结束 ====`

第 3 条是编写本仓库时才加上去的。原因见第 11 章。

### 两个入口

```bash
./run-all.sh          # shell 版，只打摘要
./run-all.sh -v       # 附带完整输出
./run-all.sh 05 06    # 只跑指定编号
```

```powershell
pwsh ./build.ps1 -All
pwsh ./build.ps1 -File 12-derived-types.f90
pwsh ./build.ps1 -Clean
```

两者判定逻辑完全一致，实测结果也一致。

---

上一章：[第 1 章 语言概览：Fortran 到底在干什么](01-overview.md) ｜ 下一章：[第 3 章 算法与程序设计方法](03-methodology.md) ｜ 返回：[README](../README.md)
