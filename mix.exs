defmodule Judgejudy.MixProject do
  use Mix.Project

  def project do
    [
      app: :judgejudy,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :swoosh],
      mod: {Judgejudy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jido, "~> 2.0"},
      {:jido_ai, "~> 2.0.0-rc.0"},
      {:swoosh, "~> 1.17"},
      {:gen_smtp, "~> 1.3"},
      {:hackney, "~> 4.0"},
      {:yugo, "~> 1.0"},
      {:pgvector, "~> 0.3"},
      {:ecto_sql, "~> 3.12"},
      {:postgrex, "~> 0.19"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
