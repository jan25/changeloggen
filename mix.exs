defmodule Changeloggen.MixProject do
  use Mix.Project

  def project do
    [
      app: :changeloggen,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      
      escript: [main_module: Cli],

      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:httpoison, "~> 1.6"},
      {:poison, "~> 3.1"}
    ]
  end
end
