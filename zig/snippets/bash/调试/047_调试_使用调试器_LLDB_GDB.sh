# 编译带调试信息的程序
zig build-exe program.zig -g

# 启动 LLDB
lldb ./program

# 常用命令：
(lldb) break set -n main              # 设置断点
(lldb) run                             # 运行程序
(lldb) next                            # 单步执行（不进入函数）
(lldb) step                            # 单步执行（进入函数）
(lldb) finish                          # 执行到函数返回
(lldb) print variable                # 打印变量
(lldb) print *pointer                # 解引用指针
(lldb) expr variable = value         # 修改变量
(lldb) bt                              # 显示调用栈
(lldb) frame variable                # 显示框架变量
(lldb) continue                        # 继续执行
(lldb) quit                            # 退出调试器
