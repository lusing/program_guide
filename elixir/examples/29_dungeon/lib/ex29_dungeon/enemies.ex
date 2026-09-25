defmodule Ex29Dungeon.Enemies do
  @moduledoc """
  怪物全集（书 6.4.3）：与英雄共用 `Ex29Dungeon.Character`——
  struct 只描述「角色是什么」，正邪之分是数据的事。
  """

  alias Ex29Dungeon.Character

  @enemies %{
    ogre: %Character{
      name: "Ogre",
      description: "A large creature. Big muscles. Angry and hungry.",
      hit_points: 12,
      max_hit_points: 12,
      damage_range: 3..5,
      attack_description: "a hammer"
    },
    orc: %Character{
      name: "Orc",
      description: "A green evil creature. Wears armor and an axe.",
      hit_points: 8,
      max_hit_points: 8,
      damage_range: 2..4,
      attack_description: "an axe"
    },
    goblin: %Character{
      name: "Goblin",
      description: "A small green creature. Wears dirty clothes and a dagger.",
      hit_points: 4,
      max_hit_points: 4,
      damage_range: 1..2,
      attack_description: "a dagger"
    }
  }

  @order [:ogre, :orc, :goblin]

  @doc """
  按固定顺序列出：

      iex> Ex29Dungeon.Enemies.all() |> Enum.map(& &1.name)
      ["Ogre", "Orc", "Goblin"]

  """
  @spec all() :: [Character.t()]
  def all, do: Enum.map(@order, &get/1)

  @doc """
  按键取怪物：

      iex> Ex29Dungeon.Enemies.get(:goblin).hit_points
      4

  """
  @spec get(:ogre | :orc | :goblin) :: Character.t()
  def get(key), do: Map.fetch!(@enemies, key)

  @doc """
  选怪。书里是 `Enum.random/1`——为了确定性输出，改成按英雄最大
  生命值取模的确定性挑选（随机性被赶出引擎，见第 28 章）：

      iex> Ex29Dungeon.Enemies.pick(%{max_hit_points: 18}).name
      "Ogre"
      iex> Ex29Dungeon.Enemies.pick(%{max_hit_points: 8}).name
      "Goblin"
      iex> Ex29Dungeon.Enemies.pick(%{max_hit_points: 10}).name
      "Orc"

  """
  @spec pick(%{max_hit_points: pos_integer()}) :: Character.t()
  def pick(character) do
    Enum.at(all(), rem(character.max_hit_points, map_size(@enemies)))
  end
end
