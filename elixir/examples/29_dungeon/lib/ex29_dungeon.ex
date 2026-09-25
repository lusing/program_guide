defmodule Ex29Dungeon do
  @moduledoc """
  第 29 章示例：领域建模——回合制地下城（收官项目）。

  对应《函数式编程入门：使用 Elixir》第 6 章「设计 Elixir 应用程序」
  与附录 1「为游戏添加房间」。书的版本是交互式 CLI（`Mix.Shell.IO`
  清屏、提问，`Enum.random` 选房选怪）；本章做**纯函数化改造**：

  ```text
  Ex29Dungeon.Character          角色 struct：英雄与敌人共用（+ @type t）
  Ex29Dungeon.Heroes / Enemies   数据即配置：三英雄、三怪物
  Ex29Dungeon.Display            协议：多态渲染（defprotocol/defimpl）
  Ex29Dungeon.Room.Action        动作 struct（forward/rest/search）
  Ex29Dungeon.Room.Trigger       行为：@callback run/2——房间触发器契约
  Ex29Dungeon.Room.Triggers.*    六种触发器：出口/敌人/伏击/陷阱/宝藏/休息
  Ex29Dungeon.Rooms              房间全集（引用 struct 的 struct）
  Ex29Dungeon.Battle             纯函数战斗：伤害由注入的 roll 决定
  Ex29Dungeon.Engine             爬塔引擎：房间序列 + 动作脚本 → 事件流
  ```

  三条确定性对局（详见 `run.exs`）：法师踩陷阱再斩哥布林**获胜**；
  骑士连战两个食人魔**阵亡**；盗贼陷阱—宝藏—出口走**治疗上限**路线。
  """

  @doc """
  本教程第 24 章收官项目用 OTP（GenServer/Supervisor）装纯函数核心；
  本章反过来：**纯函数引擎 + 数据化配置**，交互与随机全被推到边界。
  """

  @spec playbooks() :: [{String.t(), atom(), [atom()], [atom()]}]
  def playbooks do
    [
      {"胜局：法师——陷阱、哥布林、出口", :wizard, [:trap, :enemy, :exit], [:search, :forward, :forward]},
      {"败局：骑士——连战两个食人魔", :knight, [:hidden, :enemy], [:rest, :forward]},
      {"治疗局：盗贼——陷阱、宝藏、出口", :rogue, [:trap, :treasure, :exit], [:search, :search, :forward]}
    ]
  end
end
