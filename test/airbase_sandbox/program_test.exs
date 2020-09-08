defmodule AirbaseSandbox.ProgramTest do
  use ExUnit.Case

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
  describe "run/3" do
    test "run the program" do
      {:ok, add_wasm} = File.read("add.wasm")

      assert {:ok, [3]} === AirbaseSandbox.Program.run(add_wasm, %{}, [1, 2])

      # kill the instance after run
      assert %{active: 0, specs: 0, supervisors: 0, workers: 0} ===
               DynamicSupervisor.count_children(AirbaseSandbox.Program.Server)
    end
  end

  @tag cd: "test/fixtures"
  describe "validate/1" do
    test "validate the program" do
      {:ok, add_wasm} = File.read("add.wasm")
      {:ok, invalid_exports_wasm} = File.read("invalid_exports.wasm")

      assert :ok === AirbaseSandbox.Program.validate(add_wasm)

      assert {:error, :entrypoint_not_exist} ===
               AirbaseSandbox.Program.validate(invalid_exports_wasm)

      # kill the instance after run
      assert %{active: 0, specs: 0, supervisors: 0, workers: 0} ===
               DynamicSupervisor.count_children(AirbaseSandbox.Program.Server)
    end
  end
end