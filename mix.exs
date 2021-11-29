defmodule BSV.MixProject do
  use Mix.Project

  def project do
    [
      app: :bsv,
      version: "2.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "BSV",
      description: "Elixir toolsset for building Bitcoin applications",
      source_url: "https://github.com/libitx/bsv-ex",
      docs: docs(),
      package: package()
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
      {:curvy, "~> 0.3"},
      {:ex_doc, "~> 0.25", only: :dev, runtime: false},
      {:jason, "~> 1.2", only: :test, runtime: false}
    ]
  end

  defp docs do
    [
      main: "BSV",
      extras: extras(),
      groups_for_modules: [
        "Contract API": [
          BSV.Contract,
          BSV.Contract.P2PKH,
          BSV.Contract.P2PK,
          BSV.Contract.P2MS,
          BSV.Contract.P2RPH,
          BSV.Contract.OpReturn,
          BSV.Contract.Raw
        ],
        "Contract Helpers": [
          BSV.Contract.Helpers,
          BSV.Contract.OpCodeHelpers,
          BSV.Contract.PushTxHelpers,
          BSV.Contract.VarIntHelpers
        ]
      ]
    ]
  end

  defp extras do
    []
  end

  defp package do
    [
      name: "bsv",
      files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/libitx/bsv-ex"}
    ]
  end
end
