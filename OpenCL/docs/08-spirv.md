# 8. SPIR-V 离线编译：两条路线、一个 thunk、与被验证器放过的坏模块

[07 篇](./07-cpp-bindings.md) 讲主机侧的绑定。这一篇把编译从运行时挪到**运行前**：用 `clang` 把 OpenCL C 编成 SPIR-V 模块，再用 `clCreateProgramWithIL` 交给驱动。

前面七个例子全都走同一条路——把 OpenCL C 源码字符串递给 `clCreateProgramWithSource`，让驱动在 `clBuildProgram` 里现场编译。这一篇换一条路，然后**测量这两条路是否等价**。答案在本机是：**不等价**，而且不等价的方式很具体——同一个内核、同一台机器、同一个驱动，一条路线产出的模块能跑，另一条产出的模块在核显上以驱动 `abort()` 收场。

这一篇有一条贯穿全篇的实测结论，先摆在这里：

> **SPIR-V 不是一种格式，而是一族格式。** `clang` 的 SPIR-V 后端和 `llvm-spirv` 翻译器都从同一份 `.cl` 出发，产出**版本不同、生成器不同、体积不同、入口点形状也不同**的两个模块。核显的驱动只接受其中一个。而 `spirv-val` 对**两个都说合法**——所以"验证器通过"这件事，在本机**不能**用来预测"驱动能跑"。这是本篇最重要的一条，8.7 节用一次干预实验把它钉死。

> **验证方式说明**：本篇横跨全部五个通道。**离线工具链级**证据来自 `build-spirv.ps1`（三条路线，`[RESULT] PASS`）与 `tools/spirv-route-probe/`（5 个用例，`-Destructive` 下 `5/5 MATCH`）；**设备元数据级**来自 `tools/clinfo-probe/`；**运行时数值级**来自 `examples/09-spirv-il/` 与 `examples/08-cpp-bindings/`（Intel UHD Graphics 630）；**主机编译级**用于 `cl.hpp` 的 IL 构造函数；凡涉及规范措辞处标为**规范级**或**文档核对**。`tools/spirv-route-probe/build.ps1 -Destructive` 会让驱动**终止进程**（`0xC0000409`），这是设计如此，8.7.9 有逐字记录。

## 8.1 本机三台设备的 IL 支持

原始资料写：

| OpenCL 版本 | SPIR-V 支持 | 说明 |
|-------------|-------------|------|
| OpenCL 2.1+ | 原生支持 | `clCreateProgramWithIL()` |
| OpenCL 1.2 | 扩展支持 | `cl_khr_il_program` 扩展 |
| OpenCL 3.0 | 原生支持 | **完整 SPIR-V 1.5 支持** |

这张表按 **API 版本**推断 IL 能力。本机的实测结果是：**这个推断不成立**。

`tools/clinfo-probe/` 的输出（节选，可重跑）：

| # | 平台 / 设备 | 类型 | `CL_DEVICE_VERSION` | `CL_DEVICE_OPENCL_C_VERSION` | `CL_DEVICE_IL_VERSION` | `cl_khr_il_program` |
|---|---|---|---|---|---|---|
| 0 | NVIDIA CUDA / **GeForce RTX 2060** | GPU | `OpenCL 3.0 CUDA` | `OpenCL C 1.2` | **（空）** | 无 |
| 1 | Intel OpenCL HD Graphics / **UHD Graphics 630** | GPU | `OpenCL 3.0 NEO` | `OpenCL C 1.2` | **`SPIR-V_1.2`** | **有** |
| 2 | Intel(R) OpenCL / **Core i7-9700 CPU** | CPU | `OpenCL 3.0 (Build 0)` | `OpenCL C 3.0` | **`SPIR-V_1.0 SPIR-V_1.1 SPIR-V_1.2 SPIR-V_1.3 SPIR-V_1.4`** | **有** |

三台设备**都是 OpenCL 3.0**。按原表第三行，三台都该有"完整 SPIR-V 1.5 支持"。实测：

- 一台**完全没有** IL 支持（`CL_DEVICE_IL_VERSION` 是空字符串）。
- 一台支持到 **1.2**，不是 1.5。
- 一台支持到 **1.4**，也不是 1.5。

> 顺带一个细节：`SPIR-V_1.2 ` 这个值**带一个尾随空格**，字符串查询返回的 `size` 是 **12**（`"SPIR-V_1.2 "` 11 字节 + NUL）。做字符串比较时不要写 `== "SPIR-V_1.2"`。

**正确的判断方式只有一个：查 `CL_DEVICE_IL_VERSION`，看它是不是空。** API 版本、厂商、设备类型都不能替代它。原表的错误不在于"2.1 起原生支持"（那是对的），而在于把 **3.0 当成一个统一的能力档位**——OpenCL 3.0 的设计恰恰相反，它把绝大多数 2.x 特性变成了**可选**，IL 支持就是其中之一。

> **诚实边界**：本机没有任何设备广告 SPIR-V 1.5 或 1.6，而且本机的工具链也**产不出** 1.5/1.6 的模块（8.2.3）。所以"1.5 支持"这一格在本机**无法验证也无法否证**，只能说"原表的推断方式在三台 3.0 设备上都不成立"。

## 8.2 两条离线路线

原始资料给的编译命令是：

```bash
clang -cl-std=CL2.0 -target spirv64 -c kernel.cl -o kernel.spv

# 或者使用 OpenCL 离线编译器
opencl-c-compiler -cl-std=CL2.0 -o kernel.spv kernel.cl
```

这两条命令在本机**都不能直接用**，三处问题：

| 问题 | 实测 |
|---|---|
| `-target spirv64` | 不是完整三元组。本机 clang 接受的是 **`spirv64-unknown-unknown`** |
| `-cl-std=CL2.0` | 能编过，但本机核显的设备侧编译器只有 **OpenCL C 1.2**。用 2.0 编出的模块可能含设备跑不了的构造，而失败会以一个**难以解释的 `clBuildProgram` 错误**回来，而不是一条编译诊断 |
| `opencl-c-compiler` | **本机不存在这个程序**。oneAPI 与 CUDA SDK 里都没有 |

`build-spirv.ps1` 实际跑的是两条不同的路线，产出两个不同的模块：

```powershell
# backend 路线：clang 的 SPIR-V 后端，直接产出模块
clang -c -target spirv64-unknown-unknown '-cl-std=CL1.2' `
      examples\09-spirv-il\kernels\vector_add.cl -o vector_add.spv

# translator 路线：先产 LLVM IR，再由 llvm-spirv 翻译成 SPIR-V
clang -c -emit-llvm -target spirv64-unknown-unknown '-cl-std=CL1.2' `
      examples\09-spirv-il\kernels\vector_add.cl -o vector_add.bc
llvm-spirv '--spirv-max-version=1.2' vector_add.bc -o vector_add_translator.spv
```

本机工具版本（`build-spirv.ps1` 开头会打印）：

```text
clang      : D:\oneAPI\compiler\latest\bin\compiler\clang.exe
  version  : Intel(R) oneAPI DPC++/C++ Compiler 2025.3.2 (2025.3.2.20260112)
llvm-spirv : D:\oneAPI\compiler\latest\bin\compiler\llvm-spirv.exe
spirv-val  : D:\VulkanSDK\1.4.335.0\Bin\spirv-val.exe
spirv-dis  : D:\VulkanSDK\1.4.335.0\Bin\spirv-dis.exe
```

同一份 `vector_add.cl`，两条路线的产物：

| | backend | translator |
|---|---|---|
| 字节数 | **1416** | **1864** |
| SPIR-V 版本（读文件头第 2 字） | **1.4** | **1.0** |
| 生成器 tool id（第 3 字低 16 位） | **21** = `LLVM SPIR-V Backend` | **14** = `LLVM/SPIR-V Translator` |
| bound（第 4 字，id 上界） | **94** | **61** |
| magic | `0x07230203` ok | `0x07230203` ok |
| `spirv-val` | exit **0** | exit **0** |
| md5 | `666fde89950447756586b96f90b65357` | `3bb3e15d23d472bb351dab7f3031709d` |
| 核显上能否运行 | **能，1024/1024** | **不能，launch `-52`** |

最后一行是本篇的核心，8.7 节展开。这里先注意一件事：**两个模块都通过了 `spirv-val`**。

### 8.2.1 版本是从文件里读回来的，不是从命令行报的

`build-spirv.ps1` 的 `Get-SpvHeader` 直接解码每个产物的前五个字，再打印。这是有意的：backend 路线**没有任何开关能降低它的输出版本**，所以关于"它产出了什么版本"唯一诚实的说法，只能取自文件自己的头。

三种尝试压低版本的写法，全部被拒（exit code 均为 **1**）：

```text
--- --spirv-max-version=1.2 ---
exit=1
clang: error: unknown argument: '--spirv-max-version=1.2'

--- -Xclang -spirv-max-version=1.2 ---
exit=1
error: unknown argument: '-spirv-max-version=1.2'

--- -mllvm -spirv-max-version=1.2 ---
exit=1
clang (LLVM option parsing): Unknown command line argument '-spirv-max-version=1.2'.  Try: 'clang (LLVM option parsing) --help'
clang (LLVM option parsing): Did you mean '--stackmap-version=1.2'?
```

`clang -cc1 --help-hidden` 里也**没有任何 spirv 相关选项**。结论：`--spirv-max-version` 是 **`llvm-spirv` 的选项，不是 clang 的**。

### 8.2.2 `--spirv-max-version` 是上限，不是目标

translator 路线加了 `--spirv-max-version=1.2`，产出的是 **SPIR-V 1.0**。

这不是"选项没生效"。`llvm-spirv` 的这个参数是一个**天花板**：模块里实际用到的特性决定版本，天花板只负责拦住超出的部分。一个只用了 1.0 特性的模块，在 1.2 的天花板下仍然是 1.0。

**实际影响**：如果你想让 translator 路线产出更高版本，得让源码用上更高版本的特性；调这个参数没有用。反过来，backend 路线想产出更低版本，**没有参数可调**。

### 8.2.3 本机 PowerShell 的点分割陷阱

`build-spirv.ps1` 里每一个带点的参数都被**单引号**包住，包括 `'-cl-std=CL1.2'` 和 `'--spirv-max-version=1.2'`。原因是 PowerShell 在把参数交给原生命令时，会在**第一个点处切开**：

| 写法 | clang 实际收到 |
|---|---|
| `-DA=1.2` | `-DA=1` 加一个游散的 `.2`（被当成文件名） |
| `-DA=12` | `-DA=12`（完整） |
| `-DA=x.y` | `-DA=x` 加 `.y` |
| `-DA=xy` | `-DA=xy`（完整） |
| `-DA=1.2.3` | `-DA=1` 加 `.2.3`（只在第一个点切） |
| `'-DA=1.2'` | `-DA=1.2`（完整） |

触发条件是**点**，切分位置在**点处**（`=` 留在左边）。单引号足以解决。

本机在 **Windows PowerShell 5.1.26100.9444** 与 **pwsh 7** 上各测一遍，行为**完全相同**——所以"升级到 pwsh 7 就好了"不是解法，为这一处去 `cmd /c` 也没有必要。

## 8.3 SPIRV-Tools 在本机的位置与实测

原始资料写：

```bash
spirv-dis kernel.spv -o kernel.asm      # 反汇编
spirv-as kernel.asm -o kernel.spv       # 汇编
spirv-opt -O kernel.spv -o kernel_optimized.spv
spirv-val kernel.spv
spirv-cfg kernel.spv -o cfg.dot
```

