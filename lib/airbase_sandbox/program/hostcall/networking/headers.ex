defmodule AirbaseSandbox.Program.Hostcall.Networking.Headers do
  @moduledoc false

  @type t() :: [[String.t()]]

  @doc """
  Encode HTTP headers.

  ## Examples

      iex> encode!([{"Connection", "keep-alive"}])
      [["Connection", "keep-alive"]]

      iex> encode!([{"Connection", "keep-alive"}, {"Accept-Encoding", "gzip, deflate, br"}])
      [["Connection", "keep-alive"], ["Accept-Encoding", "gzip, deflate, br"]]

      iex> encode!([])
      []

  """
  @spec encode!(Mint.Types.headers()) :: t()
  def encode!(headers) when is_list(headers) do
    Enum.map(headers, fn {name, value} ->
      [name, value]
    end)
  end

  @doc """
  Decode HTTP headers.

  ## Examples

      iex> decode([["Connection", "keep-alive"]])
      {:ok, [{"Connection", "keep-alive"}]}

      iex> decode([["Connection", "keep-alive"], ["Accept-Encoding", "gzip, deflate, br"]])
      {:ok, [{"Connection", "keep-alive"}, {"Accept-Encoding", "gzip, deflate, br"}]}

      iex> decode([])
      {:ok, []}

  """
  @spec decode(t()) :: {:ok, Mint.Types.headers()} | :error
  def decode(headers) when is_list(headers) do
    headers
    |> Enum.reduce_while([], fn
      [name], acc -> {:cont, [{name, ""} | acc]}
      [name, value], acc -> {:cont, [{name, value} | acc]}
      _otherwise, _acc -> {:halt, :error}
    end)
    |> case do
      :error -> :error
      headers -> {:ok, Enum.reverse(headers)}
    end
  end
end
