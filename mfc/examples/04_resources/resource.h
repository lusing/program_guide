// 资源 ID 定义：.rc 文件和 C++ 代码共用这一份头文件。
// 惯例：资源用 #define 数值 ID（而不是 enum），因为 rc.exe 不认 C++ 的 enum。
#pragma once

#define IDR_MAINFRAME       100   // 主图标（一个 .ico 里含 32×32 与 16×16 两档）
#define IDR_MAIN_MENU       101   // 主菜单
#define IDR_MAIN_ACCEL      102   // 加速键表

#define IDM_FILE_NEW        2001  // 菜单命令 ID
#define IDM_FILE_OPEN       2002
#define IDM_FILE_SAVE       2003
#define IDM_FILE_EXIT       2004
#define IDM_EDIT_UNDO       2101
#define IDM_HELP_ABOUT      2201

#define IDS_APP_TITLE       3001  // 字符串表
#define IDS_GREETING        3002
