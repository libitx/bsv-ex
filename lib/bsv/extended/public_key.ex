defmodule BSV.Extended.PublicKey do
  @moduledoc """
  BIP-32 extended public key module.
  """

  alias BSV.Crypto.ECDSA
  alias BSV.Extended.PrivateKey
  alias BSV.Wallet.KeyPair

  defstruct network: :main,
            version_number: nil,
            key: nil,
            chain_code: <<0>>,
            fingerprint: <<0::32>>,
            depth: 0,
            child_number: 0

  @typedoc "Extended Public Key"
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
    main: <<4, 136, 178, 30>>,
    test: <<4, 53, 135, 207>>
  }

  
  @doc """
  Converts the given extended private key into an extended public key.

  ## Options

  The accepted options are:

  * `:compressed` - Specify whether to compress the generated public key. Defaults to `true`.

  ## Examples

      iex> key = BSV.Extended.PrivateKey.from_seed(BSV.Test.bsv_seed)
      ...> |> BSV.Extended.PublicKey.from_private_key
      ...> key.__struct__ == BSV.Extended.PublicKey
      true
  """
  @spec from_private_key(PrivateKey.t, keyword) :: __MODULE__.t
  def from_private_key(%PrivateKey{} = private_key, options \\ []) do
    {pub_key, _priv_key} = ECDSA.generate_key_pair(private_key: private_key.key)
    public_key = case Keyword.get(options, :compressed, true) do
      true -> ECDSA.PublicKey.compress(pub_key)
      false -> pub_key
    end

    struct(__MODULE__, [
      network: private_key.network,
      version_number: @version_numbers[private_key.network],
      key: public_key,
      chain_code: private_key.chain_code,
      fingerprint: private_key.fingerprint,
      depth: private_key.depth,
      child_number: private_key.child_number
    ])
  end


  @doc """
  Converts the given xpub string to an extended public key.

  ## Examples

      iex> key = "xpub661MyMwAqRbcEiqMJB5yEQavJnZ7XSH4VC5HaiWsw6MBym6Pcr7WpUdfFykNbZL2JDFFYVe1NpUhJwvaZN44d7R3SmPHSjmUiT8pkR8Yrkk"
      ...> |> BSV.Extended.PublicKey.from_string
      ...> key.__struct__ == BSV.Extended.PublicKey
      true
  """
  @spec from_string(String.t) :: __MODULE__.t
  def from_string(<<"xpub", _::binary>> = xpub) do
    {<<
      version::binary-3,
      depth::8,
      fingerprint::binary-4,
      child_number::binary-4,
      chain_code::binary-32,
      private_key::binary
    >>, <<0x04>>} = B58.decode58_check!(xpub)

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
  Converts the given extended public key struct to an encoded xpub string.

  ## Examples

      iex> BSV.Extended.PrivateKey.from_seed(BSV.Test.bsv_seed)
      ...> |> BSV.Extended.PublicKey.from_private_key
      ...> |> BSV.Extended.PublicKey.to_string
      "xpub661MyMwAqRbcEiqMJB5yEQavJnZ7XSH4VC5HaiWsw6MBym6Pcr7WpUdfFykNbZL2JDFFYVe1NpUhJwvaZN44d7R3SmPHSjmUiT8pkR8Yrkk"
  """
  @spec to_string(__MODULE__.t) :: String.t
  def to_string(%__MODULE__{} = public_key) do
    <<checksum::8, version::binary>> = public_key.version_number
    key = ECDSA.PublicKey.compress(public_key.key)
    <<
      version::binary,
      public_key.depth::8,
      public_key.fingerprint::binary,
      public_key.child_number::32,
      public_key.chain_code::binary,
      key::binary
    >>
    |> B58.encode58_check!(checksum)
  end


  @doc """
  Returns the Bitcoin address from the given extended private key.

  ## Examples

      iex> "xpub661MyMwAqRbcEiqMJB5yEQavJnZ7XSH4VC5HaiWsw6MBym6Pcr7WpUdfFykNbZL2JDFFYVe1NpUhJwvaZN44d7R3SmPHSjmUiT8pkR8Yrkk"
      ...> |> BSV.Extended.PublicKey.from_string
      ...> |> BSV.Extended.PublicKey.get_address
      "1DXmF4ZjpYUhPwjrt9SzFou2YbAoaNvLxx"
  """
  @spec get_address(__MODULE__.t) :: String.t
  def get_address(%__MODULE__{} = public_key) do
    KeyPair.get_address(public_key.key)
  end

end