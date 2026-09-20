defmodule Ex24Capstone.Application do
  @moduledoc "根监督树：缓存 + Task.Supervisor，one_for_one——任一死亡只重启它自己。"
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Ex24Capstone.Cache,
      {Task.Supervisor, name: Ex24Capstone.WorkerSup}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Ex24Capstone.RootSup)
  end

  @doc "供演示读取：当前存活的子进程数。"
  @spec active_children() :: non_neg_integer()
  def active_children do
    # 1.20: count_children/1 返回 map（旧版为 keyword）
    Ex24Capstone.RootSup |> Supervisor.count_children() |> Map.get(:active)
  end
end
