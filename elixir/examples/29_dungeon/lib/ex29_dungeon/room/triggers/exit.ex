defmodule Ex29Dungeon.Room.Triggers.Exit do
  @moduledoc "出口（书 6.4.1）：什么都不发生，直接找到出口。"

  @behaviour Ex29Dungeon.Room.Trigger

  @impl Ex29Dungeon.Room.Trigger
  @spec run(Ex29Dungeon.Character.t(), Ex29Dungeon.Room.Action.t()) ::
          {Ex29Dungeon.Character.t(), :exit, [String.t()]}
  def run(character, _action), do: {character, :exit, []}
end
