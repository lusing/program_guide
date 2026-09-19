# 第 20 章 DLL 进阶与插件系统

> **本章回答的问题**：插件架构怎么设计才不出事？宿主怎么扫描、加载、校验、调用、卸载插件？`api-ms-win-*` 这些怪名字是什么？PE 文件里面长什么样？资源怎么住进 exe？
>
> **前置章节**：第 19 章（两种链接、`DllMain`、搜索顺序——插件系统把它们全部用上）。
>
> **你将做出什么**：一个双插件宿主（`examples/24_dll_plugin`）：扫描目录、显式加载、版本握手、调用计算、优雅卸载——插件机制的完整骨架。

本章示例：`examples/24_dll_plugin`（plugin_api.h / plugin_circle.cpp / plugin_square.cpp / main.cpp / build.ps1）。

## 20.1 插件契约三原则

插件系统 = 宿主 + 一组 DLL + 一份**契约**。契约设计错了，后面全是坑。三条原则：

**原则一：纯 C 接口。** 契约用 `extern "C"` 函数 + POD 结构体表达（24 示例的 `plugin_api.h`）。C++ 类/STL 类型跨 DLL 边界 = 绑死编译器版本与 CRT——宿主 MSVC 2019、插件 MSVC 2022，`std::string` 布局都未必一样。要面向对象？给函数表（结构体里放函数指针），或者走 COM（20.4）。

**原则二：版本号握手。** 契约开头放 `int apiVersion`，宿主加载后**先核对再使用**。契约演进时（加字段、改语义）版本 +1：旧宿主遇新插件、新宿主遇旧插件，都能礼貌拒绝而不是行为未定义。

**原则三：内存不跨界。** 谁分配谁释放——插件分配的东西要么插件自己提供释放函数，要么干脆不分配（24 示例的 `area` 是纯函数，返回值直接进寄存器，零内存往来）。混用两边的堆是插件系统崩溃的头号来源（第 19 章易错表的第三条在这里兑现）。

```cpp
// plugin_api.h —— 三原则的完整落地，全文件不到 20 行
#define PLUGIN_API_VERSION 1

typedef struct PluginInfo {
    int apiVersion;                          // 原则二
    const wchar_t* name;
    double (*area)(double r);                // 原则一/三：函数指针 + 纯函数
} PluginInfo;

typedef const PluginInfo* (*PFN_query_plugin)(void);   // 唯一导出
```

## 20.2 宿主五步：扫描、加载、校验、调用、卸载

`examples/24_dll_plugin/main.cpp` 把宿主写成标准五步循环：

```text
① 扫描：GetModuleFileNameW 找到自己 → 拼 "*.dll" → FindFirstFileW 遍历
② 加载：LoadLibraryW(裸文件名) → 搜索顺序把 exe 旁的插件带进来（19.6）
③ 校验：GetProcAddress("query_plugin")：
      取不到 → 不是我的插件（build\ 里还有 mathlib.dll 呢）→ 静默释放跳过
      取到了 → 调 query_plugin() → 对 apiVersion：
      不等   → [拒绝] 版本不匹配 → 释放退出，不崩不挂
④ 调用：info->area(2.5) —— 通过函数指针进到插件代码
⑤ 卸载：FreeLibrary —— 用完即还，引用计数归零才真卸载
```

三个设计决策值得抄走：

- **"取不到导出就静默跳过"**：目录里的 DLL 不全是插件（系统组件、别的示例），宿主必须容错扫描——把"不是我的"当错误报出来，用户会被垃圾信息淹没；
- **"版本不匹配就礼貌拒绝"**：打印双方版本号后释放退出。真实生态（浏览器扩展、音频插件）全靠这一步活着；
- **每次调用前 `FreeLibrary`**：示例插件用完即卸；真实宿主可能选择"常驻到退出"——取决于插件会不会被反复调用与更新需求（能卸载才能热更新）。

