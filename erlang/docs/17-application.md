# 17 · application ⭐

> 对应示例：`examples/17_application/`（多模块：kvapp 四件套 + 驱动 `17_application.erl`；build.ps1 自动把 `.app` 拷进代码路径）

## 17.1 五层组织结构

进程 → 监督树 → **应用** → 节点 → 发布（release）。应用处在中间：**部署、启动、停止、配置的最小单元**。一个应用 = 一棵进程树（顶层一个监督者）+ 一个 `.app` 资源文件：

```text
examples/17_application/
├── 17_application.erl   驱动（演示应用生命周期）
├── kvapp.app            资源文件：描述 + 配置 + 回调模块（数据，erlc 不编）
├── kvapp_app.erl        应用回调：start/2 / prep_stop/1 / stop/1 / config_change/3
├── kvapp_sup.erl        顶层监督者
└── kvapp_store.erl      干活的 gen_server
```

## 17.2 .app 文件逐字段

```erlang
{application, kvapp,
 [{description, "minimal OTP application demo"},
  {vsn, "1.0.0"},
  {modules, [kvapp_app, kvapp_sup, kvapp_store]},
  {registered, [kvapp_sup, kvapp_store]},
  {applications, [kernel, stdlib]},   %% 依赖：OTP 按此排启动顺序
  {mod, {kvapp_app, []}},             %% 回调模块 + 启动参数
  {env, [{max_items, 100}, {store_mode, memory}]}]}.
```

`.app` 必须躺在代码路径上（`application:load` 就是去那儿找）；`get_all_key/1` 会把你**没写的字段补成默认值**（id/maxP/maxT/…）——最容易忽略的一点。测试可以不落盘：`application:load({application, Name, Spec})` 直接把 spec 当项交进去。

## 17.3 生命周期：load → start → stop → unload

```erlang
application:ensure_all_started(kvapp).  %% ✔ 幂等、按依赖顺序启动——用这个
application:start(kvapp).               %% ✘ 不管依赖、不判断已在跑（{error,{already_started,...}}）
application:stop(kvapp).                %% 只停进程树：env 与 get_key 都还在
application:unload(kvapp).              %% 才彻底摘掉（get_env 变 undefined）
```

**stop ≠ unload**：stop 之后 env 还能读；运行中 unload 报 `{error,{running,App}}`。

## 17.4 env 是 init 时的快照

```erlang
application:get_env(kvapp, max_items, 100).   %% 永远用 /3 版带默认值
```

三层覆盖：.app 的 env（默认）→ sys.config / 命令行（部署）→ `set_env/3`（运行时，不写回文件）。实测：set_env 之后**运行中的进程读的还是老值**——env 在进程 `init/1` 里读一次就定了；要生效得重启进程。`config_change/3` **不是** set_env 的回调，它只在发布升级（release_handler）时被调。

## 17.5 关闭顺序与头号 OTP 坑

实测顺序：`Mod:prep_stop/1`（关树前，最后读写状态的机会）→ 监督者关孩子（gen_server 的 `terminate/2` 在这里被调）→ `Mod:stop/1`（树已关完，只能收尾）。

> ⚠️ **gen_server 默认不 trap_exit，supervisor 关孩子用 `exit(Child, shutdown)`——进程直接被打死，`terminate/2` 根本不会被调用**（落盘/关表全部丢失）。kvapp_store 的 `init/1` 里那句 `process_flag(trap_exit, true)` 就是为这个加的。全教程最大坑，17/16/15 三章反复强调。

## 17.6 状态反查

```erlang
application:get_application(whereis(kvapp_store)).  %% pid → 所属应用
application:get_supervisor(kvapp).                  %% 应用 → {ok, 顶层监督者 pid}
application:which_applications().                   %% {名, 描述, 版本}，只列运行中的
```

## 17.7 坑位清单

1. **忘拷 .app 到代码路径**：load 报 `{error,{"no such file or directory","x.app"}}`——erlc 只编 .erl，构建脚本必须显式拷（build.ps1 已做）。
2. **`application:start/1` 当万能启动**：不管依赖不判重——`ensure_all_started/1` 幂等且按依赖序。
3. **stop 后以为配置没了**：env 都在；彻底清理要 unload。
4. **set_env 期望运行中进程立刻看到**：不会，init 快照。
5. **config_change 当 set_env 回调用**：它只属于发布升级链路（prep_config_change 快照 → 装载 → config_change(EnvBefore) 算 diff）。
6. **一个应用多个顶层监督者**：不应该——子树挂到唯一顶层监督者下面。
7. **terminate/2 不执行**：九成是没开 trap_exit（17.5）。

---
