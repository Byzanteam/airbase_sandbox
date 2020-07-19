defmodule AirbaseSandbox.Program.Server do
  @moduledoc """
  Manage instantiated programs.
  """

  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @idle_ms 10 * 1000

  @spec start_child(binary(), map()) :: {:ok, pid()} | {:error, term}
  def start_child(bytes, imports) do
    spec = %{
      id: GenServer,
      start:
        {GenServer, :start_link,
         [
           Wasmex,
           %{bytes: bytes, imports: stringify_keys(imports)}
         ]}
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

  defp stringify_keys(atom_key_map) when is_map(atom_key_map) do
    for {key, val} <- atom_key_map, into: %{}, do: {stringify(key), stringify_keys(val)}
  end

  defp stringify_keys(value), do: value

  defp stringify(s) when is_binary(s), do: s
  defp stringify(s) when is_atom(s), do: Atom.to_string(s)
end
