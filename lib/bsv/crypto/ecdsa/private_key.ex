defmodule BSV.Crypto.ECDSA.PrivateKey do
  @moduledoc """
  ECDSA Private Key module.
  """
  alias BSV.Crypto.ECDSA.PublicKey

  defstruct [:version, :private_key, :parameters, :public_key]

  @typedoc "ECDSA Private Key"
  @type t :: %__MODULE__{
    version: integer,
    private_key: binary,
    parameters: tuple,
    public_key: binary,
  }

  require Record

  @record_info Record.extract(:ECPrivateKey, from_lib: "public_key/asn1/OTP-PUB-KEY.hrl")
  Record.defrecord(:ec_private_key, :ECPrivateKey, @record_info)

  @typedoc "Erlang ECDSA Private Key record"
  @type sequence ::
          record(:ec_private_key,
            version: integer | :undefined,
            privateKey: binary | :undefined,
            parameters: tuple | :asn1_NOVALUE,
            publicKey: binary | :asn1_NOVALUE
          )

  @doc """
  Converts the given Erlang ECDSA key sequence to a ECDSA private key.

  ## Examples

      iex> ecdsa_key = BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> ecdsa_key.__struct__ == BSV.Crypto.ECDSA.PrivateKey
      true
  """
  @spec from_sequence(BSV.Crypto.ECDSA.sequence) :: BSV.Crypto.ECDSA.PrivateKey.t
  def from_sequence(ecdsa_key_sequence) do
    struct(__MODULE__, [
      version: elem(ecdsa_key_sequence, 1),
      private_key: elem(ecdsa_key_sequence, 2),
      parameters: elem(ecdsa_key_sequence, 3),
      public_key: elem(ecdsa_key_sequence, 4)
    ])
  end


  @doc """
  Converts the given ECDSA private key to an Erlang ECDSA key sequence.
  Convert a `t:BSV.Crypto.ECDSA.PrivateKey.t/0` to a `t:BSV.Crypto.ECDSA.PrivateKey.sequence/0`.

  ## Examples

      iex> ecdsa_key = BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...>
      ...> BSV.Crypto.ECDSA.PrivateKey.as_sequence(ecdsa_key)
      ...> |> is_tuple
      true
  """
  @spec as_sequence(BSV.Crypto.ECDSA.PrivateKey.t) :: BSV.Crypto.ECDSA.PrivateKey.sequence
  def as_sequence(ecdsa_key) do
    ec_private_key(
      version: ecdsa_key.version,
      privateKey: ecdsa_key.private_key,
      parameters: ecdsa_key.parameters,
      publicKey: ecdsa_key.public_key
    )
  end


  @doc """
  Returns the public key from the given ECDSA private key.

  ## Examples

      iex> public_key = BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Crypto.ECDSA.PrivateKey.get_public_key
      ...> public_key.__struct__ == BSV.Crypto.ECDSA.PublicKey
      true
  """
  @spec get_public_key(BSV.Crypto.ECDSA.PrivateKey.t) :: BSV.Crypto.ECDSA.PublicKey.t
  def get_public_key(ecdsa_key) do
    %PublicKey{
      point: ecdsa_key.public_key
    }
  end
  
end