### 8.3.1 出处：Vulkan SDK，不是 oneAPI

一个容易搞错的地方：**这五个工具在本机全部来自 `D:\VulkanSDK\1.4.335.0\Bin`，一个都不来自 oneAPI。**

oneAPI 的工具集是**裁剪过**的。它的 `bin\compiler\` 里有 `clang*`、`llc`、`lld*`、`llvm-ar/cov/dwp/foreach/lib/link/ml/nm/objcopy/profdata/progen/spirv/symbolizer`、`llvm-spirv`、`spirv-to-ir-wrapper`、`sycl-post-link`、`yaml2obj`——但**没有 `llvm-dis`，也没有 `llvm-bcanalyzer`**，更没有 `spirv-dis` / `spirv-as` / `spirv-opt` / `spirv-val` / `spirv-cfg`。

所以"装了 oneAPI 就有 SPIR-V 工具链"这个预期会落空：你有**编译器**，但没有**检查器**。

### 8.3.2 `spirv-dis` → `spirv-as` 能往返，但会重编号

把 backend 模块反汇编再汇编回去：

```text
spirv-dis vector_add.spv > rt.sptxt
spirv-as  rt.sptxt -o roundtrip.spv      exit 0
```

结果：**1416 字节，与原模块同尺寸；`spirv-val` exit 0**。但有两处变了：

- **bound 从 94 变成 50**（`spirv-as` 做了稠密重编号，把反汇编文本里的具名 id 重新紧凑分配）
- **生成器变成 "Khronos SPIR-V Tools Assembler"**

所以往返**不保字节相同**。要做"改了哪一条指令"的对比，往返是可行的（8.7.6 就靠它）；要做"模块有没有被动过"的校验，`md5` 会给出假警报。

### 8.3.3 `spirv-opt -O` 在这个模块上是 no-op

```text
spirv-opt -O vector_add.spv -o opt.spv     exit 0
```

体积**仍是 1416 字节**，`spirv-val` 仍 exit 0。对这个已经很小、由 clang 优化过的模块，`-O` 没有可做的事。

> 原始资料"最佳实践"第 2 条建议"使用 `spirv-opt` 优化 SPIR-V 二进制"。在本机这个例子上的实测效果是**零**。这不等于 `spirv-opt` 无用，而是说它的收益取决于输入——把它当成必经步骤，会得到一个多余的构建环节和一个变了的 bound/生成器。

### 8.3.4 `spirv-val --target-env`：验证器的结论**不能**预测设备的接受度

`--target-env` 的合法值**全小写**（`spirv-val --help` 可查）：

```text
vulkan1.0 … | spv1.0 spv1.1 spv1.2 spv1.3 spv1.4 spv1.5 spv1.6
opencl1.2embedded | opencl1.2 | opencl2.0embedded | opencl2.0
opencl2.1embedded | opencl2.1 | opencl2.2embedded | opencl2.2
opengl4.0 …
```

**这一版 SPIRV-Tools 里没有 `opencl3.0`。** 另外大小写错了不会报"invalid env"，而是**打印整段 usage 文本并 exit 1**——很容易被误读成"模块不合法"。

三个模块 × 六个环境的完整矩阵（每格是 exit code）：

| `--target-env` | `vector_add.spv` (1.4) | `vector_add_translator.spv` (1.0) | `vector_add_cpp.spv` (1.4) |
|---|---|---|---|
| `opencl1.2` | 0 | 0 | 0 |
| `opencl2.0` | 0 | 0 | 0 |
| `opencl2.1` | 0 | 0 | 0 |
| `opencl2.2` | 0 | 0 | 0 |
| `spv1.0` | 0 | 0 | 0 |
| `spv1.4` | 0 | 0 | 0 |

**18 格全部 exit 0。**

而在核显上：1.4 的模块跑通 1024/1024，1.0 的模块 launch 返回 `-52 CL_INVALID_KERNEL_ARGS`。

> **这是本篇最该记住的一条**：`spirv-val` 检查的是**模块是否符合 SPIR-V 规范**，不检查**某个驱动的实现能不能消费它**。translator 那个模块完全合法——它只是入口点形状不合 NEO 的口味。把 `spirv-val` 当成上线前的闸门，会放过这个模块。原始资料"最佳实践"第 5 条（"使用 `spirv-val` 验证 SPIR-V 文件的正确性"）本身没错，但它挡不住本篇的这个坑。

### 8.3.5 两种互不相容的"SPIR-V 文本格式"

一个反复踩到的坑：`spirv-dis` 的文本和 `llvm-spirv --spirv-text` 的文本**不是同一种格式**，彼此不能互换。

`llvm-spirv --spirv-text` **吃的是 bitcode，不是 `.spv`**。把一个 `.spv` 喂给它：

```text
file doesn't start with bitcode header
```

给它 `vector_add.bc` 才对，产出长这样：

```text
119734787 65536 393230 61 0
2 Capability Addresses
...
```

也就是**裸的数字字**加操作数名。把这段文本喂给 `spirv-as`：

```text
error: Expected <opcode> or <result-id> at the beginning of a line, found '119734787'.
```

`spirv-as` 要的是 `spirv-dis` 那种格式（`%54 = OpFunction %void None %10`）。**两套文本格式互不相通**，选错工具就是一次白跑。

### 8.3.6 `spirv-cfg`

```text
spirv-cfg vector_add.spv -o cfg.dot      exit 0，产出 618 字节
```

是个 Graphviz 输入。要有 `dot` 才能看图；本机没装，所以只验证到"工具能跑通并产出非空文件"。

## 8.4 "二进制格式，难以逆向工程"——被推翻

原始资料把"**保护知识产权**：二进制格式，难以逆向工程"列为 SPIR-V 的优势之一。

实测：**这个模块里的每一个名字都在。**

`spirv-dis vector_add.spv`（**不加任何参数**，没有 `--friendly-names` 之类）：

```text
               OpEntryPoint Kernel %vector_add "vector_add" %__spirv_BuiltInGlobalInvocationId
               OpSource OpenCL_C 102000
               OpName %vector_add "vector_add"
               OpName %__spirv_BuiltInGlobalInvocationId "__spirv_BuiltInGlobalInvocationId"
               OpName %__clang_ocl_kern_imp_vector_add "__clang_ocl_kern_imp_vector_add"
               OpDecorate %__spirv_BuiltInGlobalInvocationId LinkageAttributes "__spirv_BuiltInGlobalInvocationId" Import
               OpDecorate %__clang_ocl_kern_imp_vector_add LinkageAttributes "__clang_ocl_kern_imp_vector_add" Export
```

连 `strings vector_add.spv` 都能直接捞到这些名字。`OpSource OpenCL_C 102000` 还告诉你它是用 **OpenCL C 1.2** 编的。

再进一步：

```text
llvm-spirv -r vector_add.spv -o rev.bc     → 3204 字节的 LLVM bitcode 模块
```

也就是**可以还原回 IR**。

**准确的表述应当是**：SPIR-V 去掉了**注释、宏、局部变量名（除非显式保留）、以及源码的文件结构**；它**保留了函数名、参数布局、类型信息和完整的控制流**。它提高的是"顺手看一眼"的门槛，不是逆向工程的门槛。真要保护内核，SPIR-V 不是手段。

> **诚实边界**：`OpName` / `OpSource` 是**可选**的调试信息，编译器**可以**不产出（clang 有 `-g0` 之类的路径，SPIR-V 规范也允许剥离）。本机这两条路线都默认产出了。所以"难以逆向工程"在剥离之后会**部分**成立——但那已经不是原始资料描述的默认行为了。

## 8.5 检查 SPIR-V 支持：原始资料的两种写法都不对

### 8.5.1 写法一：读进 `cl_bool`

原始资料写：

```c
cl_bool supportsIL;
clGetDeviceInfo(device, CL_DEVICE_IL_VERSION, sizeof(supportsIL), &supportsIL, NULL);

if (supportsIL) {
    printf("Device supports IL programs (SPIR-V)\n");
}
```

`CL_DEVICE_IL_VERSION` 是一个**字符串**查询，没有布尔形式。`examples/09-spirv-il` 的第 2 步把三种写法并排跑了一遍（核显上）：

```text
[il] wrong way  : cl_bool, sizeof=4 -> err=-30 CL_INVALID_VALUE, supportsIL=0
[il] size query  : err=0 CL_SUCCESS, size=12
[il] string query: err=0 CL_SUCCESS, value='SPIR-V_1.2 ' (got 12 bytes)
```

`-30` 是 `CL_INVALID_VALUE`（`cl.h:240-251` 可核对）。关键在于**它不是"静默返回 false"**：查询失败，`supportsIL` **保持调用前的值**。原文那段 `cl_bool supportsIL;` 甚至没有初始化，所以 `if (supportsIL)` 分支的是**栈上的垃圾**。

在一台支持 IL 的设备上，这段代码可能打印"不支持"；在一台不支持的设备上，它也可能打印"支持"。**两个方向都会错。**

### 8.5.2 写法二：`if (ilVersionSize == 0)`——fail-open

原始资料的 C 示例里是：

```c
size_t ilVersionSize;
clGetDeviceInfo(device, CL_DEVICE_IL_VERSION, 0, NULL, &ilVersionSize);
if (ilVersionSize == 0) {
    printf("Device does not support IL programs\n");
    free(spvBinary);
    return NULL;
}
```

这个惯用法**差一，而且差在危险的方向**。空字符串**仍然是一个字符串**，仍然要为它的终止符留一个字节，所以 size 查询返回 **1**，不是 0。

`examples/09` 的第 11 步专门去找一台不支持 IL 的设备来测这一条，本机找到的是 RTX 2060：

```text
[no-il] NVIDIA GeForce RTX 2060 : CL_DEVICE_IL_VERSION size query -> 0 CL_SUCCESS, size=1
[no-il] "if (size == 0)" would WRONGLY ACCEPT this device
[no-il] NVIDIA GeForce RTX 2060 : clCreateProgramWithIL -> -59 CL_INVALID_OPERATION
[no-il] a clean error code is the correct behaviour; a crash would not be
```

**这个检查会放行一台根本不支持 IL 的设备。** 判空的正确条件是 `size <= 1`，或者干脆读字符串再看 `[0] != '\0'`。

好消息是失败模式很干净：`clCreateProgramWithIL` 返回 **`-59 CL_INVALID_OPERATION`**，进程不崩。但把检测写对，比依赖"崩不了"要好。

### 8.5.3 正确的写法

`examples/09-spirv-il/main.c` 第 2 步用的判定：

```c
char ilVersion[512] = {0};
size_t ilGot = 0;
cl_int eStr = clGetDeviceInfo(device, CL_DEVICE_IL_VERSION, sizeof(ilVersion), ilVersion, &ilGot);
printf("[il] string query: err=%d %s, value='%s' (got %zu bytes)\n",
       eStr, ocl_err_name(eStr), ilVersion, ilGot);

