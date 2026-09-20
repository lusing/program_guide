import Config

# 编译期配置：构建时固化进环境（release 打包后不再改变）。
config :ex22_mix_release, greeting: "编译期配置"

# 按 MIX_ENV 导入环境专属文件。
import_config "#{config_env()}.exs"
