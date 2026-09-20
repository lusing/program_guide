:io.setopts(:standard_io, encoding: :utf8)

# 测试会故意让进程异常退出；关掉崩溃报告，避免噪声写进测试输出。
Logger.configure(level: :none)

ExUnit.start()
