defmodule ExFastQueue.Queue.Job do
  @moduledoc false

  defstruct attrs: nil,
            id: nil,
            metadata: %{
              enqueued_at: nil,
              started_at: nil,
              finished_at: nil,
              attempt: 0,
              max_retries: 5
            }

  def new(attrs, metadata) do
    %__MODULE__{
      attrs: attrs,
      id: Ecto.UUID.generate(),
      metadata: Map.merge(%__MODULE__{}.metadata, metadata)
    }
  end

  def set_started_at(job) do
    %__MODULE__{
      job
      | metadata: Map.put(job.metadata, :started_at, System.system_time(:millisecond))
    }
  end

  def set_finished_at(job) do
    %__MODULE__{
      job
      | metadata: Map.put(job.metadata, :finished_at, System.system_time(:millisecond))
    }
  end

  def increaset_attempt(job) do
    %__MODULE__{
      job
      | metadata: Map.put(job.metadata, :attempt, job.metadata.attempt + 1)
    }
  end
end
