defmodule BSV.MixProject do
  use Mix.Project

  def project do
    [
      app: :bsv,
      version: "2.0.0-alpha.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:crypto, :logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:basefiftyeight, "~> 0.1"},
      {:curvy, "~> 0.2"},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:jason, "~> 1.2", only: :test}
    ]
  end
end
