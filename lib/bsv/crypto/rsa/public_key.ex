defmodule BSV.Crypto.RSA.PublicKey do
  @moduledoc """
  RSA Public Key module.
  """

  defstruct [:modulus, :public_exponent]

  @typedoc "RSA Public Key"
  @type t :: %__MODULE__{
    modulus: integer,
    public_exponent: integer
  }

  @typedoc "Erlang RSA Public Key sequence"
  @type sequence :: {
    :RSAPublicKey,
    integer,
    integer
  }

  @typedoc "Erlang RSA Public Key raw binary list"
  @type raw_key :: [binary]
  
  
  @doc """
  Converts the given Erlang public key sequence to a RSA public key struct.

  ## Examples

      iex> public_key_sequence = BSV.Crypto.RSA.PrivateKey.from_sequence(BSV.Test.rsa_key)
      ...> |> BSV.Crypto.RSA.PrivateKey.get_public_key
      ...> |> BSV.Crypto.RSA.PublicKey.as_sequence
      ...>
      ...> public_key = BSV.Crypto.RSA.PublicKey.from_sequence(public_key_sequence)
      ...> public_key.__struct__ == BSV.Crypto.RSA.PublicKey
      true
  """
  @spec from_sequence(BSV.Crypto.RSA.PublicKey.sequence) :: BSV.Crypto.RSA.PublicKey.t
  def from_sequence(rsa_key_sequence) do
    struct(__MODULE__, [
      modulus: elem(rsa_key_sequence, 1) |> :binary.encode_unsigned,
      public_exponent: elem(rsa_key_sequence, 2) |> :binary.encode_unsigned
    ])
  end


  @doc """
  Converts the given RSA public key struct to an Erlang public key sequence.=

  ## Examples

      iex> public_key = BSV.Crypto.RSA.PrivateKey.from_sequence(BSV.Test.rsa_key)
      ...> |> BSV.Crypto.RSA.PrivateKey.get_public_key
      ...>
      ...> BSV.Crypto.RSA.PublicKey.as_sequence(public_key)
      ...> |> is_tuple
      true
  """
  @spec as_sequence(BSV.Crypto.RSA.PublicKey.t) :: BSV.Crypto.RSA.PublicKey.sequence
  def as_sequence(public_key) do
    {
      :RSAPublicKey,
      :binary.decode_unsigned(public_key.modulus),
      :binary.decode_unsigned(public_key.public_exponent)
    }
  end


  @doc """
  Converts the given Erlang public key raw list to a RSA public key struct.
  """
  @spec from_raw(BSV.Crypto.RSA.PublicKey.raw_key) :: BSV.Crypto.RSA.PublicKey.t
  def from_raw([e, n]) do
    struct(__MODULE__, [
      modulus: n,
      public_exponent: e
    ])
  end


  @doc """
  Converts the given RSA private key struct to an Erlang private key raw list.
  """
  @spec as_raw(BSV.Crypto.RSA.PrivateKey.t) :: BSV.Crypto.RSA.PrivateKey.raw_key
  def as_raw(private_key) do
    [
      private_key.public_exponent,
      private_key.modulus
    ]
  end
  
end
