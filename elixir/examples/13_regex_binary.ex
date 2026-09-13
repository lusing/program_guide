defmodule Ex13RegexBinary do
  def extract_numbers(text) when is_binary(text) do
    Regex.scan(~r/\d+/, text) |> List.flatten()
  end

  def packet(type, payload) when is_integer(type) and is_binary(payload) do
    <<type::8, byte_size(payload)::16, payload::binary>>
  end
end

