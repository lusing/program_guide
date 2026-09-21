#pragma once

// ---- 资源 ID 惯例：101~ 资源块，1000~ 控件，2000~ 命令 ----
#define IDR_MAINFRAME       101
#define IDR_TOOLBAR_BMP     102
#define IDD_SETTINGS        103
#define IDD_STATS           104
#define IDD_ABOUT           105

#define IDC_TAB_SIZE        1001
#define IDC_WRAP            1002
#define IDC_STATS_LIST      1003
#define IDC_STATS_REFRESH   1004
#define IDC_EDIT            1099

#define IDM_FILE_NEW        2001
#define IDM_FILE_OPEN       2002
#define IDM_FILE_SAVE       2003
#define IDM_FILE_EXIT       2004
#define IDM_MRU_1           2101   // 最近文件槽 1~4（连续，便于 ON_COMMAND_RANGE）
#define IDM_MRU_2           2102
#define IDM_MRU_3           2103
#define IDM_MRU_4           2104
#define IDM_EDIT_UNDO       2201
#define IDM_EDIT_CUT        2202
#define IDM_EDIT_COPY       2203
#define IDM_EDIT_PASTE      2204
#define IDM_TOOLS_STATS     2301
#define IDM_TOOLS_SETTINGS  2302
#define IDM_HELP_ABOUT      2401
