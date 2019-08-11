defmodule BSV.Crypto.RSA.PublicKey do
  @moduledoc """
  RSA Public Key module.
  """

  defstruct [:version, :public_exponent, :public_modulus]

  @typedoc "RSA Public Key"
  @type t :: %__MODULE__{
    public_modulus: binary,
    public_exponent: binary
  }
  
  
  @doc """
  Convert a native erlang public key to a `t:BSV.Crypto.RSA.PublicKey.t/0`.

  ## Examples

      iex> public_key = BSV.Crypto.RSA.PublicKey.from_sequence(BSV.Test.rsa_public_key)
      ...> (%BSV.Crypto.RSA.PublicKey{} = public_key) == public_key
      true
  """
  @spec from_sequence(tuple) :: BSV.Crypto.RSA.PublicKey.t
  def from_sequence(rsa_key_sequence) do
    struct(__MODULE__, [
      public_modulus: elem(rsa_key_sequence, 1),
      public_exponent: elem(rsa_key_sequence, 2)
    ])
  end


  @doc """
  Convert a `t:BSV.Crypto.RSA.PublicKey.t/0` to a native erlang public key.

  ## Examples

      iex> public_key = BSV.Crypto.RSA.PublicKey.from_sequence(BSV.Test.rsa_public_key)
      ...>
      ...> BSV.Crypto.RSA.PublicKey.as_sequence(public_key)
      ...> |> is_tuple
      true
  """
  @spec as_sequence(BSV.Crypto.RSA.PublicKey.t) :: tuple
  def as_sequence(public_key) do
    {
      :RSAPublicKey,
      public_key.public_modulus,
      public_key.public_exponent
    }
  end


  
  
end