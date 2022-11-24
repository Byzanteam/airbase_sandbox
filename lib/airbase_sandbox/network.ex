defmodule JetSandbox.Network do
  def request_response() do
    {:ok, data} = run("./lib/airbase_sandbox/httpie.wasm")
    request(data)
  end


  def run(filename) do
    {:ok, bytes } = File.read(filename)
    {:ok, module} = Wasmex.Module.compile(bytes)
    {:ok, instance } = Wasmex.start_link(%{module: module, imports: imports()}) # starts a GenServer running this WASM instance

    try do
      measure(fn ->
        {:ok, _} = Wasmex.call_function(instance, "request_data", [])
        receive do
          {:outputs, outputs} -> {:ok, outputs}
        after
          5000 -> {:error, :timeout}
        end
      end)
    after
      GenServer.stop(instance)
    end
  end


  def measure(fun) do
    started_at = :erlang.monotonic_time(:millisecond)
    result = fun.()
    elapsed = :erlang.monotonic_time(:millisecond) - started_at
    IO.inspect("#{elapsed}ms used.")
    result
  end
# method, url, headers \\ [], body \\ nil, opts \\ [

  def request(%{"body" => body, "headers" => headers, "method" => method, "url" => url}) do
    Finch.start_link(name: MyFinch)
    Finch.build(method, url, headers, body) |> Finch.request(MyFinch)
  end

  defp imports() do
    %{env: %{print_str: set_outputs(self())}}
  end

  defp set_outputs(pid) do
    {
      :fn,
      [:i32, :i32],
      [],
      fn context, ptr, len ->
        binary = Wasmex.Memory.read_binary(context.memory, ptr, len)
        outputs = Jason.decode!(binary)
        send(pid, {:outputs, outputs})
        nil
      end
    }
  end
end
