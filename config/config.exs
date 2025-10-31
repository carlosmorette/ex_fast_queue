import Config

config :logger, level: :info

config :ex_fast_queue, ExFastQueue,
  queues: [
    {:pix_process, fun: fn job -> IO.inspect(job) end}
  ]
