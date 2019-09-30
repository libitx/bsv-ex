defmodule BSV.Address do
  @moduledoc """
  Module for calculating any Bitcoin public or private key's address.

  A Bitcoin address is calculated by hashing the public key with both the
  SHA-256 and then RIPEMD alogrithms. The resulting hash is then Base58Check
  encoded, resulting in the Bitcoin address.
  """
  alias BSV.Crypto.Hash
  alias BSV.Wallet.KeyPair
  alias BSV.Extended.PublicKey
  alias BSV.Extended.PrivateKey

  @version_bytes %{
    main: <<0x00>>,
    test: <<0x6F>>
  }

  
  @doc """
  Calculates and returns the Bitcoin address from the given public or private key.

  ## Examples

      iex> BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Wallet.KeyPair.from_ecdsa_key
      ...> |> BSV.Address.to_string
      "18cqNbEBxkAttxcZLuH9LWhZJPd1BNu1A5"

      iex> BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Wallet.KeyPair.from_ecdsa_key(compressed: false)
      ...> |> BSV.Address.to_string
      "1N5Cu7YUPQhcwZaQLDT5KnDpRVKzFDJxsf"

      iex> BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Wallet.KeyPair.from_ecdsa_key
      ...> |> BSV.Address.to_string(network: :test)
      "mo8nfeKAmmc9g56B4UFXARutAPDi1sr7tH"
  """
  @spec to_string(
    KeyPair.t | PublicKey.t | PrivateKey.t | {binary, binary}, binary
    ) :: String.t
  def to_string(key, options \\ [])

  def to_string(%KeyPair{} = key, options) do
    network = Keyword.get(options, :network, key.network)
    to_string(key.public_key, network: network)
  end

  def to_string(%PrivateKey{} = key, options) do
    PrivateKey.get_public_key(key)
    |> to_string(options)
  end

  def to_string(%PublicKey{} = key, options) do
    network = Keyword.get(options, :network, key.network)
    to_string(key.key, network: network)
  end

  def to_string({public_key, _}, options), do: to_string(public_key, options)

  def to_string(public_key, options) when is_binary(public_key) do
    network = Keyword.get(options, :network, :main)

    Hash.sha256_ripemd160(public_key)
    |> B58.encode58_check!(@version_bytes[network])
  end
    
end