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

    {:fn, [:i32, :i32, :i32], [:i32],
     fn context, ptr, len, new_ptr ->
       binary = Wasmex.Memory.read_binary(context.memory, ptr, len)
       request = Request.initialize(binary)
       Wasmex.Memory.write_binary(context.memory, new_ptr, request)
       # TODO: do request
       #IO.inspect(request)
       String.length(request)
     end}
  end


end
