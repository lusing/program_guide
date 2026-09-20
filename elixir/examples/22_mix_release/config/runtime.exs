import Config

# 运行期配置：启动时求值；可读环境变量——同一 release 包在不同机器上取不同值。
config :ex22_mix_release,
  who: System.get_env("DEMO_WHO", "世界"),
  boot_tag: "runtime 配置"
