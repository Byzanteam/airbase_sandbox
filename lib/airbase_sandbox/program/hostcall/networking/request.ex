defmodule AirbaseSandbox.Program.Hostcall.Networking.Request do
  @moduledoc """
  The request struct for Networking.
  """

  use TypedStruct

  typedstruct do
  end


  def initialize(binary) when is_binary(binary) do
    Jason.decode!(binary)
  end

  def deserialize(response) do
    Jason.encode!(response)
  end

end
