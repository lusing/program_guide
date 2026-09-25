defmodule Ex29Dungeon.Room.Triggers.Trap do
  @moduledoc "陷阱（附录 1）：搜查房间的代价是 3 点伤害。"

  @behaviour Ex29Dungeon.Room.Trigger

  alias Ex29Dungeon.Character

  @impl Ex29Dungeon.Room.Trigger
  @spec run(Character.t(), Ex29Dungeon.Room.Action.t()) :: {Character.t(), :forward, [String.t()]}
  def run(character, %Ex29Dungeon.Room.Action{id: :forward}) do
    {character, :forward, ["You're walking cautiously and can see the next room."]}
  end

  def run(character, %Ex29Dungeon.Room.Action{id: :search}) do
    damage = 3

    messages = [
      "You search the room looking for something useful.",
      "You step on a false floor and fall into a trap.",
      "You are hit by an arrow, losing #{damage} hit points."
    ]

    {Character.take_damage(character, damage), :forward, messages}
  end
end
