defmodule Ex29Dungeon.Room.Triggers.Rest do
  @moduledoc "安全屋（附录 1）：休息回复 3 点生命。"

  @behaviour Ex29Dungeon.Room.Trigger

  alias Ex29Dungeon.Character

  @impl Ex29Dungeon.Room.Trigger
  @spec run(Character.t(), Ex29Dungeon.Room.Action.t()) :: {Character.t(), :forward, [String.t()]}
  def run(character, %Ex29Dungeon.Room.Action{id: :forward}) do
    {character, :forward, ["You're walking cautiously and can see the next room."]}
  end

  def run(character, %Ex29Dungeon.Room.Action{id: :rest}) do
    healing = 3

    messages = [
      "You search the room for a comfortable place to rest.",
      "After a little rest you regain #{healing} hit points."
    ]

    {Character.heal(character, healing), :forward, messages}
  end
end
