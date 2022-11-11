defmodule JetSandbox.ProgramRegistry.CacheTest do
  use ExUnit.Case, async: true

  alias JetSandbox.ProgramRegistry.Cache, as: ProgramRegistryCache

  test "read/2" do
    assert(ProgramRegistryCache.read(:key) === :error)
    assert(ProgramRegistryCache.read(:key, fn -> {:ok, :value} end) === {:ok, :value})
    assert(Cachex.exists?(ProgramRegistryCache, :key) === {:ok, true})
    assert(ProgramRegistryCache.read(:not_exists, fn -> :error end) === :error)
    assert(Cachex.exists?(ProgramRegistryCache, :not_exists) === {:ok, false})
  end
end
