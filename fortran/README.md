# Fortran 教程与示例

现代 Fortran（Fortran 2018）入门到进阶，配套 31 个可运行示例：28 个现代 `.f90`，外加 3 个 FORTRAN 77 风格的固定格式 `.f`（70、71、72，让初学者对老 Fortran 有个手感）。**每个示例都在两个编译器上分别编译运行**：LLVM flang 23（主通道）与 GNU Fortran 15（对照通道）。教程正文 32 章，扩充时参考了《FORTRAN 语言程序设计——FORTRAN95》（清华 2017）与配套《实验指导与测试》（2018）两本教材的体系与习题。

这里讲的不是 FORTRAN 77 —— 但会把 FORTRAN 77 长什么样也演示一遍。`do concurrent`、`submodule`、`iso_c_binding`、类型绑定过程、`select type`、OpenMP 都在示例里实打实地跑了一遍。

## 目录结构

```
fortran/
├── README.md                 本文件
├── docs/                     教程正文（32 章，每章一个文件）
├── build.ps1                 PowerShell 构建/验证入口（两条通道）
├── run-all.sh                等价的 shell 版验证脚本
└── examples/
    ├── 01-basics.f90             程序结构与输出
    ├── 02-kinds.f90              类型与 KIND
    ├── 03-expressions.f90        表达式与运算符
    ├── 04-control-flow.f90       控制流
    ├── 05-arrays-basics.f90      数组基础
    ├── 06-arrays-intrinsics.f90  数组内建函数
    ├── 07-strings.f90            字符与字符串
    ├── 08-formatted-io.f90       格式化 I/O
    ├── 09-files.f90              文件与流 I/O
    ├── 10-procedures.f90         过程：子程序与函数
    ├── 11-modules.f90            模块与接口
    ├── 12-derived-types.f90      派生类型
    ├── 13-oop.f90                面向对象与多态
    ├── 14-pointers.f90           指针与可分配变量
    ├── 15-algorithms.f90         经典算法
    ├── 16-numeric.f90            数值计算
    ├── 17-random.f90             随机数与统计
    ├── 18-generics.f90           泛型、重载与 submodule
    ├── 19-c-interop.f90          C 互操作（iso_c_binding）
    ├── 20-parallel.f90           并行计算（OpenMP + do concurrent）
    ├── 21-errors-testing.f90     错误处理与单元测试
    ├── 22-project.f90            综合实战：一个 CSV 数据分析小工具
    ├── 23-memory-layout.f90      数组存储顺序（列主序）与隐 DO 循环
    ├── 24-formatted-input.f90    格式化输入：Iw/Fw.d/Lw/Aw、BN/BZ、格式重现
    ├── 25-gauss-jordan.f90       Gauss-Jordan 消元、矩阵求逆、Hilbert 病态演示
    ├── 26-ode.f90                常微分方程：欧拉/改进欧拉/RK4、方程组、稳定性
    ├── 27-debugging.f90          调试三板斧：打印摘要、计数器、断言、边界自查
    ├── 28-quiz.f90               读程序自测：十二道谜题实跑验证
    ├── 70-fixed-form.f           老格式：固定格式版面、算术 IF、计算 GOTO
    ├── 71-legacy-features.f      老特性：隐式类型、COMMON、EQUIVALENCE（附现代对照）
    └── 72-obsolescent.f          老特性 II：DATA、语句函数、alternate return、EXTERNAL
```

## 工具链

### macOS（MacPorts）

| 工具 | 路径 | 版本 | 定位 |
|---|---|---|---|
| `flang-mp-23` | `/opt/local/bin/flang-mp-23` | flang 23.1.0（LLVM 23） | 主通道。Apple 平台上是唯一跟得上新标准的原生编译器 |
| `gfortran-mp-15` | `/opt/local/bin/gfortran-mp-15` | GNU Fortran 15.2.0 | 对照通道。生态成熟，`omp_lib`、`real128` 这些 flang 没有的东西靠它补位 |
| `pwsh` | `/opt/local/bin/pwsh` | PowerShell 7.6.5 | 跑 `build.ps1`（不在默认 PATH 里） |

### Windows

