defmodule BSV.ExtKey do
  @moduledoc """
  An ExtKey is a data structure representing a Bitcoin extended key.

  An extended key is a private or public key that you can derive new keys from
  in a hierarchical deterministic wallet. This implements [BIP-32](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki).

  A master extended key is usually created by passing a `t:BSV.Mnemonic.seed/0`
  to `from_seed/2`. From there, child keys can be derived by passing a
  `t:BSV.ExtKey.derivation_path/0` to `derive/2`.

  Extended private keys can be converted to extended public keys. Using a common
  derivation path, an extended public key can derive the same child public key
  corresponding to the child private key derived from the corresponding parent
  extended private key.

  Extended keys can be serialised using `to_string/1`, to make the key easier to
  store or share.
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

  @typedoc "Extended key struct"
  @type t() :: %__MODULE__{
    version: binary(),
    depth: integer(),
    fingerprint: binary(),
    child_index: integer(),
    chain_code: binary(),
    privkey: PrivKey.t() | nil,
    pubkey: PubKey.t()
  }

  @typedoc "Serialised extended private key (xprv)"
  @type xprv() :: String.t

  @typedoc "Serialised extended public key (xpub)"
  @type xpub() :: String.t

  @typedoc """
  Derivation path

  Derivation paths are used to derive a tree of keys from a common parent known
  as the master extended key. Paths are of the format:

      m/child_index[/child_index...]

      # or

      m/0/1/2'

  The first character `m` represents the master key. A lowercase `m` derives
  a private extended key, an uppercase `M` derives a public extended key.

  The slashes seperate levels in the heirachy and each integer represents the
  child index in that level. A derivation path can be any number of levels deep
  meaning a practically limitless structure of private keys can be derived from
  a single master key.

  When a child index is followed by a `'` character, this denotes a hardened
  child extended private key. It is not possible to derive a hardened child
  extended public key from the same master key.
  """
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
  Generates and returns a new random `t:BSV.ExtKey.t/0`.
  """
  @spec new() :: t()
  def new(), do: from_seed!(:crypto.strong_rand_bytes(64))

  @doc """
  Generates and returns a new `t:BSV.ExtKey.t/0` from the given binary seed.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.
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
  Generates and returns a new `t:BSV.ExtKey.t/0` from the given binary seed.

  As `from_seed/2` but returns the result or raises an exception.
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
  Decodes the given `t:BSV.ExtKey.xprv/0` or `t:BSV.ExtKey.xpub/0` into a
  `t:BSV.ExtKey.t/0`.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Examples

      iex> ExtKey.from_string("xprv9s21ZrQH143K3qcbMJpvTQQQ1zRCPaZjXUD1zPouMDtKY9QQQ9DskzrZ3Cx38GnYXpgY2awCmJfz2QXkpxLN3Pp2PmUddbnrXziFtArpZ5v")
      {:ok, %BSV.ExtKey{
        chain_code: <<178, 208, 232, 46, 183, 65, 27, 66, 14, 172, 46, 66, 222, 84, 220, 98, 70, 249, 25, 3, 50, 209, 218, 236, 96, 142, 211, 79, 59, 166, 41, 106>>,
        child_index: 0,
        depth: 0,
        fingerprint: <<0, 0, 0, 0>>,
        privkey: %BSV.PrivKey{
          compressed: true,
          d: <<219, 231, 28, 56, 5, 76, 224, 63, 77, 224, 151, 38, 251, 136, 26, 87, 11, 186, 248, 245, 84, 56, 152, 11, 115, 35, 148, 32, 239, 241, 174, 90>>
        },
        pubkey: %BSV.PubKey{
          compressed: true,
          point: %Curvy.Point{
            x: 81914731537127506607736443451065612706836400740211682375254444777841949022440,
            y: 84194918502426421393864928067925727177552578328971362502574621746528696729690
          }
        },
        version: <<4, 136, 173, 228>>
      }}

      iex> ExtKey.from_string("xpub661MyMwAqRbcGKh4TLMvpYM8a2Fgo3Hath8cnnDWuZRJQwjYwgY8JoB2tTgiTDdwf4rdGvgUpGhGNH54Ycb8vegrhHVVpdfYCdBBii94CLF")
      {:ok, %BSV.ExtKey{
        chain_code: <<178, 208, 232, 46, 183, 65, 27, 66, 14, 172, 46, 66, 222, 84, 220, 98, 70, 249, 25, 3, 50, 209, 218, 236, 96, 142, 211, 79, 59, 166, 41, 106>>,
        child_index: 0,
        depth: 0,
        fingerprint: <<0, 0, 0, 0>>,
        privkey: nil,
        pubkey: %BSV.PubKey{
          compressed: true,
          point: %Curvy.Point{
            x: 81914731537127506607736443451065612706836400740211682375254444777841949022440,
            y: 84194918502426421393864928067925727177552578328971362502574621746528696729690
          }
        },
        version: <<4, 136, 178, 30>>
      }}
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
  Decodes the given `t:BSV.ExtKey.xprv/0` or `t:BSV.ExtKey.xpub/0` into a
  `t:BSV.ExtKey.t/0`.

  As `from_string/1` but returns the result or raises an exception.
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
  Converts the given `t:BSV.ExtKey.t/0` into a public extended key by dropping
  the `t:BSV.PrivKey.t/0` and setting the appropriate version bytes.
  """
  @spec to_public(t()) :: t()
  def to_public(%__MODULE__{} = extkey) do
    version = @pubkey_version_bytes[BSV.network()]
    struct(extkey, version: version, privkey: nil)
  end

  @doc """
  Encodes the given `t:BSV.ExtKey.t/0` into a `t:BSV.ExtKey.xprv/0` or
  `t:BSV.ExtKey.xpub/0`.

  ## Examples

      iex> ExtKey.to_string(@extkey)
      "xprv9s21ZrQH143K3qcbMJpvTQQQ1zRCPaZjXUD1zPouMDtKY9QQQ9DskzrZ3Cx38GnYXpgY2awCmJfz2QXkpxLN3Pp2PmUddbnrXziFtArpZ5v"

      iex> ExtKey.to_public(@extkey)
      ...> |> ExtKey.to_string()
      "xpub661MyMwAqRbcGKh4TLMvpYM8a2Fgo3Hath8cnnDWuZRJQwjYwgY8JoB2tTgiTDdwf4rdGvgUpGhGNH54Ycb8vegrhHVVpdfYCdBBii94CLF"
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
  Derives a new `t:BSV.ExtKey.t/0` from the given extended key and
  `t:BSV.ExtKey.derivation_path/0`.

  ## Example

      iex> ExtKey.derive(@extkey, "m/44'/0'/0'/0/99")
      %BSV.ExtKey{
        chain_code: <<72, 111, 223, 181, 41, 141, 163, 217, 66, 98, 70, 93, 27, 235, 244, 143, 117, 254, 208, 161, 245, 132, 121, 135, 47, 56, 192, 127, 164, 121, 211, 197>>,
        child_index: 99,
        depth: 5,
        fingerprint: <<235, 254, 153, 73>>,
        privkey: %BSV.PrivKey{
          compressed: true,
          d: <<66, 22, 68, 9, 137, 109, 47, 233, 148, 194, 17, 198, 13, 207, 48, 235, 180, 185, 175, 29, 71, 244, 194, 128, 71, 231, 242, 49, 202, 226, 172, 105>>
        },
        pubkey: %BSV.PubKey{
          compressed: true,
          point: %Curvy.Point{
            x: 48097579158919705714136072738459690665844860244952534154601241870317938609256,
            y: 19116837737882717027311822027213492368729037447422592302419792121787000376066
          }
        },
        version: <<4, 136, 173, 228>>
      }
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
        |> String.to_integer()
        |> Kernel.+(@mersenne_prime + 1)

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
