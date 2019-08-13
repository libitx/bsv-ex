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
  
  
  @doc """
  Convert a t:BSV.Crypto.RSA.PublicKey.sequence/0` to a `t:BSV.Crypto.RSA.PublicKey.t/0`.

  ## Examples

      iex> public_key = BSV.Crypto.RSA.PublicKey.from_sequence(BSV.Test.rsa_public_key)
      ...> (%BSV.Crypto.RSA.PublicKey{} = public_key) == public_key
      true
  """
  @spec from_sequence(BSV.Crypto.RSA.PublicKey.sequence) :: BSV.Crypto.RSA.PublicKey.t
  def from_sequence(rsa_key_sequence) do
    struct(__MODULE__, [
      modulus: elem(rsa_key_sequence, 1),
      public_exponent: elem(rsa_key_sequence, 2)
    ])
  end


  @doc """
  Convert a `t:BSV.Crypto.RSA.PublicKey.t/0` to a t:BSV.Crypto.RSA.PublicKey.sequence/0`.

  ## Examples

      iex> public_key = BSV.Crypto.RSA.PublicKey.from_sequence(BSV.Test.rsa_public_key)
      ...>
      ...> BSV.Crypto.RSA.PublicKey.as_sequence(public_key)
      ...> |> is_tuple
      true
  """
  @spec as_sequence(BSV.Crypto.RSA.PublicKey.t) :: BSV.Crypto.RSA.PublicKey.sequence
  def as_sequence(public_key) do
    {
      :RSAPublicKey,
      public_key.modulus,
      public_key.public_exponent
    }
  end


  
  
end