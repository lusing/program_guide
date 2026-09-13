defmodule Ex03EnumPipeline do
  def sum_even_squares(list) when is_list(list) do
    list
    |> Enum.filter(&(rem(&1, 2) == 0))
    |> Enum.map(&(&1 * &1))
    |> Enum.sum()
  end
end

