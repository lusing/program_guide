defmodule Ex24Capstone.Words do
  @moduledoc """
  并发词频统计：每个 .txt 一个 Task（跑在 Task.Supervisor 下），
  失败/被杀的文件显式重试一次；结果顺序全部排序。
  """

  alias Ex24Capstone
  alias Ex24Capstone.WorkerSup

  @yield_timeout 5000

  @doc "单文件词频：File.stream! 行流 + reduce，文件再大内存恒定。"
  @spec count_file(Path.t()) :: %{String.t() => pos_integer()}
  def count_file(path) do
    path
    |> File.stream!(:line)
    |> Enum.reduce(%{}, fn line, acc ->
      line
      |> Ex24Capstone.tokenize()
      |> Enum.frequencies()
      |> Ex24Capstone.merge_counts(acc)
    end)
  end

  @doc """
  目录下全部 .txt 的并发统计。

  选项 `:kill_first`：列出的文件名，其**第一轮** worker 会卡在等待（60s），
  协调方随即杀掉它并重试——用确定性卡点替代「sleep 猜时序」。

  返回 `%{file_counts:, merged:, kill_tags:}`。
  """
  @spec count_dir(Path.t(), keyword()) :: %{
          file_counts: [{String.t(), {:ok, %{String.t() => pos_integer()}}}],
          merged: %{String.t() => pos_integer()},
          kill_tags: [{:killed, String.t(), :killed}]
        }
  def count_dir(dir, opts \\ []) do
    kill_set = MapSet.new(Keyword.get(opts, :kill_first, []))

    names =
      dir
      |> File.ls!()
      |> Enum.sort()
      |> Enum.filter(&String.ends_with?(&1, ".txt"))

    # 第一轮：全部并发；kill_set 中的任务自行卡住
    pairs = for name <- names, do: {name, launch(dir, name, name in kill_set)}

    # 确定性杀：不 sleep——任务已存在（async 即返回 pid），kill 与指令位置无关。
    # async 的任务即使跑在 Task.Supervisor 下仍与调用方相 link，:kill 穿过 link
    # 会连调用方一起杀（trap 都挡不住），所以先 unlink 再下手；yield 靠 monitor。
    for {name, task} <- pairs, name in kill_set do
      Process.unlink(task.pid)
      true = Process.exit(task.pid, :kill)
    end

    collected = for {name, task} <- pairs, do: {name, collect(task)}

    # 第二轮：对失败文件重试一次（正常 worker，不再卡）
    {file_counts, kill_tags} =
      Enum.map_reduce(collected, [], fn
        {name, {:ok, counts}}, tags ->
          {{name, {:ok, counts}}, tags}

        {name, {:exit, reason}}, tags ->
          task = launch(dir, name, false)

          case collect(task) do
            {:ok, counts} ->
              {{name, {:ok, counts}}, [{:killed, name, normalize_reason(reason)} | tags]}

            {:exit, reason2} ->
              {{name, {:error, normalize_reason(reason2)}},
               [{:killed, name, normalize_reason(reason)} | tags]}
          end
      end)

    merged =
      Enum.reduce(file_counts, %{}, fn
        {_name, {:ok, counts}}, acc -> Ex24Capstone.merge_counts(acc, counts)
        {_name, {:error, _}}, acc -> acc
      end)

    %{
      file_counts: file_counts,
      merged: merged,
      kill_tags: Enum.reverse(kill_tags)
    }
  end

  # 派生一个 worker；stall=true 时先确定性等待，被杀就到不了计数阶段
  @spec launch(Path.t(), String.t(), boolean()) :: Task.t()
  defp launch(dir, name, stall) do
    Task.Supervisor.async(WorkerSup, fn ->
      if stall do
        receive do
          :cancel -> :cancelled
        after
          60_000 -> :stalled
        end
      end

      count_file(Path.join(dir, name))
    end)
  end

  # yield 拿结果；超时则 shutdown 收尾（不泄露子进程）
  @spec collect(Task.t()) :: {:ok, term()} | {:exit, term()}
  defp collect(task) do
    case Task.yield(task, @yield_timeout) || Task.shutdown(task, :brutal_kill) do
      {:ok, value} -> {:ok, value}
      {:exit, reason} -> {:exit, reason}
    end
  end

  # 退出原因归一化：:kill 造成的是 :killed，其余一律 :abnormal（不打印原始 term）
  @spec normalize_reason(term()) :: :killed | :abnormal
  defp normalize_reason(:killed), do: :killed
  defp normalize_reason(_other), do: :abnormal
end
