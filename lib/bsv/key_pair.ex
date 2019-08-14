defmodule BSV.KeyPair do
  @moduledoc """
  Module for generating and using Bitcoin key pairs.
  """

  alias BSV.Crypto.ECDSA
  alias BSV.Crypto.Hash

  defstruct [:public_key, :private_key]

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

      iex> keypair = BSV.KeyPair.generate
      ...> (%BSV.KeyPair{} = keypair) == keypair
      true
  """
  @spec generate(keyword) :: BSV.KeyPair.t
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

      iex> keypair =BSV.KeyPair.from_ecdsa_key(BSV.Test.bsv_keys)
      ...> (%BSV.KeyPair{} = keypair) == keypair
      true
  """
  @spec from_ecdsa_key(BSV.Crypto.ECDSA.PrivateKey.t | {binary, binary}, keyword) :: BSV.KeyPair.t
  def from_ecdsa_key(key, options \\ [])

  def from_ecdsa_key({public_key, private_key}, options) do
    public_key = case Keyword.get(options, :compressed, true) do
      true -> compress_public_key(public_key)
      false -> public_key
    end

    struct(__MODULE__, [
      public_key: public_key,
      private_key: private_key
    ])
  end

  def from_ecdsa_key(key, options) do
    from_ecdsa_key({key.public_key, key.private_key}, options)
  end

  
  @doc """
  Returns the Bitcoin address from the given key pair or public key.

  ## Examples

      iex> BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.KeyPair.from_ecdsa_key
      ...> |> BSV.KeyPair.get_address
      "18cqNbEBxkAttxcZLuH9LWhZJPd1BNu1A5"

      iex> BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.KeyPair.from_ecdsa_key(compressed: false)
      ...> |> BSV.KeyPair.get_address
      "1N5Cu7YUPQhcwZaQLDT5KnDpRVKzFDJxsf"
  """
  @spec get_address(BSV.KeyPair.t() | {binary, binary} | binary) :: binary
  def get_address(key)

  def get_address(key = %__MODULE__{}), do: get_address(key.public_key)

  def get_address({public_key, _}), do: get_address(public_key)

  def get_address(public_key) when is_binary(public_key) do
    Hash.sha256_ripemd160(public_key)
    |> B58.encode58_check!(<<0>>)
  end


  @doc """
  Decodes the given Wallet Import Format (WIF) binary into a BSV key pair.

  ## Examples

      iex> BSV.KeyPair.wif_decode("KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF")
      ...> |> BSV.KeyPair.get_address
      "18cqNbEBxkAttxcZLuH9LWhZJPd1BNu1A5"

      iex> BSV.KeyPair.wif_decode("5JH9eTJyj6bYopGhBztsDd4XvAbFNQkpZEw8AXYoQePtK1r86nu")
      ...> |> BSV.KeyPair.get_address
      "1N5Cu7YUPQhcwZaQLDT5KnDpRVKzFDJxsf"
  """
  @spec wif_decode(binary) :: BSV.KeyPair.t
  def wif_decode(wif) do
    {private_key, compressed} = case B58.decode58_check!(wif) do
      {<<private_key::bytes-size(32), 1>>, <<0x80>>} -> {private_key, true}
      {<<private_key::bytes-size(32)>>, <<0x80>>} -> {private_key, false}
    end

    ECDSA.generate_key_pair(private_key: private_key)
    |> from_ecdsa_key(compressed: compressed)
  end


  @doc """
  Encodes the given BSV key pair into a Wallet Import Format (WIF) binary.

  ## Examples

      iex> BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.KeyPair.from_ecdsa_key
      ...> |> BSV.KeyPair.wif_encode
      "KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF"

      iex> BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.KeyPair.from_ecdsa_key(compressed: false)
      ...> |> BSV.KeyPair.wif_encode
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
    

  defp compress_public_key(<< _::size(8), x::size(256), y::size(256) >>) do
    prefix = case rem(y, 2) do
      0 -> 0x02
      _ -> 0x03
    end
    << prefix::size(8), x::size(256) >>
  end
  
end