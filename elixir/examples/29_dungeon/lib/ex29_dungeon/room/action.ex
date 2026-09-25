defmodule Ex29Dungeon.Room.Action do
  @moduledoc """
  房间动作（书 6.3.1）：被 `Room` struct 引用的 struct——
  结构体引用结构体，领域模型层层组装。
  """

  defstruct id: nil, label: nil

  @type t :: %__MODULE__{id: atom(), label: String.t()}

  @doc """
  三个预制动作（书的辅助函数风格）：

      iex> alias Ex29Dungeon.Room.Action
      iex> Action.forward()
      %Ex29Dungeon.Room.Action{id: :forward, label: "Move forward."}

  """
  @spec forward() :: t()
  def forward, do: %__MODULE__{id: :forward, label: "Move forward."}

  @spec rest() :: t()
  def rest, do: %__MODULE__{id: :rest, label: "Take a better look and rest."}

  @spec search() :: t()
  def search, do: %__MODULE__{id: :search, label: "Search the room."}

  defimpl Ex29Dungeon.Display do
    @doc "选项列表里显示动作文本"
    def info(action), do: action.label
  end

  defimpl String.Chars do
    @doc "内建协议：插值即动作文本"
    def to_string(action), do: action.label
  end
end
