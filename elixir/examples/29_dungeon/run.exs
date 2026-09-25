# 第 29 章驱动脚本：cd examples/29_dungeon && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

alias Ex29Dungeon.{Battle, Display, Engine, Enemies, Heroes, Rooms}

IO.puts("==== 29 领域建模：回合制地下城（struct + 协议 + 行为 + typespec） ====")

# ------------------------------------------------------------
# 1. 数据即配置：英雄与怪物
# ------------------------------------------------------------
IO.puts("\n-- 1. 英雄与怪物：struct 是形状，数据是血肉 --")

Enum.each(
  Heroes.all(),
  &IO.puts("  英雄 #{Display.info(&1)} —— #{&1.attack_description}，伤害 #{inspect(&1.damage_range)}")
)

Enum.each(
  Enemies.all(),
  &IO.puts("  怪物 #{Display.info(&1)} —— #{&1.attack_description}，伤害 #{inspect(&1.damage_range)}")
)

# ------------------------------------------------------------
# 2. 协议：一个 info/1，两种 struct
# ------------------------------------------------------------
IO.puts("\n-- 2. 协议 Display：多态渲染；String.Chars：插值即名字 --")

IO.puts("  Display.info(hero)  => #{inspect(Display.info(Heroes.get(:knight)))}")

IO.puts(
  "  Display.info(action) => #{inspect(Display.info(Rooms.get(:trap).actions |> List.last()))}"
)

IO.puts("  String.Chars 插值    => \"#{Heroes.get(:wizard)} casts!\"")

# ------------------------------------------------------------
# 3. 行为：触发器契约
# ------------------------------------------------------------
IO.puts("\n-- 3. 行为 @callback：六种触发器都实现 run/2（漏了编译器就告警）--")

Enum.each(Rooms.keys(), fn key ->
  room = Rooms.get(key)

  IO.puts(
    "  #{inspect(key)} => #{inspect(room.trigger)}，动作 #{inspect(Enum.map(room.actions, & &1.id))}"
  )
end)

# ------------------------------------------------------------
# 4. 战斗：注入 roll 的纯函数
# ------------------------------------------------------------
IO.puts("\n-- 4. 战斗：伤害由 roll(攻击序号, 区间) 决定——同样的序列同样的战斗 --")

wizard = Heroes.get(:wizard)
goblin = Enemies.get(:goblin)
{w2, g2, log} = Battle.fight(wizard, goblin)

Enum.each(log, &IO.puts("  #{&1}"))
IO.puts("  终局 => #{Display.info(w2)} vs #{Display.info(g2)}")

# ------------------------------------------------------------
# 5. 三局两胜一败的完整对局
# ------------------------------------------------------------
games = [
  {"胜局", :wizard, [:trap, :enemy, :exit], [:search, :forward, :forward]},
  {"败局", :knight, [:hidden, :enemy], [:rest, :forward]},
  {"治疗局", :rogue, [:trap, :treasure, :exit], [:search, :search, :forward]}
]

for {label, hero_key, room_keys, script} <- games do
  IO.puts(
    "\n-- 5. #{label}：#{Heroes.get(hero_key).name} 走 #{inspect(room_keys)}，脚本 #{inspect(script)} --"
  )

  game = Engine.play(Heroes.get(hero_key), room_keys, script)

  Enum.each(game.events, &IO.puts("  #{&1}"))

  IO.puts(
    "  [结局] #{game.outcome}，终局 #{game.hero.hit_points}/#{game.hero.max_hit_points} HP，共 #{Enum.count(game.events)} 条事件"
  )
end

# ------------------------------------------------------------
# 6. 协议 vs 行为：一张表
# ------------------------------------------------------------
IO.puts("\n-- 6. 协议管数据，行为管模块 --")
IO.puts("  协议 defprotocol：Display.info/1 —— Character 与 Action 各自 defimpl")
IO.puts("  行为 @callback  ：Room.Trigger.run/2 —— 六个触发器模块各自 @behaviour + @impl")
IO.puts("  （书 6.4 小结：协议创建函数接口处理多种数据类型；行为定义模块应实现的函数）")

IO.puts("\n==== 29 结束 ====")
