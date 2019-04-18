defmodule LogicSim.MixProject do
  @moduledoc false
  use Mix.Project

  def project do
    [
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [
        ignore_warnings: ".dialyzer_ignore.exs",
        list_unused_filters: true,
        plt_file: {:no_warn, "logic_sim.plt"}
      ],
      app: :logic_sim,
      version: "0.1.3",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      source_url: "https://github.com/TheFirstAvenger/logic_sim",
      description: description()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:git_hooks, "~> 0.2.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.10.6", only: :test},
      {:credo, "~> 1.0.4", only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.9.0", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: :dev, runtime: false},
      {:earmark, "~> 1.3.2", only: :dev, runtime: false},
      {:ex_doc, "~> 0.20.1", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/TheFirstAvenger/logic_sim"}
    ]
  end

  defp description do
    "Logical Circuit Simulator using GenServers and Message Passing"
  end
end
