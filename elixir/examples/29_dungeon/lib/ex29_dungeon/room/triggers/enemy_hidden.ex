defmodule Ex29Dungeon.Room.Triggers.EnemyHidden do
  @moduledoc """
  伏击（附录 1）：想休息？怪物先动手。`Battle.fight/2` 的参数顺序
  决定先手——敌人排第一。
  """

  @behaviour Ex29Dungeon.Room.Trigger

  alias Ex29Dungeon.Battle
  alias Ex29Dungeon.Character
  alias Ex29Dungeon.Enemies

  @impl Ex29Dungeon.Room.Trigger
  @spec run(Character.t(), Ex29Dungeon.Room.Action.t()) :: {Character.t(), :forward, [String.t()]}
  def run(character, %Ex29Dungeon.Room.Action{id: :forward}) do
    {character, :forward, ["You're walking cautiously and can see the next room."]}
  end

  def run(character, %Ex29Dungeon.Room.Action{id: :rest}) do
    enemy = Enemies.pick(character)

    opening = [
      "You search the room for a comfortable place to rest.",
      "Suddenly...",
      enemy.description,
      "The enemy #{enemy.name} surprises you and attacks first."
    ]

    {_enemy_final, you_final, log} = Battle.fight(enemy, character)
    {you_final, :forward, opening ++ log}
  end
end
