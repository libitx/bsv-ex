defmodule BSV.Address do
  @moduledoc """
  A Bitcoin address is a 26-35 character string beginning with the number 1,
  that represents the hash of a pulic key.

  An address is derived by calculating the RIPEMD hash of a SHA-256 hash of the
  public key, and then Base58check encoding it.

  Addresses are used in [`P2PKH`](`BSV.Contract.P2PKH`) outputs, a common
  script template used to send Bitcoin payments.
  """
  alias BSV.{Hash, PubKey}

  defstruct pubkey_hash: nil

  @typedoc """
  Bitcoin address

  An Elixir struct containing the public key hash.
  """
  @type t() :: %__MODULE__{
    pubkey_hash: <<_::160>>
  }

  @typedoc """
  Bitcoin address string

  Base58Check encoded public key hash.
  """
  @type address_str() :: String.t()

  @version_bytes %{
    main: <<0x00>>,
    test: <<0x6F>>
  }

  @doc """
  Converts the given `t:BSV.PubKey.t/0` into an `t:BSV.Address.t/0`.

  ## Examples

      iex> Address.from_pubkey(@pubkey)
      %Address{
        pubkey_hash: <<83, 143, 209, 121, 200, 190, 15, 40, 156, 115, 14, 51, 181, 246, 163, 84, 27, 233, 102, 143>>
      }
  """
  @spec from_pubkey(PubKey.t() | binary()) :: t()
  def from_pubkey(%PubKey{} = pubkey) do
    pubkey
    |> PubKey.to_binary()
    |> from_pubkey()
  end

  def from_pubkey(pubkey)
    when is_binary(pubkey) and byte_size(pubkey) in [33, 65]
  do
    pubkey_hash = Hash.sha256_ripemd160(pubkey)
    struct(__MODULE__, pubkey_hash: pubkey_hash)
  end

  @doc """
  Decodes the given `t:BSV.Address.address_str/0` into an `t:BSV.Address.t/0`.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Examples

      iex> Address.from_string("18cqNbEBxkAttxcZLuH9LWhZJPd1BNu1A5")
      {:ok, %Address{
        pubkey_hash: <<83, 143, 209, 121, 200, 190, 15, 40, 156, 115, 14, 51, 181, 246, 163, 84, 27, 233, 102, 143>>
      }}
  """
  @spec from_string(address_str()) :: {:ok, t()} | {:error, term()}
  def from_string(address) when is_binary(address) do
    version_byte = @version_bytes[BSV.network()]
    case B58.decode58_check(address) do
      {:ok, {<<pubkey_hash::binary-20>>, ^version_byte}} ->
        {:ok, struct(__MODULE__, pubkey_hash: pubkey_hash)}

      {:ok, {<<_pubkey_hash::binary-20>>, version_byte}} ->
        {:error, {:invalid_base58_check, version_byte, BSV.network()}}

      _error ->
        {:error, :invalid_address}
    end
  end

  @doc """
  Decodes the given `t:BSV.Address.address_str/0` into an `t:BSV.Address.t/0`.

  As `from_string/1` but returns the result or raises an exception.
  """
  @spec from_string!(address_str()) :: t()
  def from_string!(address) when is_binary(address) do
    case from_string(address) do
      {:ok, privkey} ->
        privkey
      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  Encodes the given `t:BSV.Address.t/0` as a Base58Check encoded
  `t:BSV.Address.address_str/0`.

  ## Example

      iex> Address.to_string(@address)
      "18cqNbEBxkAttxcZLuH9LWhZJPd1BNu1A5"
  """
  @spec to_string(t()) :: address_str()
  def to_string(%__MODULE__{pubkey_hash: pubkey_hash}) do
    version_byte = @version_bytes[BSV.network()]
    B58.encode58_check!(pubkey_hash, version_byte)
  end

end