int ilSupported = (eStr == CL_SUCCESS && ilGot > 1 && ilVersion[0] != '\0');
```

三个条件都要：**查询成功**、**返回的不止一个终止符**、**首字符非空**。

### 8.5.4 扩展名是另一条线索，但不是替代

原始资料写：

```c
if (strstr(extensions, "cl_khr_il_program")) {
    printf("Supports cl_khr_il_program (OpenCL 1.2 SPIR-V)\n");
}
if (strstr(extensions, "cl_khr_spirv_no_integer_wrap_decoration")) {
    printf("Supports SPIR-V no integer wrap decoration\n");
}
```

这两条实测都对得上。核显的扩展列表里两个都有；Intel CPU 设备有 `cl_khr_il_program`；NVIDIA 两个都没有。

`cl_khr_spirv_no_integer_wrap_decoration` 是核显独有的一个（Intel CPU 设备没有），它说的是整数溢出的**装饰**语义——SPIR-V 默认不定义整数回绕，这个扩展让模块可以声明"不要加 no-wrap 装饰"。这与本篇主线无关，但它是**核显广告而 CPU 运行时不广告**的少数几个 SPIR-V 相关扩展之一。

**但扩展名不能替代 `CL_DEVICE_IL_VERSION`**：`cl_khr_il_program` 是 1.2 时代的扩展，2.1 起 IL 是核心特性，一台 2.1+ 的设备可能**不再广告这个扩展**却完整支持 IL。字符串查询是唯一可靠的入口。

## 8.6 从 SPIR-V 创建程序：C API

原始资料的 C 示例整体结构是对的，`examples/09-spirv-il/main.c` 保留了它的骨架。需要修正的点：

| # | 原始资料 | 问题 | 修正 |
|---|---|---|---|
| 1 | `size_t lengths[1] = { size };` 然后 `clCreateProgramWithIL(context, spvBinary, size, &err)` | 声明了 `lengths` 却**从未使用**。这是从 `clCreateProgramWithSource`（计数 + 字符串数组 + 长度数组）照抄过来的习惯 | `clCreateProgramWithIL` 只要**一块连续内存 + 一个 `size_t`**。删掉 `lengths` |
| 2 | `fread(spvBinary, 1, size, fp);` | 返回值没检查 | 短读会留下未初始化的字节，交给驱动是一个难以定位的错误 |
| 3 | `if (ilVersionSize == 0)` | fail-open，见 8.5.2 | `size <= 1` 或读字符串 |
| 4 | `clBuildProgram(program, 1, &device, NULL, NULL, NULL)` | 这一行**是对的**，而且比原文自己意识到的更重要 | IL 程序**没有源码可编**，构建选项对它没有意义。8.10.3 有实测 |
| 5 | `unsigned char* spvBinary` 传给 `clCreateProgramWithIL` | 原型要 `const void*`，能编过 | 无需改，但注意**不要**用 `ocl_read_file` 那类会 NUL 终止的文本读取函数——模块内部的 `0x00` 字节会被当成结尾 |

第 5 点值得单独说。`examples/09` 因此自带了一个 `read_binary`：

```c
// Read a whole binary file. ocl_read_file is for text and NUL-terminates, which is
// wrong for a SPIR-V module: a 0x00 byte inside the module would look like the end.
static unsigned char* read_binary(const char* path, size_t* outLen) {
    FILE* fp = fopen(path, "rb");
    if (!fp) return NULL;
    fseek(fp, 0, SEEK_END);
    long sz = ftell(fp);
    fseek(fp, 0, SEEK_SET);
    if (sz <= 0) { fclose(fp); return NULL; }
    unsigned char* buf = (unsigned char*)malloc((size_t)sz);
    if (!buf) { fclose(fp); return NULL; }
    if (fread(buf, 1, (size_t)sz, fp) != (size_t)sz) { fclose(fp); free(buf); return NULL; }
    fclose(fp);
    *outLen = (size_t)sz;
    return buf;
}
```

本机的 `vector_add.spv` 里**确实有** `0x00` 字节（`OpSource OpenCL_C 102000` 那个版本字的高位就是 0），所以这不是理论问题。

### 8.6.1 实测输出

`.\build.ps1 -Examples 09-spirv-il`（Intel UHD Graphics 630）：

```text
[device] Intel(R) UHD Graphics 630
[device] OpenCL 3.0 NEO  | OpenCL C 1.2  | max_work_group_size=256 | local_mem=65536 B
[il] wrong way  : cl_bool, sizeof=4 -> err=-30 CL_INVALID_VALUE, supportsIL=0
[il] size query  : err=0 CL_SUCCESS, size=12
[il] string query: err=0 CL_SUCCESS, value='SPIR-V_1.2 ' (got 12 bytes)
[module] spv/vector_add.spv : 1416 bytes
[module] magic=0x07230203 (ok)  SPIR-V 1.4  generator tool 21  bound 94
[module] device advertises 'SPIR-V_1.2 ', module is 1.4
[il] clCreateProgramWithIL -> 0 CL_SUCCESS
[build log] empty (1 bytes) - the driver had nothing to say
[il] clBuildProgram -> 0 CL_SUCCESS
[il] clCreateKernel("vector_add") -> 0 CL_SUCCESS
[il] CL_KERNEL_NUM_ARGS -> 4 (the source declares 4)
[launch] global=1024 local=64 -> 0 CL_SUCCESS
[verify] 1024/1024 elements correct
```

注意第 6 行：**设备广告 `SPIR-V_1.2`，模块是 1.4，而它接受了**。`examples/09` 把这行**打印出来而不是藏起来**，因为"这个不匹配要不要紧"是一个必须回答的问题，不是一个该被静默处理的问题。答案在 8.7.2。

四个断言：

```text
assert SPIR-V magic 0x07230203          : OK
assert module built and launched        : OK
assert CL_KERNEL_NUM_ARGS == 4          : OK
assert all 1024 elements match CPU ref    : OK
[RESULT] PASS
```

## 8.7 【本篇核心】核显为什么只接受其中一条路线

### 8.7.1 观察

`tools/spirv-route-probe/` 把每个模块在两台 Intel 设备上跑一遍（`key=uhd` 是核显，`key=intelcpu` 是 CPU 运行时），报告 `numargs`、launch 错误码和数值校验：

```text
=== CASE 1: backend route: the entry point IS the kernel ===
[probe] key=uhd create=0 build=0 kernel=0 numargs=4 launch=0(CL_SUCCESS) verify=1024/1024
[probe] key=intelcpu create=0 build=0 kernel=0 numargs=4 launch=0(CL_SUCCESS) verify=1024/1024

=== CASE 2: translator route: thunk entry point doubles the count on the iGPU only ===
[probe] key=uhd create=0 build=0 kernel=0 numargs=8 launch=-52(CL_INVALID_KERNEL_ARGS) verify=-1/1024
[probe] key=intelcpu create=0 build=0 kernel=0 numargs=4 launch=0(CL_SUCCESS) verify=1024/1024
```

同一个内核，四个参数。核显对 backend 模块报 `numargs=4`，对 translator 模块报 **`numargs=8`**。

探针按源码的元数绑定 4 个参数，然后 launch：核显返回 **`-52 CL_INVALID_KERNEL_ARGS`**（`cl.h` 可核对，`-52` 就是"参数没绑全"）。也就是说，**驱动认为还有 4 个参数没绑**，而源码里根本没有那 4 个参数。

而 **Intel CPU 运行时对同一个 translator 模块报 `numargs=4`，跑通 1024/1024**。

### 8.7.2 被推翻的假设一：SPIR-V 版本

最自然的解释是：设备广告 `SPIR-V_1.2`，backend 模块是 1.4，translator 模块是 1.0——版本不匹配导致行为异常。

**这个假设直接被 8.6.1 那行输出否掉了**：核显**接受了 1.4 的模块**并跑通 1024/1024，尽管它只广告 1.2。所以"设备广告 1.2"意味着的是**下限/基线**，不是**上限**；一个更高版本的模块，只要没用到设备不认的特性，就能过。

而被拒的那个模块版本**更低**（1.0）。如果版本是原因，方向应该反过来。

> 顺带一条可操作的结论：**`CL_DEVICE_IL_VERSION` 里的版本号不能用来预判模块能否加载。** 本机唯一一个能做的预判是"空 = 一定不行"。

### 8.7.3 被推翻的假设二：`Export` 装饰

第二个候选解释：translator 模块给 `%vector_add` 加了 `LinkageAttributes "vector_add" Export`，backend 模块没有（backend 只给那个不被调用的 `__clang_ocl_kern_imp_vector_add` 加了 Export）。也许 NEO 把带 Export 的函数当成"额外的可调用实体"，于是把参数算了两遍。

**这个假设也被推翻了**，但要说清楚证据的强度。8.7.6 的 de-thunk 版本**同时**去掉了那条 Export 装饰**和** thunk，`numargs` 从 8 降到 4——这一次改动本身分不开两者。分开它们靠的是另一次编辑：**只**删掉 `LinkageAttributes "vector_add" Export` 那一条装饰、**保留** thunk，重新汇编后再跑，计数**仍是 8**。

> **诚实边界（本条）**：那次"只删装饰"的编辑是**一次性的排查实验，没有留在常驻探针里**——`tools/spirv-route-probe/build.ps1` 的五个用例中只有 Case 3 做编辑，而它做的是完整的 de-thunk。所以这一条的可复现性弱于 8.7.6。要重跑，在 Case 3 的编辑里注释掉 `$final = $out | Where-Object { $_ -notmatch 'LinkageAttributes "vector_add" Export' }` 那一句即可（注意 `spirv-as` 会接受，`spirv-val` 也会接受，因为 thunk 仍是 `OpEntryPoint` 的目标而 `%vector_add` 不再是）。

另外那条 Export 装饰**必须**从 de-thunked 模块里删掉，原因与 NEO 无关：**`spirv-val` 拒绝 `OpEntryPoint` 目标带 `LinkageAttributes`**。而 NEO 反而**接受**带 Export 的入口点——这本身又是 8.3.4 那条"验证器与驱动不一致"的一个实例，只是这次方向相反：验证器更严。

### 8.7.4 反汇编：thunk 的真身

`spirv-dis` 把差异摊开了。

**backend 模块**——入口点**就是**内核本体：

```text
               OpEntryPoint Kernel %vector_add "vector_add" %__spirv_BuiltInGlobalInvocationId
...
 %vector_add = OpFunction %void None %6
         %12 = OpFunctionParameter %_ptr_CrossWorkgroup_float
         %13 = OpFunctionParameter %_ptr_CrossWorkgroup_float
         %14 = OpFunctionParameter %_ptr_CrossWorkgroup_float
         %16 = OpFunctionParameter %uint
         %44 = OpLabel
         %17 = OpLoad %v3ulong %__spirv_BuiltInGlobalInvocationId Aligned 1
         ...
```

整个模块里 **`OpFunctionCall` 出现 0 次**。

**translator 模块**——入口点是一个**转发 thunk**：

```text
               OpEntryPoint Kernel %54 "vector_add" %__spirv_BuiltInGlobalInvocationId
...
 %vector_add = OpFunction %void None %10          ← 真正的内核，4 个参数，完整函数体
         %12 = OpFunctionParameter %_ptr_CrossWorkgroup_float
         %13 = OpFunctionParameter %_ptr_CrossWorkgroup_float
         %14 = OpFunctionParameter %_ptr_CrossWorkgroup_float
         %15 = OpFunctionParameter %uint
         %16 = OpLabel
         %19 = OpLoad %v3ulong %__spirv_BuiltInGlobalInvocationId Aligned 32
         ...
               OpFunctionEnd
