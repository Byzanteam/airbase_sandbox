defmodule JetSandbox.Program.Hostcall do
  @moduledoc """
  hostcall functions for Program.
  """

  def set_outputs(instance_pid) do
    {:fn, [:i32, :i32], [],
     fn context, ptr, len ->
       binary = Wasmex.Memory.read_binary(context.memory, ptr, len)

       send(instance_pid, {:outputs, binary})
       nil
     end}
  end

  def networking_request(_instance_pid) do
    alias AirbaseSandbox.Program.Hostcall.Networking.Request

    {:fn, [:i32, :i32], [],
     fn context, ptr, len ->
       binary = Wasmex.Memory.read_binary(context.memory, ptr, len)
       request = Request.initialize(binary)

       # TODO: do request
       IO.inspect(request)

       nil
     end}
  end
end
