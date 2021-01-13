defmodule AirbaseSandbox.ProgramTest do
  use ExUnit.Case

  require Logger
  import ExUnit.CaptureLog

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
      assert {:ok, [1, 2]} ===
               AirbaseSandbox.Program.run([1, 2],
                 program_loader: fn ->
                   File.read("echo.wasm")
                 end
               )

      # kill the instance after run
      assert %{active: 0, specs: 0, supervisors: 0, workers: 0} ===
               DynamicSupervisor.count_children(AirbaseSandbox.Program.Server)
    end
  end

  @tag cd: "test/fixtures"
  describe "validate/1" do
    setup do
      prev_level = Logger.level()
      Logger.configure(level: :info)

      on_exit(fn ->
        Logger.configure(level: prev_level)
      end)
    end

    test "validate the program" do
      assert :ok ===
               AirbaseSandbox.Program.validate(
                 program_loader: fn ->
                   File.read("echo.wasm")
                 end
               )

      assert {:error, :entrypoint_not_exported} ===
               AirbaseSandbox.Program.validate(
                 program_loader: fn ->
                   File.read("invalid_exports.wasm")
                 end
               )

      assert capture_log([level: :info], fn ->
               assert {:error, :invalid_program} ===
                        AirbaseSandbox.Program.validate(
                          program_loader: fn ->
                            File.read("invalid_memory.wasm")
                          end
                        )

               Logger.info("123")
             end) =~ "The WebAssembly module has no exported memory."

      # kill the instance after run
      assert %{active: 0, specs: 0, supervisors: 0, workers: 0} ===
               DynamicSupervisor.count_children(AirbaseSandbox.Program.Server)
    end
  end
end
