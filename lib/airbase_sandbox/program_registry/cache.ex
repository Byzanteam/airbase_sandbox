defmodule AirbaseSandbox.ProgramRegistry.Cache do
  @moduledoc """
  Cache storage for programs.
  """

  import Cachex.Spec

  @expiration :timer.seconds(24 * 60 * 60)
  @limit 200

  @spec child_spec(term) :: Supervisor.child_spec()
  def child_spec(_opts) do
    limit =
      limit(
        size: @limit,
        policy: Cachex.Policy.LRW,
        reclaim: 0.1
      )

    expiration =
      expiration(
        default: @expiration,
        interval: nil,
        lazy: true
      )

    Supervisor.child_spec(
      {Cachex, [name: __MODULE__, expiration: expiration, limit: limit]},
      []
    )
  end

  @doc """
  Retrieve the value of a key from cache.

  If the key exits, return the corresponding value, otherwise return the fallback value if provided.

  ## Examples

      iex> AirbaseSandbox.ProgramRegistry.Cache.read(:key)
      :error

      iex> AirbaseSandbox.ProgramRegistry.Cache.read(:key, fn -> {:ok, :value} end)
      {:ok, :value}

      iex> Cachex.exists?(AirbaseSandbox.ProgramRegistry.Cache, :key)
      {:ok, true}

      iex> AirbaseSandbox.ProgramRegistry.Cache.read(:not_exists, fn -> :error end)
      :error

      iex> Cachex.exists?(AirbaseSandbox.ProgramRegistry.Cache, :not_exists)
      {:ok, false}
  """
  @spec read(key :: term(), nil) :: {:ok, term()} | :error
  @spec read(key :: term(), fallback :: (() -> {:ok, term()} | :error)) :: {:ok, term} | :error
  def read(key, fallback \\ nil) do
    case Cachex.get(__MODULE__, key) do
      {:ok, value} when not is_nil(value) ->
        Cachex.touch(__MODULE__, key)
        {:ok, value}

      _ ->
        with(
          true <- is_function(fallback, 0),
          {:ok, value} <- fallback.()
        ) do
          write(key, value)
        else
          _ -> :error
        end
    end
  end

  @spec write(key :: term(), value) :: value when value: var
  def write(key, value) do
    case Cachex.put(__MODULE__, key, value) do
      {:ok, true} -> {:ok, value}
      _ -> :error
    end
  end
end
