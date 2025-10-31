# ExFastQueue

A high-performance, concurrent job queue system for Elixir applications. ExFastQueue provides a simple yet powerful way to process background jobs with configurable concurrency and persistence.

## Features

- **Lightweight and Fast**: Built on top of ETS and GenServer for optimal performance
- **Concurrent Processing**: Process multiple jobs in parallel with configurable concurrency
- **Supervision**: Built-in supervision tree for fault tolerance
- **Simple API**: Easy-to-use interface for enqueuing and processing jobs
- **Monitoring**: Built-in logging and monitoring capabilities
- **Snapshots**: Optional job snapshots using ETS tables

## Installation

Add `ex_fast_queue` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_fast_queue, "~> 0.1.0"}
  ]
end
```

## Usage

1. Configure your queues in `config/config.exs`:

```elixir
config :my_app, ExFastQueue, queues: [
  {:pix_process, fun: &MyApp.PixProcessor.process/1},
  {:emails, fun: &MyApp.EmailWorker.process/1}
]
```

2. Start the queue supervisor in your application's supervision tree:

```elixir
children = [
  {ExFastQueue, Application.get_env(:my_app, ExFastQueue)}
  # ... other children
]

Supervisor.start_link(children, strategy: :one_for_one)
```

3. Enqueue jobs from anywhere in your application:

```elixir
# Enqueue a job with custom attributes
ExFastQueue.Queue.enqueue(:pix_process, %{user_id: 123, amount: 100.0})
ExFastQueue.Queue.enqueue(:emails, %{to: "user@example.com", template: "welcome"})
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc) and published on [HexDocs](https://hexdocs.pm). Once published, the docs can be found at [https://hexdocs.pm/ex_fast_queue](https://hexdocs.pm/ex_fast_queue).
