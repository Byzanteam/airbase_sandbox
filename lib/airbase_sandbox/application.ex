defmodule AirbaseSandbox.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      AirbaseSandbox.ProgramRegistry.Cache,
      AirbaseSandbox.Program.Server,
      {Finch, name: AirbaseSandboxFinch}
    ]

    opts = [strategy: :one_for_one, name: AirbaseSandbox.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
