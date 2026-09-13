# SDL2 编程指南示例集

本目录按 `guide` 的统一结构组织 SDL2 教程与可编译示例。

## 目录结构

```text
sdl2/
├── README.md
├── SDL2编程指南.md
├── build.ps1
└── examples/
    ├── 01_init_version.cpp
    ├── 02_window_renderer.cpp
    ├── 03_event_loop_skeleton.cpp
    ├── 04_texture_surface.cpp
    ├── 05_draw_primitives.cpp
    ├── 06_timer_fps.cpp
    ├── 07_keyboard_state.cpp
    ├── 08_audio_callback.cpp
    ├── 09_threads_mutex.cpp
    └── 10_raii_wrappers.cpp
```

## 构建工具链

- SDL2：`G:\scoop\apps\sdl2\current`
- VC：`G:\Program Files\Microsoft Visual Studio\18\Community\VC`
- 编译器：`cl.exe (MSVC)`

## 编译验证

```powershell
cd G:\code\guide\sdl2
.\build.ps1 -All
```

单文件编译：

```powershell
.\build.ps1 -File 06_timer_fps.cpp
```

清理：

```powershell
.\build.ps1 -Clean
```

