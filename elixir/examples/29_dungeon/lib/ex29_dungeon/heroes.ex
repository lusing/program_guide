defmodule Ex29Dungeon.Heroes do
  @moduledoc """
  英雄全集（书 6.2.2）：数据即配置——加一个英雄不改任何逻辑，
  往 map 里添一项就行。
  """

  alias Ex29Dungeon.Character

  @heroes %{
    knight: %Character{
      name: "Knight",
      description: "Knight has strong defense and consistent damage.",
      hit_points: 18,
      max_hit_points: 18,
      damage_range: 4..5,
      attack_description: "a sword"
    },
    wizard: %Character{
      name: "Wizard",
      description: "Wizard has strong attack, but low health.",
      hit_points: 8,
      max_hit_points: 8,
      damage_range: 6..10,
      attack_description: "a fireball"
    },
    rogue: %Character{
      name: "Rogue",
      description: "Rogue has high variability of attack damage.",
      hit_points: 12,
      max_hit_points: 12,
      damage_range: 1..12,
      attack_description: "a dagger"
    }
  }

  @order [:knight, :wizard, :rogue]

  @doc """
  按固定顺序列出（map 迭代顺序不保证，顺序自己掌握）：

      iex> Ex29Dungeon.Heroes.all() |> Enum.map(& &1.name)
      ["Knight", "Wizard", "Rogue"]

  """
  @spec all() :: [Character.t()]
  def all, do: Enum.map(@order, &get/1)

  @doc """
  按键取英雄：

      iex> Ex29Dungeon.Heroes.get(:wizard).damage_range
      6..10

  """
  @spec get(:knight | :wizard | :rogue) :: Character.t()
  def get(key), do: Map.fetch!(@heroes, key)
end
