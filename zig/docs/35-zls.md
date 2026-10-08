# 35 · ZLS 与编辑器工具链

前面 34 章一直在跟"编译好的程序"打交道。这一章退一步，把每天敲代码时盯着你的那个工具——语言服务器——装好、配对、调优。取材《Learning Zig》第 2 章，但原书出版于 Zig 0.15 时代，而本章写作时的真实生态是 **Zig 0.17.0 + ZLS master（0.17.0-dev）**——中间隔着一次 ZLS 的"断代事故"，恰好是学习"工具链版本管理"最好的教材。原书的核心内容（安装、ZLS 构建、zls.json、check 步骤、两大编辑器接线）本章全部自包含讲清，过时之处逐条标注。

## 35.1 没有语言服务器，等于回到石器时代

LSP（Language Server Protocol）把"理解代码"这件事从编辑器里剥出来，交给一个独立进程：编辑器只负责显示，语言服务器负责补全、跳转、悬停文档、诊断、重命名。Zig 的语言服务器叫 **ZLS**（Zig Language Server），由社区 zigtools 组织维护。

Zig 为什么尤其需要它？三个原因：

1. **comptime 让"文本层面的理解"彻底失效**。`fn Container(comptime T: type) type` 这种代码，正则表达式和语法高亮永远猜不出 `Container(u8)` 是什么——只有真正跑过类型求值的工具知道。ZLS 内部嵌着 Zig 的语义分析器，补全列表是经过 comptime 求值后的真实成员。
2. **错误发现提前到敲完的那一瞬**。没有 ZLS，你要等 `zig build` 跑完才知道某行类型不对；有了它，红线在保存时就画出来。
3. **标准库即文档**。0.17 的 `std.Io` 大改版后，悬停一下就能看到 `writer` 的真实签名，比翻源码快得多——本教程前面各章的"实测签名表"很多就是这么核出来的。

## 35.2 版本配对铁律，与 0.17 的断代现场

ZLS 不是"一个版本通吃"的工具。**它和 Zig 编译器共享 AST 与编译器内部的私有协议，必须按版本配对**：

| Zig 版本 | 配对的 ZLS | 状态（2026-10 实测） |
|---|---|---|
| 0.15.1 | ZLS 0.15.x | 历史组合 |
| 0.16.0 | ZLS 0.16.0（2026-04-16 发布） | 最后一个"官方配对"的稳定组合 |
| **0.17.0** | **没有正式版，用 master 源码构建** | 本章实测路线 |

为什么 0.17 没有配对版？这不是 ZLS 偷懒，而是 Zig 0.17 动了一次大手术：**构建系统拆成了 maker 与 configurer 两个进程**（16 章讲的 build.zig 现在由 maker 进程驱动）。ZLS 过去靠 fork 构建运行器来探知工程的模块、依赖与目标——那个可 fork 的机制在 0.17 里不存在了，Zig 官方release notes 明说这"使 ZLS 无法配合 0.17.0 工作"。

修复路径是 0.17 新引入的 **Build Server Protocol**（构建服务器协议，`--listen=-` 标准流接口）：构建系统变成可以被外部工具查询、驱动的服务器，ZLS 正迁移到这条路上。Zig 与 ZLS 两边的目标是让 ZLS 借助新协议**超过**从前的能力。所以现状是：

> Zig 0.17.0 + ZLS master：**编辑功能（补全/跳转/悬停/诊断）已可用**，与构建系统深度联动的部分（跨模块依赖解析、build-on-save 的完整诊断）仍在施工，ZLS 官方 README 也坦白"master 当前缺乏与 Zig nightly/master 的关键构建系统集成"。

### 实测：用 0.17.0 从源码构建 ZLS master

```
git clone https://github.com/zigtools/zls.git
cd zls
zig build -Doptimize=ReleaseSafe
```

在本机（Windows 11 / Zig 0.17.0，ZLS 提交 `eab2be0`）一次通过，中途只有一条无害提示：

```
failed command: pkg-config --list-all
```

这是构建脚本探测系统 pkg-config 的可选步骤，Windows 上没有 pkg-config，探测失败被忽略，**不影响产物**。产物在 `zig-out/bin/`：

```
$ zls --version
0.17.0-dev
```

再用一次最小 LSP 握手（`initialize` → `shutdown`）验证它真的能服役，响应里带着：

```json
"serverInfo":{"name":"zls","version":"0.17.0-dev"}
```

握手干净退出、stderr 无报错——构建成功且协议栈完好。这就是本章后面所有配置所依托的二进制。

### 如果你的工程钉在 0.16

另一个完全合理的选择：工程留在 Zig 0.16.0，装官方发布的 ZLS 0.16.0（各平台包管理器都有），享受完整构建集成，等 Build Server Protocol 落地再一起升。**Zig 的多版本共存零成本**——每个版本是自包含的压缩包，解开即用（Windows 用户用 scoop：`scoop install zig`；也可以用 zigup 这类版本切换器在多个 Zig 之间跳）。选稳定还是追新，原书给了一个"Stable or Bold"决策游戏，浓缩成一句话：**要交付选稳定配对，要跟着社区教程走就选新**。

