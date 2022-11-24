defmodule AirbaseSandbox.Program.Hostcall.NetworkingTest do
  use ExUnit.Case

  require Logger

  setup context do
    # Read the :cd tag value
    if cd = context[:cd] do
      prev_cd = File.cwd!()
      File.cd!(cd)
      on_exit(fn -> File.cd!(prev_cd) end)
    end

    :ok
  end

  @tag cd: "test/fixtures"
  describe "run/2" do
    test "run the program" do
      args_binary = "hello"

      assert {:ok, outputs} =
               JetSandbox.Program.run(args_binary,
                 program_loader: fn ->
                   File.read("networking-sample.wasm")
                 end
               )

      assert outputs === args_binary

      # kill the instance after run
      assert %{active: 0, specs: 0, supervisors: 0, workers: 0} ===
               DynamicSupervisor.count_children(JetSandbox.Program.Server)
    end
  end
end
