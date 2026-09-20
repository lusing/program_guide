defmodule Ex24Capstone.Cache do
  @moduledoc "容错键值缓存：GenServer 裸 map，由根监督树以 :permanent 看护。"
  use GenServer

  # ---- API ----

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def put(key, value), do: GenServer.call(__MODULE__, {:put, key, value})
  def get(key), do: GenServer.call(__MODULE__, {:get, key})
  def delete(key), do: GenServer.call(__MODULE__, {:delete, key})
  def size, do: GenServer.call(__MODULE__, :size)
  def keys, do: GenServer.call(__MODULE__, :keys)

  # ---- 回调 ----

  @impl true
  def init(_opts), do: {:ok, %{}}

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    {:reply, :ok, Map.put(state, key, value)}
  end

  def handle_call({:get, key}, _from, state) do
    {:reply, Map.get(state, key), state}
  end

  def handle_call({:delete, key}, _from, state) do
    {:reply, :ok, Map.delete(state, key)}
  end

  def handle_call(:size, _from, state), do: {:reply, map_size(state), state}
  def handle_call(:keys, _from, state), do: {:reply, state |> Map.keys() |> Enum.sort(), state}
end
