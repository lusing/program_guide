:io.setopts(:standard_io, encoding: :utf8)

# 本章故意制造任务崩溃与超时杀死；关掉崩溃报告，避免噪声写进测试输出。
Logger.configure(level: :none)

ExUnit.start()
