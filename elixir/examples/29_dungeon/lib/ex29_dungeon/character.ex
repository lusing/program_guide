defmodule Ex29Dungeon.Character do
  @moduledoc """
  角色（书 6.2.1）：英雄与敌人**共用**一个 struct。

  结构体不允许在定义之外添加新属性——角色在游戏的任何角落都保持
  一致的形状，这是领域建模的第一块砖。`@type t` 给每个属性定类型，
  供 `@callback`、`@spec` 与 1.20 的渐进类型检查器引用。
  """

  defstruct name: nil,
            description: nil,
            hit_points: 0,
            max_hit_points: 0,
            attack_description: nil,
            damage_range: nil

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          hit_points: non_neg_integer(),
          max_hit_points: non_neg_integer(),
          attack_description: String.t(),
          damage_range: Range.t()
        }

  @doc """
  受击：生命值**往下钳到 0**——不存在负血量：

      iex> alias Ex29Dungeon.Character
      iex> knight = Ex29Dungeon.Heroes.get(:knight)
      iex> knight |> Character.take_damage(4) |> Map.get(:hit_points)
      14
      iex> knight |> Character.take_damage(99) |> Map.get(:hit_points)
      0

  """
  @spec take_damage(t(), non_neg_integer()) :: t()
  def take_damage(character, damage) do
    %{character | hit_points: max(0, character.hit_points - damage)}
  end

  @doc """
  治疗：生命值**往上钳到上限**——喝十瓶药也不会超血：

      iex> alias Ex29Dungeon.Character
      iex> wizard = Ex29Dungeon.Heroes.get(:wizard)
      iex> wizard |> Character.take_damage(3) |> Character.heal(99) |> Map.get(:hit_points)
      8

  """
  @spec heal(t(), non_neg_integer()) :: t()
  def heal(character, healing_value) do
    %{character | hit_points: min(character.hit_points + healing_value, character.max_hit_points)}
  end

  @doc """
  当前状态一行（书 6.4.3）：

      iex> alias Ex29Dungeon.Character
      iex> Ex29Dungeon.Heroes.get(:knight) |> Character.current_stats()
      "Player Stats | HP: 18/18"

  """
  @spec current_stats(t()) :: String.t()
  def current_stats(character),
    do: "Player Stats | HP: #{character.hit_points}/#{character.max_hit_points}"

  defimpl Ex29Dungeon.Display do
    @doc "协议实现：渲染成「名字 (当前血/满血)」"
    def info(character),
      do: "#{character.name} (#{character.hit_points}/#{character.max_hit_points})"
  end

  defimpl String.Chars do
    @doc "内建协议实现：字符串插值时只显示名字"
    def to_string(character), do: character.name
  end
end
