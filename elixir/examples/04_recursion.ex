defmodule Ex04Recursion do
  def factorial(n) when is_integer(n) and n >= 0, do: do_factorial(n, 1)

  defp do_factorial(0, acc), do: acc
  defp do_factorial(n, acc), do: do_factorial(n - 1, n * acc)

  def len(list), do: do_len(list, 0)
  defp do_len([], acc), do: acc
  defp do_len([_ | rest], acc), do: do_len(rest, acc + 1)
end

