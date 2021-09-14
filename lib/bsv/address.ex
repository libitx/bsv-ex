defmodule BSV.Address do
  @moduledoc """
  TODO
  """
  alias BSV.{Hash, PubKey}

  defstruct pubkey_hash: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    pubkey_hash: <<_::160>>
  }

  @typedoc "TODO"
  @type address_str() :: String.t()

  @version_bytes %{
    main: <<0x00>>,
    test: <<0x6F>>
  }

  @doc """
  TODO
  """
  @spec from_pubkey(PubKey.t() | PubKey.pubkey_bin()) :: t()
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
  TODO
  """
  @spec from_string(address_str()) :: t()
  def from_string(address) when is_binary(address) do
    version_byte = @version_bytes[BSV.network()]
    case B58.decode58_check!(address) do
      {<<pubkey_hash::binary-20>>, ^version_byte} ->
        struct(__MODULE__, pubkey_hash: pubkey_hash)

      {<<_pubkey_hash::binary-20>>, version_byte} ->
        raise ArgumentError, "Invalid version byte #{ version_byte } for network: #{ BSV.network() }"

      _result ->
        raise ArgumentError, "Invalid address"
    end
  end

  @doc """
  TODO
  """
  @spec to_string(t()) :: address_str()
  def to_string(%__MODULE__{pubkey_hash: pubkey_hash}) do
    version_byte = @version_bytes[BSV.network()]
    B58.encode58_check!(pubkey_hash, version_byte)
  end

end
