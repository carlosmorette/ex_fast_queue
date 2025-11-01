defmodule ExFastQueue.Queue do
  use GenServer

  alias ExFastQueue.Queue.Job
  alias ExFastQueue.Queue.State

  require Logger

  def enqueue(queue_id, attrs), do: GenServer.cast(queue_id, {:enqueue, attrs})

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @impl true
  def init(opts) do
    state = State.new(opts)
    {:ok, state}
  end

  @impl true
  def handle_cast({:enqueue, attrs}, state) do
    if length(state.pending) >= state.buffer_size do
      Logger.warning("#{__MODULE__} Queue is full. Discarding job. #{inspect(attrs)}")
      {:noreply, state}
    else
      job =
        Job.new(attrs, %{
          enqueued_at: System.system_time(:millisecond),
          attempt: 0
        })

      Logger.info(log_message(state, "Enqueuing job #{job.id}"))

      new_pending = state.pending ++ [job]
      new_state = %{state | pending: new_pending}

      {:noreply, process_queue(new_state)}
    end
  end

  def process_queue(%State{current_workers: workers, max_concurrency: max} = state)
      when workers >= max,
      do: state

  def process_queue(%State{pending: []} = state), do: state

  def process_queue(%State{} = state) do
    [job | remaining] = state.pending

    task =
      Task.Supervisor.async_nolink(state.task_supervisor, fn ->
        state.fun.(job)
      end)

    new_state = %{
      state
      | pending: remaining,
        in_progress: Map.put(state.in_progress, task.ref, Job.set_started_at(job)),
        current_workers: state.current_workers + 1
    }

    process_queue(new_state)
  end

  @impl true
  def handle_info({ref, _result}, %State{} = state) when is_reference(ref) do
    case Map.pop(state.in_progress, ref) do
      {nil, _state} ->
        {:noreply, state}

      {%Job{} = job, new_in_progress} ->
        duration = System.system_time(:millisecond) - job.metadata.started_at

        Logger.info(
          log_message(state, """
          Job #{job.id} finished processing
          Duration: #{duration}ms
          """)
        )

        new_state = %{
          state
          | in_progress: new_in_progress,
            current_workers: state.current_workers - 1
        }

        {:noreply, process_queue(new_state)}
    end
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    case Map.pop(state.in_progress, ref) do
      {nil, _in_prog} ->
        {:noreply, state}

      {job, new_in_progress} ->
        Logger.error(log_message(state, "Job #{job.id} failed"))

        new_state = %{
          state
          | in_progress: new_in_progress,
            current_workers: state.current_workers - 1
        }

        new_state = handle_failure(job, new_state)
        {:noreply, process_queue(new_state)}
    end
  end

  defp handle_failure(job, state) do
    if job.metadata.attempt < job.metadata.max_retries do
      job = Job.set_started_at(job) |> Job.increaset_attempt()
      new_pending = state.pending ++ [job]

      Logger.warning(log_message(state, "Requeuing failed job #{job.id}"))

      %{state | pending: new_pending}
    else
      duration = System.system_time(:millisecond) - job.metadata.started_at

      Logger.error(log_message(state, "Discarding job after max retries. Duration #{duration}"))

      state
    end
  end

  defp log_message(state, msg) do
    "[#{__MODULE__}] [#{state.name}] #{msg}"
  end
end
