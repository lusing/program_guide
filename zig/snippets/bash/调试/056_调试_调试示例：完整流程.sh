# 编译
zig build-exe debug_demo.zig -g

# 启动调试
lldb ./debug_demo

(lldb) break set -n main
(lldb) break set -n calculate
(lldb) break set -n divide

(lldb) run

# 在 calculate 断点处
(lldb) frame variable
(lldb) print a
(lldb) print b
(lldb) print c

(lldb) next
(lldb) frame variable

(lldb) continue
