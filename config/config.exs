import Config

config :logger, level: :info

config :ex_fast_queue, ExFastQueue.Repo,
  adapter: Ecto.Adapters.SQLite3,
  database: "priv/repo/#{Mix.env()}.db",
  pool_size: 5

config :ex_fast_queue, ExFastQueue,
  queues: [
    {:pix_process,
     buffer_size: 100_000,
     max_concurrency: 3000,
     fun: fn _args ->
       :timer.sleep(1000)
       IO.inspect("some_processing")
     end},
    {:email_sender, fun: fn _args -> IO.inspect("lá ele") end}
  ]
