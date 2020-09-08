defmodule AirbaseSandbox.MixProject do
  use Mix.Project

  def project do
    [
      app: :airbase_sandbox,
      version: "0.9.0-next",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AirbaseSandbox.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:wasmex, github: "tessi/wasmex", branch: "master"},
      {:typed_struct, "~> 0.2.0"}
    ]
  end
end
