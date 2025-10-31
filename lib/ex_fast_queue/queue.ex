defmodule ExFastQueue.Queue do
  use GenServer

  alias ExFastQueue.Queue.Job

  require Logger

  defmodule State do
    @moduledoc false
    defstruct pending: [],
              name: nil,
              in_progress: %{},
              max_concurrency: 0,
              current_workers: 0,
              task_supervisor: nil,
              ets_table: nil,
              fun_to_apply: nil
  end

  def enqueue(queue_id, attrs), do: GenServer.cast(queue_id, {:enqueue, attrs})

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    name = Keyword.fetch!(opts, :name)

    table =
      opts
      |> Keyword.fetch!(:ets_table)
      |> :ets.new([:ordered_set, :public, :named_table, read_concurrency: true])

    state = %State{
      name: name,
      max_concurrency: 10,
      task_supervisor: Keyword.fetch!(opts, :task_supervisor),
      ets_table: table,
      fun_to_apply: Keyword.fetch!(opts, :fun)
    }

    {:ok, state}
  end

  def handle_cast({:enqueue, attrs}, %State{ets_table: table} = state) do
    job = Job.new(attrs, %{enqueued_at: System.system_time(:millisecond)})
    Logger.info("[#{state.name}]: #{job.id}")
    true = :ets.insert(table, {job.id, job})
    {:noreply, process_queue(state)}
  end

  def process_queue(
        %State{
          current_workers: current_workers,
          max_concurrency: max_concurrency,
          ets_table: table
        } = state
      ) do
    if current_workers >= max_concurrency do
      state
    else
      case next_job(table) do
        nil ->
          state

        job ->
          task =
            Task.Supervisor.async_nolink(state.task_supervisor, fn ->
              state.fun_to_apply.(job.attrs)
            end)

          new_state = %{
            state
            | in_progress: Map.put(state.in_progress, task.ref, job),
              current_workers: state.current_workers + 1
          }

          process_queue(new_state)
      end
    end
  end

  defp next_job(table) do
    case :ets.first(table) do
      :"$end_of_table" ->
        nil

      key ->
        [{id, job}] = :ets.lookup(table, key)
        :ets.delete(table, id)
        job
    end
  end

  def handle_info({ref, _result}, %State{} = state) when is_reference(ref) do
    {job, in_prog} = Map.pop(state.in_progress, ref)
    new_state = %{state | in_progress: in_prog, current_workers: state.current_workers - 1}
    Logger.info("[#{state.name}]: #{job.id}")
    {:noreply, process_queue(new_state)}
  end

  def handle_info({:DOWN, ref, :process, _pid, reason}, %State{} = state) do
    case Map.pop(state.in_progress, ref) do
      {nil, _state} ->
        {:noreply, state}

      {job, in_prog} ->
        :ets.insert(state.ets_table, {job.id, job})
        Logger.error("[#{state.name}] Job #{job.id} failed: #{inspect(reason)}")
        new_state = %{state | in_progress: in_prog, current_workers: state.current_workers - 1}
        {:noreply, process_queue(new_state)}
    end
  end
end
