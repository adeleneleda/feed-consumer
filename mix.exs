defmodule FeedConsumer.Mixfile do
  use Mix.Project

  def project do
    [app: :feed_consumer,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
     applications: [:logger, :httpoison, :ex_aws],
     mod: {FeedConsumer, []}
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:httpoison, "~> 0.10"},
      {:hackney, "1.6.1", override: true},
      {:poison, "~> 2.2"},
      {:earmark, "~> 1.1.0", override: true, only: :dev},
      {:ex_doc, "~> 0.7", only: :dev},
      {:msgpax, "~> 2.0"},
      {:ex_aws, github: "vasumahesh1/ex_aws", branch: "feature/mon"},
      {:sweet_xml, "~> 0.6"}
    ]
  end
end
