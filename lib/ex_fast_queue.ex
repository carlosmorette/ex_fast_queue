defmodule ExFastQueue do
  use Supervisor

  alias ExFastQueue.Queue

  @doc """
  Start the queue supervisor.

  Config example:

  ### Example
  config :ex_fast_queue, ExFastQueue, queues: [
    {:pix_process, max_concurrency: 1, buffer_size: 300, fun: fn job -> IO.inspect(job) end},
    {:emails, &MyApp.EmailWorker.process/1}
  ]
  """

  def start_link(config) do
    Supervisor.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl true
  def init(config) do
    queues = Keyword.get(config, :queues, [])
    children = Enum.flat_map(queues, fn {name, opts} -> build_tree(name, opts) end)
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

  def build_tree(name, opts) do
    task_supervisor = :"#{name}_task_supervisor"

    queue_opts =
      opts
      |> Keyword.put(:name, name)
      |> Keyword.put(:task_supervisor, task_supervisor)

    [
      Supervisor.child_spec({Task.Supervisor, name: task_supervisor}, id: task_supervisor),
      Supervisor.child_spec({Queue, queue_opts}, id: name)
    ]
  end
end
