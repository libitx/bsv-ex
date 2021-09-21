defmodule BSV.ExtKey do
  @moduledoc """
  TODO
  """
  alias BSV.{Hash, PrivKey, PubKey}
  alias Curvy.Point
  import BSV.Util, only: [decode: 2]

  defstruct version: nil,
            depth: 0,
            fingerprint: <<0::32>>,
            child_index: 0,
            chain_code: <<0>>,
            privkey: nil,
            pubkey: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    version: binary(),
    depth: integer(),
    fingerprint: binary(),
    child_index: integer(),
    chain_code: binary(),
    privkey: PrivKey.t() | nil,
    pubkey: PubKey.t()
  }

  @typedoc "TODO"
  @type xprv() :: String.t

  @typedoc "TODO"
  @type xpub() :: String.t

  @typedoc "TODO"
  @type derivation_path() :: String.t

  @privkey_version_bytes %{
    main: <<4, 136, 173, 228>>,
    test: <<4, 53, 131, 148>>
  }

  @pubkey_version_bytes %{
    main: <<4, 136, 178, 30>>,
    test: <<4, 53, 135, 207>>
  }

  @mersenne_prime 2_147_483_647

  defguardp normal?(index) when index >= 0 and index <= @mersenne_prime
  defguardp hardened?(index) when index > @mersenne_prime


  @doc """
  TODO
  """
  @spec from_seed(Mnemonic.seed(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_seed(seed, opts \\ []) when is_binary(seed) do
    encoding = Keyword.get(opts, :encoding)
    version = @privkey_version_bytes[BSV.network()]

    with {:ok, seed} when bit_size(seed) >= 128 and bit_size(seed) <= 512 <- decode(seed, encoding) do
      <<d::binary-32, chain_code::binary-32>> = Hash.sha512_hmac(seed, "Bitcoin seed")
      privkey = PrivKey.from_binary!(d)
      pubkey = PubKey.from_privkey(privkey)

      {:ok, struct(__MODULE__, [
        version: version,
        chain_code: chain_code,
        privkey: privkey,
        pubkey: pubkey
      ])}
    else
      {:ok, seed} ->
        {:error, {:invalid_seed, byte_size(seed)}}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  TODO
  """
  @spec from_seed!(Mnemonic.seed(), keyword()) :: t()
  def from_seed!(seed, opts \\ []) when is_binary(seed) do
    case from_seed(seed, opts) do
      {:ok, extkey} ->
        extkey
      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  TODO
  """
  @spec from_string(xprv() | xpub()) :: {:ok, t()} | {:error, term()}
  def from_string(<<"xprv", _::binary>> = xprv) do
    <<version_byte, prefix::binary>> = version = @privkey_version_bytes[BSV.network()]

    with {:ok, {data, <<^version_byte>>}} when byte_size(data) == 77 <- B58.decode58_check(xprv) do
      <<
        ^prefix::binary-3,
        depth::8,
        fingerprint::binary-4,
        child_index::32,
        chain_code::binary-32,
        0::8,
        d::binary
      >> = data

      privkey = PrivKey.from_binary!(d)
      pubkey = PubKey.from_privkey(privkey)

      {:ok, struct(__MODULE__, [
        version: version,
        depth: depth,
        fingerprint: fingerprint,
        child_index: child_index,
        chain_code: chain_code,
        privkey: privkey,
        pubkey: pubkey
      ])}
    else
      _error ->
        {:error, :invalid_xprv}
    end
  end

  def from_string(<<"xpub", _::binary>> = xprv) do
    <<version_byte, prefix::binary>> = version = @pubkey_version_bytes[BSV.network()]

    with {:ok, {data, <<^version_byte>>}} when byte_size(data) == 77 <- B58.decode58_check(xprv) do
      <<
        ^prefix::binary-3,
        depth::8,
        fingerprint::binary-4,
        child_index::32,
        chain_code::binary-32,
        pubkey::binary
      >> = data

      pubkey = PubKey.from_binary!(pubkey)

      {:ok, struct(__MODULE__, [
        version: version,
        depth: depth,
        fingerprint: fingerprint,
        child_index: child_index,
        chain_code: chain_code,
        pubkey: pubkey
      ])}
    else
      _error ->
        {:error, :invalid_xpub}
    end
  end

  @doc """
  TODO
  """
  @spec from_string!(xprv() | xpub()) :: t()
  def from_string!(data) when is_binary(data) do
    case from_string(data) do
      {:ok, extkey} ->
        extkey
      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end


  @doc """
  TODO
  """
  @spec to_public(t()) :: t()
  def to_public(%__MODULE__{} = extkey) do
    version = @pubkey_version_bytes[BSV.network()]
    struct(extkey, version: version, privkey: nil)
  end

  @doc """
  TODO
  """
  @spec to_string(t()) :: xprv() | xpub()
  def to_string(%__MODULE__{privkey: %PrivKey{}} = extkey) do
    <<version_byte, version::binary>> = @privkey_version_bytes[BSV.network()]
    privkey = PrivKey.to_binary(extkey.privkey)
    <<
      version::binary,
      extkey.depth::8,
      extkey.fingerprint::binary,
      extkey.child_index::32,
      extkey.chain_code::binary,
      0::8,
      privkey::binary
    >>
    |> B58.encode58_check!(version_byte)
  end

  def to_string(%__MODULE__{privkey: nil, pubkey: %PubKey{}} = extkey) do
    <<version_byte, version::binary>> = @pubkey_version_bytes[BSV.network()]
    pubkey = PubKey.to_binary(extkey.pubkey)
    <<
      version::binary,
      extkey.depth::8,
      extkey.fingerprint::binary,
      extkey.child_index::32,
      extkey.chain_code::binary,
      pubkey::binary
    >>
    |> B58.encode58_check!(version_byte)
  end

  @doc """
  TODO
  """
  @spec derive(t(), derivation_path()) :: t()
  def derive(%__MODULE__{} = extkey, path) when is_binary(path) do
    case String.match?(path, ~r/^[mM](\/\d+'?)+/) do
      true ->
        derive_pathlist(extkey, get_pathlist(path))
      false ->
        raise ArgumentError, "Invalid derivation path"
    end
  end

  # Returns a list of integers from the given path string
  defp get_pathlist(<<"m/", path::binary>>), do: {:private, get_pathlist(path)}
  defp get_pathlist(<<"M/", path::binary>>), do: {:public, get_pathlist(path)}

  defp get_pathlist(path) do
    String.split(path, "/")
    |> Enum.map(&path_chunk_to_integer/1)
  end

  # Returns a hardened or normal integer from the given path chunk
  defp path_chunk_to_integer(chunk) do
    case Regex.run(~r/(\d+)(')?$/, chunk) do
      [_, chunk, "'"] ->
        chunk
        |> String.to_integer
        |> Kernel.+(1)
        |> Kernel.+(@mersenne_prime)

      [_, chunk] ->
        String.to_integer(chunk)
    end
  end

  # Iterrates over the pathlist to derive keys
  defp derive_pathlist(key, {_type, []}), do: key

  defp derive_pathlist(%{privkey: %PrivKey{}} = key, {:public, pathlist}),
    do: derive_pathlist(to_public(key), {:public, pathlist})

  defp derive_pathlist(%{privkey: nil}, {:private, _pathlist}),
    do: raise ArgumentError, "Cannot derive private child from public parent"

  defp derive_pathlist(key, {kind, [index | rest]}) do
    with {privkey, pubkey, child_chain} <- derive_key(key, index) do
      struct(__MODULE__, [
        version: key.version,
        depth: key.depth + 1,
        fingerprint: get_fingerprint(key),
        child_index: index,
        chain_code: child_chain,
        privkey: privkey,
        pubkey: pubkey
      ])
      |> derive_pathlist({kind, rest})
    end
  end

  # Derives an extended private or public key from the given index
  defp derive_key(extkey, index) when normal?(index) do
    pubkey = PubKey.to_binary(extkey.pubkey)
    <<pubkey::binary, index::32>>
    |> Hash.sha512_hmac(extkey.chain_code)
    |> derive_keypair(extkey)
  end

  defp derive_key(%{privkey: %PrivKey{}} = extkey, index) when hardened?(index) do
    privkey = PrivKey.to_binary(extkey.privkey)
    <<0::8, privkey::binary, index::32>>
    |> Hash.sha512_hmac(extkey.chain_code)
    |> derive_keypair(extkey)
  end

  defp derive_key(%{privkey: nil}, index) when hardened?(index),
    do: raise ArgumentError, "Cannot derive hardened public child"

  # Derives a key pair
  defp derive_keypair(
    <<derived_key::256, child_chain::binary>>,
    %{privkey: %PrivKey{d: <<d::256>>}}
  ) do
    curve_order = Curvy.Curve.secp256k1()[:n]

    privkey = derived_key
    |> Kernel.+(d)
    |> rem(curve_order)
    |> :binary.encode_unsigned()
    |> pad_bytes()
    |> PrivKey.from_binary!()

    {privkey, PubKey.from_privkey(privkey), child_chain}
  end

  defp derive_keypair(
    <<derived_key::256, child_chain::binary>>,
    %{privkey: nil, pubkey: %PubKey{}} = extkey
  ) do
    point = Curvy.Curve.secp256k1()[:G]
    |> Point.mul(derived_key)
    |> Point.add(extkey.pubkey.point)

    {nil, %PubKey{point: point}, child_chain}
  end

  # Pads bytes with leading zeros if necessary
  defp pad_bytes(bytes) when byte_size(bytes) < 32 do
    padding = 32 - byte_size(bytes)
    :binary.copy(<<0>>, padding) <> bytes
  end

  defp pad_bytes(bytes), do: bytes

  # Gets a fingerpinrt from the extended public key
  defp get_fingerprint(%{pubkey: %PubKey{}} = extkey) do
    <<fingerprint::binary-4, _::binary>> = extkey.pubkey
    |> PubKey.to_binary()
    |> Hash.sha256_ripemd160()
    fingerprint
  end

end
