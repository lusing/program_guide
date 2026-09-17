%% kvapp 之外第二个 .app 实例：mini-grep 的应用资源文件。
%% 它是**数据文件**（file:consult 读），erlc 不编译它；
%% build.ps1 会把它拷到 build/24_minigrep/（代码路径上）。
%% epp 默认 UTF-8，注释里可以写中文。
{application, mg,
 [{description, "mini-grep: supervisor + dispatcher + worker pool"},
  {vsn, "1.0.0"},
  {modules, [mg_app, mg_sup, mg_dispatcher, mg_worker]},
  {registered, [mg_sup, mg_dispatcher]},
  {applications, [kernel, stdlib]},
  {mod, {mg_app, []}},
  %% env 是配置来源：dispatcher 在 init/1 里读一次（17 章：init 快照）
  {env, [{max_workers, 4}]}]}.
