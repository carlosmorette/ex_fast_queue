defmodule ExFastQueue.Queue.SnapshotWorker do
  use GenServer

  @interval :timer.seconds(15)

  defmodule State do
    defstruct [:ets_table, :name]
  end

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    state = %State{
      name: Keyword.fetch!(opts, :name),
      ets_table: Keyword.fetch!(opts, :ets_table)
    }

    {:ok, state, {:continue, :snapshot}}
  end

  def handle_continue(:snapshot, state) do
    do_snapshot(state)
    Process.send_after(self(), :snapshot, @interval)
    {:noreply, state}
  end

  defp do_snapshot(_tate) do
    # WIP
  end
end
