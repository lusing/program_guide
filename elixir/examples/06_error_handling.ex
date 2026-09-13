defmodule Ex06ErrorHandling do
  def safe_div(_a, 0), do: {:error, :divide_by_zero}
  def safe_div(a, b), do: {:ok, a / b}

  def safe_parse_int(text) when is_binary(text) do
    case Integer.parse(String.trim(text)) do
      {value, ""} -> {:ok, value}
      _ -> {:error, :invalid_integer}
    end
  end
end