| 工具 | 路径 | 版本 | 定位 |
|---|---|---|---|
| flang | `G:\scoop\apps\llvm\current\bin\flang.exe` | flang 23.1.1（LLVM 23，MSVC ABI） | 主通道。注意 MSYS2 的 flang 是 22.1.8，**别用它**：`c_long` 报 64 位（LLP64 下应为 32），`execute_command_line` 基本不可用 |
| gfortran | `G:\scoop\apps\msys2\current\ucrt64\bin\gfortran.exe` | GNU Fortran 16.2.0 | 对照通道（MSYS2 UCRT64） |
| `pwsh` | `G:\Program Files\PowerShell\7\pwsh.exe` | PowerShell 7 | 跑 `build.ps1` |

Windows 上跑脚本前要保证编译器的 DLL 目录在 PATH 里（gfortran 的 `cc1` 依赖 `ucrt64\bin` 下的 DLL，缺了会全部「编译失败」）：

```bash
export PATH="/g/scoop/apps/llvm/current/bin:/g/scoop/apps/msys2/current/ucrt64/bin:$PATH"
export FLANG="/g/scoop/apps/llvm/current/bin/flang.exe"
export GFORTRAN="/g/scoop/apps/msys2/current/ucrt64/bin/gfortran.exe"
```

验证安装：

```bash
flang-mp-23 --version     # flang version 23.1.0
gfortran-mp-15 --version  # GNU Fortran (MacPorts gcc15 15.2.0_0+stdlib_flag) 15.2.0
```

## 构建与验证

三条通道，每个示例都跑一遍：

| 通道 | 命令 | 说明 |
|---|---|---|
| flang | `flang-mp-23 -std=f2018 -pedantic -O2 -J build/mod/flang FILE -o OUT` | 主通道（`.f90`） |
| gfortran | `gfortran-mp-15 -std=f2018 -pedantic -O2 -J build/mod/gfortran FILE -o OUT` | 对照通道（`.f90`） |
| 老格式 `.f` | gfortran 侧改 `-std=legacy`；flang 侧去掉 `-std` 与 `-pedantic` | 70、71、72 三个示例，脚本按后缀自动切换 |
| 一致性比对 | `cmp` | 两个编译器的 stdout 应当逐字节相同 |

老格式示例不跑 `-pedantic`：老特性本来就是标准里的「已删/已过时」集合，用现代标准挑它的毛病没有意义。顺带一提，flang 23 不认 `-std=legacy`（只接受 `-std=f2018`），不加 `-std` 时本来就接受固定格式 —— 这本身就是一个跨编译器差异。

PowerShell：

```powershell
cd /Users/xulun/code/programming/fortran        # Windows: cd G:\code\guide\fortran
pwsh ./build.ps1 -All                 # 跑全部（31 个 × 2 通道）
pwsh ./build.ps1 -File 12-derived-types.f90
pwsh ./build.ps1 -All -Verbose        # 附带打印每个示例的运行输出
pwsh ./build.ps1 -Clean               # 清理 build 目录
```

macOS / Linux（等价的 shell 脚本）：

```bash
cd /Users/xulun/code/programming/fortran
./run-all.sh            # 跑全部，只看结果摘要
./run-all.sh -v         # 跑全部并显示每个例子的完整输出
./run-all.sh 05 06      # 只跑指定编号
```

两个脚本都会自动判断：源码里出现 `!$omp` 就自动补 `-fopenmp`，不需要维护清单。

### 判定标准

两条通道共用同一套判定，**四条都满足**才算通过：

1. **退出码为 0**
2. **stderr 为空**（`-pedantic` 下的警告也算问题）
3. **stdout 里没有多余控制字符**
   —— 出现这个基本只有一个原因：格式描述符比数据项少，触发了「格式重现」，多出来的整数被 `(a)` 描述符当成字符，原始字节直接落盘。这种输出用肉眼翻看不出来，但绝对不是通过。
4. **stdout 里出现结束标记** `==== NN 结束 ====`
   —— 确保程序真跑到了最后一行，而不是中途失败。

### 跨编译器输出比对

最后还会拿两个编译器的 stdout 逐字节 `cmp`。绝大多数示例应当完全一致；下面这几个**按设计**不一致，脚本只打印原因、不计入告警（见 `diff_reason()` / `Get-DiffReason()`）：

