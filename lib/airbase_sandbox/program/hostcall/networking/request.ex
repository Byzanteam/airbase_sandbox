defmodule AirbaseSandbox.Program.Hostcall.Networking.Request do
  @moduledoc """
  The request struct for Networking.
  """

  use TypedStruct

  typedstruct do
  end



  @spec initialize(binary) :: binary
  def initialize(binary) when is_binary(binary) do
    json = Jason.decode!(binary)
    Jason.encode!(request(json))
  end


  def request(%{"method" => method, "url" => url, "headers" => headers , "body" => body}) do
    Finch.start_link(name: MyFinch)
    Finch.build(method, url, headers, body)
  end
end
