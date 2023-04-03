defmodule JetSandbox.Program.Hostcall.Networking.ResponseTest do
  use ExUnit.Case
  alias JetSandbox.Program.Hostcall.Networking.Response

  test "ok/2 returns a valid response payload" do
    response = %Finch.Response{
      body: "{\"name\": \"byzanteam\"}",
      headers: [
        {"content-type", "application/json"},
        {"content-length", "21"},
        {"accept", "application/json"},
        {"access-control-allow-origin", "*"},
        {"via", "1.1 google"},
        {"alt-svc", "h3=\":443\"; ma=2592000,h3-29=\":443\"; ma=2592000"}
      ],
      status: 200
    }

    assert match?(
             %JetSandbox.Program.Hostcall.Networking.Response{response: ^response},
             Response.ok(response)
           )
  end
end