| 示例 | 不一致的原因 |
|---|---|
| `02-kinds` | flang 23 没有四倍精度（`real128 = -1`），gfortran 有 |
| `08-formatted-io` | namelist 写出的排版由编译器决定 |
| `09-files` | **仅 Windows**：flang 的 Windows 运行时 `inquire(size=)` 恒为 -1，`close(status='delete')` 失效（见下文「Windows 已知问题」） |
| `15-algorithms` | 洗牌用了 `random_number`，两个发生器不同 |
| `16-numeric` | **仅 Windows**：Richardson 外推的末位浮点差异（FMA 收缩与否随编译器/平台不同） |
| `17-random` | 随机数发生器与种子长度都不同（flang 的 `random_seed` 长度是 1，gfortran 是 8） |
| `20-parallel` | 含墙钟计时，线程调度也不保证一致 |
| `21-errors-testing` | **仅 Windows**：flang 的 Windows 运行时 `inquire(size=)` 恒为 -1 |

其余示例若出现输出差异，脚本会报 `[DIFF]` 并附 `diff` 片段 —— 那才是需要人工确认的东西。比对逻辑是**先逐字节比，不一致才查已知差异清单**，所以 macOS 上这些条目照常报 `[same]`，不会误报。

失败时 `build.ps1` / `run-all.sh` 返回退出码 1，可以直接拿去做回归。

## 章节索引

