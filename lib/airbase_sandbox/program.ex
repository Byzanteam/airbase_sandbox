defmodule AirbaseSandbox.Program do
  @moduledoc """
  A program is a WebAssembly program.

  The entrypoint of the program is `main` function.
  """

  @program_entrypoint "main"

  @spec run(binary(), map(), list()) :: {:ok, term()} | {:error, term()}
  def run(bytes, imports, args) do
    with(
      {:ok, instance} <-
        AirbaseSandbox.Program.Server.start_child(bytes, imports)
    ) do
      try do
        # TODO: memory
        Wasmex.call_function(instance, @program_entrypoint, args)
      after
        AirbaseSandbox.Program.Server.stop_child(instance)
      end
    end
  end
end
