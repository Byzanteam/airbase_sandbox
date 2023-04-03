defmodule AirbaseSandbox.Program.Hostcall do
  @moduledoc """
  hostcall functions for Program.
  """
  @last_response :__last_response__

  @typep data_type() :: :i32 | :i64 | :f32 | :f64 | :v128
  @typep callback_context() :: struct()
  @typep imported_function(callback) ::
           {
             :fn,
             params :: [data_type()],
             returns :: [data_type()],
             callback :: callback
           }

  @spec set_outputs(instance_pid :: pid()) ::
          imported_function(
            (callback_context(), ptr :: non_neg_integer(), len :: non_neg_integer() -> nil)
          )
  def set_outputs(instance_pid) do
    {:fn, [:i32, :i32], [],
     fn context, ptr, len ->
       binary = Wasmex.Memory.read_binary(context.memory, ptr, len)

       send(instance_pid, {:outputs, binary})
       nil
     end}
  end

  @spec networking_request(instance_pid :: pid()) ::
          imported_function(
            (callback_context(), ptr :: non_neg_integer(), len :: non_neg_integer() ->
               non_neg_integer())
          )
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

  @spec networking_retrieve_response(instance_pid :: pid()) ::
          imported_function((callback_context(), ptr :: non_neg_integer() -> nil))

  def networking_retrieve_response(_insatance_pid) do
    {:fn, [:i32], [],
     fn context, ptr ->
       response_binary = Process.get(@last_response)
       Wasmex.Memory.write_binary(context.memory, ptr, response_binary)
       nil
     end}
  end

  @spec logger_debug(instance_pid :: pid()) ::
          imported_function(
            (callback_context(), ptr :: non_neg_integer(), len :: non_neg_integer() -> nil)
          )
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
