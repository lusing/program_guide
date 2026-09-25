defmodule Ex29Dungeon.Room.Triggers.Enemy do
  @moduledoc "正面敌人（书 6.4.3）：选一只怪，你先手打完一整场。"

  @behaviour Ex29Dungeon.Room.Trigger

  alias Ex29Dungeon.Battle
  alias Ex29Dungeon.Character
  alias Ex29Dungeon.Enemies

  @impl Ex29Dungeon.Room.Trigger
  @spec run(Character.t(), Ex29Dungeon.Room.Action.t()) :: {Character.t(), :forward, [String.t()]}
  def run(character, %Ex29Dungeon.Room.Action{id: :forward}) do
    enemy = Enemies.pick(character)

    opening = [
      enemy.description,
      "The enemy #{enemy.name} wants to fight.",
      "You were prepared and attack first."
    ]

    # fight/2 按参数顺序返回 {A 终态, B 终态, 战报}——英雄排第一
    {you_final, _enemy_final, log} = Battle.fight(character, enemy)
    {you_final, :forward, opening ++ log}
  end
end