%__clang_ocl_kern_imp_vector_add = OpFunction %void Inline %10    ← 第三份，没人调用
         ...
               OpFunctionEnd
         %54 = OpFunction %void None %10          ← OpEntryPoint 指向的 thunk
         %55 = OpFunctionParameter %_ptr_CrossWorkgroup_float
         %56 = OpFunctionParameter %_ptr_CrossWorkgroup_float
         %57 = OpFunctionParameter %_ptr_CrossWorkgroup_float
         %58 = OpFunctionParameter %uint
         %59 = OpLabel
         %60 = OpFunctionCall %void %vector_add %55 %56 %57 %58
               OpReturn
               OpFunctionEnd
```

`%54` 是个**匿名函数**，四个参数，整个函数体就一条 `OpFunctionCall`，把四个参数原样转给 `%vector_add`。它是这个模块里**唯一**的 `OpFunctionCall`。

### 8.7.5 算术：为什么是 8，不是 12

模块里有**三个** `OpFunction`，每个 4 参数：

| 函数 | 参数数 | 被谁调用 |
|---|---|---|
| `%vector_add` | 4 | 被 `%54` 调用 |
| `%__clang_ocl_kern_imp_vector_add` | 4 | **没人调用** |
| `%54`（thunk） | 4 | 是 `OpEntryPoint` |

3 × 4 = **12**。NEO 报的是 **8**。

所以"NEO 把模块里所有函数的参数都算上了"**不成立**。8 = 4（入口点）+ 4（入口点调用的那个函数）。结合 8.7.3 已经否掉的 Export 假设，**唯一还站得住的读法是："入口点，加上它调用的函数"**。

backend 模块里 `OpFunctionCall` 是 0 次，所以 4 + 0 = **4**。两个数字都对上了。

这个加倍**跨元数成立**：换 2 参数的内核，核显报 4；换 3 参数的，报 6；4 参数的，报 8。是"×2"，不是"+4"。

### 8.7.6 干预实验：把 thunk 拆掉

相关性不等于因果。Case 1 和 Case 2 在**很多**方面不同——SPIR-V 版本、生成器、体积、bound、入口点形状。只观察到"Case 2 计数翻倍"，说不出是哪一个差异造成的。

所以 Case 3 **只改一样东西**：拿 translator 自己的模块，把 `OpEntryPoint` 重新指向 `%vector_add`，按位置删掉 thunk 那一段。版本、生成器、其余每一条指令**都是 `llvm-spirv` 原样产出的**。

`tools/spirv-route-probe/build.ps1` 里这段编辑是**从反汇编文本里读出 id**，不硬编码：

```powershell
$entryLine = $lines | Where-Object { $_ -match '^\s*OpEntryPoint\s+Kernel\s+(\S+)' } | Select-Object -First 1
$thunkId = if ($entryLine -and $entryLine -match 'OpEntryPoint\s+Kernel\s+(\S+)') { $Matches[1] } else { $null }
```

（硬编码 `%54` 的话，换一个 `llvm-spirv` 版本编号一变，脚本就会去改错的函数，或者什么都不改却报成功。）

结果：

```text
=== CASE 3: CONTROL: same translator module, thunk removed, nothing else changed ===
[probe] key=uhd create=0 build=0 kernel=0 numargs=4 launch=0(CL_SUCCESS) verify=1024/1024
```

**`numargs` 从 8 降到 4，launch 从 `-52` 变成 `CL_SUCCESS`，数值 1024/1024。**

如果加倍的原因是版本、生成器或 bound，这一刀不该有任何效果。它有效果，而且效果正好是去掉的那个东西——**thunk 就是原因**。

### 8.7.7 这是 NEO 特有的，不是 SPIR-V 的

同一个**未经修改的** translator 模块（带 thunk 的那个）：

| 设备 | `numargs` | launch | verify |
|---|---|---|---|
| Intel UHD Graphics 630（NEO） | **8** | `-52 CL_INVALID_KERNEL_ARGS` | `-1/1024`（没跑） |
| Intel Core i7-9700 CPU（Intel OpenCL runtime） | **4** | `0 CL_SUCCESS` | **1024/1024** |

两个都是 Intel 的实现，读同一个文件，给出**不同的参数个数**。CPU 运行时把 thunk 看穿了，NEO 没有。

所以这不是"SPIR-V 模块有问题"，也不是"`llvm-spirv` 产出了坏东西"——那个模块**完全合法**（8.3.4 的六个环境全过），而且**有一个 Intel 实现能正确运行它**。这是 **NEO 对带 thunk 入口点的模块的一个实现层面的行为**。

### 8.7.8 探针的五个用例

`tools/spirv-route-probe/build.ps1 -Destructive` 的汇总：

```text
MATCH      1    backend route: the entry point IS the kernel
MATCH      2    translator route: thunk entry point doubles the count on the iGPU only
MATCH      3    CONTROL: same translator module, thunk removed, nothing else changed
MATCH      4    cpp route: templated OpenCL C++ source, -cl-std=CLC++
MATCH      5    DESTRUCTIVE: bind all 8 advertised slots; the iGPU driver aborts
5 case(s) tested, 0 not tested, 0 unexpected
[RESULT] PASS
```

每个用例都带 `Require`（必须出现的输出串）和 `Forbid`（不得出现的输出串）。Case 1 的 `Forbid` 是 `@('numargs=8')`，Case 3 也是——**这就把"计数恢复正常"从一句叙述变成了一个会失败的检查**。

Case 3 在缺 `spirv-dis`/`spirv-as` 时报 **`NOT TESTED`**，既不算通过也不算失败。一个缺失的测量被明确标成缺失，而不是被悄悄提升成它本该支持的那条结论的证据。

### 8.7.9 驱动 abort：相信 `CL_KERNEL_NUM_ARGS` 的代价

如果不 launch、而是**老老实实按驱动报的 8 个参数去绑**，会发生什么？这是 Case 5，`-Destructive` 开关后面：

```text
=== CASE 5: DESTRUCTIVE: bind all 8 advertised slots; the iGPU driver aborts ===
[setarg] key=uhd index=0 -> 0(CL_SUCCESS)
[setarg] key=uhd index=1 -> 0(CL_SUCCESS)
[setarg] key=uhd index=2 -> 0(CL_SUCCESS)
[setarg] key=uhd index=3 -> 0(CL_SUCCESS)
Abort was called at 211 line in file:
    (exit -1073740791)
```

`-1073740791` = **`0xC0000409`**（`STATUS_STACK_BUFFER_OVERRUN`，也就是 `__fastfail`）。前四个索引返回 `CL_SUCCESS`，第五个（索引 4，即源码元数之外）**不是返回 `-49 CL_INVALID_ARG_INDEX`，而是终止进程**。

三个要点：

1. **这是一个 `abort()`，不是错误码。** 应用程序**无法捕获**，无法优雅降级。一个"我信任驱动报的参数个数"的程序，在这里直接死掉。
2. **驱动本身没坏。** 进程终止后，后续的 OpenCL 调用在新进程里照常工作——Case 5 是最后一个用例，跑完汇总仍然 `PASS`。
3. **这个用例默认不跑**，因为它会终止进程。`build.ps1` 需要显式 `-Destructive`。

> 把 8.7.1 和 8.7.9 放在一起看，就是这一篇最实用的一条：**`CL_KERNEL_NUM_ARGS` 对 IL 程序不是可信输入**。它可能报一个源码里没有的数字，而照着它做会**崩**，不是**报错**。要用 IL 程序，就必须在离线侧知道自己编出了什么形状的模块。

### 8.7.10 没有 IL 支持的设备：干净的 `-59`

对照实验（`examples/09` 第 11 步，RTX 2060）：

```text
[no-il] NVIDIA GeForce RTX 2060 : clCreateProgramWithIL -> -59 CL_INVALID_OPERATION
```

**这才是正确的失败方式**——一个错误码，进程活着。8.7.9 那个 `abort()` 之所以是缺陷，正是因为它有这个对照：同一个 API，一台设备给出错误码，另一台终止进程。

## 8.8 OpenCL C++ 到 SPIR-V

原始资料写：

```cpp
// kernel.clcpp - OpenCL C++ 内核
kernel void vector_add(global const float* a, global const float* b,
                       global float* c, const int n) {
    int idx = get_global_id(0);
    if (idx < n) { c[idx] = a[idx] + b[idx]; }
}
```

```bash
clang++ -cl-std=c++ -target spirv64 -c kernel.clcpp -o kernel.spv
```

### 8.8.1 `-cl-std=c++` 不是一个合法值

实测（exit code 1）：

```text
error: invalid value 'c++' in '-cl-std=c++'
```

`-cl-std=C++`（大写）同样被拒。本机 clang 接受的全部值，逐个单独编译实测：

| 值 | 结果 |
|---|---|
| `CL1.1` | 接受 |
| `CL1.2` | 接受 |
| `CL2.0` | 接受 |
| `CL3.0` | 接受 |
| **`CLC++`** | **接受** |
| `CLC++1.0` | 接受 |
| `CLC++2021` | 接受 |
| `clc++` | 接受（大小写不敏感） |
| `c++` | **拒绝** |
| `C++` | **拒绝** |
| `CL2.1` | **拒绝**（没有 2.1 这个语言级别） |

正确的写法是 **`-cl-std=CLC++`**。

原文用的驱动名 `clang++` **本身不是错误**——本机 `clang++` 存在，且

```text
clang++ -c -target spirv64-unknown-unknown '-cl-std=CLC++' kernels\vector_add_cpp.cl -o ...   exit 0
```

与用 `clang` 产出同样的模块。`.cl` 后缀被两个驱动都识别为 OpenCL 源，语言级别由 `-cl-std` 决定，不由驱动名决定。**原文那一行唯一错的是 `c++` 这个值。**

### 8.8.2 那个"OpenCL C++ 内核"里没有任何 C++

原文给的示例，内容**全是 OpenCL C**——没有模板、没有类、没有 `auto`。一个只含 C 的 C++ 文件**什么也证明不了**：它在 `-cl-std=CL1.2` 下同样能编过。

`examples/09-spirv-il/kernels/vector_add_cpp.cl` 因此写成了真正用到 C++ 构造的形式：

```c
template <typename T>
struct Adder {
    static T apply(T x, T y) { return x + y; }
};

kernel void vector_add(global const float* a, global const float* b,
                       global float* c, int n) {
    int i = get_global_id(0);
    if (i < n) c[i] = Adder<float>::apply(a[i], b[i]);
}
```

模板和带静态成员的 struct **不是装饰**，它们正是 `-cl-std=CL1.2` 会直接拒绝的构造（实测 exit 1）：

```text
kernels/vector_add_cpp.cl:17:1: error: unknown type name 'template'
   17 | template <typename T>
      | ^
kernels/vector_add_cpp.cl:17:10: error: expected identifier or '('
```

**所以这个文件能编过，本身就证明语言级别真的动了。**

参数顺序和语义与 `vector_add.cl` 刻意保持一致，这样 `tools/spirv-route-probe` 能用同一份参考数据跑它。第一版探测时我写的内核算的是 `a*2`，探针报 `verify=1/1024`——那个数字**在"C++ 路线坏了"和"探针的参考数据坏了"之间是有歧义的**。改成同语义之后才有可报告的结论。**一个有歧义的数值比没有数值更糟。**

### 8.8.3 与 C 模块只差一条指令

`build-spirv.ps1` 的 cpp 路线把两个模块的反汇编逐行对比，**并且断言差异必须只有 `OpSource` 一条**：

```text
=== cpp: OpenCL C++ source, -cl-std=CLC++ ===
    clang exit 0
    1416 bytes | SPIR-V 1.4 | LLVM SPIR-V Backend | bound 94 | magic ok
    spirv-val exit 0
    disassembly: 89 lines (C) vs 89 lines (C++)
      [C++] OpSource OpenCL_C 200000
      [C  ] OpSource OpenCL_C 102000
    differs only in OpSource: the C++ abstraction generated identical code
