defmodule Ex11SupervisorSpec do
  def child_specs do
    [
      %{
        id: :counter,
        start: {Ex10GenServerCounter, :start_link, [0]},
        restart: :permanent,
        shutdown: 5_000,
        type: :worker
      }
    ]
  end

  def supervisor_flags do
    %{strategy: :one_for_one, intensity: 5, period: 10}
  end
end

