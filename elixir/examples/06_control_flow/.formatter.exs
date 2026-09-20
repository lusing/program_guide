# 每个示例都是独立 mix 工程，各自带一份格式化配置（mix format 只认工程根目录的那份）。
# inputs 里额外列了 run.exs —— 驱动脚本同样要过格式检查。
[
  inputs: ["mix.exs", "run.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
