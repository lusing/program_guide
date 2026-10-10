# 02 · 第一个程序与项目结构

> 对应示例：`examples/02_hello/`

## 2.1 一个最小 Godot 工程长什么样

```text
02_hello/
├── project.godot   # 工程配置——有这个文件，目录才是一个"工程"
└── main.gd         # 本教程的入口脚本
```

真实项目会多出场景（`.tscn`）、资源（贴图、音频、`.tres`）等目录，但配置文件
`project.godot` 永远是工程的根标志。打开本示例的 `project.godot`，全文如下：

```ini
; Engine configuration file.
; It's best edited using the editor if possible.

config_version=5

[application]
config/name="02_hello"
run/main_scene=""
config/features=PackedStringArray("4.3")

[rendering]
renderer/rendering_method="mobile"
```

逐项解释：

- `config_version=5`：配置格式版本，4.x 固定为 5；
- `config/name`：工程名；
- `run/main_scene=""`：**没有**主场景——这正是 headless 脚本模式的前提；真实游戏
  会填 `res://scenes/main.tscn`；
- `config/features`：声明工程面向的引擎版本，编辑器据此做兼容提示；
- `renderer/rendering_method="mobile"`：headless 下不真正渲染，但显式声明可以避免
  桌面渲染器在 CI 机器上探测 GPU 的噪声。

工程内所有路径都以 `res://` 为前缀映射到工程根：`res://main.gd` 即
`02_hello/main.gd`。这个前缀会贯穿整个教程。

## 2.2 入口脚本逐行精讲

`examples/02_hello/main.gd` 全文：

```gdscript
extends SceneTree

func _initialize():
    print("Hello, Godot!")
    print("这是 Godot 4 的 headless 入口脚本。")
    quit()
```

- `extends SceneTree`：脚本的父类是 `SceneTree`——引擎主循环的实际实现类。以
  `--script` 方式启动时，Godot 用这个脚本的实例**替代**默认主循环，于是我们拿到了
  引擎生命周期的一份控制权（详见 1.4 节的边界说明）。
- `_initialize()`：主循环启动时的一次性回调，下划线开头是 Godot 的"虚方法/回调"
  命名惯例（同类还有 `_ready`、`_process`，第 07、09 章讲）。
- `print(...)`：输出到标准输出，可接任意多个参数、任意类型，自动转字符串——
  headless 模式下这就是我们全部的观测手段。
- `quit()`：请求主循环退出。**漏掉它，进程会永远挂着**——这是本教程所有示例都必须
  以 `quit()` 收尾的原因，也是 `run-all.sh` 带看门狗超时的原因（脚本加载失败时
  `quit()` 根本执行不到，见 2.4 节）。

## 2.3 运行

```bash
cd godot
godot --headless --path examples/02_hello --script main.gd
```

实测输出（Godot 4.7.1）：

```text
Godot Engine v4.7.1.stable.macports_build - https://godotengine.org

Hello, Godot!
这是 Godot 4 的 headless 入口脚本。
```

第一行是引擎自报版本，随后是两行 `print`。注意 `--script` 的值：`main.gd` 是相对
工程根的路径，等价于 `res://main.gd`。

## 2.4 失败形态实测：路径写错会怎样

在 `godot/` 目录下运行（`--path` 指向工程，`--script` 却按 shell 当前目录来写）：

```bash
godot --headless --path examples/02_hello --script examples/02_hello/main.gd   # 错误示范
```

`--script` 的参数会被先拼到 `res://` 下解析——相对的是**工程根**，不是 shell 的
当前目录。实测得到：

```text
ERROR: Attempt to open script 'res://examples/02_hello/main.gd' resulted in error 'File not found'.
ERROR: Failed loading resource: res://examples/02_hello/main.gd.
ERROR: Can't load script: examples/02_hello/main.gd
```

而 `echo $?` 显示**退出码依然是 0**。也就是说：脚本没跑，进程却"成功"退出。任何
自动化校验如果只看退出码就会把失败当成功——必须像 `run-all.sh` 那样检查期望的输出
文本。这是 Godot CLI 的老问题，教程层面只能防、不能修。

（顺带实测：写成 `--script ../02_hello/main.gd` 这种 shell 相对路径反而能跑通——
Godot 对含 `..` 的参数走了文件系统查找分支。行为不一致，所以**永远写成相对工程根的
路径或显式的 `res://…`**，别依赖这种侥幸。）

## 2.5 更多 print 能力

`print` 之外还有几个常用输出形态，值得现在认识（后文各章都会用到）：

```gdscript
print("普通行")            # stdout + 换行
printt("两列", "制表符分隔")  # 列间加 \t，适合对齐小表格
prints("参数间加空格")       # 列间加空格
print_rich("[color=red]红字[/color]")  # 支持 BBCode，编辑器输出面板里生效
push_warning("黄色警告")     # 不是 print，是"带源码行号的警告"，调试利器
push_error("红色错误")      # 同上，报错误
```

headless 模式只能看到前四种直接输出的效果；`push_warning/push_error` 会附带
`文件:行号` 的后缀信息，写脚本时优先用它们标记可疑分支。

## 2.6 坑位清单

1. **`quit()` 不调用，进程永不退出**；`--quit-after <帧数>` 可作保险栓。
2. **脚本加载失败退出码仍为 0**：CI 校验看输出，不看退出码（2.4 实测）。
3. **`--script` 只认 `res://` 或相对工程根路径**：绝对路径/越界路径全部解析失败。
4. **`_initialize` 里 `await` 要小心时序**：主循环尚未开始迭代，涉及树结构的操作
   可能没就绪（07 章有完整实测案例）。
5. **`run/main_scene=""` 是脚本模式的前提**：配置了主场景又用 `--script`，行为以
   脚本为准，但编辑器 F5 运行会去找那个场景——两边配置要心里有数。

上一章：[01 · Godot 全景](01-overview.md) ｜ 下一章：[03 · 变量与基本类型](03-variables.md) ｜ 返回：[README](../README.md)