## 35.3 zls.json：一份配置，通吃所有编辑器

ZLS 的配置文件是 `zls.json`，**对所有使用 ZLS 的编辑器生效**——配一次，VS Code 和 Neovim 吃的是同一份。先问 ZLS 它去哪儿找配置：

```
$ zls env
{
 "version": "0.17.0-dev",
 "global_cache_dir": "C:\\Users\\lusin\\AppData\\Local\\Temp\\zls",
 "global_config_dir": "C:\\ProgramData",
 "local_config_dir": "C:\\Users\\lusin\\AppData\\Local",
 "config_file": null,
 "log_file": "C:\\Users\\lusin\\AppData\\Local\\Temp\\zls\\zls.log"
}
```

这是 Windows 上的实测输出：`local_config_dir` 是 `%LOCALAPPDATA%`（即 `C:\Users\<你>\AppData\Local`），把 `zls.json` 放进去，`config_file` 一栏就会从 `null` 变成它的全路径。Linux 下对应 `~/.config/zls.json`。注意 `zls.json` 必须是**合法 JSON**：不许注释、不许尾随逗号。

本章示例目录 `examples/35_zls/` 里放了一份可直接抄的配置：

```json
{
  "enable_build_on_save": true,
  "build_on_save_args": ["check"],
  "semantic_tokens": "partial",
  "inlay_hints_show_variable_type_hints": true,
  "inlay_hints_hide_redundant_param_names": true
}
```

逐字段说（字段名是从 ZLS master 的 `src/Config.zig` 里核出来的，不是抄书）：

- `enable_build_on_save`：每次保存文件，ZLS 替你跑一次 `zig build`——下一节的主角。
- `build_on_save_args`：保存时把哪些参数追加给 `zig build`。⚠️ **原书写的 `"build_on_save_step": "check"` 已不存在**——ZLS 把"步骤名"泛化成了"参数列表"，所以现在写 `["check"]`。这是原书第一个过时点。
- `semantic_tokens`：`"partial"` 用部分语义高亮，省性能又够用；`"full"` 最准但大文件会卡。
- `inlay_hints_*`：内联提示家族——变量类型、结构体字面量字段类型、参数名、内建函数。`hide_redundant_param_names` 建议打开，否则 `foo(x, y)` 每个参数前都冒出一个名字，很吵。Config.zig 里这族字段有 7 个，默认值都合理，只挑你想改的写。
- 书里提过的 `zig_exe_path` 依然在：PATH 里找不到 zig 时，用它显式指路。

## 35.4 check 步骤：让"保存"只做检查，不做产出

`enable_build_on_save` 一开，ZLS 每次保存跑的是 `zig build`——完整编译加安装，大工程太贵。社区的标准解法是：**在 build.zig 里登记一个只做语义分析、不产出二进制的 `check` 步骤**，再让 `build_on_save_args` 指它。

`examples/35_zls/build.zig` 里就是完整写法，核心四行：

```zig
const exe_check = b.addExecutable(.{ .name = "zls_demo_check", .root_module = exe_mod });
const check = b.step("check", "只检查能否编译（ZLS 保存时调用）");
check.dependOn(&exe_check.step);
```

三个要点：

1. **同一个模块，再登记一次编译**。`exe_check` 与正式的 `exe` 共用 `exe_mod`（同一个 `createModule` 产物），源码、target、optimize 完全一致——检查的就是你要发布的那些代码。这是"复制一份 exe 定义"的正确理解：复制的是**编译节点**，不是源码。
2. **故意不 `installArtifact`**。对比同文件里正式产物那行 `b.installArtifact(exe)`——`exe_check` 没有它。安装是把二进制拷到 `zig-out/` 的动作；不安装，ZLS 跑一次检查就不会在你磁盘上留任何东西。
3. **0.17 会替你省到底**。实测 `zig build check` 失败时打印的底层命令里带着 `-fno-emit-bin`：

   ```
   zig build-exe -Odebug -Mroot=src\main.zig -fno-emit-bin ... --listen=-
   ```

   0.17 的构建系统发现这个 artifact 无人安装，干脆告诉编译器"连二进制都别生成"——编译器跑完语义分析就停，这正是 check 步骤想要的全部。末尾那个 `--listen=-` 就是 35.2 说的 Build Server Protocol 管道，0.17 的编译进程是通过它接受构建系统驱动的，肉眼可见。

手动验证一遍（本章示例三层验证的一部分）：

```
zig build check   # 只查不产
zig build test    # 跑 src/main.zig 里的 test 块
zig build run     # 正常运行
```

