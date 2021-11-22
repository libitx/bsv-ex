defmodule BSV do
  @moduledoc """
  BSV-ex is a general purpose library for building Bitcoin SV applications in
  Elixir. Under the hood, [Curvy](https://hexdocs.pm/curvy) is used for all
  `secp256k1` flavoured crypto, making BSV-ex the first pure Elixir Bitcoin
  library.

  ## Features

  Currently supported features:

  - Keypair generation and address encoding and decoding
  - BIP-39 mnemonic phrase generation and BIP-32 hierarchical deterministic keys
  - Script and smart contract builder with built in Script simulator
  - Transaction builder, signing and verification
  - Block and block header parsing and serialization
  - Merkle proof parsing, serialization and verification
  - Bitcoin Signed Messages and ECIES encryption (Electrum compatible)

  ## Installation

  The package can be installed by adding `bsv` to your list of dependencies in
  `mix.exs`:

  ```elixir
  def deps do
    [
      {:bsv, "~> #{Mix.Project.config[:version]}"}
    ]
  end
  ```

  ## Upgrading

  Version `2.x` of this library is so signifcantly different to version `0.x`
  that we skipped an entire version. This is a rewrite from top to bottom, with
  an entirely new API, and makes no attempt to maintain backwards compatibility.

  If upgrading from a previous version then be prepared to update your code
  where it interfaces with this library. If this library is depended on by other
  third party dependencies, then check each dependency and make sure it has been
  upgraded to support version `2.x`.

  Main changes:

  * Many modules have been renamed to follow the conventions established in
  [Money Button's bsv JavaScript library](https://github.com/moneybutton/bsv).
  * `from_binary/2` and `to_binary/2` functions replace the old `parse/2` and
  `serialize/2` functions.
  * The old `Crypto` namespace and modules have been removed. Crypto code
  unrelated to Bitcoin is no longer maintained. Hash functions can be found in
  the `BSV.Hash` module, and ECDSA functions are provided by `Curvy`.
  * An entirely new script and smart contract building API has been created.

  ## Configuration

  Optionally, BSV can be configured for testnet network by editing your
  application's configuration:

  ```elixir
  config :bsv,
    network: :test  # defaults to :main
  ```

  ## Usage

  BSV-ex is a comprehensive Bitcoin library. Many examples can be found through
  the documentation. See the following for some quick-start examples:

  ### Keypairs, Addresses, BIP-32

  Generate a new random keypair and derive its address.

  ```elixir
  iex> keypair = BSV.KeyPair.new()
  %BSV.KeyPair{
    privkey: %BSV.PrivKey{
      compressed: true,
      d: <<119, 134, 104, 227, 196, 255, 3, 163, 39, 9, 0, 43, 84, 137, 55, 218, 146, 182, 246, 3, 18, 64, 159, 108, 46, 24, 108, 111, 239, 180, 74, 161>>
    },
    pubkey: %BSV.PubKey{
      compressed: true,
      point: %Curvy.Point{
        x: 80675204119348790085831157628459085855227400073327708725575496785606354176436,
        y: 9270420727654506759611377999115473532064051910093243567168505762017618809348
      }
    }
  }

  iex> address = BSV.Address.from_pubkey(keypair.pubkey)
  iex> BSV.Address.to_string(address)
  "19D5DoRKchdZbsP3fXYhopbFDdCJCPaLjr"
  ```

  Generate a BIP-32 HD wallet, derive and child and its address.

  ```elixir
  iex> mnemonic = BSV.Mnemonic.new()
  "taste canvas eternal brain rent cement fat dilemma duty fame floor defy"

  iex> seed = BSV.Mnemonic.to_seed(mnemonic)
  iex> extkey = BSV.ExtKey.from_seed!(seed)
  %BSV.ExtKey{
    chain_code: <<110, 26, 215, 117, 61, 123, 141, 33, 144, 225, 219, 244, 190, 61, 102, 123, 48, 131, 110, 209, 3, 193, 247, 57, 46, 72, 196, 13, 33, 189, 61, 6>>,
    child_index: 0,
    depth: 0,
    fingerprint: <<0, 0, 0, 0>>,
    privkey: %BSV.PrivKey{
      compressed: true,
      d: <<177, 226, 248, 91, 203, 59, 219, 9, 27, 117, 171, 67, 62, 138, 86, 122, 9, 215, 241, 4, 118, 97, 110, 174, 141, 2, 86, 116, 186, 32, 155, 133>>
    },
    pubkey: %BSV.PubKey{
      compressed: true,
      point: %Curvy.Point{
        x: 13957581247370416663735268664956755789623055115850818561656783044351458532461,
        y: 13811705978617564383043442008879108616838570537839984416253146804416417872149
      }
    },
    version: <<4, 136, 173, 228>>
  }

  # Derive child key and address
  iex> child = BSV.ExtKey.derive(extkey, "m/0/1")
  iex> address = BSV.Address.from_pubkey(child.pubkey)
  iex> BSV.Address.to_string(address)
  "1Cax2dCtapJZtwzYXCdLuTkZ1egG8JSugA"
  ```

  ### Building transactions

  The `TxBuilder` module provides a simple declarative way to build any type of transaction.

  ```elixir
  iex> alias BSV.Contract.{P2PKH, OpReturn}

  iex> utxo = BSV.UTXO.from_params(utxo_params)
  iex> builder = %BSV.TxBuilder{
  ...>   inputs: [
  ...>     P2PKH.unlock(utxo, %{keypair: keypair})
  ...>   ],
  ...>   outputs: [
  ...>     P2PKH.lock(10000, %{address: address}),
  ...>     OpReturn.lock(0, %{data: ["hello", "world"]})
  ...>   ]
  ...> }

  iex> tx = BSV.TxBuilder.to_tx(builder)
  iex> rawtx = BSV.Tx.to_binary(tx, encoding: :hex)
  "02000000011f4e5a628f..."
  ```

  ### Creating custom contracts

  The `BSV.Contract` module provides a way to define a locking script and
  unlocking script in a pure Elixir function.

  ```elixir
  # Define a module that implements the `Contract` behaviour
  defmodule P2PKH do
    use BSV.Contract

    def locking_script(ctx, %{address: address}) do
      ctx
      |> op_dup
      |> op_hash160
      |> push(address.pubkey_hash)
      |> op_equalverify
      |> op_checksig
    end

    def unlocking_script(ctx, %{keypair: keypair}) do
      ctx
      |> sig(keypair.privkey)
      |> push(BSV.PubKey.to_binary(keypair.pubkey))
    end
  end
  ```

  Contracts can be tested using the built-in simulator.

  ```elixir
  iex> keypair = BSV.KeyPair.new()
  iex> lock_params = %{address: BSV.Address.from_pubkey(keypair.pubkey)}
  iex> unlock_params = %{keypair: keypair}
  iex> {:ok, vm} = BSV.Contract.simulate(P2PKH, lock_params, unlock_params)
  iex> BSV.VM.valid?(vm)
  true
  ```
  """

  @typedoc "Bitcoin network"
  @type network() :: :main | :test

  @version Mix.Project.config[:version]

  @doc """
  Returns the currently configured Bitcoin network.
  """
  @spec network() :: network()
  def network(), do: Application.get_env(:bsv, :network, :main)

  @doc """
  Returns the version of the BSV-ex hex package.
  """
  @spec version() :: String.t
  def version(), do: @version

end