```

断言逻辑：

```powershell
$onlySource = ($diff.Count -eq 2) -and
    (@($diff | Where-Object { $_.InputObject -notmatch '^\s*OpSource\s' }).Count -eq 0)
if ($onlySource) {
    Write-Host "    differs only in OpSource: the C++ abstraction generated identical code"
} else {
    Write-Host "    FAIL: expected exactly one differing instruction (OpSource), got $($diff.Count)"
    Write-Host "          docs/08-spirv.md describes this comparison and must be re-measured"
    $failed++
}
```

（`Compare-Object` 对"一条指令不同"会给出 **2** 行——左右各一行。第二个条件确保这 2 行**都是** `OpSource`，否则断言失败。那句 `docs/08-spirv.md ... must be re-measured` 是写给未来的人的：如果哪天 clang 变了，本篇这一节就成了过期陈述，脚本会主动这么说。）

两个模块的 md5：

| 模块 | md5 |
|---|---|
| `vector_add.spv`（C，`-cl-std=CL1.2`） | `666fde89950447756586b96f90b65357` |
| `vector_add_cpp.spv`（C++，`-cl-std=CLC++`） | `214079bc9851c03c94e5976fc0363509` |

**3 个字节不同**，偏移 133–135（`cmp -l` 可验），正是 `OpSource` 的版本字面量的小端低三字节：

```text
102000 = 0x00018E70  →  70 8E 01 00
200000 = 0x00030D40  →  40 0D 03 00
```

第四个字节（最高位）两边都是 `00`，所以只差三个。

模板和静态成员函数**完全内联**，生成了与手写 C 逐指令相同的代码。

### 8.8.4 设备侧：两台 Intel 设备都跑通

"它编过了"和"驱动接受了"在这一篇已经分家过一次（8.7），所以 cpp 路线也有设备侧的一半，是探针的 Case 4：

```text
=== CASE 4: cpp route: templated OpenCL C++ source, -cl-std=CLC++ ===
[probe] key=uhd create=0 build=0 kernel=0 numargs=4 launch=0(CL_SUCCESS) verify=1024/1024
[probe] key=intelcpu create=0 build=0 kernel=0 numargs=4 launch=0(CL_SUCCESS) verify=1024/1024
```

`Forbid = @('numargs=8')`。cpp 路线走的是 backend 后端，所以入口点就是内核本体，没有 thunk——**这也从另一个方向印证了 8.7 的结论**：加倍与语言无关，只与入口点形状有关。

### 8.8.5 这与"本机没有设备能在运行时编译 OpenCL C++"并不矛盾

[07 篇 §7.8](./07-cpp-bindings.md) 记过一条：**本机没有任何设备的运行时编译器接受 OpenCL C++**——两块 GPU 的 `CL_DEVICE_OPENCL_C_VERSION` 都是 `OpenCL C 1.2`，Intel CPU 设备是 3.0 但不含 C++ for OpenCL。

而 Case 4 刚刚在一个**模板内核**上跑通了 1024/1024，设备正是那台只报 OpenCL C 1.2 的核显。

**设备侧那一半不是推断出来的，是测出来的。** `tools\cl-build-probe\build.ps1` 的第 9–10 行把 `examples/09` 真正加载的那两个内核文件喂给核显自己的前端：

```text
=== ..\..\..\examples\09-spirv-il\kernels\vector_add.cl on 'UHD'  -> expect exit 0
    why this case is here: CONTROL: plain OpenCL C from the same directory builds
clCreateKernel("vector_add") -> 0 (CL_SUCCESS)
[RESULT] BUILD OK
    MATCH (exit 0)

=== ..\..\..\examples\09-spirv-il\kernels\vector_add_cpp.cl on 'UHD'  -> expect exit 1
    why this case is here: device front end rejects template; the offline SPIR-V route runs it
source       : F:\code\programming\OpenCL\examples\09-spirv-il\kernels\vector_add_cpp.cl
device       : Intel(R) UHD Graphics 630
opencl C ver : OpenCL C 1.2
clBuildProgram -> -11 (CL_BUILD_PROGRAM_FAILURE)
--- build log ---
1:17:1: error: unknown type name 'template'
1:17:10: error: expected identifier or '('
1:25:29: error: expected expression
1:25:23: error: use of undeclared identifier 'Adder'
[RESULT] BUILD FAILED
    MATCH (exit 1)
```

第 9 行是**对照**：同一个目录下的纯 C 内核 `BUILD OK`，所以第 10 行的失败既不能怪路径解析，也不能怪这台设备编不了普通 OpenCL C。

这两行**故意指向 `fixtures/` 外面**（`..\..\..\examples\09-spirv-il\kernels\`）。把文件复制一份到 `fixtures/` 会让两份副本各自漂移，而这里要测的恰恰是"**同一个文件**被设备编译器拒绝、被离线 clang 接受"——复制会让这条断言变得不可证伪。

两者都成立，因为**这是两个不同的编译器**：

| | 谁在编译 | 什么时候 | 本机能力 |
|---|---|---|---|
| 源码路线 | **设备驱动里的**编译器 | `clBuildProgram` 时 | 核显只接受 OpenCL C 1.2；`-cl-std=c++` 无从谈起 |
| SPIR-V 路线 | **oneAPI 的 clang** | 程序运行**之前** | 接受 `CLC++`、模板、静态成员 |

`clCreateProgramWithIL` 交给驱动的已经是**编译完成的模块**，驱动只做后端代码生成，**不再有前端**。所以"设备不支持 OpenCL C++"限制的是**运行时编译**这条路，而 SPIR-V 路线**正好绕开了它**。

**这是本篇唯一一个"离线编译能做到的事比在线编译多"的具体例子**，也是原始资料"跨平台：一次编译，多处运行"那句话里唯一被本机证实的部分——不是"同一个模块能跑在更多设备上"（8.7.7 正好相反），而是"**离线编译器能接受设备编译器不接受的语言**"。

> **诚实边界**：这条路能走多远，本机只验证了一个模板 + 一个静态成员函数。OpenCL C++ 的其余部分（`cl::vector`、`pipe`、设备端 `enqueue`）在 SPIR-V 路线下能不能编、能不能被 NEO 消费，**没有测**。别把这一节读成"OpenCL C++ 在本机可用"——可用的只有"**能被 clang 编成 SPIR-V 且能被 NEO 加载的那一部分**"，而这个子集的边界本机没有探。

## 8.9 C++ 绑定侧：`cl.hpp` 的 IL 构造函数

原始资料写：

```cpp
#include <CL/cl2.hpp>
...
    std::string ilVersion;
    device.getInfo(CL_DEVICE_IL_VERSION, &ilVersion);
    if (ilVersion.empty()) {
        throw std::runtime_error("Device does not support IL programs");
    }
...
    cl_int err;
    cl::Program program = cl::Program(context, spvBinary, true, &err);
    if (err != CL_SUCCESS) {
        throw cl::Error(err, "Failed to create program from IL");
    }
    program.build(device);
```

（`<CL/cl2.hpp>` 本机不存在，见 [07 篇 §7.1](./07-cpp-bindings.md)；以下行号均指本机 `D:\cuda\13.3\include\CL\cl.hpp`。）

### 8.9.1 构造函数存在，但被版本宏门控

两个重载：

| 行号 | 签名 |
|---|---|
| `cl.hpp:6405` | `Program(const vector<char>& IL, bool build = false, cl_int* err = nullptr)` |
| `cl.hpp:6460` | `Program(const Context& context, const vector<char>& IL, bool build = false, cl_int* err = nullptr)` |

两者都在

```cpp
#if defined(CL_HPP_USE_IL_KHR) || CL_HPP_TARGET_OPENCL_VERSION >= 210
```

里面。本教程的 `build.ps1` 传 `/DCL_HPP_TARGET_OPENCL_VERSION=300`，所以可用。

`build = true` 时，`cl.hpp:6486-6497` 会替你调 `clBuildProgram`：

```cpp
error = ::clBuildProgram(
    object_,
    0,                        // ← 0 个设备 = 上下文里的全部
    nullptr,
#if !defined(CL_HPP_CL_1_2_DEFAULT_BUILD)
    "-cl-std=CL2.0",          // ← 硬编码
#else
    "",
#endif
    nullptr, nullptr);
