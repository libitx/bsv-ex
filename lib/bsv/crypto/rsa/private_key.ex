defmodule BSV.Crypto.RSA.PrivateKey do
  @moduledoc """
  RSA Private Key module.
  """
  alias BSV.Crypto.RSA.PublicKey

  defstruct [:version, :public_modulus, :public_exponent, :private_exponent,
    :prime_1, :prime_2, :exponent_1, :exponent_2, :crt_coefficient, :other_prime_info]

  @typedoc "RSA Private Key"
  @type t :: %__MODULE__{
    version: atom,
    public_modulus: integer,
    public_exponent: integer,
    private_exponent: integer,
    prime_1: integer,
    prime_2: integer,
    exponent_1: integer,
    exponent_2: integer,
    crt_coefficient: integer,
    other_prime_info: atom
  }

  
  @doc """
  Convert a native erlang private key to a `t:BSV.Crypto.RSA.PrivateKey.t/0`.

  ## Examples

      iex> private_key = BSV.Crypto.RSA.PrivateKey.from_sequence(BSV.Test.rsa_private_key)
      ...> (%BSV.Crypto.RSA.PrivateKey{} = private_key) == private_key
      true
  """
  @spec from_sequence(tuple) :: BSV.Crypto.RSA.PrivateKey.t
  def from_sequence(rsa_key_sequence) do
    version = case elem(rsa_key_sequence, 1) do
      0 -> :"two-prime"
      _ -> elem(rsa_key_sequence, 1)
    end

    struct(__MODULE__, [
      version:          version,
      public_modulus:   elem(rsa_key_sequence, 2),
      public_exponent:  elem(rsa_key_sequence, 3),
      private_exponent: elem(rsa_key_sequence, 4),
      prime_1:          elem(rsa_key_sequence, 5),
      prime_2:          elem(rsa_key_sequence, 6),
      exponent_1:       elem(rsa_key_sequence, 7),
      exponent_2:       elem(rsa_key_sequence, 8),
      crt_coefficient:  elem(rsa_key_sequence, 9),
      other_prime_info: elem(rsa_key_sequence, 10)
    ])
  end


  @doc """
  Convert a `t:BSV.Crypto.RSA.PrivateKey.t/0` to a native erlang private key.

  ## Examples

      iex> private_key = BSV.Crypto.RSA.PrivateKey.from_sequence(BSV.Test.rsa_private_key)
      ...>
      ...> BSV.Crypto.RSA.PrivateKey.as_sequence(private_key)
      ...> |> is_tuple
      true
  """
  @spec as_sequence(BSV.Crypto.RSA.PrivateKey.t) :: tuple
  def as_sequence(private_key) do
    {
      :RSAPrivateKey,
      private_key.version,
      private_key.public_modulus,
      private_key.public_exponent,
      private_key.private_exponent,
      private_key.prime_1,
      private_key.prime_2,
      private_key.exponent_1,
      private_key.exponent_2,
      private_key.crt_coefficient,
      private_key.other_prime_info
    }
  end


  @doc """
  TODOC
  """
  def get_public_key(private_key) do
    %PublicKey{
      public_modulus:   private_key.public_modulus,
      public_exponent:  private_key.public_exponent
    }
  end
  
end