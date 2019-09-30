# bsv-ex - Elixir Bitcoin SV Library

The intent of this library is to provide a full-featured BSV library that is broadly comparable in scope to [Money Button's BSV Javascript library](https://github.com/moneybutton/bsv).

Currently this library offers the following:

* General crypto functions - wide range of hashing, ECDSA and RSA encryption and signature functions.
* Bitcoin specific crypto - Electrum-compatible message encryption and signatures.
* Bitcoin key pair generation and related functions.
* BIP-39 mnemonic phrase generation and deterministic keys.
* Raw transaction parsing, manipulation and serialization.

What is NOT in this library:

* P2P - this is not a full node implementation. 

Documentation can be found at [https://hexdocs.pm/bsv](https://hexdocs.pm/bsv).

## Installation

As this package uses `libsecp256k1` NIF bindings, please ensure you have `libtool`, `automake` and `autogen` installed in order for the package to compile.

The package can be installed by adding `bsv` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:bsv, "~> 0.1.0"}
  ]
end
```

## Usage

### Key pairs and addresses

```elixir
iex> keys = BSV.KeyPair.generate
%BSV.KeyPair{
  network: :main,
  private_key: <<1, 249, 98, 144, 230, 172, 5, 56, 197, 143, 133, 240, 144, 223, 25, 32, 55, 42, 159, 26, 128, 66, 149, 49, 235, 179, 116, 11, 209, 235, 240, 163>>,
  public_key: <<3, 173, 251, 14, 108, 217, 224, 80, 133, 244, 200, 33, 191, 137, 80, 62, 141, 133, 166, 201, 224, 141, 101, 152, 144, 92, 237, 54, 220, 131, 58, 26, 4>>
}

iex> address = BSV.Address.to_string(keys)
"1MzYtHPymTjgxx9npR6Pu9ZCUhtU9hHYTL"
```

### Mnemonic phrase and deterministic keys

```elixir
iex> mnemonic = BSV.Mnemonic.generate
"various attitude grain market food wheat arena disagree soccer dust wrestle auction fiber wrestle sort wonder vital gym ill word amazing sniff have biology"

iex> master = BSV.Mnemonic.to_seed(mnemonic)
...> |> BSV.Extended.PrivateKey.from_seed
%BSV.Extended.PrivateKey{
  chain_code: <<164, 12, 192, 154, 59, 209, 85, 172, 76, 7, 42, 138, 247, 125, 161, 30, 135, 25, 124, 160, 170, 234, 126, 162, 228, 146, 135, 232, 67, 181, 219, 91>>,
  child_number: 0,
  depth: 0,
  fingerprint: <<0, 0, 0, 0>>,
  key: <<111, 24, 247, 85, 107, 58, 162, 225, 135, 190, 185, 200, 226, 131, 68, 152, 159, 111, 232, 166, 21, 211, 235, 180, 140, 190, 109, 39, 31, 33, 107, 17>>,
  network: :main,
  version_number: <<4, 136, 173, 228>>
}

iex> child_address = master
...> |> BSV.Extended.Children.derive("m/44'/0'/0'/0/0")
...> |> BSV.Address.to_string
"1F6fuP7HrBY8aeUazXZitaAsgpsJQFfUun"
```

### Creating transactions

```elixir
iex> script = %BSV.Transaction.Script{}
...> |> BSV.Transaction.Script.push(:OP_FALSE)
...> |> BSV.Transaction.Script.push(:OP_RETURN)
...> |> BSV.Transaction.Script.push("hello world")
%BSV.Transaction.Script{chunks: [:OP_FALSE, :OP_RETURN, "hello world"]}

iex> output = %BSV.Transaction.Output{script: script}
%BSV.Transaction.Output{
  amount: 0,
  satoshis: 0,
  script: %BSV.Transaction.Script{
    chunks: [:OP_FALSE, :OP_RETURN, "hello world"]
  }
}

iex> tx = %BSV.Transaction{outputs: [output]}
...> |> BSV.Transaction.serialize(encoding: :hex)
"01000000000100000000000000000e006a0b68656c6c6f20776f726c6400000000"
```

For more examples please refer to the [full documentation](https://hexdocs.pm/bsv).

## Credit

`bsv-ex` is a new project with new objectives and new code, but the following projects have helped me through some of the more nuanced aspects of Bitcoin:

* [KamilLelonek/ex_wallet](https://github.com/KamilLelonek/ex_wallet)
* [comboy/bitcoin-elixir](https://github.com/comboy/bitcoin-elixir)
* [moneybutton/bsv](https://github.com/moneybutton/bsv)

## License

© Copyright 2019 libitx.

BSV-ex is free software and released under the [MIT license](https://github.com/libitx/bsv-elixir/blob/master/LICENSE.md).