```

两处要注意：**设备数传 0**（上下文里所有设备都构建），以及**构建选项硬编码 `-cl-std=CL2.0`**（除非定义了 `CL_HPP_CL_1_2_DEFAULT_BUILD`）。这与 [07 篇 §7.7](./07-cpp-bindings.md) 里源码构造函数的行为是同一个设计，也是同一个坑。

### 8.9.2 `if (err != CL_SUCCESS)` 是**死代码**

`cl.hpp` 的顺序是：

```cpp
detail::errHandler(error, __CREATE_PROGRAM_WITH_IL_ERR);   // 6484：这里就抛了
...
if (err != nullptr) { *err = error; }                      // 6502：这里才写
```

**`errHandler` 在 `*err` 之前**。开了异常（`CL_HPP_ENABLE_EXCEPTIONS`）的话，出错时构造函数**直接抛**，`*err` **永远不会被写**。

`examples/08-cpp-bindings/main.cpp` 第 12 节用一个哨兵值实测了这一点——把模块的 magic 首字节改成 `0xFF`，`sentinel` 预置为 `12345`：

```text
[il-cpp] constructing from a module with a corrupt magic...
[il-cpp]   threw cl::Error -42 CL_INVALID_BINARY (clCreateProgramWithIL)
[il-cpp]   *err is still 12345: it is written after errHandler,
[il-cpp]   so a caller's if(err != CL_SUCCESS) never runs
```

**`*err` 仍然是 12345**，构造器抛的是 `-42 CL_INVALID_BINARY`。

所以原文那个 `throw cl::Error(err, "Failed to create program from IL")` **永远执行不到**，它拼出来的那条错误消息**谁也看不见**。真正抛出的是 `clCreateProgramWithIL` 这个名字（见 [07 篇 §7.5.1](./07-cpp-bindings.md)：`cl::Error::what()` 返回的是 C 入口点名）。

**结论**：开着异常用绑定时，`cl_int* err` 这个出参**只有成功路径上有意义**。要检查失败，用 `try`/`catch`。

### 8.9.3 `getInfo<CL_DEVICE_IL_VERSION>()` 那半段是**对的**

原文用 `std::string ilVersion` + `.empty()` 判空。这一处**恰好正确**，因为 `cl.hpp:1506` 的特化是：

```cpp
F(cl_device_info, CL_DEVICE_IL_VERSION, string)
```

`getInfo<CL_DEVICE_IL_VERSION>()` 返回 `std::string`，绑定内部会先做 size 查询再取字符串，空值就是空 `std::string`。**8.5.2 那个 `size == 0` 的 fail-open 在这里不存在**——这是绑定比裸 C API 好的一处，值得点名。

### 8.9.4 `program.build(device)` 是多余的

构造时 `build = true` 已经调过 `clBuildProgram` 了（8.9.1）。再 `build(device)` 是第二次构建。对 IL 程序它不会报错（8.10.3 会看到构建选项对 IL 程序根本没有意义），但它是**白做的一次往返**。

### 8.9.5 "完整使用示例"在本机必然抛异常

原文 `main()` 里：

```cpp
cl::Platform platform = platforms[0];
platform.getDevices(CL_DEVICE_TYPE_GPU, &devices);
cl::Device device = devices[0];
```

本机 `platforms[0]` 是 **NVIDIA CUDA**，`devices[0]` 是 **RTX 2060**——8.1 表里那台 `CL_DEVICE_IL_VERSION` 为**空**的设备。

于是这段"完整使用示例"在本机的执行路径是：`getInfo<CL_DEVICE_IL_VERSION>()` 得到空串 → `throw std::runtime_error("Device does not support IL programs")`。**它一次也走不到 `clCreateProgramWithIL`。**

这与 [07 篇 §7.10 第 4 条](./07-cpp-bindings.md) 是同一个缺陷，只是在这一篇里它的后果更直接：C++ 版**连一个 `cl_int` 都不给你**，只有一个异常。修法是遍历所有平台按名字匹配（`examples/common/ocl_util.h` 的 `ocl_pick_device`）。

### 8.9.6 实测输出

`examples/08-cpp-bindings` 第 12 节（读的是 `..\09-spirv-il\spv\vector_add.spv`，所以要先跑 `build-spirv.ps1`；找不到文件时报 **SKIPPED** 而不是 FAILED——缺工具链不是程序坏了）：

```text
[il-cpp] ..\09-spirv-il\spv\vector_add.spv : 1416 bytes
[il-cpp] CL_DEVICE_IL_VERSION = 'SPIR-V_1.2 ' -> IL supported
[il-cpp] good module: *err = 0 CL_SUCCESS
[il-cpp] CL_PROGRAM_BUILD_OPTIONS = '-cl-std=CL2.0'
[il-cpp] CL_KERNEL_NUM_ARGS = 4 (the source declares 4)
[il-cpp] 1024/1024 elements correct through the C++ binding
assert the IL constructor loads and runs         : OK
[RESULT] PASS
```

`CL_PROGRAM_BUILD_OPTIONS = '-cl-std=CL2.0'` 就是 8.9.1 那个硬编码的回读证据——**没人要求过这个选项**，而它出现在程序的构建选项里。

> 一个构建系统的坑：根 `build.ps1` 的增量判断只看 `*.c, *.cpp, *.cl, *.h, *.hpp`（第 100 行），**改了 `.spv` 不会触发 `examples/08` 重跑**。跨例子的 `.spv` 依赖需要 `-Rebuild`。

## 8.10 IL 程序的运行时查询，与源码程序不一样

### 8.10.1 `CL_PROGRAM_IL` 能逐字节读回来

原始资料最后一段的写法是对的。实测：

```text
[readback] CL_PROGRAM_IL size query -> 0 CL_SUCCESS, size=1416
[readback] -> 0 CL_SUCCESS, 1416 bytes, identical to the file: yes
```

**逐字节相同**（`memcmp` == 0）。NEO 原样保存了输入模块，没有重新序列化。这意味着"缓存编译后的 SPIR-V"（原文最佳实践第 4 条）在本机是可行的，而且从程序里读回来和从文件里读是一回事。

### 8.10.2 `CL_PROGRAM_NUM_KERNELS` 与 `CL_PROGRAM_KERNEL_NAMES` 不一致

```text
[readback] CL_PROGRAM_NUM_KERNELS -> -30 CL_INVALID_VALUE, value=0
[readback] CL_PROGRAM_KERNEL_NAMES -> 'vector_add'
```

同一个程序，**计数查询失败而名字查询成功**。规范上两者都要求程序处于"已成功构建"状态，而这个程序确实构建成功了（8.6.1）。

`examples/09` 把这一处的**错误码一起打印**，因为只打印值的话，`-30` 留下的 `nk = 0` 会被读成"这个程序有 0 个内核"。**一个不检查错误码的 `printf` 会把驱动的不一致变成你的逻辑错误。**

### 8.10.3 构建选项对 IL 程序没有意义，对源码程序则**检查错了对象**

`examples/09` 第 8 步把四个 `-cl-std` 值在**同一个内核**的 IL 程序和源码程序上各扫一遍：

```text
[options] IL program,     "-cl-std=CL1.2" -> 0 CL_SUCCESS
[options] IL program,     "-cl-std=CL2.0" -> 0 CL_SUCCESS
[options] IL program,     "-cl-std=CL3.0" -> 0 CL_SUCCESS
[options] IL program,     "-cl-std=CL9.9" -> 0 CL_SUCCESS
[options] source program, "-cl-std=CL1.2" -> 0 CL_SUCCESS
[options] source program, "-cl-std=CL2.0" -> 0 CL_SUCCESS
[options] source program, "-cl-std=CL3.0" -> 0 CL_SUCCESS
[options] source program, "-cl-std=CL9.9" -> -11 CL_BUILD_PROGRAM_FAILURE
[build log] -cl-std OpenCLC version greater than OpenCL (API) version
```

**IL 那一列四个全过，包括一个根本不存在的语言级别 `CL9.9`。** 这符合直觉：模块在离线编译时就把语言级别记进了 `OpSource`，运行时已经没有源码可以给选项作用了。

**源码那一列才是意外。** 这台设备的 `CL_DEVICE_OPENCL_C_VERSION` 是 **`OpenCL C 1.2`**，而 `-cl-std=CL2.0` 和 `-cl-std=CL3.0` 都返回 **`CL_SUCCESS`**。

> 跑之前写下的预测是：CL2.0 会被**拒绝**，因为设备只实现 OpenCL C 1.2。**预测错了。** 错了之后没有把注释留着，而是加了一个 `CL9.9` 去区分两种可能的解释——如果 CL9.9 也被接受，说明 NEO 完全不看 `-cl-std`；如果它被拒绝，说明 NEO **检查了这个 token，但比对的是另一个版本号**。是后者。

那行构建日志把机制说清楚了：

```text
-cl-std OpenCLC version greater than OpenCL (API) version
```

**NEO 比对的是 `CL_DEVICE_VERSION`（3.0），不是 `CL_DEVICE_OPENCL_C_VERSION`（1.2）。** CL3.0 通过而 CL9.9 失败，正好印证日志的措辞是"**大于**"而不是"大于等于"。

**可操作的后果**：在一台 API 3.0、编译器只有 1.2 的设备上，你可以要求 OpenCL C 2.0，从 `clBuildProgram` 拿到 `CL_SUCCESS`，然后**只在一个 2.0 独有的构造编译失败或静默无效时**才发现语言级别从未被兑现。`-cl-std` **不能**用来探测设备是否太旧。

### 8.10.4 `clGetKernelArgInfo`：只有参数名丢了

这一节原来写的是"对 IL 程序返回垃圾"。**那个说法是错的**，而且错得很有代表性，所以把过程留下来。

`examples/09` 第 10 步做的不是"查一下 IL 内核的参数信息"，而是**对照**：同一个 `.cl` 文件，一个走 IL 路径，一个走 `clCreateProgramWithSource`，同一台设备、同一次运行里各查一遍：

```text
[arginfo] il     arg0: addr=4507 err=0 | acc=4515 err=0 | type='float*' err=0 | name='' err=0
[arginfo] il     arg1: addr=4507 err=0 | acc=4515 err=0 | type='float*' err=0 | name='' err=0
[arginfo] il     arg2: addr=4507 err=0 | acc=4515 err=0 | type='float*' err=0 | name='' err=0
[arginfo] il     arg3: addr=4510 err=0 | acc=4515 err=0 | type='int'    err=0 | name='' err=0
[arginfo] source arg0: addr=4507 err=0 | acc=4515 err=0 | type='float*' err=0 | name='a' err=0
[arginfo] source arg1: addr=4507 err=0 | acc=4515 err=0 | type='float*' err=0 | name='b' err=0
[arginfo] source arg2: addr=4507 err=0 | acc=4515 err=0 | type='float*' err=0 | name='c' err=0
[arginfo] source arg3: addr=4510 err=0 | acc=4515 err=0 | type='int'    err=0 | name='n' err=0
```

那些看着像未初始化内存的数字，对着 `cl.h:769-782` 一查**全是合法枚举值**：

| 值 | 十六进制 | 名字 | 对不对 |
|---|---|---|---|
| 4507 | `0x119B` | `CL_KERNEL_ARG_ADDRESS_GLOBAL` | arg0–2 是 `global float*`，**对** |
| 4510 | `0x119E` | `CL_KERNEL_ARG_ADDRESS_PRIVATE` | arg3 是 `int n`，**对** |
| 4515 | `0x11A3` | `CL_KERNEL_ARG_ACCESS_NONE` | 四个参数都没有 access 限定符，**对** |

而且**两列一模一样**，只有 `name` 不同。错误码全是 `0`。

**所以正确的结论窄得多**：IL 程序的 `clGetKernelArgInfo` **照常工作**，地址空间限定符、访问限定符、类型名三项与源码构建的内核**完全一致**；**唯一丢失的是 `CL_KERNEL_ARG_NAME`**。

原因在模块里看得见。8.4 那段反汇编里 `OpName` 出现了三次，全是**函数**：

```text
               OpName %vector_add "vector_add"
               OpName %__spirv_BuiltInGlobalInvocationId "__spirv_BuiltInGlobalInvocationId"
               OpName %__clang_ocl_kern_imp_vector_add "__clang_ocl_kern_imp_vector_add"
