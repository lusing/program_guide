%% ============================================================
%% kvapp.app —— 应用的「资源文件」（application resource file）
%%
%% 这是第 23 章用的最小 OTP 应用。它必须叫 <应用名>.app，
%% 并且必须放在**代码路径**上的某个目录里（本仓库是 build/ebin/），
%% application:load(kvapp) 就是去代码路径里找 kvapp.app 这个名字。
%%
%% 内容是一个普通的 Erlang 项（term），以一个「点」结尾 —— 它**不是模块**，
%% 是数据文件，用 file:consult/1 读。所以：
%%   · 不能写函数、不能写注释以外的代码
%%   · 编码：file:consult/1 内部会先调 epp:set_encoding/1，而 epp 的
%%     ?DEFAULT_ENCODING 就是 utf8（本机 stdlib-8.0.2/src/epp.erl:111）。
%%     实测 `file:consult` 读含「中文描述」的 .app 得到的正是
%%     [20013,25991,25551,36848]，所以**这里写中文没问题**。
%%     想强制 latin1 要在文件里写 `%% coding: latin-1` 注释。
%%     （这一条容易想当然地写成「.app 不能有中文」，实测过才敢下结论。）
%%
%% 本文件里仍然全用 ASCII，只是因为描述文本要跟 README/指南里的输出对齐。
%%
%% 各字段含义：
%%   description  一句人话，application:which_applications/0 会显示它
%%   vsn          版本，字符串
%%   modules      本应用包含的模块列表（发布（release）工具靠它决定装哪些 beam）
%%   registered   本应用注册的进程名（发布时用来判断应用是否在跑）
%%   applications 依赖的**其它应用**列表；本应用启动前它们必须已经启动
%%   mod          应用回调模块 + 启动参数，{Module, StartArgs}；
%%                没有监督树的应用（纯库）可以把 mod 整个省掉
%%   env          应用环境的**默认值**；运行时可以覆盖，不会写回这个文件
%% ============================================================
{application, kvapp,
 [{description, "minimal OTP application demo (1 gen_server + 1 supervisor)"},
  {vsn, "1.0.0"},
  {modules, [kvapp_app, kvapp_sup, kvapp_store]},
  {registered, [kvapp_sup, kvapp_store]},
  {applications, [kernel, stdlib]},
  {mod, {kvapp_app, []}},
  {env, [{greeting, "hello from kvapp.app"},
         {max_items, 100},
         {store_mode, memory}]}
 ]}.
