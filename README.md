# BSV (elixir)

**🚨 This repo is a work in progress. Not production ready yet.**

Elixir Bitcoin SV library. The aim is to create a full-featured library that broadly covers the following:

* [x] General crypto functions (hash, ecdsa, rsa)
* [x] Bitcoin specific crypto (Electrum compatible message encrypt/decrypt and sign/verify)
* [x] Bitcoin key pair generation and related functions
* [x] HD seed and key derivation
* [x] Transaction parsing, building and encoding

Documentation can be found at [https://hexdocs.pm/bsv](https://hexdocs.pm/bsv).

## Installation

The package can be installed by adding `bsv` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bsv, "~> 0.1.0-dev.2"}
  ]
end
```

## License

© Copyright 2019 libitx.

BSV-ex is free software and released under the [MIT license](https://github.com/libitx/bsv-elixir/blob/master/LICENSE.md).