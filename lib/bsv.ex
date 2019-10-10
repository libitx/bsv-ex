defmodule BSV do
  @moduledoc """
  BSV-ex. Elixir Bitcoin SV library.

  BSV-ex is a general purpose library for building Bitcoin SV applications in
  Elixir. The intent of this library is to be broadly comparable in scope, and
  cross compatible with [Money Button's BSV Javascript library](https://github.com/moneybutton/bsv).

  ## Features

  Currently this library offers the following functionality:

  * Transaction parsing, construction, signing and serialization
  * Keypair generation and address encoding and decoding
  * BIP-39 mnemonic phrase generation and deterministic keys
  * Bitcoin message signing (Electrum compatible)
  * ECIES encryption/decryption (Electrum compatible)
  * Wide range of both Bitcoin and non-Bitcoin specific crypto functions

  Full documentation can be found at [https://hexdocs.pm/bsv](https://hexdocs.pm/bsv).

  #### Note to developers

  This is a new library and new codebase. As such developers should proceed with
  caution and test using testnet and small value transactions. In future
  versions the API is subject to change as the library is developed towards
  maturity.

  ## Installation

  The package is bundled with `libsecp256k1` NIF bindings. `libtool`, `automake`
  and `autogen` are required in order for the package to compile.

  The package can be installed by adding `bsv` to your list of dependencies in
  `mix.exs`:

      def deps do
        [
          {:bsv, "~> 0.1.0"}
        ]
      end

  ## Usage

  Many examples are demonstrated throught the documentation, but see the
  following for some quick-start examples:

  ### Key pairs and addresses

  For more examples refer to `BSV.KeyPair` and `BSV.Address`.

      iex> keys = BSV.KeyPair.generate
      %BSV.KeyPair{
        network: :main,
        private_key: <<1, 249, 98, 144, 230, 172, 5, 56, 197, 143, 133, 240, 144, 223, 25, 32, 55, 42, 159, 26, 128, 66, 149, 49, 235, 179, 116, 11, 209, 235, 240, 163>>,
        public_key: <<3, 173, 251, 14, 108, 217, 224, 80, 133, 244, 200, 33, 191, 137, 80, 62, 141, 133, 166, 201, 224, 141, 101, 152, 144, 92, 237, 54, 220, 131, 58, 26, 4>>
      }

      iex> address = BSV.Address.from_public_key(keys)
      ...> |> BSV.Address.to_string
      "1MzYtHPymTjgxx9npR6Pu9ZCUhtU9hHYTL"

  ### Mnemonic phrase and deterministic keys

  For further details and examples refer to `BSV.Mnemonic`,
  `BSV.Extended.PrivateKey`, `BSV.Extended.PublicKey` and `BSV.Extended.Children`.

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
      ...> |> BSV.Address.from_public_key
      ...> |> BSV.Address.to_string
      "1F6fuP7HrBY8aeUazXZitaAsgpsJQFfUun"

  ### Creating transactions

  For further details and examples refer to `BSV.Transaction`,
  `BSV.Transaction.Input`, `BSV.Transaction.Output` and `BSV.Script`.

      iex> script = %BSV.Script{}
      ...> |> BSV.Script.push(:OP_FALSE)
      ...> |> BSV.Script.push(:OP_RETURN)
      ...> |> BSV.Script.push("hello world")
      %BSV.Script{chunks: [:OP_FALSE, :OP_RETURN, "hello world"]}

      iex> output = %BSV.Transaction.Output{script: script}
      %BSV.Transaction.Output{
        amount: 0,
        satoshis: 0,
        script: %BSV.Script{
          chunks: [:OP_FALSE, :OP_RETURN, "hello world"]
        }
      }

      iex> tx = %BSV.Transaction{}
      ...> |> BSV.Transaction.spend_from(utxo)
      ...> |> BSV.Transaction.add_output(output)
      ...> |> BSV.Transaction.change_to("15KgnG69mTbtkx73vNDNUdrWuDhnmfCxsf")
      ...> |> BSV.Transaction.sign(private_key)
      ...> |> BSV.Transaction.serialize(encoding: :hex)
      "010000000142123cac628be8df8bbf1fc21449c94bb8b81bc4a5960193be37688694626f49000000006b483045022100df13af549e5f6a23f70e0332856a0934a6fbbf7edceb19b15cafd8d3009ce12f02205ecf6b0f9456354de7c0b9d6b8877dac896b72edd9f7e3881b5ac69c82c03aac41210296207d8752d01b1cf8de77d258c02dd7280edc2bce9b59023311bbd395cbe93affffffff0100000000000000000e006a0b68656c6c6f20776f726c6400000000"
  """
end