三条都绿，说明 check 步骤挂对了。以后在编辑器里保存 `.zig` 文件，ZLS 后台跑的就是第一条——**编译错误以编辑器诊断的形式出现，而不是等你手动构建**。为什么值得？15 章讲过 comptime 求值里的错误（比如 `@setEvalBranchQuota` 爆配额、类型函数里的类型错）在纯语法层面完全隐形，只有真编译才现形；check 步骤把"真编译"压缩到只剩语义分析，成本足够低，可以挂在每次保存上。

> ⚠️ 如实说明：在 Zig 0.17.0 + ZLS master 这个组合上，build-on-save 依赖的构建系统集成正在向 Build Server Protocol 迁移，**当前可能是降级状态**——补全、跳转、悬停都正常，保存时的完整构建诊断未必每次都触发。配置仍然照配：它是 ZLS 官方文档钦定的标准姿势，0.16 组合上完整可用，0.17 上等集成落地即刻生效，不需要你再改任何东西。

## 35.5 编辑器接线

**VS Code / VSCodium**：装官方扩展 `ziglang.vscode-zig`（扩展市场搜 "Zig Language"）。扩展默认用 PATH 里的 `zls`；我们的是自己编的，在设置里指过去：

```json
{
  "zig.zls.path": "F:\\tmp\\zls-src\\zig-out\\bin\\zls.exe",
  "zig.zls.checkForUpdate": false
}
```

第二行关掉扩展的"替你更新 ZLS"——否则它可能拉一个与 Zig 0.17 不配对的正式版，35.2 的配对铁律就白守了。

**Neovim**：用 `nvim-lspconfig`，原书的片段更新后是这样：

```lua
local lspconfig = require('lspconfig')
lspconfig.zls.setup {
  cmd = { '/path/to/zls' },            -- PATH 里有可省
  settings = {
    zls = {
      zig_exe_path = '/path/to/zig',   -- PATH 里有可省
    }
  }
}
-- 保存时用 LSP 格式化（而不是 zig.vim 自带的格式化）
vim.g.zig_fmt_autosave = 0
vim.cmd [[autocmd BufWritePre *.zig lua vim.lsp.buf.format()]]
```

要点是最后两行：把 zig.vim 插件自带的保存格式化**关掉**，改走 ZLS 的格式化——全社区统一由 `zig fmt` 的同一实现出手，不会出现"插件和命令行格式化成两个样子"。两个 `path` 字段在 PATH 配好时全省；`settings.zls` 里写的键和 `zls.json` 是同一份 schema，编辑器内配置只对那个编辑器生效，`zls.json` 对所有编辑器生效——**团队共享的配置放 `zls.json`，个人口味放编辑器**。

## 35.6 zig fmt：格式问题的终审法官

ZLS 的格式化只是 `zig fmt` 的远程调用，终审权永远在命令行。本教程仓库的三层验证第一道就是 `zig fmt --check .`——任何示例格式不合法，后面的 test 和运行根本不会开始。团队里建议同样把它挂进 CI 或 pre-commit。`zig fmt` 没有配置项，**故意没有**——Zig 学 Go 的思路：格式只有一种，争论归零。顺带把原书强调的三条源文件纪律记住，fmt 不管、但 Zig 工具链默认遵守：行尾一律 LF（Windows 上给仓库加 `.gitattributes` 钉死，本仓库就是这么做的）、缩进用空格（fmt 产出 4 空格）、BOM 只允许出现在文件开头且最好别要。

## 35.7 坑位清单

1. **ZLS 与 Zig 版本必须配对**。0.17.0 没有官方配对版：要么 ZLS master 源码构建（本章实测可行，构建集成降级），要么工程留在 0.16.0 + ZLS 0.16.0。混用的典型症状是补全乱跳、诊断报错的位置对不上。
2. **原书三处过时**：`build_on_save_step` 已改为 `build_on_save_args`（参数列表）；check 步骤的 `root_source_file` 写法在 0.17 是 `createModule` + `addExecutable(.root_module})`（16 章的新 API）；"Mason 装 ZLS"的警告依然有效，但理由更强了——包管理器只会给你正式版，追新必须源码构建。
3. **构建 ZLS 时的 `pkg-config` 失败提示无害**，是可选探测。
4. `zls.json` 是**严格 JSON**，注释和尾逗号会让整份配置静默失效——改完用 `zls env` 复查 `config_file` 是否被识别。
5. **0.17 无人安装的 artifact 自动 `-fno-emit-bin`**：check 步骤只登记编译、不 install，就能得到"纯语义分析"的廉价检查。
6. Windows 的 ZLS 配置目录是 `%LOCALAPPDATA%`，不是 `%APPDATA%`——`zls env` 的输出为准。
7. VS Code 扩展会热心替你更新 ZLS——用自编译二进制时记得关 `zig.zls.checkForUpdate`。
8. build-on-save 在 0.17 + ZLS master 上可能降级（Build Server Protocol 迁移中），不是你没配对——看 ZLS 日志（`zls env` 里的 `log_file`）能确认。

---

上一章：[34 LRU 缓存服务器](34-zcache.md) · 下一章：[36 指针与内存深水区](36-pointers.md)
