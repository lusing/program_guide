defmodule Ex05StructProtocol.User do
  defstruct [:name, :age]
end

defprotocol Ex05Stringify do
  def to_text(data)
end

defimpl Ex05Stringify, for: Ex05StructProtocol.User do
  def to_text(%Ex05StructProtocol.User{name: name, age: age}), do: "#{name}(#{age})"
end

defimpl Ex05Stringify, for: Integer do
  def to_text(v), do: "int:#{v}"
end

