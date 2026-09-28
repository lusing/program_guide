#pragma once

#define IDR_MAIN_MENU      101
#define IDM_FILE_EXIT      1001
#define IDM_TEST_DYNAMIC   1002    // 动态构造弹出菜单
#define IDM_TEST_POPUP     1003    // 跟着鼠标走的三种上下文菜单
#define IDM_TEST_SYSCMD    1004    // 往系统菜单塞一项
#define IDM_VIEW_STATUS    11001   // 复选：状态栏开关
#define IDM_VIEW_TOOL      11002   // 复选：工具栏开关
#define IDM_COLOR_RED      11003   // 单选组：颜色
#define IDM_COLOR_GREEN    11004
#define IDM_COLOR_BLUE     11005
#define IDM_DYN_FIRST      12001   // 动态菜单命令段（ON_COMMAND_RANGE）
#define IDM_DYN_LAST       12008
#define IDM_SYS_ABOUT      13001   // 系统菜单附加项（WM_SYSCOMMAND）
#define IDM_POP_FIRST      12001   // 上下文菜单命令段（与动态段复用一个 RANGE）
#define IDM_POP_LAST       12008

// owner-draw 菜单项的私有结构（挂在 MenuItemInfo dwItemData 上）
#define ODM_COLOR_FIRST    12100   // 颜色 swatch 项的 ID 段
#define ODM_COLOR_LAST     12105
