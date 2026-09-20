# 见 run.exs 首行的说明：locale 未设时 BEAM 的 stdio 退回 latin1，中文会被转义。
:io.setopts(:standard_io, encoding: :utf8)

ExUnit.start()
