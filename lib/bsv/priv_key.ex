defmodule BSV.PrivKey do
  @moduledoc """
  TODO
  """
  import BSV.Util, only: [decode: 2, encode: 2]

  defstruct d: nil, compressed: true

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    d: privkey_bin(),
    compressed: boolean()
  }

  @typedoc "TODO"
  @type privkey_bin() :: <<_::256>> | privkey_hex()

  @typedoc "TODO"
  @type privkey_hex() :: String.t()

  @typedoc "TODO"
  @type privkey_wif() :: String.t()

  @version_bytes %{
    main: <<0x80>>,
    test: <<0xEF>>
  }

  @doc """
  TODO
  """
  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    {_pubkey, privkey} = :crypto.generate_key(:ecdh, :secp256k1)
    from_binary!(privkey, opts)
  end

  @doc """
  TODO
  """
  @spec from_binary(privkey_bin(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_binary(privkey, opts \\ []) when is_binary(privkey) do
    encoding = Keyword.get(opts, :encoding)
    compressed = Keyword.get(opts, :compressed, true)

    case decode(privkey, encoding) do
      {:ok, <<d::binary-32>>} ->
        {:ok, struct(__MODULE__, d: d, compressed: compressed)}
      {:ok, d} ->
        {:error, {:invalid_privkey, byte_size(d)}}
      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  TODO
  """
  @spec from_binary!(privkey_bin(), keyword()) :: t()
  def from_binary!(privkey, opts \\ []) when is_binary(privkey) do
    case from_binary(privkey, opts) do
      {:ok, privkey} ->
        privkey
      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  TODO
  """
  @spec from_wif(privkey_wif()) :: {:ok, t()} | {:error, term()}
  def from_wif(wif) when is_binary(wif) do
    version_byte = @version_bytes[BSV.network()]

    case B58.decode58_check(wif) do
      {:ok, {<<d::binary-32, 1>>, ^version_byte}} ->
        {:ok, struct(__MODULE__, d: d, compressed: true)}

      {:ok, {<<d::binary-32>>, ^version_byte}} ->
        {:ok, struct(__MODULE__, d: d, compressed: false)}

      {:ok, {<<d::binary>>, version_byte}} when byte_size(d) in [32,33] ->
        {:error, {:invalid_base58_check, version_byte, BSV.network()}}

      _error ->
        {:error, :invalid_wif}
    end
  end

  @doc """
  TODO
  """
  @spec from_wif!(privkey_wif()) :: t()
  def from_wif!(wif) when is_binary(wif) do
    case from_wif(wif) do
      {:ok, privkey} ->
        privkey
      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  TODO
  """
  @spec to_binary(t()) :: privkey_bin()
  def to_binary(%__MODULE__{d: d}, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)
    encode(d, encoding)
  end

  @doc """
  TODO
  """
  @spec to_wif(t()) :: privkey_wif()
  def to_wif(%__MODULE__{d: d, compressed: compressed}) do
    version_byte = @version_bytes[BSV.network()]
    privkey_with_suffix = case compressed do
      true -> <<d::binary, 0x01>>
      false -> d
    end

    B58.encode58_check!(privkey_with_suffix, version_byte)
  end

end
