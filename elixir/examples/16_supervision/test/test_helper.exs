:io.setopts(:standard_io, encoding: :utf8)

# 本章故意让 worker 崩溃以演示监督重启；关掉崩溃报告，避免噪声写进测试输出。
Logger.configure(level: :none)

ExUnit.start()
