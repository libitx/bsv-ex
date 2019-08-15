defmodule BSV.MixProject do
  use Mix.Project

  def project do
    [
      app: :bsv,
      version: "0.1.0-dev.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "BSV",
      source_url: "https://github.com/libitx/bsv-ex",
      docs: [
        main: "README",
        extras: ["README.md"]
      ]
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
      {:basefiftyeight, "~> 0.1.0"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
