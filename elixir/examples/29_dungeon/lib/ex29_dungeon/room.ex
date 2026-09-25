defmodule Ex29Dungeon.Room do
  @moduledoc """
  房间（书 6.3.1）：**引用 struct 的 struct**——一个房间装着若干动作，
  外加一个遵守 `Room.Trigger` 契约的触发器模块（存的是模块名原子）。
  """

  alias Ex29Dungeon.Room.Action

  defstruct description: nil, actions: [], trigger: nil

  @type t :: %__MODULE__{
          description: String.t(),
          actions: [Action.t()],
          trigger: module()
        }
end
