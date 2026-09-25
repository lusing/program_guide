defmodule Ex29Dungeon.Rooms do
  @moduledoc """
  房间全集（书 6.3.1 + 附录 1）：六种房间，各配一个触发器模块。

  书里 `crawl/2` 用 `Enum.random` 随机选房；纯函数化改造里房间序列由
  调用方显式给出（`Engine.play/3`），加新房间 = 加一个 map 项 + 一个
  顺序键，**不改任何引擎代码**。
  """

  alias Ex29Dungeon.Room
  alias Ex29Dungeon.Room.Action
  alias Ex29Dungeon.Room.Triggers

  @rooms %{
    exit: %Room{
      description: "You can see the light of day. You found the exit!",
      actions: [Action.forward()],
      trigger: Triggers.Exit
    },
    enemy: %Room{
      description: "You can see an enemy blocking your path.",
      actions: [Action.forward()],
      trigger: Triggers.Enemy
    },
    hidden: %Room{
      description: "It's too quiet here. A corner looks good for a nap.",
      actions: [Action.forward(), Action.rest()],
      trigger: Triggers.EnemyHidden
    },
    trap: %Room{
      description: "You found a dungeon with suspicious floor tiles.",
      actions: [Action.forward(), Action.search()],
      trigger: Triggers.Trap
    },
    treasure: %Room{
      description: "You see a dusty old chest in the corner.",
      actions: [Action.forward(), Action.search()],
      trigger: Triggers.Treasure
    },
    rest: %Room{
      description: "You found a quiet place. Looks safe for a little nap.",
      actions: [Action.forward(), Action.rest()],
      trigger: Triggers.Rest
    }
  }

  @order [:exit, :enemy, :hidden, :trap, :treasure, :rest]

  @doc """
  按固定顺序列出全部房间（map 迭代顺序不保证，顺序自己掌握）：

      iex> Ex29Dungeon.Rooms.all() |> Enum.map(& &1.description) |> List.first()
      "You can see the light of day. You found the exit!"

  """
  @spec all() :: [Room.t()]
  def all, do: Enum.map(@order, &get/1)

  @doc """
  按键取房间：

      iex> Ex29Dungeon.Rooms.get(:trap).trigger
      Ex29Dungeon.Room.Triggers.Trap

  """
  @spec get(atom()) :: Room.t()
  def get(key), do: Map.fetch!(@rooms, key)

  @spec keys() :: [atom()]
  def keys, do: @order
end
