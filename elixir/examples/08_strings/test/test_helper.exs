# 本章是 IO 编码坑的正面教材：测试进程也钉死 UTF-8。
:io.setopts(:standard_io, encoding: :utf8)

ExUnit.start()