| 章 | 主题 | 示例 |
|---|---|---|
| [01 语言概览：Fortran 到底在干什么](docs/01-overview.md) | 1957 年出身与设计哲学、公式到代码的一对一映射、固定格式与自由格式（打孔卡片遗产）、Fortran 90 分水岭 | — |
| [02 工具链与运行方式](docs/02-toolchain.md) | flang/gfortran 双编译器、编译命令与模块目录、构建验证脚本 | — |
| [03 算法与程序设计方法](docs/03-methodology.md) | 不涉语法：怎么把问题变成「计算机能执行的步骤」，从欧几里得算法讲起 | — |
| [04 程序结构、类型与 KIND](docs/04-program-kinds.md) | `program`/`end program`、`implicit none`、`print` vs `write`、格式描述符、`;` 与 `&`、内部写、`block`；`integer(int32)`/`real(real64)`、`selected_real_kind`、`digits`/`range`/`huge`/`tiny`/`epsilon`、`complex`、`z'FF'` | `01-basics`、`02-kinds` |
| [05 表达式、运算符与数值陷阱](docs/05-expressions.md) | 优先级、整数除法 vs 实数除法、混合模式、`**` 的坑 | `03-expressions` |
| [06 控制流](docs/06-control-flow.md) | `if`/`select case`、命名循环、`exit`/`cycle`、`where`/`elsewhere`、`merge`、`associate`、`block` 作用域 | `04-control-flow` |
| [07 数组（一）：声明、构造、切片](docs/07-arrays-basics.md) | 声明与自定义下标、数组构造器、`reshape`、静态赋值、切片与跨步、重叠赋值 | `05-arrays-basics` |
| [08 数组（二）：内建函数](docs/08-arrays-intrinsics.md) | 归约、`dim=`/`mask=`、`maxloc`/`findloc`、`matmul`/`dot_product`/`norm2`/`transpose`、`pack`/`unpack`/`spread`/`cshift`/`eoshift`、位归约 | `06-arrays-intrinsics` |
| [09 数组在内存里的样子：存储顺序与隐 DO 循环](docs/09-memory-layout.md) | 列主序存储顺序、`reshape` 的 `order=`、隐 DO 在输出表/输入表/构造器、循环嵌套顺序与存储位序、`transfer` vs `reshape` | `23-memory-layout` |
| [10 字符与字符串](docs/10-strings.md) | 定长 vs 延迟长度、拼接、`index`/`scan`/`adjustl`/`trim`/`repeat`、内部读写、手写 `split` | `07-strings` |
| [11 格式化 I/O：输出](docs/11-formatted-output.md) | 描述符全表、`dt` 自定义 I/O、namelist、格式重现与复用 | `08-formatted-io` |
| [12 格式化输入](docs/12-formatted-input.md) | `Iw` 空格/截断/全空规则、`Fw.d` 自带小数点优先、指数输入、`Lw`、`Aw` 取最右、`X` 跳列、`BN`/`BZ`、输入版格式重现、`iostat` 捕获 | `24-formatted-input` |
| [13 文件与流 I/O](docs/13-files.md) | 有格式/无格式/流/直接访问、`newunit`、`inquire`、`rec=` | `09-files` |
| [14 过程：子程序、函数与参数传递](docs/14-procedures.md) | 内部/外部/模块过程、可选参数、`procedure()` 哑元、把内建函数包起来、递归、`impure elemental` | `10-procedures` |
| [15 模块、接口与模块目录](docs/15-modules.md) | `use`/`only`/重命名、`private`/`public`、模块变量、`-J` 模块目录 | `11-modules` |
| [16 派生类型](docs/16-derived-types.md) | 构造器、数组与可分配分量、嵌套、`move_alloc`、深拷贝 | `12-derived-types` |
| [17 面向对象与多态](docs/17-oop.md) | 抽象类型、`extends`、延迟绑定、`class(*)`、`select type`、多态数组、终结器、类型绑定泛型 | `13-oop` |
| [18 指针与可分配变量](docs/18-pointers.md) | 指针 vs 可分配（别名 vs 值语义）、`target`、`associated`/`nullify`、指针切片、链表、`move_alloc` | `14-pointers` |
| [19 老特性考古 II：DATA、语句函数与 alternate return](docs/19-obsolescent.md) | 隐式类型规则、`COMMON` 块、`EQUIVALENCE` 位型查看、无 `intent` 的过程调用；`DATA`（重复因子/隐 DO/SAVE 语义）、语句函数、alternate return（`*` 虚参 + `RETURN n`）、`EXTERNAL`/`INTRINSIC`；注释里逐条给现代对照写法 | `71-legacy-features`、`72-obsolescent` |
| [20 泛型、重载与 submodule](docs/20-generics.md) | 运算符重载、`assignment(=)`、泛型接口、`elemental`、`dt` 自定义 I/O、`submodule` 拆分实现、`pure` | `18-generics` |
| [21 经典算法](docs/21-algorithms.md) | 冒泡/插入/快速/归并排序、递归与迭代二分、筛法、`gcd`、汉诺塔、记忆化斐波那契、洗牌 | `15-algorithms` |
| [22 数值计算](docs/22-numeric.md) | 二分/牛顿/割线/不动点求根、梯形/辛普森/中点积分、中心差分 + 理查森外推、**列主元 LU 分解**、行列式、拉格朗日插值 | `16-numeric` |
| [23 线性方程组专题：Gauss-Jordan 与矩阵求逆](docs/23-gauss-jordan.md) | 列主元消元、`[A|I]→[I|A⁻¹]`、乘法验算、Hilbert 病态矩阵误差爆炸（1e-14→3e-7） | `25-gauss-jordan` |
| [24 常微分方程数值解](docs/24-ode.md) | 欧拉/改进欧拉/RK4 三法对照（精确解标尺）、二阶降阶成方程组、`procedure` 哑元传右端函数、显式欧拉稳定边界 | `26-ode` |
| [25 随机数与统计](docs/25-random.md) | `random_seed`/`random_number`、直方图、Box-Muller、蒙特卡洛求 π 与积分、中心极限定理、均值/方差/中位数/分位数/偏度/峰度/相关系数 | `17-random` |
| [26 C 互操作](docs/26-c-interop.md) | KIND 对照表、`strlen`/`malloc`/`memset`/`memcpy`/`fabs`、字符串互转、`c_f_pointer`、`qsort` 回调、`bind(c)` 结构体布局、列主序陷阱 | `19-c-interop` |
| [27 并行计算：OpenMP 与 do concurrent](docs/27-parallel.md) | `!$omp` 指令、reduction/atomic/critical/private、`schedule`、sections、计时与加速比、竞态、`do concurrent` | `20-parallel` |
| [28 调试与查错方法](docs/28-debugging.md) | 三类错误活体、`iostat` 防御、打印摘要/计数器二分三板斧、断言不变量、手写边界自查、Recursive I/O 陷阱 | `27-debugging` |
| [29 错误处理与单元测试](docs/29-testing.md) | 手写 `unittest` 断言框架、被测模块、`iostat`/`stat`/`err=`/`inquire`、子进程 `error stop` 退出码 | `21-errors-testing` |
| [30 读程序自测：谜题集](docs/30-quiz.md) | 十二道改编自教材的谜题（整数除法/循环变量终值/if 配对/mod-modulo/case 语义等），十题实跑验证 | `28-quiz` |
| [31 坑清单（与编译器无关）](docs/31-pitfalls.md) | `cs(i)` 是函数调用不是子串赋值、格式重现把整数当字符串吐出、`a(5:1:-1)` 是 5 个元素、`es`/`en`/`e` 不写 `Ee` 时指数只占 2 位 | — |
| [32 双编译器差异清单与可移植写法](docs/32-diffs.md) | flang 23 × gfortran 15 共 15 条实测差异（`real128`、PDT、coarray、`omp_lib`、`random_seed` 长度等）与可移植写法 | — |

