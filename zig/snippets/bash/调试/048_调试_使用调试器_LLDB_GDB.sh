# 编译带调试信息的程序
zig build-exe program.zig -g

# 启动 GDB
gdb ./program

# 常用命令：
(gdb) break main                       # 设置断点
(gdb) run                              # 运行程序
(gdb) next                             # 单步执行
(gdb) step                             # 进入函数
(gdb) print variable                   # 打印变量
(gdb) print *pointer                   # 解引用指针
(gdb) bt                               # 显示调用栈
(gdb) continue                         # 继续执行
(gdb) quit                             # 退出调试器
