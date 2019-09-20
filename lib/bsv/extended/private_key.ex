defmodule BSV.Extended.PrivateKey do
  @moduledoc """
  BIP-32 extended private key module.
  """
  alias BSV.Crypto.Hash
  alias BSV.Extended.PublicKey
  alias BSV.Util

  defstruct network: :main,
            version_number: nil,
            key: nil,
            chain_code: <<0>>,
            fingerprint: <<0::32>>,
            depth: 0,
            child_number: 0

  @typedoc "Extended Private Key"
  @type t :: %__MODULE__{
    network: atom,
    version_number: binary,
    key: binary,
    chain_code: binary,
    fingerprint: binary,
    depth: integer,
    child_number: integer
  }

  @version_numbers %{
    main: <<4, 136, 173, 228>>,
    test: <<4, 53, 131, 148>>
  }


  @doc """
  Converts the given BIP39 seed to an extended private key.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the given seed with either the `:base64` or `:hex` encoding scheme.
  * `:network` - Specify the intended network. Defaults to `:main`. Set to `:test` for testnet.

  ## Examples

      iex> key = BSV.Extended.PrivateKey.from_seed(BSV.Test.bsv_seed)
      ...> key.__struct__ == BSV.Extended.PrivateKey
      true
  """
  @spec from_seed(binary, keyword) :: __MODULE__.t
  def from_seed(seed, options \\ []) do
    network = Keyword.get(options, :network, :main)
    encoding = Keyword.get(options, :encoding)

    <<private_key::binary-32, chain_code::binary-32>> = seed
    |> Util.decode(encoding)
    |> Hash.hmac(:sha512, "Bitcoin seed")

    struct(__MODULE__, [
      network: network,
      version_number: @version_numbers[network],
      key: private_key,
      chain_code: chain_code
    ])
  end


  @doc """
  Converts the given xprv string to an extended private key.

  ## Examples

      iex> key = "xprv9s21ZrQH143K2EktC9YxsGeBkkid7yZD7y9gnL7GNkpD6xmF5JoGGgKBQk2tQtA9vAnEfZ6mxhhmULRN5zNwrnDsmX38VGFyBJuhxQPGMsS"
      ...> |> BSV.Extended.PrivateKey.from_string
      ...> key.__struct__ == BSV.Extended.PrivateKey
      true
  """
  @spec from_string(String.t) :: __MODULE__.t
  def from_string(<<"xprv", _::binary>> = xprv) do
    {<<
      version::binary-3,
      depth::8,
      fingerprint::binary-4,
      child_number::binary-4,
      chain_code::binary-32,
      0::8,
      private_key::binary
    >>, <<0x04>>} = B58.decode58_check!(xprv)

    network = @version_numbers
    |> Enum.find(fn {_k, v} -> v == <<4, version::binary>> end)
    |> elem(0)

    struct(__MODULE__, [
      network: network,
      version_number: @version_numbers[network],
      key: private_key,
      chain_code: chain_code,
      fingerprint: fingerprint,
      depth: depth,
      child_number: child_number
    ])
  end


  @doc """
  Converts the given extended private key struct to an encoded xprv string.

  ## Examples

      iex> BSV.Extended.PrivateKey.from_seed(BSV.Test.bsv_seed)
      ...> |> BSV.Extended.PrivateKey.to_string
      "xprv9s21ZrQH143K2EktC9YxsGeBkkid7yZD7y9gnL7GNkpD6xmF5JoGGgKBQk2tQtA9vAnEfZ6mxhhmULRN5zNwrnDsmX38VGFyBJuhxQPGMsS"
  """
  @spec to_string(__MODULE__.t) :: String.t
  def to_string(%__MODULE__{} = private_key) do
    <<v::8, version::binary>> = private_key.version_number
    <<
      version::binary,
      private_key.depth::8,
      private_key.fingerprint::binary,
      private_key.child_number::32,
      private_key.chain_code::binary,
      0::8,
      private_key.key::binary
    >>
    |> B58.encode58_check!(v)
  end


  @doc """
  Returns the extended public key from the given extended private key.

  ## Examples

      iex> key = BSV.Extended.PrivateKey.from_seed(BSV.Test.bsv_seed)
      ...> |> BSV.Extended.PrivateKey.get_public_key
      ...> key.__struct__ == BSV.Extended.PublicKey
      true
  """
  @spec get_public_key(__MODULE__.t, keyword) :: PublicKey.t
  def get_public_key(%__MODULE__{} = private_key, options \\ []) do
    PublicKey.from_private_key(private_key, options)
  end


  @doc """
  Returns the Bitcoin address from the given extended private key.

  ## Examples

      iex> BSV.Extended.PrivateKey.from_seed(BSV.Test.bsv_seed)
      ...> |> BSV.Extended.PrivateKey.get_address
      "1DXmF4ZjpYUhPwjrt9SzFou2YbAoaNvLxx"
  """
  @spec get_address(__MODULE__.t) :: String.t
  def get_address(%__MODULE__{} = private_key) do
    get_public_key(private_key)
    |> PublicKey.get_address
  end
  
end