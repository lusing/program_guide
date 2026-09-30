cmake_minimum_required(VERSION 3.28)
project(cppgui LANGUAGES CXX)

# ============================================================
# cppgui —— C++ GUI 编程指南（四部分 24 章）
#   一 wxWidgets（01–07）  二 Dear ImGui（08–13）
#   三 FTXUI（14–19）      四 tvision（20–24）
# 章号 = 示例号；每示例支持 --selftest 自动退出冒烟。
# 框架源码路径可用 cache 变量覆盖（默认指向 G:/github/cpp 本地布局）。
# ============================================================

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CPPGUI_WX_DIR      "G:/github/cpp/wxWidgets" CACHE PATH "wxWidgets 源码根")
set(CPPGUI_IMGUI_DIR   "G:/github/cpp/imgui"     CACHE PATH "Dear ImGui 源码根")
set(CPPGUI_FTXUI_DIR   "G:/github/cpp/FTXUI"     CACHE PATH "FTXUI 源码根")
set(CPPGUI_TVISION_DIR "G:/github/cpp/tvision"   CACHE PATH "tvision 源码根")
set(CPPGUI_SDL2_DIR    "G:/scoop/apps/sdl2/current" CACHE PATH "SDL2 前缀（08 章 SDL2 变体）")

option(CPPGUI_ENABLE_WX      "启用 wxWidgets 部分（01–07）" ON)
option(CPPGUI_ENABLE_IMGUI   "启用 Dear ImGui 部分（08–13）" ON)
option(CPPGUI_ENABLE_FTXUI   "启用 FTXUI 部分（14–19）" ON)
option(CPPGUI_ENABLE_TVISION "启用 tvision 部分（20–24）" ON)

