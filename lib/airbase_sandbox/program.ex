defmodule AirbaseSandbox.Program do
  @moduledoc """
  A program is a WebAssembly program.

  The entrypoint of the program is `run` function.
  """

  @typep options_t :: [program_loader: (() -> {:ok, binary()} | :error)]

  @program_entrypoint "run"
  # 10MB
  @max_bytes_size 10 * 1024 * 1000 * 8
  @memory_index 0

  alias AirbaseSandbox.Program.Hostcall
  require Logger

  @spec run(list(), options_t()) :: {:ok, term()} | {:error, term()}
  def run(args, options) do
    case instantiate_program(options) do
      {:ok, instance, memory} ->
        function_args = prepare_args(memory, args)

        try do
          {:ok, _result} = Wasmex.call_function(instance, @program_entrypoint, function_args)

          receive_outputs(args)
        after
          AirbaseSandbox.Program.Server.stop_child(instance)
        end

      _error ->
        {:error, :invalid_program}
    end
  end

  defp prepare_args(memory, args) do
    binary = :erlang.term_to_binary(args)
    Wasmex.Memory.write_binary(memory, @memory_index, binary)

    [@memory_index, div(bit_size(binary), 8)]
  end

  defp receive_outputs(args) do
    receive do
      {:outputs, outputs} when is_list(outputs) ->
        {:ok, outputs}

      reply ->
        Logger.error(fn ->
          """
          [#{inspect(__MODULE__)}] unexpected reply for outputs.
          args: #{inspect(args)}
          reply: #{inspect(reply)}
          """
        end)

        {:error, :unexpected_outputs}
    after
      0 ->
        Logger.error(fn ->
          """
          [#{inspect(__MODULE__)}] no reply for outputs.
          args: #{inspect(args)}
          """
        end)

        {:error, :no_outputs}
    end
  end

  @spec validate(options_t()) :: :ok | {:error, term()}
  def validate(options) do
    case instantiate_program(options) do
      {:ok, instance, _memory} ->
        try do
          if Wasmex.function_exists(instance, @program_entrypoint) do
            :ok
          else
            {:error, :entrypoint_not_exported}
          end
        after
          AirbaseSandbox.Program.Server.stop_child(instance)
        end

      _ ->
        {:error, :invalid_program}
    end
  end

  defp instantiate_program(options) do
    with(
      {:ok, program_loader} <- Keyword.fetch(options, :program_loader),
      {:ok, bytes} when is_binary(bytes) <- program_loader.(),
      {_, true} <- {:max_bytes_size, @max_bytes_size >= bit_size(bytes)},
      imports = %{env: %{hostcall_set_outputs: Hostcall.set_outputs(self())}},
      {:ok, instance} <- AirbaseSandbox.Program.Server.start_child(bytes, imports)
    ) do
      try do
        case Wasmex.memory(instance, :uint8, @memory_index) do
          {:ok, memory} ->
            {:ok, instance, memory}

          _ ->
            {:error, :memory_not_exported}
        end
      rescue
        _ ->
          AirbaseSandbox.Program.Server.stop_child(instance)
          {:error, :memory_not_exported}
      catch
        kind, value ->
          Logger.info(fn ->
            """
            [#{inspect(__MODULE__)}] failed to instantiate program.
            kind: #{inspect(kind)}
            value: #{inspect(value)}
            """
          end)

          AirbaseSandbox.Program.Server.stop_child(instance)
          {:error, :memory_not_exported}
      end
    else
      :error ->
        {:error, :invalid_program_loader}

      {:max_bytes_size, false} ->
        {:error, :program_size_exceeds}

      {:error, {msg, stack}} ->
        Logger.info(fn ->
          """
          [#{inspect(__MODULE__)}] failed to instantiate program.
          message: #{inspect(msg)}
          stack: #{inspect(stack)}
          """
        end)

        {:error, :invalid_program}

      _error ->
        {:error, :invalid_program}
    end
  end
end
