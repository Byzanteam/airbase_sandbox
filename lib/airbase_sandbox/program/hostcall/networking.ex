defmodule AirbaseSandbox.Program.Hostcall.Networking do
  @moduledoc """
  The Networking.
  """
  
  def request(%{"method" => method, "url" => url, "headers" => headers, "body" => body}) do
    Finch.start_link(name: MyFinch)
    Finch.build(method, url, headers, body)
  end
end
