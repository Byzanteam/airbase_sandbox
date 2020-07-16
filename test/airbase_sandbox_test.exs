defmodule AirbaseSandboxTest do
  use ExUnit.Case
  doctest AirbaseSandbox

  test "greets the world" do
    assert AirbaseSandbox.hello() == :world
  end
end
