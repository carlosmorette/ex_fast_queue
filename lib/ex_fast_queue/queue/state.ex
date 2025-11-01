defmodule ExFastQueue.Queue.State do
  @enforce_keys [
    :name,
    :max_concurrency,
    :task_supervisor,
    :buffer_size,
    :fun,
    :pending,
    :in_progress,
    :current_workers
  ]

  defstruct @enforce_keys

  def new(opts) do
    name = Keyword.fetch!(opts, :name)
    task_supervisor = Keyword.fetch!(opts, :task_supervisor)
    fun = Keyword.fetch!(opts, :fun)
    max_concurrency = Keyword.get(opts, :max_concurrency, 1_000)
    buffer_size = Keyword.get(opts, :buffer_size, 5_000)

    %__MODULE__{
      name: name,
      max_concurrency: max_concurrency,
      task_supervisor: task_supervisor,
      fun: fun,
      buffer_size: buffer_size,
      pending: [],
      in_progress: %{},
      current_workers: 0
    }
  end
end
