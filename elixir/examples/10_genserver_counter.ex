defmodule Ex10GenServerCounter do
  use GenServer

  def start_link(initial \\ 0) do
    GenServer.start_link(__MODULE__, initial, [])
  end

  def get(pid), do: GenServer.call(pid, :get)
  def inc(pid), do: GenServer.cast(pid, :inc)

  @impl true
  def init(initial), do: {:ok, initial}

  @impl true
  def handle_call(:get, _from, state), do: {:reply, state, state}

  @impl true
  def handle_cast(:inc, state), do: {:noreply, state + 1}
end