运行效果（`build\` 里同时有 mathlib.dll、plugin_circle.dll、plugin_square.dll）：

```text
[插件] 圆形（πr²）        area(2.5) = 19.6350
[插件] 正方形（a²）        area(2.5) = 6.2500
共加载 2 个插件            ← mathlib.dll 被静默跳过，正是设计的容错
```

## 20.3 版本协商：硬匹配之外

`apiVersion != PLUGIN_API_VERSION` 是最简单的**硬匹配**（相等才要）。进阶两种：

- **能力位（capability bits）**：版本号改成位掩码，宿主按需查"你支持多边形吗？支持 3D 吗？"——插件生态壮大后的主流做法；
- **多契约共存**：导出 `query_plugin_v1` / `query_plugin_v2` 两个入口，宿主按自己的新旧选——Photoshop 等老牌宿主的真实姿势。

## 20.4 COM 是更好的插件机制吗？

把本章的"契约"放大看：函数表结构体 ≈ 接口；`query_plugin` ≈ 类厂；版本握手 ≈ `QueryInterface`；"内存不跨界" ≈ 引用计数生命周期。**COM 就是把插件机制标准化到二进制层**的产物——契约即接口（vtable）、创建即类厂、版本协商即 `QueryInterface`、内存即 `IMalloc`。第 22~24 章你将手写一遍这套标准形态，回头看本章会发现：**你已经独立发明过 COM 的雏形**。

## 20.5 资源段：exe 里还能住什么

`.rsrc` 节存放资源：图标、光标、对话框模板、字符串表、版本信息、自定义二进制。第 10 章的对话框模板就住这里。资源的身份 = 类型 + 名称 + 语言，代码侧统一用 `FindResource`/`LoadResource`/`LockResource` 三步取：

```cpp
HRSRC rc = FindResourceW(hInst, MAKEINTRESOURCEW(IDR_DATA1), L"MYDATA");
HGLOBAL h = LoadResource(hInst, rc);       // 注意：这个"句柄"不需要释放
const void* data = LockResource(h);
DWORD size = SizeofResource(hInst, rc);
```

（`LoadResource` 是少数**不配对释放**的加载 API——资源随模块常驻。）用资源而非单独文件携带数据的理由：单文件分发、完整性、防误删。版本信息资源（`VS_VERSION_INFO`）还是文件"详细信息"页里那些文字的家。

## 20.6 PE 速览：DLL/EXE 的解剖图

DLL/EXE 都是 PE（Portable Executable）文件，结构从上到下：

```text
DOS 头（MZ 魔数）── "This program cannot be run in DOS mode" 的家
   │
NT 头 ── 签名 PE\0\0
   ├── 文件头（机器类型 x64/ARM64、节数量、时间戳）
   └── 可选头（入口点、Subsystem、DataDirectory[16]）
          └── ★ 导入表（依赖谁、要哪些函数）与导出表（给别人什么）
                    都在 DataDirectory 的槽位里被指到
节表与各节：
   .text  代码
   .data  可写数据
   .rdata 只读数据（常量、导入/导出表本体）
   .rsrc  资源
   .reloc 重定位（DLL 加载地址不定，靠它修正）