```

而那八个 `OpFunctionParameter`（`%12 %13 %14 %16` 与 `%28 %29 %30 %32`）**一个 `OpName` 都没有**。参数名从来没被写进模块，驱动自然给不出来。

**可操作的结论**：

- 想按**类型**做反射（例如自动生成绑定代码），IL 程序**够用**。
- 想按**名字**找参数（`clCreateKernel` 之后按 `"a"` 定位索引），IL 程序**不行**，必须按位置。
- 要保住参数名，得让离线编译器把 `OpName` 写进参数——本机这两条路线都不写。

> **这一节的方法论比结论重要。** 单看 IL 那一列，`addr=4507 acc=4515` 加上空名字，读起来就是"驱动返回了未初始化内存"，我自己第一次就是这么记的。**加一列源码构建的对照，同一个数字立刻变成了合法枚举值。** 一个"看起来像垃圾"的值，在没有对照组的情况下是无法解释的——它既可能是驱动坏了，也可能是你不认识那个编码。这也是 `examples/09` 里这一步**故意不带断言**的原因：这些值是这台驱动和这条工具链的性质，不是这个例子该强制的契约；换一个保留参数元数据的驱动，断言会失败，而它的行为其实**更好**。

## 8.11 SPIR-V 与源码编译对比：原表逐行核对

原始资料写：

| 特性 | 源码编译 | SPIR-V 编译 |
|------|----------|-------------|
| 编译时间 | 运行时编译 | 预编译，加载快 |
| 代码保护 | 源码可见 | 二进制格式 |
| 跨设备 | 需要重新编译 | 可跨设备使用 |
| 调试 | 较容易 | 需要特殊工具 |
| 文件大小 | 较小 | 较大 |

| 行 | 本机核对结果 | 通道 |
|---|---|---|
| 编译时间 | **未测**。`examples/09` 没有对两条路线计时 | 诚实边界，见 8.13 |
| 代码保护 | **不成立**，函数名、类型、控制流全在（8.4） | 离线工具链级 |
| 跨设备 | **部分成立，但有陷阱**。同一个模块在 Intel CPU 上跑通、在核显上 launch `-52`（8.7.7） | 运行时数值级 |
| 调试 | 成立。而且比原文说的更具体：参数**名**丢失（8.10.4），构建日志是空的（8.6.1），`CL_PROGRAM_NUM_KERNELS` 直接 `-30`（8.10.2） | 运行时数值级 |
| 文件大小 | **无法比较**。模块 1416 B，对应源码 977 B（其中大半是注释）——但源码不是预编译产物，两者不是同一个东西的两种大小 | — |

"跨设备"这一行值得多说一句。原文的意思大概是"一个模块可以喂给不同厂商的设备"。本机实测到的是：**同一个合法模块，同一厂商的两个实现，一个接受一个不接受**。跨设备的可移植性**不是**由 `spirv-val` 保证的（8.3.4），也不是由 `CL_DEVICE_IL_VERSION` 的版本号保证的（8.7.2）。

## 8.12 "最佳实践"五条逐条核对

| # | 原始资料 | 本机核对 |
|---|---|---|
| 1 | 确保目标设备支持相应的 SPIR-V 版本 | **查 `CL_DEVICE_IL_VERSION` 只能告诉你"空 / 非空"**。本机核显广告 1.2 却接受了 1.4 的模块（8.6.1）。版本号**不能**用来预判加载结果 |
| 2 | 使用 `spirv-opt` 优化 | 本例上是 **no-op**：1416 B → 1416 B（8.3.3）。而且它会改 bound 和生成器，让"模块有没有被动过"的校验失效 |
| 3 | 始终检查 `clCreateProgramWithIL` 的返回值 | **对**。而且这是唯一可靠的检查——8.5.1 的设备查询写法和 8.5.2 的 size 惯用法都不可靠。用 C++ 绑定时，检查方式是 `catch`，不是 `err` 出参（8.9.2） |
| 4 | 缓存编译后的 SPIR-V 以减少加载时间 | **可行**。`CL_PROGRAM_IL` 能逐字节读回（8.10.1）。但"减少加载时间"这个收益本机**没有计时验证** |
| 5 | 使用 `spirv-val` 验证 | **必要但远不充分**。18 格矩阵全过，其中一个模块在核显上跑不了（8.3.4）。`spirv-val` 验证的是规范符合性，不是驱动可消费性 |

补一条原文没有、但本篇证据支持的：

> **6. 别相信 `CL_KERNEL_NUM_ARGS`。** 对 IL 程序它可能报一个源码里没有的数字（8.7.1），而照着它绑定参数会**终止进程**（8.7.9）。参数个数应当从离线侧（反汇编，或你自己的源码）来。

## 8.13 诚实边界

以下几条本机**无法验证**，明确标注：

> **诚实边界 1：加载速度。** 原文说 SPIR-V "预编译，加载快"。本机**从未对两条路线计时**。`examples/09` 测的是正确性（1024/1024）和错误码，不是耗时。要验证需要一个大得多的模块和多次重复测量，而本篇没有做。当作未测。

> **诚实边界 2：跨厂商可移植性。** 本机只有**一个厂商**（Intel）的设备支持 IL，而且是两个不同的实现（NEO 与 CPU 运行时）。"SPIR-V 可以跨厂商"这个说法在本机**没有证据**，正反都没有。NVIDIA 那台设备根本不支持 IL，所以连一次跨厂商尝试都做不了。

> **诚实边界 3：SPIR-V 1.5 / 1.6。** 本机工具链**产不出** 1.5 或 1.6 的模块（backend 固定在 1.4，translator 的 `--spirv-max-version` 是上限不是目标），本机设备也**没有一台广告** 1.5 或 1.6。原表"OpenCL 3.0 → 完整 SPIR-V 1.5 支持"这一格，本机既不能证实也不能否证——只能证明**这个推断方式在三台 3.0 设备上都不成立**（8.1）。

> **诚实边界 4：thunk 加倍的机制。** 8.7 证明的是"**thunk 是原因**"（干预实验）和"**计数 = 入口点 + 被它调用的函数**"（三个函数的算术 + 跨元数加倍）。但 NEO **为什么**这么算——是把 callee 的参数表并进了入口点，还是别的路径——本机没有 NEO 源码，**无法确定**。8.7.5 给的是唯一与全部观测相容的读法，不是内部实现。

> **诚实边界 5：`spirv-cfg` 的图。** 只验证到"exit 0，产出 618 字节非空文件"。本机没有 Graphviz，**没有看过那张图**。

> **诚实边界 6：驱动 abort 的具体位置。** `Abort was called at 211 line in file:` 这一行**没有文件名**——NEO 的这条消息本身就缺了它。所以"211 行是哪个文件的 211 行"本机无法确定。可确定的只有：`0xC0000409`，且发生在第五个 `clSetKernelArg` 上。

## 8.14 原教程 SPIR-V 部分的逐条修正

| # | 原始资料 | 问题 | 修正 | 通道 |
|---|---|---|---|---|
| 1 | 版本表："OpenCL 3.0 → 完整 SPIR-V 1.5 支持" | 本机三台 3.0 设备分别是**空**、**1.2**、**1.4**。API 版本推不出 IL 能力 | 只查 `CL_DEVICE_IL_VERSION`（8.1） | 设备元数据级 |
| 2 | "保护知识产权：二进制格式，难以逆向工程" | 函数名、参数类型、控制流、源语言级别**全在**；`spirv-dis` 不加任何参数就能看到；还能 `-r` 还原成 IR | 改成"去掉了注释与源码结构，保留符号与类型"（8.4） | 离线工具链级 |
| 3 | `cl_bool supportsIL; clGetDeviceInfo(..., sizeof(supportsIL), &supportsIL, NULL)` | 字符串查询读进 4 字节 → `-30 CL_INVALID_VALUE`，变量**保持原值**（还没初始化） | 读字符串，判 `got > 1 && [0] != '\0'`（8.5.1、8.5.3） | 设备元数据级 |
| 4 | `if (ilVersionSize == 0)` | **fail-open**：空字符串 size 是 **1**。本机 RTX 2060 被这个检查**放行** | `size <= 1`，或直接读字符串（8.5.2） | 设备元数据级 |
| 5 | `clang -cl-std=CL2.0 -target spirv64 -c kernel.cl` | `-target spirv64` 不是完整三元组；`CL2.0` 高于本机核显的编译器级别 | `-target spirv64-unknown-unknown '-cl-std=CL1.2'`（8.2） | 离线工具链级 |
| 6 | `opencl-c-compiler` | **本机不存在**，两个 SDK 都没有 | 删掉；用 `clang` 或 `clang` + `llvm-spirv`（8.2） | 离线工具链级 |
| 7 | `size_t lengths[1] = { size };` | 声明后**从未使用**，是从 `clCreateProgramWithSource` 抄来的 | 删掉；`clCreateProgramWithIL` 只要一块内存 + 一个 `size_t`（8.6） | 文档核对 |
| 8 | `fread(spvBinary, 1, size, fp);` | 返回值未检查 | 检查短读（8.6，`read_binary`） | 主机编译级 |
| 9 | `#include <CL/cl2.hpp>` | 本机不存在 | `<CL/cl.hpp>`（[07 篇 §7.1](./07-cpp-bindings.md)） | 主机编译级 |
| 10 | `cl::Program program = cl::Program(context, spvBinary, true, &err); if (err != CL_SUCCESS) throw ...` | **死代码**。`errHandler`（`cl.hpp:6484`）在 `*err = error`（`cl.hpp:6502`）**之前**，出错时直接抛，`*err` 从不被写。实测哨兵值 `12345` 保持不变 | 用 `try`/`catch`；`err` 出参只在成功路径有意义（8.9.2） | 主机编译级 + 运行时数值级 |
| 11 | 未提 IL 构造函数硬编码 `-cl-std=CL2.0` 且传 0 个设备 | `cl.hpp:6492` / `6488`。回读 `CL_PROGRAM_BUILD_OPTIONS` 就是 `'-cl-std=CL2.0'` | 显式 `build("-cl-std=CL1.2")`，别用 `build = true`（8.9.1、8.9.6） | 运行时数值级 |
| 12 | `program.build(device)`（构造时已 `true`） | 重复构建 | 二选一（8.9.4） | 文档核对 |
| 13 | `platforms[0]` / `devices[0]` | 本机选中 **RTX 2060**，一台 `IL_VERSION` 为空的设备，"完整使用示例"**必然抛异常**，一次也到不了 `clCreateProgramWithIL` | 遍历平台按名字匹配（8.9.5） | 设备元数据级 |
| 14 | `clang++ -cl-std=c++ -target spirv64 -c kernel.clcpp` | `c++` **不是合法值**：`error: invalid value 'c++' in '-cl-std=c++'`，exit 1 | `-cl-std=CLC++`（8.8.1） | 离线工具链级 |
| 15 | 那段 "OpenCL C++ 内核"示例 | 内容**全是 C**，在 `-cl-std=CL1.2` 下同样能编，**证明不了任何事** | 用真正含模板/类的源码；本机 `vector_add_cpp.cl` 在 CL1.2 下报 `unknown type name 'template'`（8.8.2） | 离线工具链级 |
| 16 | `spirv-val kernel.spv` 作为正确性验证 | 18 格矩阵**全过**，其中一个模块核显跑不了 | 必要但不充分；还要在目标设备上真跑一次（8.3.4） | 离线工具链级 + 运行时数值级 |
| 17 | "使用 `spirv-opt` 优化" | 本例 no-op（1416 B → 1416 B），且改 bound 与生成器 | 按需使用，别当必经步骤（8.3.3） | 离线工具链级 |
| 18 | "跨设备：可跨设备使用" | 同一合法模块，Intel CPU 跑通、核显 `-52` | 加上"入口点形状必须匹配目标驱动"（8.7.7、8.11） | 运行时数值级 |
| 19 | 未提 `clGetKernelArgInfo` 对 IL 程序的限制 | **只有参数名丢失**：限定符与类型名与源码构建的内核**逐项相同**，`err` 全为 0，`name=''`。原因是模块里的 `OpName` 只给了函数，没给参数 | 按类型反射可用；按名字定位参数不可用，必须按位置（8.10.4） | 运行时数值级（含源码构建的对照列） |
| 20 | 未提 `CL_PROGRAM_NUM_KERNELS` 与 `KERNEL_NAMES` 不一致 | 前者 `-30 CL_INVALID_VALUE`，后者成功返回 `'vector_add'` | 打印值时必须一起打印错误码（8.10.2） | 运行时数值级 |
| 21 | 未提构建选项对 IL 程序无意义 | 四个 `-cl-std` 值（含不存在的 `CL9.9`）**全部** `CL_SUCCESS` | IL 程序不要指望构建选项（8.10.3） | 运行时数值级 |
| 22 | `-cl-std=CL2.0` 在源码程序上"应当"被 1.2 设备拒绝 | **预测被推翻**：返回 `CL_SUCCESS`。NEO 比对的是 `CL_DEVICE_VERSION`(3.0) 而非 `CL_DEVICE_OPENCL_C_VERSION`(1.2)，日志写的是 `greater than OpenCL (API) version` | `-cl-std` 不能用来探测设备能力（8.10.3） | 运行时数值级（含构建日志原文） |