`22-project`（CSV 综合实战）与 `70-fixed-form`（FORTRAN 77 固定格式手感）不对应单一章节：前者把前面各章的能力拼成一个完整小工具；后者的固定格式版面规则讲解在第 1 章末「固定格式与自由格式」一节。

## flang 23 与 gfortran 15 的差异清单

这些是写示例时一个个撞出来的，**不是猜测**。碰到「同一份代码一边过一边不过」先来这里对一下。

| # | 差异 | flang 23 | gfortran 15 |
|---|---|---|---|
| 1 | 四倍精度 `real128` | 不支持（`real128 = -1`） | 支持 |
| 2 | 参数化派生类型（PDT） | 不支持 | 支持 |
| 3 | 协程/共数组（coarray） | 不支持 | 支持（需 `-fcoarray`） |
| 4 | `omp_lib` 模块 | **没有** | 有 |
| 5 | `-fcheck=bounds` 之类运行时检查 | 没有对应选项 | 有 |
| 6 | `block` 作用域里的 `!$omp atomic`、`do concurrent ... local()` | 报错（不接受块内变量） | 接受 |
| 7 | `forall` 里带类型声明 `forall(integer(int32)::k=1:6)` | 接受（F2008 语法） | 拒绝；且认为 `forall` 已过时 |
| 8 | `pure function` 带 `intent(inout)` 哑元 | 放行 | 按标准拒绝 |
| 9 | 递归函数 | 未声明 `recursive` 也可能放行 | 必须显式写 `recursive` |
| 10 | 重复 `allocate` 已分配的变量 | 运行时宽容 | 运行时报错 |
| 11 | `random_seed` 的 `size` | 1 | 8 |
| 12 | `stat=` 返回的数值 | 与 gfortran 不同（如 12） | 与 flang 不同（如 5014） |
| 13 | namelist 输出排版 | 各自的排版风格 | 各自的排版风格 |
| 14 | 已删/过时特性（PAUSE、语句函数、alternate return）在 `-std=f2018` 下 | PAUSE 接受（仅 portability 警告），另两个零警告接受 | **PAUSE 拒绝编译**；另两个报 Obsolescent 警告 |
| 15 | 同一数组元素被两条 DATA 重复初始化（legacy 通道） | 拒绝 | 接受（后者覆盖） |

第 4 条最要命：`use omp_lib` 在 flang 上直接编译不过。示例 20 的解法是自己写一个 `module omprt`，用 `bind(c, name='omp_get_wtime')` 这类接口把 OpenMP 运行时函数声明一遍 —— 这也顺便说明了 `bind(c)` 是怎么用的。

## Windows 已知问题

这些是 2026-09 在 Windows 11 + MSYS2 UCRT64（gfortran 16.2.0）+ scoop LLVM（flang 23.1.1）上实测撞出来的，全部有最小复现：

| # | 问题 | 影响 | 处置 |
|---|---|---|---|
| W1 | LLVM 版 flang 链接时报 `__floattidf`/`__fixdfti` 未定义 —— flang-rt 的 findloc 代码引用了 128 位转换例程，MSVC ABI 下没人提供 | 任何用到 findloc 的程序（示例 06） | 脚本自动探测并补链 `lib\clang\*\lib\windows\clang_rt.builtins-x86_64.lib`；手动编译时把它追加到命令行末尾即可 |
| W2 | flang 的 Windows 运行时 `inquire(file=..., size=)` 恒返回 -1（22 和 23 都有） | 示例 09、21 的字节数输出 | 平台差异，无法在源码层绕过，脚本按已知差异处理 |
| W3 | flang 的 Windows 运行时 `close(status='delete')` **静默失败**：文件残留，删后 `inquire(exist=)` 仍报 T（22 和 23 都有） | 示例 09 的删除演示 | 同上。教学上顺带说明了「delete 失败不报错」也是一种 iostat 盲区 |
| W4 | `execute_command_line` 的重定向语法随 shell 不同：POSIX 是 `>/dev/null`，cmd.exe 只认 `>nul`，且路径要加引号 | 示例 21（已修复：按 `OS` 环境变量分支） | 源码已按平台分支 |
| W5 | flang 22（MSYS2 版）`execute_command_line` 报 `Invalid command`，基本不可用；且 `c_long` 报 64 位（Windows 是 LLP64，应为 32） | 示例 19、21 | 别用 MSYS2 的 flang，主通道用 LLVM 23 |
| W6 | Windows 上顺序格式化文件写 `\r\n`，字节数与 macOS 的 `\n` 不同 | 依赖字节数的输出（示例 21 的注释文字已改成平台无关） | 无需处理 |
| W7 | 跑 gfortran 前必须把 `ucrt64\bin` 加进 PATH，否则 `cc1` 缺 DLL 全部「编译失败」 | 脚本使用者 | 见「工具链 · Windows」的环境变量设置 |

