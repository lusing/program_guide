defmodule Ex29Dungeon.Room.Trigger do
  @moduledoc """
  房间触发器契约（书 6.4.1）：Elixir **行为（behaviour）**。

  协议用于 struct，行为用于模块——这里规定「每个房间触发器模块必须
  有 `run/2`」。漏实现时编译器直接告警（`undefined behaviour function
  run/2`），把契约违约拦在编译期。

  与书的差异：书里触发器用 `Shell.info` 直接打印并返回
  `{character, flag}` 两元组；纯函数化改造把打印改成**返回事件流**
  ——副作用变成数据（第 28 章的纪律）。
  """

  alias Ex29Dungeon.Character
  alias Ex29Dungeon.Room.Action

  @doc """
  执行动作的后果。返回：

  - 更新后的角色（受击/治疗后的新 struct）；
  - `:exit`（游戏胜利）或 `:forward`（继续爬下一间）；
  - 事件流（引擎负责展示，触发器只产数据）。
  """
  @callback run(Character.t(), Action.t()) :: {Character.t(), :exit | :forward, [String.t()]}
end
