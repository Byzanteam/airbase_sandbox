defmodule AirbaseSandbox.Program do
  @moduledoc """
  A program is a WebAssembly program.

  The entrypoint of the program is `main` function.
  """

  @program_entrypoint "main"

  @spec run(binary(), map(), list()) :: {:ok, term()} | {:error, term()}
  def run(bytes, imports, args) do
    case AirbaseSandbox.Program.Server.start_child(bytes, imports) do
      {:ok, instance} ->
        try do
          # TODO: memory
          Wasmex.call_function(instance, @program_entrypoint, args)
        after
          AirbaseSandbox.Program.Server.stop_child(instance)
        end

      _ ->
        {:error, :invalid_wasm}
    end
  end

  @spec validate(binary()) :: :ok | {:error, term()}
  def validate(bytes) do
    case AirbaseSandbox.Program.Server.start_child(bytes, %{}) do
      {:ok, instance} ->
        try do
          if Wasmex.function_exists(instance, @program_entrypoint) do
            :ok
          else
            {:error, :entrypoint_not_exist}
          end
        after
          AirbaseSandbox.Program.Server.stop_child(instance)
        end

      _ ->
        {:error, :invalid_wasm}
    end
  end
end
