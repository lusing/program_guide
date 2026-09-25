defprotocol Ex29Dungeon.Display do
  @moduledoc """
  自定义协议（书 6.3.3）：一个函数、多种 struct。

  协议管**数据**（哪些类型实现了 `info/1`），行为管**模块**（哪些模块
  实现了 `run/2`）——见 `Ex29Dungeon.Room.Trigger`。
  """

  @doc "把值渲染成一行玩家可读文本"
  @spec info(t()) :: String.t()
  def info(value)
end
