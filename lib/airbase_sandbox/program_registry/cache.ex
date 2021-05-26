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

  @spec read(key :: term(), nil) :: {:ok, term()} | :error
  @spec read(key :: term(), fallback :: (() -> term())) :: {:ok, term} | :error
  def read(key, fallback \\ nil) do
    case Cachex.get(__MODULE__, key) do
      {:ok, value} when not is_nil(value) ->
        Cachex.touch(__MODULE__, key)
        {:ok, value}

      _ ->
        if is_function(fallback, 0) do
          write(key, fallback.())
        else
          :error
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
