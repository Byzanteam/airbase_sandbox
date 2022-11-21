defmodule JetSandbox.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      JetSandbox.ProgramRegistry.Cache,
      JetSandbox.Program.Server,
      {Finch, name: JetSandboxFinch}
    ]

    opts = [strategy: :one_for_one, name: JetSandbox.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
