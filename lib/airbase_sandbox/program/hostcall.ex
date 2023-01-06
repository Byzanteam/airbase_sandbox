defmodule JetSandbox.Program.Hostcall do
  @moduledoc """
  hostcall functions for Program.
  """
  @last_response :__last_response__

  def set_outputs(instance_pid) do
    {:fn, [:i32, :i32], [],
     fn context, ptr, len ->
       binary = Wasmex.Memory.read_binary(context.memory, ptr, len)

       send(instance_pid, {:outputs, binary})
       nil
     end}
  end

  def networking_request(_instance_pid) do
    alias AirbaseSandbox.Program.Hostcall.Networking

    {:fn, [:i32, :i32], [:i32],
     fn context, request_ptr, request_len ->
       request_binary = Wasmex.Memory.read_binary(context.memory, request_ptr, request_len)
       response_binary = Networking.request(request_binary)

       Process.put(@last_response, response_binary)
       byte_size(response_binary)
     end}
  end

  def networking_retrieve_response(_insatance_pid) do
    {:fn, [:i32], [],
     fn context, ptr ->
       response_binary = Process.get(@last_response)
       Wasmex.Memory.write_binary(context.memory, ptr, response_binary)
       nil
     end}
  end

  def logger_debug(_insatance_pid) do
    {:fn, [:i32, :i32], [],
     fn context, ptr, len ->
       require Logger

       binary = Wasmex.Memory.read_binary(context.memory, ptr, len)
       Logger.debug(binary)
       nil
     end}
  end
end
