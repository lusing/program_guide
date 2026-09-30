# cppgui —— C++ GUI 编程指南 macOS 兼容性验证报告

> 验证日期：2026-10-01
> 结论：**25 个示例中，19 个可验证目标全部通过（19 通过 / 0 失败）**；imgui 09-13 主线为设计内 Windows 限定，在 macOS 上无对应示例。

## 1. 验证环境

| 项目 | 版本/说明 |
|---|---|
| 系统 | macOS 14.8（Intel） |
| 编译器 | Apple clang 16（libc++） |
| 构建系统 | CMake + Ninja（`CMAKE_GENERATOR=Ninja`） |
| wxWidgets | 3.3.4，源码本地构建静态库（`build/dep-wx`） |
| FTXUI / tvision / imgui | 本地源码接入（`/Volumes/mac004/lang/cpp/` 下各库源码） |
| SDL2 | MacPorts 提供的 SDL2（dylib + headers + CMake config） |

验证协议与 `run-all.sh` 一致：构建 exit 0 + `--selftest` exit 0（60 秒超时）+ 输出含 `==== NN` 与 `结束 ====` 标记 + stderr 为空。

## 2. 验证矩阵

| 章节 | 框架 | 结果 | 备注 |
|---|---|---|---|
| 01-07 | wxWidgets | 7/7 通过 | `app.rc` 与 WIN32 子系统被 CMake 在非 Windows 自动忽略，**零代码适配** |
| 08 | imgui（SDL2+OpenGL3 变体） | 1/1 通过 | 需 `CPPGUI_IMGUI_SDL2=1`；selftest 40 帧渲染正常 |
| 08-13 主线 | imgui（Win32+D3D11） | 跳过（设计内） | D3D11 SDK 仅 Windows 存在；已用 `if(WIN32)` 守卫隔离，开启全框架时 configure 不报错 |
| 09-13 | imgui（其余主线示例） | 无 macOS 版本 | 指南主线示例绑定 D3D11 初始化流程；可参照 08 的 SDL2 变体模式移植 |
| 14-19 | FTXUI | 6/6 通过 | 需 jthread 兼容层（见 3.1） |
| 20-24 | tvision | 5/5 通过 | 需 run-all.sh 的 sidecar 路径修复（见 3.2），示例代码本身零修改 |

## 3. 为通过 macOS 所做的最小适配

### 3.1 jthread 兼容层（唯一必要的示例代码变更）

Apple clang 的 libc++ 不提供 `std::jthread`（MSVC 提供）。原版 15/18/19 三章代码在 clang 下直接编译失败（4 处错误）。新建 `examples/cppgui_jthread.hpp`：

- `__cpp_lib_jthread` 已定义时，`cppgui::jthread` 就是 `std::jthread` 的别名，MSVC 下行为零变化；
- 否则用 `std::thread` + 析构 join 包装（等价于 jthread 的自动汇合语义，含移动赋值前先汇合旧线程）。

三个示例的 `std::jthread` 统一替换为 `cppgui::jthread`，共 4 处使用点（15 章后台线程、18 章 worker、19 章默认构造 + 移动赋值）。适配后三章全部通过。

### 3.2 run-all.sh 三处修复

1. **bash 5.3 变量定界**：GNU bash 5.3 在 UTF-8 locale 下会把全角括号并入变量名，`$name（` 报"未绑定的变量"。4 处改为 `${name}（`。
2. **sidecar 相对路径**：tvision 系示例的 selftest 产物写相对路径（进程 CWD），判定却在 `build-run/` 找。测试调用改为 `(cd "$BUILD" && timeout 60 "bin/$name" --selftest ...)` 统一落位。
3. **wx 安装路径**：wxWidgets 的 CMake config 安装在 `lib/cmake/wxWidgets-3.3/`（带版本号子目录），存在性检查改为通配 `ls build/dep-wx/lib/cmake/wxWidgets*/wxWidgetsConfig.cmake`。

### 3.3 CMakeLists.txt 跨平台适配（imgui SDL2 通路）

- SDL2 目标获取按平台分支：Windows 用 scoop IMPORTED 接口库；其他平台 `find_package(SDL2)`。
- OpenGL 链接名按平台：`opengl32`（Windows）/ OpenGL framework（macOS）/ `GL`（Linux）。
- Win32+D3D11 静态库与 08-13 主线示例登记包进 `if(WIN32)`；SDL2.dll 拷贝加 `WIN32` 守卫。

### 3.4 构建依赖摩擦点（本机环境，非指南问题）

| 问题 | 解法 |
|---|---|
| macOS 无 GNU `timeout` | 桥接 MacPorts `gtimeout` 的 shim 脚本 |
| 自带 gmake/msgfmt 位于含空格路径，无法执行 | 构建器统一用 Ninja（`CMAKE_GENERATOR=Ninja`）；wx 构建加 `-DwxBUILD_LOCALES=OFF` 跳过 locale 生成 |
| wx 构建需关闭的两项 | `-DwxBUILD_LOCALES=OFF`、`-DwxUSE_STC=0`（lexilla 子模块错位） |

## 4. 最终验收输出（run-all.sh，四框架全开）

```
  [通过] 01_wx_hello ... 07_wx_docview_thread   （7 项）
  [通过] 08_imgui_hello_sdl2                    （1 项）
  [跳过] 08-13 主线（该部分未启用）              （6 项，设计内）
  [通过] 14_ftxui_dom ... 19_ftxui_app          （6 项）
  [通过] 20_tv_hello ... 24_tv_editor           （5 项）
======================================
 通过 19  失败 0
======================================
RUNALL_EXIT=0
```

## 5. 给指南维护者的建议

1. **jthread 是唯一硬性移植点**：如希望指南开箱跨平台，可在第 15 章首次引入 `std::jthread` 时附上 `cppgui_jthread.hpp` 的兼容层写法（约 40 行），并在设计文档"跨平台承诺"一节补充说明。
2. **run-all.sh 修复具有普适性**：`${name}（` 定界与 sidecar 相对路径两条在任何 Linux/macOS 环境都会踩到，建议回灌主线。
3. **imgui 09-13 的 SDL2 移植路径已验证可行**：08 的 SDL2 变体证明"SDL2 窗口 + OpenGL3 后端"在 macOS 可编译可运行，其余五章按同一模式替换 `imgui_impl_win32/dx11` 为 `imgui_impl_sdl2/opengl3` 即可，指南如增加平台分支章节可复用本次 CMake 改动。
4. **验收局限**：selftest 验证的是程序化行为（窗口创建、事件循环、渲染帧计数），各示例的视觉呈现未做人工确认。
