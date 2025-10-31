defmodule ExFastQueue.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_fast_queue,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ExFastQueue.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.13"},
      {:ecto_sqlite3, "~> 0.17"},
      {:gen_stage, "~> 1.3.2"}
    ]
  end
end