# 每章一个示例目标：examples/NN_topic.cpp → build/bin/NN_topic.exe
# cppgui_example(<名> [链接库...])——增量开发守卫：源文件尚未写出时
# 跳过整个登记（WARNING 提示），不阻断 configure。
function(cppgui_example NAME)
    if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/examples/${NAME}.cpp")
        message(WARNING "cppgui: examples/${NAME}.cpp 不存在，目标 ${NAME} 暂不登记")
        return()
    endif()
    add_executable(${NAME} examples/${NAME}.cpp)
    if(MSVC)
        target_compile_options(${NAME} PRIVATE /W3)
    endif()
    set_target_properties(${NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
    if(ARGN)
        target_link_libraries(${NAME} PRIVATE ${ARGN})
    endif()
endfunction()

# wx 应用：WIN32 子系统（wxIMPLEMENT_APP 生成 WinMain；真实 GUI 程序形态）。
# 该类示例的 selftest 标记写 sidecar 文件 build/selftest-<名>.txt
# （GUI 子系统无 stdout 管道，build.ps1 走 sidecar 判定分支）。
function(cppgui_example_wx NAME)
    if(NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/examples/${NAME}.cpp")
        message(WARNING "cppgui: examples/${NAME}.cpp 不存在，目标 ${NAME} 暂不登记")
        return()
    endif()
    add_executable(${NAME} WIN32 examples/${NAME}.cpp examples/app.rc)
    if(MSVC)
        target_compile_options(${NAME} PRIVATE /W3)
        # manifest 已由 app.rc 嵌入，关掉链接器默认 manifest 避免双清单
        set_target_properties(${NAME} PROPERTIES LINK_FLAGS "/MANIFEST:NO")
    endif()
    set_target_properties(${NAME} PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
    if(ARGN)
        target_link_libraries(${NAME} PRIVATE ${ARGN})
    endif()
endfunction()

# ---------- Dear ImGui：源码直接编入（两个后端库）----------
if(CPPGUI_ENABLE_IMGUI)
    set(CPPGUI_IMGUI_CORE
        ${CPPGUI_IMGUI_DIR}/imgui.cpp
        ${CPPGUI_IMGUI_DIR}/imgui_draw.cpp
        ${CPPGUI_IMGUI_DIR}/imgui_tables.cpp
        ${CPPGUI_IMGUI_DIR}/imgui_widgets.cpp
        ${CPPGUI_IMGUI_DIR}/imgui_demo.cpp)

    # 主线：Win32 平台后端 + D3D11 渲染后端（零第三方依赖，Windows SDK 自带）
    add_library(cppgui_imgui STATIC
        ${CPPGUI_IMGUI_CORE}
        ${CPPGUI_IMGUI_DIR}/backends/imgui_impl_win32.cpp
        ${CPPGUI_IMGUI_DIR}/backends/imgui_impl_dx11.cpp)
    target_include_directories(cppgui_imgui PUBLIC
        ${CPPGUI_IMGUI_DIR} ${CPPGUI_IMGUI_DIR}/backends)

    # 08 章对照变体：SDL2 平台后端 + OpenGL3 渲染后端（scoop SDL2）
    add_library(cppgui_imgui_sdl2 STATIC
        ${CPPGUI_IMGUI_CORE}
        ${CPPGUI_IMGUI_DIR}/backends/imgui_impl_sdl2.cpp
        ${CPPGUI_IMGUI_DIR}/backends/imgui_impl_opengl3.cpp)
    target_include_directories(cppgui_imgui_sdl2 PUBLIC
        ${CPPGUI_IMGUI_DIR} ${CPPGUI_IMGUI_DIR}/backends)
    # scoop 的 SDL2 不带 CMake config（裸 .lib + 头文件），用 IMPORTED 目标直连
    if(NOT TARGET SDL2::SDL2)
        add_library(SDL2::SDL2 INTERFACE IMPORTED)
        set_target_properties(SDL2::SDL2 PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${CPPGUI_SDL2_DIR}/include/SDL2"
            INTERFACE_LINK_LIBRARIES "${CPPGUI_SDL2_DIR}/lib/SDL2.lib")
    endif()
    target_link_libraries(cppgui_imgui_sdl2 PUBLIC SDL2::SDL2)
endif()

# ---------- FTXUI：add_subdirectory，链接 ftxui ----------
if(CPPGUI_ENABLE_FTXUI)
    set(FTXUI_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    set(FTXUI_BUILD_TESTS    OFF CACHE BOOL "" FORCE)
    set(FTXUI_BUILD_DOCS     OFF CACHE BOOL "" FORCE)
    set(FTXUI_BUILD_MODULES  OFF CACHE BOOL "" FORCE)
    add_subdirectory(${CPPGUI_FTXUI_DIR} ${CMAKE_BINARY_DIR}/ftxui EXCLUDE_FROM_ALL)
endif()

# ---------- tvision：add_subdirectory，链接 tvision ----------
if(CPPGUI_ENABLE_TVISION)
    set(TV_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
    add_subdirectory(${CPPGUI_TVISION_DIR} ${CMAKE_BINARY_DIR}/tvision EXCLUDE_FROM_ALL)
endif()

# ---------- wxWidgets：预构建静态库（tools/build-wx.ps1 产物）----------
if(CPPGUI_ENABLE_WX)
    find_package(wxWidgets CONFIG REQUIRED
        PATHS ${CMAKE_SOURCE_DIR}/build/dep-wx NO_DEFAULT_PATH)
endif()

# ============================================================
# 示例登记（随批次扩充）
# ============================================================

# ---- 一、wxWidgets ----
if(CPPGUI_ENABLE_WX)
    cppgui_example_wx(01_wx_hello wx::core wx::base)
    cppgui_example_wx(02_wx_menus wx::core wx::base)
    cppgui_example_wx(03_wx_sizers wx::core wx::base)
    cppgui_example_wx(04_wx_controls wx::core wx::base wx::adv)
    cppgui_example_wx(05_wx_dialogs wx::core wx::base wx::adv)
    cppgui_example_wx(06_wx_drawing wx::core wx::base wx::adv)
    cppgui_example_wx(07_wx_docview_thread wx::core wx::base wx::adv)
endif()

# ---- 二、Dear ImGui ----
if(CPPGUI_ENABLE_IMGUI)
    cppgui_example(08_imgui_hello cppgui_imgui d3d11 dxgi d3dcompiler)
    cppgui_example(09_imgui_widgets cppgui_imgui d3d11 dxgi d3dcompiler)
    cppgui_example(10_imgui_windows cppgui_imgui d3d11 dxgi d3dcompiler)
    cppgui_example(11_imgui_tables cppgui_imgui d3d11 dxgi d3dcompiler)
    cppgui_example(12_imgui_drawlist_fonts cppgui_imgui d3d11 dxgi d3dcompiler)
    cppgui_example(13_imgui_app cppgui_imgui d3d11 dxgi d3dcompiler)

    cppgui_example(08_imgui_hello_sdl2 cppgui_imgui_sdl2 opengl32)
    # SDL2 是动态库：把 DLL 拷到产物目录
    if(TARGET 08_imgui_hello_sdl2)
        add_custom_command(TARGET 08_imgui_hello_sdl2 POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${CPPGUI_SDL2_DIR}/lib/SDL2.dll" $<TARGET_FILE_DIR:08_imgui_hello_sdl2>)
    endif()
endif()

# ---- 三、FTXUI ----
if(CPPGUI_ENABLE_FTXUI)
    cppgui_example(14_ftxui_dom ftxui)
    cppgui_example(15_ftxui_components ftxui)
    cppgui_example(16_ftxui_layout ftxui)
    cppgui_example(17_ftxui_style_canvas ftxui)
    cppgui_example(18_ftxui_composition ftxui)
    cppgui_example(19_ftxui_app ftxui)
endif()

# ---- 四、tvision ----
if(CPPGUI_ENABLE_TVISION)
    cppgui_example(20_tv_hello tvision)
    cppgui_example(21_tv_menus_dialogs tvision)
    cppgui_example(22_tv_views tvision)
    cppgui_example(23_tv_colors_forms tvision)
    cppgui_example(24_tv_editor tvision)
endif()
