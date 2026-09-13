defmodule Ex07ModuleAliasImport.Math do
  def add(a, b), do: a + b
end

defmodule Ex07ModuleAliasImport.Use do
  alias Ex07ModuleAliasImport.Math, as: M
  import Kernel, except: [div: 2]

  def sum3(a, b, c), do: M.add(M.add(a, b), c)
  def quotient(a, b), do: Kernel.div(a, b)
end

