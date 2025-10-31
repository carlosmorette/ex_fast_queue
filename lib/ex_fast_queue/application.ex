defmodule ExFastQueue.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    ExFastQueue.start_link(Application.get_env(:ex_fast_queue, ExFastQueue))
  end
end
