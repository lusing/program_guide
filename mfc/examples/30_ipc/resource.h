#pragma once

#define IDD_MAIN            100
#define IDC_BTN_COPYDATA    1001   // WM_COPYDATA：发给另一个实例
#define IDC_BTN_MAILSLOT    1002   // 邮槽：服务端线程 + 客户端写
#define IDC_BTN_PIPE        1003   // 命名管道：echo 服务 + 客户端
#define IDC_BTN_SHAREDMEM   1004   // 共享内存 + 互斥体
#define IDC_EDIT_LOG        1005
#define IDC_EDIT_SEND       1006   // 要发送的文本
