defmodule Ex29DungeonTest do
  use ExUnit.Case, async: true

  alias Ex29Dungeon.{Battle, Character, Display, Engine, Enemies, Heroes, Room, Rooms}

  doctest Ex29Dungeon.Character
  doctest Ex29Dungeon.Heroes
  doctest Ex29Dungeon.Enemies
  doctest Ex29Dungeon.Room.Action
  doctest Ex29Dungeon.Rooms
  doctest Ex29Dungeon.Battle
  doctest Ex29Dungeon.Engine

  describe "Character：受击与治疗的钳制" do
    test "take_damage 往下钳到 0，heal 往上钳到上限" do
      knight = Heroes.get(:knight)
      assert knight |> Character.take_damage(4) |> Map.get(:hit_points) == 14
      assert knight |> Character.take_damage(99) |> Map.get(:hit_points) == 0

      assert knight |> Character.take_damage(10) |> Character.heal(99) |> Map.get(:hit_points) ==
               18
    end

    test "take_damage/heal 返回新 struct，原值不变" do
      wizard = Heroes.get(:wizard)
      hurt = Character.take_damage(wizard, 3)
      assert hurt.hit_points == 5
      assert wizard.hit_points == 8
    end

    test "current_stats 一行战况" do
      assert Character.current_stats(Heroes.get(:rogue)) == "Player Stats | HP: 12/12"
    end
  end

  describe "协议" do
    test "Display.info 对两种 struct 多态" do
      assert Display.info(Heroes.get(:knight)) == "Knight (18/18)"
      trap_search = Rooms.get(:trap).actions |> List.last()
      assert Display.info(trap_search) == "Search the room."
    end

    test "String.Chars：角色插值即名字，动作插值即文本" do
      assert to_string(Heroes.get(:wizard)) == "Wizard"
      assert "Go: #{Ex29Dungeon.Room.Action.forward()}" == "Go: Move forward."
    end
  end

  describe "战斗" do
    test "法师先手一发带走哥布林，自身无伤" do
      {w2, g2, log} = Battle.fight(Heroes.get(:wizard), Enemies.get(:goblin))
      assert {w2.hit_points, g2.hit_points} == {8, 0}

      assert log == [
               "Wizard attacks with a fireball and deals 9 damage.",
               "Goblin receives 9. Current HP: 0."
             ]
    end

    test "骑士先手打食人魔：确定性拉锯，骑士 11 血胜出" do
      {k2, o2, log} = Battle.fight(Heroes.get(:knight), Enemies.get(:ogre))
      assert {k2.hit_points, o2.hit_points} == {11, 0}
      assert Enum.count(log) == 10
      assert List.first(log) == "Knight attacks with a sword and deals 5 damage."
      assert List.last(log) == "Ogre receives 5. Current HP: 0."
    end

    test "死者不还手：0 血攻击者直接跳过" do
      dead = Character.take_damage(Heroes.get(:knight), 99)
      {d2, r2, log} = Battle.fight(dead, Enemies.get(:orc))
      assert d2.hit_points == 0
      assert r2.hit_points == 8
      assert log == []
    end

    test "注入自定义 roll：伤害全可控" do
      max_roll = fn _i, _range -> 99 end
      {k2, o2, log} = Battle.fight(Heroes.get(:knight), Enemies.get(:ogre), max_roll)
      assert k2.hit_points == 18
      assert o2.hit_points == 0
      assert Enum.count(log) == 2
    end
  end

  describe "触发器：行为契约" do
    test "六种触发器都导出 run/2" do
      for key <- Rooms.keys() do
        trigger = Rooms.get(key).trigger
        # function_exported?/3 对未加载模块恒 false——先强制加载再查
        Code.ensure_loaded!(trigger)
        assert function_exported?(trigger, :run, 2), "#{inspect(trigger)} 缺 run/2"
      end
    end

    test "出口触发器直接 :exit" do
      knight = Heroes.get(:knight)

      assert Ex29Dungeon.Room.Triggers.Exit.run(knight, Ex29Dungeon.Room.Action.forward()) ==
               {knight, :exit, []}
    end

    test "陷阱扣 3 血、宝藏与休息各回血" do
      wizard = Heroes.get(:wizard)
      action = Ex29Dungeon.Room.Action

      {w2, :forward, msgs} = Ex29Dungeon.Room.Triggers.Trap.run(wizard, action.search())
      assert w2.hit_points == 5
      assert List.last(msgs) == "You are hit by an arrow, losing 3 hit points."

      {w3, :forward, _} = Ex29Dungeon.Room.Triggers.Treasure.run(w2, action.search())
      assert w3.hit_points == 8

      hurt = Character.take_damage(Heroes.get(:knight), 10)
      {k2, :forward, _} = Ex29Dungeon.Room.Triggers.Rest.run(hurt, action.rest())
      assert k2.hit_points == 11
    end

    test "伏击触发器让敌人先手（fight 参数顺序即先手）" do
      knight = Heroes.get(:knight)

      {k2, :forward, msgs} =
        Ex29Dungeon.Room.Triggers.EnemyHidden.run(knight, Ex29Dungeon.Room.Action.rest())

      assert k2.hit_points == 6
      assert "The enemy Ogre surprises you and attacks first." in msgs
    end
  end

  describe "Engine：三局经典对局" do
    test "胜局：法师 陷阱→敌人→出口，终局 5 血" do
      game =
        Engine.play(Heroes.get(:wizard), [:trap, :enemy, :exit], [:search, :forward, :forward])

      assert game.outcome == :won
      assert {game.hero.name, game.hero.hit_points} == {"You", 5}
      assert List.last(game.events) == "You found the exit. You won the game. Congratulations!"
      assert "You are hit by an arrow, losing 3 hit points." in game.events
      assert "You attack with a fireball and deal 9 damage." in game.events
    end

    test "败局：骑士伏击后再遇食人魔，战至 0 血" do
      game = Engine.play(Heroes.get(:knight), [:hidden, :enemy], [:rest, :forward])
      assert game.outcome == :lost
      assert game.hero.hit_points == 0
      assert List.last(game.events) == "Game over!"

      assert game.events |> Enum.filter(&String.starts_with?(&1, "You attack")) |> Enum.count() ==
               5
    end

    test "治疗局：盗贼 -3 后 +5 钳到满血，胜利" do
      game =
        Engine.play(Heroes.get(:rogue), [:trap, :treasure, :exit], [:search, :search, :forward])

      assert game.outcome == :won
      assert {game.hero.hit_points, game.hero.max_hit_points} == {12, 12}
      assert "You drink the potion and restore 5 hit points." in game.events
    end

    test "房间走完还活着：out_of_rooms" do
      game = Engine.play(Heroes.get(:knight), [:rest], [:rest])
      assert game.outcome == :out_of_rooms
      assert game.hero.hit_points == 18
    end

    test "脚本不足时取房间第一个动作兜底" do
      game = Engine.play(Heroes.get(:rogue), [:trap, :exit], [])
      assert game.outcome == :won
      assert "Your choice: Move forward." in game.events
      refute "You are hit by an arrow" in game.events
    end
  end

  describe "数据即配置" do
    test "Rooms.all 顺序固定且 trigger 都是模块原子" do
      rooms = Rooms.all()
      assert Enum.count(rooms) == 6
      assert Enum.all?(rooms, &is_atom(&1.trigger))
    end

    test "Room struct 的形状" do
      room = Rooms.get(:enemy)
      assert %Room{} = room
      assert room.actions == [%Ex29Dungeon.Room.Action{id: :forward, label: "Move forward."}]
    end
  end
end
