defmodule VowpalClient.MixProject do
  use Mix.Project

  def project do
    [
      app: :vowpal_client,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/jackdoe/elixir-vowpal-client",
      name: "vowpal_client"
    ]
  end

  def application() do
    []
  end

  defp deps() do
    [{:earmark, "~> 1.2", only: :dev}, {:ex_doc, "~> 0.19", only: :dev}]
  end

  defp description() do
    "Vowpal Wabbit (awesome machine learning tool - https://github.com/JohnLangford/vowpal_wabbit/) TCP client to query for training and predicting"
  end

  defp package() do
    [
      name: "vowpal_client",
      files: ~w(lib priv .formatter.exs mix.exs README* readme* LICENSE*
                license* CHANGELOG* changelog* src),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/jackdoe/elixir-vowpal-client"}
    ]
  end
end