另外两处脚本层面的说明：`build.ps1` 与 `run-all.sh` 在 Windows 上都验证过可用（`Start-Process` 能解析无扩展名的二进制名，自动落到 `.exe`）；pwsh 控制台代码页不是 UTF-8 时输出会乱码，`.out` 文件本身是 UTF-8、不受影响。

## Fortran 本身容易踩的坑

跟编译器无关、纯粹是语言层面的坑，值得先看一眼（详见[第 31 章 · 坑清单](docs/31-pitfalls.md)）：

- **`cs(i) = x` 是函数调用，不是子串赋值**。要给子串赋值必须写 `cs(i:i) = x`。
- **格式描述符个数少于数据项会「格式重现」**。`write(*,'(a,3i5)') 'x', arr` 里 `arr` 有 5 个元素时，多出来的 2 个会从头再走一遍格式，而第一个描述符是 `(a)`——于是整数的原始字节被当字符串吐出来，stdout 里混进 NUL。这是本次编写过程中真实踩到的坑，验证脚本现在专门查这个。
- **`a(5:1:-1)` 是 5 个元素**，不是 3 个。元素个数是 `(last - first + stride) / stride`。
- **`es`/`en`/`e` 描述符不写 `Ee` 时指数只占 2 位**。`huge(1.0_real64)` 用 `es13.6` 会印成 `1.797693+308`（位数不够被挤掉了），必须写 `es15.6e3` 才得到 `1.797693E+308`。
- **`F0.d` 省略前导零**：`f0.2` 打印 `0.5` 会得到 `.50`，不是 `0.50`。
- **内部读的 unit 必须是字符变量**，不能直接写字符串字面量。
- **`buf = c_null_char` 只把第 1 个字符设成 NUL**，剩下的是空格不是 NUL。要清空得逐字符赋值。
- **`a` 描述符不带宽度时用声明长度**，所以 `trim(s)` 照样补空格到声明长度。要紧凑输出用 `s(1:len_trim(s))` 或 `(a)` 配 `trim` 的结果变量。
- **泛型内建函数不能当过程实参**。`sin`、`exp` 这类是泛型名，要传得先用 `procedure()` 包一层。
- **自由格式上限 132 列**，超了会被截断（gfortran 直接报 `Line truncated`）。
- **列主序 vs C 行主序**。跟 C 互操作传二维数组时忘了转置，会得到转置的结果。
- **数组节重叠赋值是标准禁止的**。`a(2:4) = a(1:3)` 必须先存临时副本。

## 当前状态

- **macOS x86_64**（flang 23.1.0 / GNU Fortran 15.2.0，2026-09-26 扩充后全量复验）：31 示例 × 2 通道 = **62 项全部通过**，0 项意外输出差异；已登记的按设计差异中 5 项在 macOS 上实际不同（02/08/15/17/20，脚本打印原因、不计告警），3 项仅 Windows（09/16/21，macOS 上逐字节一致）。
- **Windows 11**（flang 23.1.1 / GNU Fortran 16.2.0，2026-09 扩充校验）：31 示例 × 2 通道（22 个原有示例 + 6 个新增 `.f90` + 3 个固定格式老示例 70/71/72）= **62 项全部通过**，0 项意外输出差异；仅剩上表列出的已知差异（其中 3 项只在 Windows 出现，根因见「Windows 已知问题」W2/W3）。

`build.ps1` 与 `run-all.sh` 在两个平台上均实测，结果一致。
