defmodule Ex02TypesPattern do
  def describe({:user, name, age}) when is_binary(name) and is_integer(age) do
    {:ok, "user=#{name}, age=#{age}"}
  end

  def describe(%{name: name, age: age}) when is_binary(name) and is_integer(age) do
    {:ok, "user=#{name}, age=#{age}"}
  end

  def describe(_), do: {:error, :invalid_data}
end

