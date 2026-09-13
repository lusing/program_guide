defmodule Ex14MacroDemo do
  defmacro unless_expr(condition, do: block) do
    quote do
      if !unquote(condition) do
        unquote(block)
      else
        :ok
      end
    end
  end
end

defmodule Ex14MacroUse do
  require Ex14MacroDemo

  def run(flag) do
    Ex14MacroDemo.unless_expr flag do
      :ran
    end
  end
end

