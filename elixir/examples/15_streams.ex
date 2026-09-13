defmodule Ex15Streams do
  def first_n_even_squares(n) when is_integer(n) and n >= 0 do
    Stream.iterate(1, &(&1 + 1))
    |> Stream.filter(&(rem(&1, 2) == 0))
    |> Stream.map(&(&1 * &1))
    |> Enum.take(n)
  end
end

