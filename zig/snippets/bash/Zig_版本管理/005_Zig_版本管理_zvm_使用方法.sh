# 查看帮助
zvm --help

# 列出所有可用版本
zvm list-remote

# 列出已安装版本
zvm list

# 安装指定版本
zvm install 0.13.0
zvm install master      # 安装开发版

# 使用指定版本
zvm use 0.13.0

# 设置默认版本
zvm default 0.13.0

# 查看当前版本
zvm current

# 卸载版本
zvm uninstall 0.12.0

# 自动切换版本
zvm use auto
