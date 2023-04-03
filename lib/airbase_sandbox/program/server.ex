defmodule AirbaseSandbox.Program.Server do
  @moduledoc """
  Manage instantiated programs.
  """

  use DynamicSupervisor

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_child(binary(), map()) :: {:ok, pid()} | {:error, term}
  def start_child(bytes, imports) do
    spec = %{
      id: Wasmex,
      start:
        {Wasmex, :start_link,
         [
           %{bytes: bytes, imports: imports}
         ]},
      restart: :temporary,
      type: :worker
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @spec stop_child(pid()) :: :ok
  def stop_child(pid) do
    case DynamicSupervisor.terminate_child(__MODULE__, pid) do
      :ok -> :ok
      {:error, :not_found} -> :ok
    end
  end
end
