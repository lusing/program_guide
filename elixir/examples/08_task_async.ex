defmodule Ex08TaskAsync do
  def parallel_sum(a, b) do
    t1 = Task.async(fn -> Enum.sum(1..a) end)
    t2 = Task.async(fn -> Enum.sum(1..b) end)
    Task.await(t1, 5_000) + Task.await(t2, 5_000)
  end
end

