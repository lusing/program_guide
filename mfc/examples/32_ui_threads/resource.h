#pragma once

#define IDD_MAIN            100
#define IDC_BTN_START_UI    1001   // 起 UI 线程（自带窗口的动画监视器）
#define IDC_BTN_STOP_UI     1002   // 让 UI 线程收摊（PostThreadMessage WM_QUIT）
#define IDC_BTN_POST_THREAD 1003   // PostThreadMessage 发任务
#define IDC_BTN_RACE_ON     1004   // 无锁竞争演示（丢计数）
#define IDC_BTN_RACE_OFF    1005   // CMutex 修正（计数不丢）
#define IDC_BTN_PRIORITY    1006   // 优先级实验
#define IDC_EDIT_LOG        1007
