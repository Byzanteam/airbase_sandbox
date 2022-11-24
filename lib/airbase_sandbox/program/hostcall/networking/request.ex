defmodule AirbaseSandbox.Program.Hostcall.Networking.Request do
  @moduledoc """
  The request struct for Networking.
  """

  use TypedStruct

  typedstruct do
  end

  @spec initialize(binary()) :: t()
  def initialize(binary) when is_binary(binary) do
    Jason.decode!(binary)
  end
end