## 8.15 小结

1. **本机三台设备都是 OpenCL 3.0，IL 支持却分别是"无"、"1.2"、"1.4"。** 原表"3.0 → 完整 1.5"的推断在三台上全不成立。唯一的判据是 `CL_DEVICE_IL_VERSION` 空不空。
2. **检测 IL 支持的两种流行写法都错，而且都错在危险的方向。** 读进 `cl_bool` → `-30`，变量保持原值；`if (size == 0)` → 空字符串 size 是 **1**，本机 RTX 2060 被放行。正确条件是 `got > 1 && str[0] != '\0'`。
3. **两条离线路线产出两个不同的模块**：backend（1416 B，SPIR-V **1.4**，生成器 21）与 translator（1864 B，SPIR-V **1.0**，生成器 14）。同一份源码，同一台机器，**核显只接受 backend 那个**。
4. **backend 路线没有任何开关能压低版本**——`--spirv-max-version` 是 `llvm-spirv` 的选项，clang 三种传递方式全部 exit 1。而 `--spirv-max-version` 是**上限不是目标**：translator 加了 `=1.2`，产出的仍是 1.0。
5. **核显广告 `SPIR-V_1.2`，却接受了 1.4 的模块并跑通 1024/1024。** 所以 `CL_DEVICE_IL_VERSION` 里的版本号**不能**用来预判加载结果。
6. **加倍的原因是入口点 thunk，这一点由干预实验确定，不是由相关性推断。** translator 模块的 `OpEntryPoint` 指向一个匿名转发函数，函数体只有一条 `OpFunctionCall`。把 `OpEntryPoint` 改指真内核、删掉 thunk，**其余一字不动**，`numargs` 从 8 降到 4，launch 从 `-52` 变成成功。SPIR-V 版本假设与 `Export` 装饰假设**都被推翻过**。
7. **算术排除了"数所有函数"**：模块里有三个 4 参数函数（= 12），NEO 报 8 = 入口点(4) + 被它调用的函数(4)。那个没人调用的 `__clang_ocl_kern_imp_*` 副本不计入。加倍跨元数成立：2→4、3→6、4→8。
8. **这是 NEO 特有的，不是 SPIR-V 的。** 同一个未修改的 translator 模块，Intel CPU 运行时报 `numargs=4` 且跑通 1024/1024。
9. **`spirv-val` 全过不能保证设备能跑。** 三个模块 × 六个 `--target-env`，**18 格全部 exit 0**，而其中一个是核显跑不了的那个。验证器检查规范符合性，不检查驱动可消费性。
10. **相信 `CL_KERNEL_NUM_ARGS` 会终止进程，不是报错。** 按驱动报的 8 个绑定，前四个 `CL_SUCCESS`，第五个是 `Abort was called at 211 line in file:` + **`0xC0000409`**。对照：一台不支持 IL 的设备给的是干净的 `-59 CL_INVALID_OPERATION`。
11. **`-cl-std=c++` 不是合法值**，正确写法是 **`-cl-std=CLC++`**。原文那段"C++ 内核"内容全是 C，在 CL1.2 下同样能编，**证明不了语言级别动过**；本机改用真含模板的源码，它在 CL1.2 下报 `unknown type name 'template'`。
12. **C++ 路线与 C 路线产出的模块只差一条指令**——`OpSource OpenCL_C 200000` vs `102000`，3 个字节，偏移 133–135。89 行反汇编，其余逐行相同。模板与静态成员**完全内联**。这条现在是 `build-spirv.ps1` 里的**硬断言**。
13. **离线路线绕开了设备侧编译器，这是本篇唯一"离线比在线能做得更多"的实例。** 那个模板内核跑在核显上（1024/1024），而核显自己的前端拒绝同一个文件（`-11`，`unknown type name 'template'`）。两者不矛盾：`clCreateProgramWithIL` 之后驱动**只做后端代码生成，没有前端**。这与 [07 篇 §7.8](./07-cpp-bindings.md) 的"本机没有任何设备能在运行时编译 OpenCL C++"同时成立，两侧都在 `tools\cl-build-probe\build.ps1` 第 9–10 行常驻断言（8.8.5）。
14. **构建选项对 IL 程序完全没有意义**：`CL1.2`/`CL2.0`/`CL3.0`/**`CL9.9`** 四个值全部 `CL_SUCCESS`。对源码程序则**检查错了对象**——NEO 比对 `CL_DEVICE_VERSION`(3.0) 而不是 `CL_DEVICE_OPENCL_C_VERSION`(1.2)，所以在 1.2 编译器上要求 OpenCL C 2.0 会得到 `CL_SUCCESS`。
15. **`cl.hpp` 的 IL 构造函数里，`cl_int* err` 出参在失败路径上从不被写**（`errHandler` 在 `*err = error` 之前）。实测哨兵值 `12345` 在抛出 `-42 CL_INVALID_BINARY` 之后**原封不动**。原文那个 `if (err != CL_SUCCESS) throw` 是死代码。
16. **IL 程序的运行时查询有两处陷阱**：`CL_PROGRAM_NUM_KERNELS` 返回 `-30` 而 `CL_PROGRAM_KERNEL_NAMES` 成功；`clGetKernelArgInfo` **只丢参数名**——限定符与类型名与源码构建的内核逐项相同（`4507`/`4510`/`4515` 是 `cl.h:769-782` 里的合法枚举值，不是垃圾），`err` 全为 0。`CL_PROGRAM_IL` 则能**逐字节**读回原模块。**这三个值只有在加了源码构建的对照列之后才可解释**——单看 IL 那一列，`addr=4507 acc=4515` 加空名字读起来就像未初始化内存。
17. **"难以逆向工程"不成立**：不加参数的 `spirv-dis` 就打印全部函数名与 `OpSource`，`strings` 也能捞到，`llvm-spirv -r` 还能还原成 3204 字节的 bitcode。
18. **SPIRV-Tools 在本机来自 Vulkan SDK，不是 oneAPI**；oneAPI 的工具集是裁剪过的，连 `llvm-dis` 都没有。`spirv-dis` 的文本与 `llvm-spirv --spirv-text` 的文本是**两种互不相容的格式**。
19. **PowerShell 会在参数里第一个点处切开**（`-cl-std=CL1.2` → `-cl-std=CL1` + 游散的 `.2`），PS 5.1 与 pwsh 7 行为相同，单引号是解法。

### 本机验证状态

| 结论 | 通道 | 复现方式 |
|---|---|---|
| 三设备 IL 支持表（空 / 1.2 / 1.4），均 OpenCL 3.0 | 设备元数据级 | `tools\clinfo-probe\build.ps1` |
| backend 1416 B / 1.4 / 生成器 21 / bound 94；translator 1864 B / 1.0 / 生成器 14 / bound 61 | 离线工具链级 | `build-spirv.ps1` |
| backend 无法压低版本（三种传参全 exit 1） | 离线工具链级 | 8.2.1 的三条命令 |
| `-cl-std` 合法值集合，`c++`/`C++`/`CL2.1` 被拒 | 离线工具链级 | 8.8.1 的逐个编译 |
| C++ 与 C 模块只差一条 `OpSource`（3 字节，偏移 133–135） | 离线工具链级 | `build-spirv.ps1` 的 cpp 路线**硬断言** |
| `spirv-val` 18 格全 exit 0；`--target-env` 必须小写且无 `opencl3.0` | 离线工具链级 | 8.3.4 的矩阵 |
| `spirv-opt -O` 是 no-op（1416 → 1416） | 离线工具链级 | 8.3.3 |
| `spirv-dis` → `spirv-as` 往返 exit 0，但 bound 94→50、生成器改变 | 离线工具链级 | 8.3.2 |
| 两种文本格式互不相容 | 离线工具链级 | 8.3.5 |
| "难以逆向工程"被推翻 | 离线工具链级 | `spirv-dis` 无参数 + `strings` + `llvm-spirv -r` |
| `cl_bool` 查询 → `-30`；size 查询 → 12（UHD）/ 1（NVIDIA） | 设备元数据级 | `examples\09-spirv-il` 第 2、11 步 |
| IL 模块加载、构建、launch、1024/1024 | 运行时数值级 | `examples\09-spirv-il`，`[RESULT] PASS` |
| `CL_PROGRAM_IL` 逐字节回读相同 | 运行时数值级 | 同上，第 9 步 |
| `CL_PROGRAM_NUM_KERNELS` `-30` vs `KERNEL_NAMES` 成功 | 运行时数值级 | 同上 |
| `-cl-std` 四值扫描 + 构建日志原文 | 运行时数值级 | 同上，第 8 步 |
| `clGetKernelArgInfo` 只丢参数名，其余与源码构建的内核逐项相同 | 运行时数值级 | `examples\09-spirv-il` 第 10 步（IL 列与 source 列并排打印） |
| thunk 导致 `numargs` 8；de-thunk 后 4 且 1024/1024 | 运行时数值级 + 离线工具链级 | `tools\spirv-route-probe\build.ps1`，Case 1/2/3 |
| 加倍跨元数成立（2→4、3→6、4→8） | 运行时数值级 | 用不同元数的内核重跑 `build-spirv.ps1` 与探针（元数是探针的第 3 个命令行参数）；**这一条不在常驻断言里** |
| Intel CPU 运行时对同一 thunk 模块报 4 且跑通 | 运行时数值级 | `tools\spirv-route-probe\build.ps1`，Case 2 的 `key=intelcpu` 行 |
| cpp 模块在两台 Intel 设备上 1024/1024 | 运行时数值级 | 同上，Case 4 |
| 模板内核跑在只接受 OpenCL C 1.2 的核显上（离线路线绕开设备前端） | 离线工具链级 + 内核编译级 + 运行时数值级 | `build-spirv.ps1` 的 cpp 路线 + `tools\spirv-route-probe\build.ps1` Case 4；对照 `tools\cl-build-probe\build.ps1` 的第 9–10 行（同一目录下，纯 C 内核 BUILD OK，模板内核 `-11`） |
| `clang++` 与 `clang` 对 `-cl-std=CLC++` 的 `.cl` 文件产出相同 | 离线工具链级 | 8.8.1 的 `clang++` 命令行 |
| 越界 `clSetKernelArg` → `abort()`，`0xC0000409` | 运行时数值级 | `tools\spirv-route-probe\build.ps1 -Destructive`，Case 5 |
| NVIDIA `clCreateProgramWithIL` → `-59 CL_INVALID_OPERATION` | 运行时数值级 | `examples\09-spirv-il` 第 11 步 |
| `cl.hpp` IL 构造函数：`errHandler` 在 `*err` 之前，哨兵 `12345` 不变 | 主机编译级 + 运行时数值级 | `examples\08-cpp-bindings` 第 12 节 |
| `CL_PROGRAM_BUILD_OPTIONS = '-cl-std=CL2.0'`（硬编码回读） | 运行时数值级 | 同上 |
| 加载速度、跨厂商可移植性、SPIR-V 1.5/1.6、NEO 内部机制 | **本机不可验证** | 见 8.13 诚实边界 |

---

上一篇：[07-cpp-bindings.md](./07-cpp-bindings.md) ｜ 下一篇：[09-practical-examples.md](./09-practical-examples.md) —— 实战篇：把前面八篇的构件组装成完整程序，以及本机设备能力**不支持**的那些特性（设备端队列、pipe、SVM 细粒度）各自卡在哪一步。
