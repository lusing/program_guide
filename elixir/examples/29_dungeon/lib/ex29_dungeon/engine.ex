defmodule Ex29Dungeon.Engine do
  @moduledoc """
  爬塔引擎（书 6.1.3 / 6.4.1 的 `CLI.Main`，纯函数化）。

  书的版本把清屏、提问、随机选房混在 `crawl/2` 里；这里房间序列与
  动作脚本都是**数据**，事件流是唯一输出——同一引擎既能被 `run.exs`
  驱动做演示，也能被 ExUnit 驱动做断言。

  ```text
  play(英雄, 房间键序列, 动作脚本)
    → %{outcome: :won | :lost | :out_of_rooms, hero: 终态, events: 事件流}
  ```
  """

  alias Ex29Dungeon.{Battle, Character, Display, Rooms}

  @doc """
  开一局。动作脚本不足时取房间第一个动作（书里的默认 `forward`）。
  法师的胜局：陷阱 -3 血、火球秒哥布林、走出出口：

      iex> alias Ex29Dungeon.{Engine, Heroes}
      iex> game = Engine.play(Heroes.get(:wizard), [:trap, :enemy, :exit], [:search, :forward, :forward])
      iex> game.outcome
      :won
      iex> {game.hero.name, game.hero.hit_points}
      {"You", 5}
      iex> List.last(game.events)
      "You found the exit. You won the game. Congratulations!"

  """
  @spec play(Character.t(), [atom()], [atom()], (non_neg_integer(), Range.t() -> integer())) :: %{
          outcome: :won | :lost | :out_of_rooms,
          hero: Character.t(),
          events: [String.t()]
        }
  def play(hero, room_keys, script, opts \\ []) do
    roll = Keyword.get(opts, :roll, &Battle.roll/2)
    # 书 6.4.3：玩家角色统一改名 You，战报读起来有代入感
    hero = %{hero | name: "You"}
    crawl(hero, room_keys, script, welcome(hero), roll)
  end

  defp crawl(%{hit_points: 0} = hero, _room_keys, _script, events, _roll) do
    %{
      outcome: :lost,
      hero: hero,
      events:
        events ++
          [
            "Unfortunately your wounds are too many to keep walking.",
            "You fall onto the floor without strength to carry on.",
            "Game over!"
          ]
    }
  end

  defp crawl(hero, [], _script, events, _roll) do
    %{
      outcome: :out_of_rooms,
      hero: hero,
      events: events ++ ["The dungeon goes quiet. No more rooms on your map."]
    }
  end

  defp crawl(hero, [room_key | rest_rooms], script, events, roll) do
    room = Rooms.get(room_key)
    {action, script_rest} = pick_action(script, room)

    events =
      events ++
        [
          "You keep moving forward to the next room.",
          room.description,
          Character.current_stats(hero)
        ] ++
        render_options(room.actions) ++
        ["Which one? [#{question(room)}]", "Your choice: #{Display.info(action)}"]

    {hero, flag, trigger_events} = room.trigger.run(hero, action)
    events = events ++ trigger_events

    case flag do
      :exit ->
        %{
          outcome: :won,
          hero: hero,
          events: events ++ ["You found the exit. You won the game. Congratulations!"]
        }

      :forward ->
        crawl(hero, rest_rooms, script_rest, events, roll)
    end
  end

  # 脚本给不出（或给错）动作时，取房间第一个动作兜底
  defp pick_action([], room), do: {hd(room.actions), []}

  defp pick_action([id | rest], room) do
    case Enum.find(room.actions, &(&1.id == id)) do
      nil -> {hd(room.actions), rest}
      action -> {action, rest}
    end
  end

  defp render_options(actions) do
    actions
    |> Enum.with_index(1)
    |> Enum.map(fn {action, index} -> "#{index} - #{Display.info(action)}" end)
  end

  defp question(room) do
    Enum.join(1..Enum.count(room.actions)//1, ",")
  end

  defp welcome(hero) do
    [
      "== Dungeon Crawl ===",
      "You awake in a dungeon full of monsters.",
      "You need to survive and find the exit.",
      "Hero: #{hero.description}",
      Character.current_stats(hero)
    ]
  end
end
