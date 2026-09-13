# 查看帮助
zigup --help

# 列出已安装的版本
zigup list

# 安装指定版本
zigup 0.13.0
zigup master        # 安装最新开发版
zigup release       # 安装最新稳定版

# 切换默认版本
zigup 0.12.0
zigup default 0.13.0

# 删除指定版本
zigup remove 0.11.0

# 自动检测并更新到项目指定版本
echo "0.13.0" > .zigversion
zigup auto
