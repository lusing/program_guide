defmodule Ex29Dungeon.Room.Triggers.Treasure do
  @moduledoc "宝藏（附录 1）：搜查房间的奖励是 5 点治疗。"

  @behaviour Ex29Dungeon.Room.Trigger

  alias Ex29Dungeon.Character

  @impl Ex29Dungeon.Room.Trigger
  @spec run(Character.t(), Ex29Dungeon.Room.Action.t()) :: {Character.t(), :forward, [String.t()]}
  def run(character, %Ex29Dungeon.Room.Action{id: :forward}) do
    {character, :forward, ["You're walking cautiously and can see the next room."]}
  end

  def run(character, %Ex29Dungeon.Room.Action{id: :search}) do
    healing = 5

    messages = [
      "You search the room looking for something useful.",
      "You find a treasure box with a healing potion inside.",
      "You drink the potion and restore #{healing} hit points."
    ]

    {Character.heal(character, healing), :forward, messages}
  end
end
