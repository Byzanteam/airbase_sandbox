defmodule JetSandbox.MixProject do
  use Mix.Project

  def project do
    [
      app: :jet_sandbox,
      version: "0.9.0",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.14.0",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [extra_applications: [:logger, :cachex], mod: {JetSandbox.Application, []}]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:wasmex, "~> 0.7.0"},
      {:typed_struct, "~> 0.3.0"},
      {:jet_ext, github: "Byzanteam/jet-ext"},
      {:jason, "~> 1.4"},
      {:cachex, "~> 3.3"},
      {:finch, "~> 0.13"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end
end
