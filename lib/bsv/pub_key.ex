defmodule BSV.PubKey do
  @moduledoc """
  TODO
  """
  alias BSV.PrivKey
  alias Curvy.{Key, Point}
  import BSV.Util, only: [decode: 2, encode: 2]

  defstruct point: nil, compressed: true

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    point: Point.t(),
    compressed: boolean()
  }

  @typedoc "TODO"
  @type pubkey_bin :: <<_::264>> | <<_::520>> | pubkey_hex()

  @typedoc "TODO"
  @type pubkey_hex :: String.t()

  @doc """
  TODO
  """
  @spec from_binary(pubkey_bin(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_binary(pubkey, opts \\ []) when is_binary(pubkey) do
    encoding = Keyword.get(opts, :encoding)

    with {:ok, pubkey} when byte_size(pubkey) in [33, 65] <- decode(pubkey, encoding) do
      %Key{point: point, compressed: compressed} = Key.from_pubkey(pubkey)
      {:ok, struct(__MODULE__, point: point, compressed: compressed)}
    else
      {:ok, pubkey} ->
        {:error, {:invalid_pubkey, byte_size(pubkey)}}
      error ->
        error
    end
  end

  @doc """
  TODO
  """
  @spec from_binary!(pubkey_bin(), keyword()) :: t()
  def from_binary!(pubkey, opts \\ []) when is_binary(pubkey) do
    case from_binary(pubkey, opts) do
      {:ok, pubkey} ->
        pubkey
      {:error, {:invalid_pubkey, _length} = error} ->
        raise BSV.DecodeError, error
      {:error, error} ->
        raise error
    end
  end

  @doc """
  TODO
  """
  @spec from_privkey(PrivKey.t()) :: t()
  def from_privkey(%PrivKey{d: d, compressed: compressed}) do
    {pubkey, _privkey} = :crypto.generate_key(:ecdh, :secp256k1, d)
    %Key{point: point} = Key.from_pubkey(pubkey)
    struct(__MODULE__, point: point, compressed: compressed)
  end

  @doc """
  TODO
  """
  @spec to_binary(t(), keyword()) :: binary()
  def to_binary(%__MODULE__{point: point, compressed: compressed}, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)
    %Key{point: point, compressed: compressed}
    |> Key.to_pubkey()
    |> encode(encoding)
  end

end
