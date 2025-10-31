defmodule ExFastQueue do
  use Supervisor

  alias ExFastQueue.Queue
  alias ExFastQueue.Queue.SnapshotWorker

  @doc """
  Start the queue supervisor.

  Config example:

  ### Example
  config :ex_fast_queue, ExFastQueue, queues: [
    {:pix_process, fun: fn job -> IO.inspect(job) end},
    {:emails, &MyApp.EmailWorker.process/1}
  ]
  """

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(config) do
    queues = Keyword.get(config, :queues, [])

    children =
      Enum.flat_map(queues, fn {name, opts} ->
        fun = Keyword.fetch!(opts, :fun)
        task_supervisor = String.to_atom("#{name}_task_supervisor")
        ets_table_name = String.to_atom("#{name}_ets")
        snapshot_worker_name = String.to_atom("#{name}_snapshot_worker")

        [
          {Task.Supervisor, name: task_supervisor},
          {Queue,
           name: name, fun: fun, task_supervisor: task_supervisor, ets_table: ets_table_name},
          {SnapshotWorker, name: snapshot_worker_name, ets_table: ets_table_name}
        ]
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def list_queues do
    __MODULE__
    |> Supervisor.which_children()
    |> Enum.map(fn {_, pid, _flags, _children} ->
      queue_name = pid |> Process.info() |> Keyword.get(:registered_name)
      {queue_name, pid}
    end)
  end

  def enqueue(name, attrs) do
    Queue.enqueue(name, attrs)
  end
end
