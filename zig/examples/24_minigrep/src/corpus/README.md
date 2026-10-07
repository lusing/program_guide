# minigrep 语料说明
#
# 这个目录里的三个文件是 24 章的固定样本语料。
# 主程序 zig build run 会在 src/corpus 上跑一遍综合演示，
# 所以**内容一旦定稿就不要改**——文档里的运行输出是逐字节抄自实测的。

- app.log   8 行日志，含 INFO / WARN / ERROR / DEBUG 四种级别
- app.conf  9 行配置，含 [section] 头与 key = value
- README.md 本文件，含 Markdown 的 #标题 与 -列表

关键词：ERROR、WARN、timeout、service=、0.94
正则练习素材：s*rvice=[a-z]+、^2026.*ERROR、(INFO|WARN|DEBUG)、
             tim(eou)+t、[0-9]{2}（本引擎不支持 {n}，会当字面量）
