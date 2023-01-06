defmodule JetSandbox.Program do
  @moduledoc """
  A program is a WebAssembly program.

  The entrypoint of the program is `run` function.
  """

  @typep options_t :: [program_loader: (() -> {:ok, binary()} | :error)]

  @program_entrypoint "run"
  # 10MB
  @max_bytes_size 10 * 1024 * 1000 * 8
  @memory_index 0

  alias JetSandbox.Program.Hostcall
  alias JetSandbox.Program.Server
  require Logger

  @spec run(binary(), options_t()) :: {:ok, binary()} | {:error, term()}
  def run(args_binary, options) when is_binary(args_binary) do
    case instantiate_program(options) do
      {:ok, instance, memory} ->
        function_args = prepare_args(memory, args_binary)

        try do
          {:ok, _result} = Wasmex.call_function(instance, @program_entrypoint, function_args)

          receive_outputs(args_binary)
        after
          Server.stop_child(instance)
        end

      _error ->
        {:error, :invalid_program}
    end
  end

  defp prepare_args(memory, args_binary) when is_binary(args_binary) do
    Wasmex.Memory.write_binary(memory, @memory_index, args_binary)

    [@memory_index, div(bit_size(args_binary), 8)]
  end

  defp receive_outputs(args_binary) do
    receive do
      {:outputs, outputs} when is_binary(outputs) ->
        {:ok, outputs}

      reply ->
        Logger.error(fn ->
          """
          unexpected reply for outputs.
          args_binary: #{inspect(args_binary)}
          reply: #{inspect(reply)}
          """
        end)

        {:error, :unexpected_outputs}
    after
      0 ->
        Logger.error(fn ->
          """
          no reply for outputs.
          args_binary: #{inspect(args_binary)}
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
          Server.stop_child(instance)
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
      imports = %{env: make_env(self())},
      {:ok, instance} <- Server.start_child(bytes, imports)
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
          Server.stop_child(instance)
          {:error, :memory_not_exported}
      catch
        kind, value ->
          Logger.info(fn ->
            """
            failed to instantiate program.
            kind: #{inspect(kind)}
            value: #{inspect(value)}
            """
          end)

          Server.stop_child(instance)
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
          failed to instantiate program.
          message: #{inspect(msg)}
          stack: #{inspect(stack)}
          """
        end)

        {:error, :invalid_program}

      _error ->
        {:error, :invalid_program}
    end
  end

  defp make_env(instance_pid) do
    %{
      hostcall_set_outputs: Hostcall.set_outputs(instance_pid),
      hostcall_networking_request: Hostcall.networking_request(instance_pid),
      hostcall_networking_retrieve_response: Hostcall.networking_retrieve_response(instance_pid)
    }
  end
end
