defmodule Ex12FileIO do
  def write_lines(path, lines) when is_binary(path) and is_list(lines) do
    File.write(path, Enum.join(lines, "\n"))
  end

  def read_text(path) when is_binary(path) do
    File.read(path)
  end
end

