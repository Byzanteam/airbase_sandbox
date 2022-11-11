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
end
