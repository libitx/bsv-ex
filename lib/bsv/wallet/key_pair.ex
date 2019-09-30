defmodule BSV.Wallet.KeyPair do
  @moduledoc """
  Module for generating and using Bitcoin key pairs.
  """

  alias BSV.Crypto.Hash
  alias BSV.Crypto.ECDSA
  alias BSV.Crypto.ECDSA.PublicKey
  alias BSV.Crypto.ECDSA.PrivateKey

  defstruct network: :main, public_key: nil, private_key: nil

  @typedoc "BSV Key Pair"
  @type t :: %__MODULE__{
    public_key: binary,
    private_key: binary
  }


  @doc """
  Generates a new BSV key pair.

  ## Options

  The accepted options are:

  * `:compressed` - Specify whether to compress the generated public key. Defaults to `true`.

  ## Examples

      iex> keypair = BSV.Wallet.KeyPair.generate
      ...> keypair.__struct__ == BSV.Wallet.KeyPair
      true
  """
  @spec generate(keyword) :: __MODULE__.t
  def generate(options \\ []) do
    ECDSA.generate_key
    |> from_ecdsa_key(options)
  end


  @doc """
  Converts ECDSA keys to a BSV key pair.

  ## Options

  The accepted options are:

  * `:compressed` - Specify whether to compress the given public key. Defaults to `true`.

  ## Examples

      iex> keypair = BSV.Wallet.KeyPair.from_ecdsa_key(BSV.Test.bsv_keys)
      ...> keypair.__struct__ == BSV.Wallet.KeyPair
      true
  """
  @spec from_ecdsa_key(PrivateKey.t | {binary, binary}, keyword) :: __MODULE__.t
  def from_ecdsa_key(key, options \\ [])

  def from_ecdsa_key({public_key, private_key}, options) do
    network = Keyword.get(options, :network, :main)
    public_key = case Keyword.get(options, :compressed, true) do
      true -> PublicKey.compress(public_key)
      false -> public_key
    end

    struct(__MODULE__, [
      network: network,
      public_key: public_key,
      private_key: private_key
    ])
  end

  def from_ecdsa_key(key, options) do
    from_ecdsa_key({key.public_key, key.private_key}, options)
  end


  @doc """
  Decodes the given Wallet Import Format (WIF) binary into a BSV key pair.

  ## Examples

      iex> BSV.Wallet.KeyPair.wif_decode("KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF")
      ...> |> BSV.Address.to_string
      "18cqNbEBxkAttxcZLuH9LWhZJPd1BNu1A5"

      iex> BSV.Wallet.KeyPair.wif_decode("5JH9eTJyj6bYopGhBztsDd4XvAbFNQkpZEw8AXYoQePtK1r86nu")
      ...> |> BSV.Address.to_string
      "1N5Cu7YUPQhcwZaQLDT5KnDpRVKzFDJxsf"
  """
  @spec wif_decode(binary) :: __MODULE__.t
  def wif_decode(wif) do
    {private_key, compressed} = case B58.decode58_check!(wif) do
      {<<private_key::binary-32, 1>>, <<0x80>>} -> {private_key, true}
      {<<private_key::binary-32>>, <<0x80>>} -> {private_key, false}
    end

    ECDSA.generate_key_pair(private_key: private_key)
    |> from_ecdsa_key(compressed: compressed)
  end


  @doc """
  Encodes the given BSV key pair into a Wallet Import Format (WIF) binary.

  ## Examples

      iex> BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Wallet.KeyPair.from_ecdsa_key
      ...> |> BSV.Wallet.KeyPair.wif_encode
      "KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF"

      iex> BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Wallet.KeyPair.from_ecdsa_key(compressed: false)
      ...> |> BSV.Wallet.KeyPair.wif_encode
      "5JH9eTJyj6bYopGhBztsDd4XvAbFNQkpZEw8AXYoQePtK1r86nu"
  """
  def wif_encode(key = %__MODULE__{}) do
    suffix = case byte_size(key.public_key) do
      33 -> <<0x01>>
      _ -> ""
    end

    (key.private_key <> suffix)
    |> B58.encode58_check!(<<0x80>>)
  end
  
end