defmodule AirbaseSandbox.Program.Hostcall.NetworkingTest do
  use ExUnit.Case
  alias AirbaseSandbox.Program.Hostcall.Networking
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
  describe "networking run/2" do
    test "run the networking-sample" do
      args = [
        %{
          "field_type" => "single_line_field",
          "type" => "literal",
          "value" => "Asia/Shanghai"
        }
      ]

      args_binary = Jason.encode!(args)

      assert {:ok, outputs} =
               JetSandbox.Program.run(args_binary,
                 program_loader: fn ->
                   File.read("networking-sample.wasm")
                 end
               )

      map = Jason.decode!(outputs) |> List.first()
      assert {:ok, _datatime} = map["value"] |> Calendar.ISO.parse_naive_datetime()
    end
  end

  describe "request/2" do
    test "returns a response with a successful request" do
      request_binary =
        Jason.encode!(%{
          "method" => "get",
          "url" => "http://httpbin.org/get"
        })

      response_binary = Networking.request(request_binary)
      {:ok, response} = Jason.decode(response_binary)
      assert response["code"] == 0
    end

    test "returns a response with invalid json" do
      request_binary = Jason.encode!(1234)
      response_binary = Networking.request(request_binary)
      {:ok, response} = Jason.decode(response_binary)
      assert response["code"] == 1
      assert response["message"] == "Expected a map json, got 1234"
    end

    test "returns a response with a request without method" do
      request_binary =
        Jason.encode!(%{
          "url" => "http://httpbin.org/get"
        })

      response_binary = Networking.request(request_binary)
      {:ok, response} = Jason.decode(response_binary)
      assert response["code"] == 2
      assert response["message"] == "The method parameter is required."
    end

    test "returns a response with an invalid method" do
      request_binary =
        Jason.encode!(%{
          "method" => "invalid",
          "url" => "http://httpbin.org/get"
        })

      response_binary = Networking.request(request_binary)
      {:ok, response} = Jason.decode(response_binary)
      assert response["code"] == 3

      assert response["message"] ==
               "The method parameter is invalid, expected one of [:get, :post, :put, :patch, :delete, :head, :options], but got \"invalid\"."
    end

    test "returns a response with an bad_request" do
      request_binary = "bad_request"
      response_binary = Networking.request(request_binary)
      {:ok, response} = Jason.decode(response_binary)
      assert response["code"] == 4
      assert response["message"] == "unexpected byte at position 0: 0x62 (\"b\")"
    end
  end
end
