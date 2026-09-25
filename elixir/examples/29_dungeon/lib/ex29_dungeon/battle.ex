defmodule Ex29Dungeon.Battle do
  @moduledoc """
  战斗（书 6.4.3）：两个角色轮流互攻，一方倒下即停（死者不还手）。

  书里 `attack` 用 `Enum.random(char.damage_range)` 取伤害——本章把
  随机性**注入化**（第 28 章）：`roll/2` 以攻击序号为自变量，同样的
  序列永远同样的伤害，战斗因此可逐字节复跑、可直接 doctest。
  """

  alias Ex29Dungeon.Character

  @doc """
  确定性掷骰：`first + ((i * 7 + 3) mod 区间宽度)`——攻击序号走进来，
  伤害走出去：

      iex> Ex29Dungeon.Battle.roll(0, 4..5)
      5
      iex> Ex29Dungeon.Battle.roll(1, 3..5)
      4
      iex> Ex29Dungeon.Battle.roll(2, 6..10)
      8

  """
  @spec roll(non_neg_integer(), Range.t()) :: integer()
  def roll(i, range) do
    size = range.last - range.first + 1
    range.first + rem(i * 7 + 3, size)
  end

  @doc """
  打完一整场：A 先手；返回 `{A 终态, B 终态, 战报}`——**按参数顺序**
  返回，与谁死谁活无关（书 6.4.3 的约定，调用方自己认人；把返回解构
  反了，英雄就会变成怪物——本项目实测踩过的坑）。法师先手打哥布林：
  一发火球 9 点直接带走：

      iex> alias Ex29Dungeon.Battle
      iex> wizard = Ex29Dungeon.Heroes.get(:wizard)
      iex> goblin = Ex29Dungeon.Enemies.get(:goblin)
      iex> {wizard2, goblin2, log} = Battle.fight(wizard, goblin)
      iex> {wizard2.hit_points, goblin2.hit_points}
      {8, 0}
      iex> log
      ["Wizard attacks with a fireball and deals 9 damage.",
       "Goblin receives 9. Current HP: 0."]

  """
  @spec fight(Character.t(), Character.t(), (non_neg_integer(), Range.t() -> integer())) ::
          {Character.t(), Character.t(), [String.t()]}
  def fight(char_a, char_b, roll \\ &__MODULE__.roll/2), do: do_fight(char_a, char_b, 0, roll)

  defp do_fight(%{hit_points: hp_a} = char_a, %{hit_points: hp_b} = char_b, _i, _roll)
       when hp_a == 0 or hp_b == 0,
       do: {char_a, char_b, []}

  defp do_fight(char_a, char_b, i, roll) do
    {char_b_after, log_a, i2} = attack(char_a, char_b, i, roll)
    {char_a_after, log_b, i3} = attack(char_b_after, char_a, i2, roll)
    {char_a_final, char_b_final, log_c} = do_fight(char_a_after, char_b_after, i3, roll)
    {char_a_final, char_b_final, log_a ++ log_b ++ log_c}
  end

  # 死人不攻击（书 6.4.3 attack 的第一个子句）
  defp attack(%{hit_points: 0} = _dead_attacker, defender, i, _roll),
    do: {defender, [], i}

  defp attack(attacker, defender, i, roll) do
    damage = roll.(i, attacker.damage_range)
    defender_after = Character.take_damage(defender, damage)

    log = [
      attack_message(attacker, damage),
      receive_message(defender_after, damage)
    ]

    {defender_after, log, i + 1}
  end

  defp attack_message(%{name: "You"} = attacker, damage) do
    "You attack with #{attacker.attack_description} and deal #{damage} damage."
  end

  defp attack_message(attacker, damage) do
    "#{attacker.name} attacks with #{attacker.attack_description} and deals #{damage} damage."
  end

  defp receive_message(%{name: "You"} = receiver, damage) do
    "You receive #{damage}. Current HP: #{receiver.hit_points}."
  end

  defp receive_message(receiver, damage) do
    "#{receiver.name} receives #{damage}. Current HP: #{receiver.hit_points}."
  end
end
