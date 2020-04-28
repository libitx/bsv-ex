defmodule BSV.MixProject do
  use Mix.Project

  def project do
    [
      app: :bsv,
      version: "0.2.5",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "BSV-ex",
      description: "Elixir Bitcoin SV library",
      source_url: "https://github.com/libitx/bsv-ex",
      docs: [
        main: "BSV",
        groups_for_modules: [
          "Crypto": [
            BSV.Crypto.AES,
            BSV.Crypto.ECDSA,
            BSV.Crypto.ECDSA.PrivateKey,
            BSV.Crypto.ECDSA.PublicKey,
            BSV.Crypto.ECIES,
            BSV.Crypto.Hash,
            BSV.Crypto.RSA,
            BSV.Crypto.RSA.PrivateKey,
            BSV.Crypto.RSA.PublicKey
          ]
        ]
      ],
      package: [
        name: "bsv",
        files: ~w(lib priv .formatter.exs mix.exs README.md LICENSE.md),
        licenses: ["MIT"],
        links: %{"GitHub" => "https://github.com/libitx/bsv-ex"}
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
      {:basefiftyeight, "~> 0.1"},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:libsecp256k1, "~> 0.1"}
    ]
  end
end
