defmodule BSV.Crypto.RSA.PrivateKey do
  @moduledoc """
  RSA Private Key module.
  """
  alias BSV.Crypto.RSA.PublicKey

  defstruct [:version, :modulus, :public_exponent, :private_exponent,
    :prime_1, :prime_2, :exponent_1, :exponent_2, :coefficient, :other_prime_info]

  @typedoc "RSA Private Key"
  @type t :: %__MODULE__{
    version: atom,
    modulus: integer,
    public_exponent: integer,
    private_exponent: integer,
    prime_1: integer,
    prime_2: integer,
    exponent_1: integer,
    exponent_2: integer,
    coefficient: integer,
    other_prime_info: atom | tuple
  }

  @typedoc "Erlang RSA Private Key sequence"
  @type sequence :: {
    :RSAPrivateKey,
    atom,
    integer,
    integer,
    integer,
    integer,
    integer,
    integer,
    integer,
    integer,
    atom | tuple
  }

  @typedoc "Erlang RSA Private Key raw binary list"
  @type raw_key :: [binary]

  
  @doc """
  Converts the given Erlang private key sequence to a RSA private key struct.

  ## Examples

      iex> private_key = BSV.Crypto.RSA.PrivateKey.from_sequence(BSV.Test.rsa_key)
      ...> private_key.__struct__ == BSV.Crypto.RSA.PrivateKey
      true
  """
  @spec from_sequence(BSV.Crypto.RSA.PrivateKey.sequence) :: BSV.Crypto.RSA.PrivateKey.t
  def from_sequence(rsa_key_sequence) do
    version = case elem(rsa_key_sequence, 1) do
      0 -> :"two-prime"
      _ -> elem(rsa_key_sequence, 1)
    end

    struct(__MODULE__, [
      version: version,
      modulus: elem(rsa_key_sequence, 2) |> :binary.encode_unsigned,
      public_exponent: elem(rsa_key_sequence, 3) |> :binary.encode_unsigned,
      private_exponent: elem(rsa_key_sequence, 4) |> :binary.encode_unsigned,
      prime_1: elem(rsa_key_sequence, 5) |> :binary.encode_unsigned,
      prime_2: elem(rsa_key_sequence, 6) |> :binary.encode_unsigned,
      exponent_1: elem(rsa_key_sequence, 7) |> :binary.encode_unsigned,
      exponent_2: elem(rsa_key_sequence, 8) |> :binary.encode_unsigned,
      coefficient: elem(rsa_key_sequence, 9) |> :binary.encode_unsigned,
      other_prime_info: elem(rsa_key_sequence, 10)
    ])
  end


  @doc """
  Converts the given RSA private key struct to an Erlang private key sequence.

  ## Examples

      iex> private_key = BSV.Crypto.RSA.PrivateKey.from_sequence(BSV.Test.rsa_key)
      ...>
      ...> BSV.Crypto.RSA.PrivateKey.as_sequence(private_key)
      ...> |> is_tuple
      true
  """
  @spec as_sequence(BSV.Crypto.RSA.PrivateKey.t) :: BSV.Crypto.RSA.PrivateKey.sequence
  def as_sequence(private_key) do
    {
      :RSAPrivateKey,
      private_key.version,
      :binary.decode_unsigned(private_key.modulus),
      :binary.decode_unsigned(private_key.public_exponent),
      :binary.decode_unsigned(private_key.private_exponent),
      :binary.decode_unsigned(private_key.prime_1),
      :binary.decode_unsigned(private_key.prime_2),
      :binary.decode_unsigned(private_key.exponent_1),
      :binary.decode_unsigned(private_key.exponent_2),
      :binary.decode_unsigned(private_key.coefficient),
      private_key.other_prime_info
    }
  end


  @doc """
  Converts the given Erlang private key raw list to a RSA private key struct.
  """
  @spec from_raw(BSV.Crypto.RSA.PrivateKey.raw_key) :: BSV.Crypto.RSA.PrivateKey.t
  def from_raw([e, n, d, p1, p2, e1, e2, c]) do
    struct(__MODULE__, [
      version: :"two-prime",
      modulus: n,
      public_exponent: e,
      private_exponent: d,
      prime_1: p1,
      prime_2: p2,
      exponent_1: e1,
      exponent_2: e2,
      coefficient: c,
      other_prime_info: :asn1_NOVALUE
    ])
  end


  @doc """
  Converts the given RSA private key struct to an Erlang private key raw list.
  """
  @spec as_raw(BSV.Crypto.RSA.PrivateKey.t) :: BSV.Crypto.RSA.PrivateKey.raw_key
  def as_raw(private_key) do
    [
      private_key.public_exponent,
      private_key.modulus,
      private_key.public_exponent,
      private_key.private_exponent,
      private_key.prime_1,
      private_key.prime_2,
      private_key.exponent_1,
      private_key.exponent_2,
      private_key.coefficient
    ]
  end


  @doc """
  Returns the public key from the given RSA private key.

  ## Examples

      iex> public_key = BSV.Crypto.RSA.PrivateKey.from_sequence(BSV.Test.rsa_key)
      ...> |> BSV.Crypto.RSA.PrivateKey.get_public_key
      ...> public_key.__struct__ == BSV.Crypto.RSA.PublicKey
      true
  """
  @spec get_public_key(BSV.Crypto.RSA.PrivateKey.t) :: BSV.Crypto.RSA.PublicKey.t
  def get_public_key(private_key) do
    %PublicKey{
      modulus: private_key.modulus,
      public_exponent: private_key.public_exponent
    }
  end
  
end
