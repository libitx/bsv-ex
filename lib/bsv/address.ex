defmodule BSV.Address do
  @moduledoc """
  Module for calculating any Bitcoin public or private key's address.

  A Bitcoin address is calculated by hashing the public key with both the
  SHA-256 and then RIPEMD alogrithms. The hash is then Base58Check encoded,
  resulting in the Bitcoin address.
  """
  alias BSV.Crypto.Hash
  alias BSV.KeyPair
  alias BSV.Extended.{PublicKey, PrivateKey}

  defstruct network: :main, version_number: nil, hash: nil

  @typedoc "Extended Private Key"
  @type t :: %__MODULE__{
    network: atom,
    hash: binary
  }

  @version_bytes %{
    main: <<0x00>>,
    test: <<0x6F>>
  }


  @doc """
  Returns a Bitcoin address from the given public key.

  ## Examples

      iex> address = BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.KeyPair.from_ecdsa_key
      ...> |> BSV.Address.from_public_key
      iex> address.__struct__ == BSV.Address
      true
  """
  @spec from_public_key(
    KeyPair.t | PublicKey.t | PrivateKey.t | {binary, binary} | binary,
    keyword
  ) :: __MODULE__.t
  def from_public_key(public_key, options \\ [])

  def from_public_key(%KeyPair{} = key, options) do
    network = Keyword.get(options, :network, key.network)
    from_public_key(key.public_key, network: network)
  end

  def from_public_key(%PublicKey{} = key, options) do
    network = Keyword.get(options, :network, key.network)
    from_public_key(key.key, network: network)
  end

  def from_public_key(%PrivateKey{} = key, options) do
    PrivateKey.get_public_key(key)
    |> from_public_key(options)
  end

  def from_public_key({public_key, _}, options),
    do: from_public_key(public_key, options)

  def from_public_key(public_key, options) when is_binary(public_key) do
    network = Keyword.get(options, :network, :main)
    hash = Hash.sha256_ripemd160(public_key)

    struct(__MODULE__, [
      network: network,
      version_number: @version_bytes[network],
      hash: hash
    ])
  end


  @doc """
  Returns a Bitcoin address struct from the given address string.

  ## Examples

      iex> BSV.Address.from_string("15KgnG69mTbtkx73vNDNUdrWuDhnmfCxsf")
      %BSV.Address{
        network: :main,
        hash: <<47, 105, 50, 137, 102, 179, 60, 141, 131, 76, 2, 71, 24, 254, 231, 1, 101, 139, 55, 71>>
      }
  """
  @spec from_string(binary) :: __MODULE__.t
  def from_string(address) when is_binary(address) do
    {hash, version_byte} = B58.decode58_check!(address)
    network = @version_bytes
    |> Enum.find(fn {_k, v} -> v == version_byte end)
    |> elem(0)

    struct(__MODULE__, [
      network: network,
      hash: hash
    ])
  end

  
  @doc """
  Returns a Base58Check encoded string from the given Bitcoin address struct.

  ## Examples

      iex> BSV.Test.bsv_keys
      ...> |> BSV.KeyPair.from_ecdsa_key
      ...> |> BSV.Address.from_public_key
      ...> |> BSV.Address.to_string
      "15KgnG69mTbtkx73vNDNUdrWuDhnmfCxsf"

      iex> BSV.Test.bsv_keys
      ...> |> BSV.KeyPair.from_ecdsa_key(compressed: false)
      ...> |> BSV.Address.from_public_key
      ...> |> BSV.Address.to_string
      "13qKCNCBSgcis1TGBgCr2D9qz9iywiYrYd"

      iex> BSV.Test.bsv_keys
      ...> |> BSV.KeyPair.from_ecdsa_key
      ...> |> BSV.Address.from_public_key(network: :test)
      ...> |> BSV.Address.to_string
      "mjqe5KB8aV39Y4afdwBkJZ4qmDJViTNDLQ"
  """
  @spec to_string(__MODULE__.t) :: String.t
  def to_string(%__MODULE__{} = address) do
    version = @version_bytes[address.network]
    B58.encode58_check!(address.hash, version)
  end
    
end