# 17 · 包与环境 ⭐

> 对应示例：`examples/17_pkgenv/`（包工程：env/ 环境 + MathTools/ 本地包）
>
> Pkg 是 Julia 的 npm/cargo：REPL 一等公民，可完全复现，离线友好。

## 17.1 两个文件、三层概念

| 概念 | 载体 | 回答的问题 |
|---|---|---|
| 环境 environment | `Project.toml` | 直接依赖谁（name + UUID + 版本界） |
| 清单 manifest | `Manifest.toml` | **精确**装了什么（完整依赖图 + 版本 + 来源） |
| 仓库 registry | General 注册表 | 全世界的包目录（按 UUID 索引） |

`Manifest.toml` 由解析生成——**应用提交、库不提交**是社区惯例（提交 = 团队人人同环境）。

## 17.2 pkg> 模式：日常操作

REPL 按 `]` 进入（退格/退 ESC 出来）：

```text
pkg> activate myenv            # 切换/创建环境（写 Project.toml）
pkg> add JSON                  # 装包（写 [deps] + 解析 + 下载 + 预编译）
pkg> add JSON@0.21             # 指定版本
pkg> dev / add local#path      # 本地路径依赖
pkg> status                    # 看环境
pkg> instantiate              # 按 Project/Manifest 还原（团队协作入口）
pkg> update JSON              # 升级
pkg> remove JSON
pkg> test MathTools            # 跑包测试
pkg> precompile               # 手动预编译
```

脚本里等价 API：`using Pkg; Pkg.add("JSON")`（`Pkg.activate(path)`——注意 1.13 已无 `interactive` 关键字，实测坑）。

## 17.3 环境：一个目录一个 Project.toml

```text
examples/17_pkgenv/
├── env/               ← 环境（build.ps1 用 --project=env 激活）
│   ├── Project.toml
│   └── Manifest.toml  ← instantiate 生成
├── MathTools/         ← 本地包（可发布的结构）
│   ├── Project.toml
│   ├── src/MathTools.jl
│   └── test/runtests.jl
├── main.jl            ← 演示入口
└── runtests.jl
```

环境 Project.toml（[sources] 是 1.11+ 的"路径依赖写进文件"机制）：

```toml
[deps]
MathTools = "8f5c1a2b-3d4e-5f60-7a8b-9c0d1e2f3a4b"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[sources]
MathTools = { path = "../MathTools" }
```

**TOML 路径写正斜杠 `/`**——`"..\MathTools"` 是非法 TOML 转义（`\M`），实测直接解析失败。

包 Project.toml（最小集）：`name` + `uuid` + `version`（+ `[compat]` 声明 julia 版本界）。UUID 是包的全球身份证——本地包可自造，发布前须注册表分配。

## 17.4 环境栈：@ / @v#.# / @stdlib

```julia
Base.active_project()      # 当前活动项目
LOAD_PATH                  # ["@", "@v#.#", "@stdlib"]
```

`--project=env` 激活的 `@` 在栈顶；`@v1.13` 是默认全局环境（无 --project 时的一切 add 落这里）；`@stdlib` 让标准库免声明可用（但 1.11+ 的**包内**依赖仍须显式写 [deps]——脚本直跑则不用）。`using` 沿栈向下找——这就是"环境隔离 + 标准库永远在"的机制。

## 17.5 本地路径依赖 = 开发模式

`[sources]` / `Pkg.develop(path=...)` 的包**源码就地可改**：改 `MathTools/src/MathTools.jl` 重启会话即生效（配合 Revise.jl 免重启）——本教程示例把它当作"迷你包开发"全流程。与 `add` 的区别：add 解析版本并安装副本，dev/路径直连源码。

## 17.6 实操：本示例的验证流（两个入口的特判层）

```powershell
JULIA_PKG_OFFLINE=true julia --project=env -e 'using Pkg; Pkg.instantiate(); Pkg.status()'   # 还原环境（只在 Manifest 缺失时需要）
julia --project=env main.jl                                           # 在环境中运行
julia --project=env runtests.jl                                       # 在环境中测试
```

`instantiate` 幂等：已有 Manifest 就精确还原，没有就解析生成。本教程把 `env/Manifest.toml` 一并入库，
所以**常规验证流根本不用 instantiate**（两个入口只在 Manifest 缺失时才调它）——这既省时间，
也绕开了 macOS 上「解压 registry 慢到像死锁」那个坑（见 17.8 第 7 条）。

`instantiate` 幂等：已有 Manifest 就精确还原，没有就解析生成。离线可行性：**路径依赖 + 标准库**完全离线（实测）；registry 只在解析新包时触网。

## 17.7 包的一生（从目录到生态）

`Pkg.generate("MyPkg")`（或手写骨架）→ 写 src/module.jl + test/runtests.jl → `Pkg.test()` → 加 `[compat]`（Aqua.jl 查质量）→ 提交 GitHub → General 注册表 PR（Registrator 机器人）→ 全世界 `add MyPkg`。本教程到 `Pkg.test()` 为止，注册流程知道路径即可。

## 17.8 坑位清单

1. **Project.toml 里 Windows 路径用 `/`**：反斜杠是非法 TOML 转义，`{path = "..\\MathTools"}` 直接解析错误（17.3 实测）。
2. **`Pkg.activate` 无 `interactive` kwarg**（1.13 移除）：老代码 `Pkg.activate(dir; interactive=false)` 报 MethodError（17.2 实测）。
3. **1.11+ 包内 stdlib 依赖要显式**：包的 [deps] 不写 `Statistics` 就 `using` 不到（脚本/REPL 靠 @stdlib 可以，包不行）。
4. **环境 ≠ 目录全家桶**：`--project` 认的是含 Project.toml 的目录；跑错目录 = 静默用上默认环境——先 `Pkg.status()` 确认在哪。
5. **`add` 写的是"当前活动环境"**：忘 activate 就 add，包进了 `@v1.13` 全局环境——先看提示行的环境名。
6. **改了本地包源码还报老行为**：预编译缓存没失效——改完 `Pkg.precompile()` 或用 Revise.jl。
7. **首跑 `Pkg.instantiate()` 卡住十几分钟**：Pkg 要读/解压 General registry
   （7.5MB → 240MB、约 4 万个小文件），在没有可用 registry 的 depot 上，这一步慢得像死锁（macOS 实测）。
   只依赖路径包 + stdlib 的工程**根本不需要 instantiate**：`env/Manifest.toml` 已入库，
   `julia --project=env main.jl` 直接就能跑——两个入口都已改成「Manifest 缺失才 instantiate」。
   手工 `instantiate` 时设 `JULIA_PKG_OFFLINE=true` 能省掉联网动作，但省不掉 registry 解压。
