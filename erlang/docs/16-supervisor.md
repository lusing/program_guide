# 16 · supervisor ⭐

> 对应示例：`examples/16_supervisor/`（`-behaviour(supervisor)`）

## 16.1 重启策略变成一份声明

```erlang
init({Strategy, Intensity, Period, Tags, Notify}) ->
    SupFlags = #{strategy => Strategy, intensity => Intensity, period => Period},
    {ok, {SupFlags, [spec(T, Notify) || T <- Tags]}}.
```

`init/1` 返回 `{ok, {监督标志, 子进程规格列表}}`——重启几次、谁先谁后、怎么关停全部声明式。子进程两条硬性要求：start 函数返回 `{ok, Pid}`；进程必须**已与 supervisor 建立 link**（`spawn_link` / `gen_server:start_link`）。

## 16.2 三种重启策略（实测区分）

| strategy | 谁被重启 | 适用 |
|---|---|---|
| `one_for_one` | 只有崩掉的那个 | 进程互相独立（默认，最常用） |
| `one_for_all` | 全部 | 强耦合，缺一不可 |
| `rest_for_one` | 崩的那个 + 启动顺序在它**之后**的 | 有启动依赖（先 DB 后缓存） |

实测要点：**杀第一个孩子时 one_for_all 与 rest_for_one 结果相同**——要杀最后一个才能区分开。示例用"收到几条 child_up 通知"判定重启范围，不靠等待时间猜。

## 16.3 child spec 逐字段

```erlang
#{id       => kv_store,          %% 唯一标识：重启靠它认「同一个孩子」
  start    => {M, F, Args},      %% 必须返回 {ok, Pid}
  restart  => permanent,         %% permanent 永远重启 | transient 只重启异常退出 | temporary 从不
  shutdown => 5000,              %% 关闭宽限 ms；brutal_kill 直接 kill；子监督者用 infinity
  type     => worker,            %% worker | supervisor
  modules  => [M],               %% release 升级提示
  significant => false}          %% OTP 24：标记「核心成员」，配合 auto_shutdown（16.5）
```

## 16.4 重启强度：撑不住就整树关掉

`intensity / period` = period 秒内最多重启 intensity 次。连续杀 3 次（强度 2/1s）→ 第 3 次 supervisor **自己终止**（原因 shutdown），整棵树关掉——这是有意的保护：子进程在 init 里就崩时，没有它就是无限重启风暴。上层监督者接到 shutdown 再决定怎么办（多级树的意义）。

## 16.5 auto_shutdown：干完活自动收队（OTP 24）

临时监督树（一次性任务编组、测试夹具）有个老问题：任务进程正常退出了，supervisor 还挂在那儿，得有人记得去关。OTP 24 把"何时自动关闭"写进 sup flags，配合 child spec 的 `significant` 标记区分"主角"和"陪跑"：

```erlang
Flags = #{strategy => one_for_one,
          auto_shutdown => any_significant},   %% never(默认) | any_significant | all_significant
Children = [#{id => main_task, restart => temporary, significant => true,  ...},  %% 主角
            #{id => helper,    restart => temporary, significant => false, ...}], %% 陪跑
```

实测（本机 OTP 29）：主角 `gen_server:stop` 正常退出后，**supervisor 自动终止**，链接方收到 `{'EXIT', Sup, shutdown}`；对照组陪跑正常退出，supervisor 原地不动。两档自动关闭语义：

- `any_significant`：**任何一个** significant 子进程终止就关整棵树（其余子进程按 shutdown 宽限带走）。文档精确表述：transient 的 significant 正常退出，或 temporary 的 significant 正常/异常退出时触发。
- `all_significant`：**最后一个** significant 退出才关——全员到齐型任务组。

两个约束（文档原文，都实测可查）：`auto_shutdown => never`（默认）时 child spec 带 `significant => true` 会**被直接拒绝**——这个标记只在自动关闭开启时有意义；significant 配 `permanent` 重启没意义（退了又拉起，永远等不到关闭条件）。

**hibernate_after（OTP 28）**：sup flags 再加 `hibernate_after => 1000`，空闲 1 秒的 supervisor 整机休眠（实测 flag 被接受启动正常）——管着几千个动态子进程的长驻 supervisor 省内存的开关。

## 16.6 观察与运行期增删

```erlang
supervisor:which_children(Sup).   %% [{Id, Pid, Type, Modules}]——顺序未定义，要 sort
supervisor:count_children(Sup).   %% [{specs,N},{active,N},{supervisors,N},{workers,N}]
supervisor:start_child(Sup, Spec).
supervisor:terminate_child(Sup, Id).   %% 停（清单还在）
supervisor:delete_child(Sup, Id).      %% 才是从清单里去掉
```

## 16.7 坑位清单

1. **which_children 顺序未定义**：依赖顺序的代码在别的 OTP 版本就翻车——按 Id 查、输出前 sort。
2. **terminate_child ≠ delete_child**：terminate 只是停，清单还在（permanent 的会被重启行为管着）；delete 才移除；重复 delete 返回 `{error, ...}`。
3. **子进程没和 supervisor link**：死了 supervisor 根本不知道，无所谓重启——start 函数里必须用 `*_link`。
4. **transient 只重启异常退出**：`exit(normal)` 的正常退出不重启——做"干完就退"的任务进程用它。
5. **intensity 太小误伤**：正常发版/重启会吃掉重启额度——上线前想清楚数值。
6. **shutdown 是宽限不是杀死**：超时后才 brutal kill；gen_server 在宽限期内收到 shutdown → 调 terminate/2（前提 trap_exit，17 章）。
7. **auto_shutdown=never + significant=true 直接被拒**（16.5）——significant 只在自动关闭开启时合法；且触发的是 transient normal / temporary normal+abnormal 退出，permanent 重启策略下等不到。

---

---

上一章：[15 gen_server ⭐](15-gen-server.md) · 下一章：[17 application ⭐](17-application.md)