```

理解 PE 的回报：读得懂 `dumpbin /imports`（第 19 章欠条论的实体）、`dumpbin /exports`（你的 DLL 卖什么）、`dumpbin /dependents`（它依赖谁）；理解为什么 DLL 能被"内存映射"加载（第 15 章的映射机制——PE 的节就是按页属性映射的）；理解签名校验与防篡改落在哪里。用 `Dependencies`（开源工具）对着自己的 mathlib.dll 看一眼，一上午胜过十页文字。

## 20.7 API Set：为什么依赖列表里全是 `api-ms-win-*`

`dumpbin /dependents some.exe` 常看到：

```text
api-ms-win-crt-runtime-l1-1-0.dll
api-ms-win-core-file-l1-2-1.dll
ext-ms-win-ntuser-window-l1-1-0.dll
```

这些**不是真实文件**，是第 1 章提过的 **API Set 逻辑名**：加载器遇到这类名字时，查进程的 API Set 映射表，把请求转发到真正的实现 DLL（比如上面第一个会落到 `ucrtbase.dll`）。

设计动机：系统 DLL 需要不断重构拆分，如果应用直接依赖物理文件名，每次重构都破坏兼容；引入"逻辑名 → 物理名"间接层后，**重排内部结构对应用完全透明**。这也解释了 Win8+ 程序的依赖为什么看起来"虚"——虚的是名字，实的是兼容承诺。链接时你仍然只写 `kernel32.lib` 这类导入库，开发者日常无感；知道机制是为了读得懂工具输出、排查"为什么这台机器缺这个 api-ms 文件"（答案通常是它对应的目标 DLL 或系统更新缺失）。

## 20.8 DLL 地狱简史与现代对策

“DLL Hell”是 Win9x 时代的噩梦：A 软件装了 `msvcrt.dll` 2.0，B 软件覆盖成 3.0，A 当场暴毙。三代对策：

1. **Windows 文件保护 + 系统目录只读**（Win2000）：治了覆盖，治不了版本选择；
2. **SxS（Side-by-Side）**（XP/Vista）：同一 DLL 多版本共存于 WinSxS 仓库，程序用**清单（manifest）**声明要哪版——manifest 从此进入 Win32 词汇表；
3. **现代实践**：应用自带依赖（exe 旁目录，19.6 的第一条）+ VC 运行库有.redist 约定；`SetDefaultDllDirectories` 收紧搜索面。今天的 DLL Hell 主要剩下"PATH 里飘着的野 DLL"和"劫持攻击"两个变体——第 19 章的搜索纪律就是解药。

## 20.9 易错清单

| 错误 | 后果 |
|------|------|
| 契约里出现 C++ 类型/STL | 跨编译器版本即崩，纯 C 三原则（20.1） |
| 插件里 `new` 宿主里 `delete` | 双堆崩溃；谁分配谁释放 |
| 宿主扫到非插件 DLL 当错误报 | 垃圾告警淹没用户；静默跳过（20.2） |
| 版本不核对直接用 | 契约一改全线未定义行为；apiVersion 握手 |
| 插件卸载后宿主还缓存着函数指针 | 指进已卸载内存的野指针；先断引用再 FreeLibrary |
| `LoadResource` 后找 `FreeResource` | 不需要——资源常驻（20.5） |
| 靠文件名认依赖（api-ms-*） | 那是逻辑名，找文件永远找不到（20.7） |
| 版本地狱思维：覆盖系统 DLL | 现代 Windows 拒绝写 System32；自带依赖 |

## 20.10 小结

1. 插件契约三原则：纯 C 接口、版本号握手、内存不跨界——24 示例 20 行头文件全部落地。
2. 宿主五步：扫描→加载→校验→调用→卸载；"静默跳过非插件"与"礼貌拒绝错版本"是工程成熟度标志。
3. COM = 插件机制的二进制标准化（函数表→接口、query→类厂、版本→QI）——22 章见。
4. 资源三步取（Find/Load/Lock），`LoadResource` 免释放。
5. PE 五节 + 导入/导出表；`api-ms-win-*` 是逻辑名，间接层保兼容。
6. DLL Hell 三代对策走到"自带依赖 + manifest"。

## 20.11 动手练习

1. 写第三个插件 `plugin_triangle.cpp`（三角形面积，底×高/2），不改宿主代码直接扔进 `build\`，验证宿主自动发现——插件架构"开放扩展、关闭修改"的实证。
2. 把 `PLUGIN_API_VERSION` 改成 2 只重编译圆形插件：宿主应打印"[拒绝] 版本不匹配"——亲手制造并观察版本冲突。
3. 用 `dumpbin /exports build\plugin_circle.dll` 看导出表，再对 `build\24_dll_plugin.exe` 跑 `/dependents`——对照 20.6 的 PE 图把每一段都认出来。

---

**下一章**：[第 21 章 注册表](21-注册表.md)——Windows 的配置中心。
