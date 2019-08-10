defmodule BSV.Crypto.RSA.PublicKey do
  @moduledoc """
  RSA Public Key module.
  """

  @typedoc "RSA Public Key"
  @type t :: %__MODULE__{
    public_exponent: binary(),
    public_modulus: binary()
  }

  @enforce_keys [:public_exponent, :public_modulus]
  defstruct [:public_exponent, :public_modulus]
  
  
  @doc """
  Convert a native erlang public key to a `t:BSV.Crypto.RSA.PublicKey.t/0`.

  ## Examples

      iex> public_key = BSV.Crypto.RSA.PublicKey.from_erlang(BSV.Test.rsa_public_key)
      ...> (%BSV.Crypto.RSA.PublicKey{} = public_key) == public_key
      true
  """
  @spec from_erlang(list()) :: BSV.Crypto.RSA.public_key
  def from_erlang([e, n]) do
    struct(__MODULE__, [
      public_exponent:  e,
      public_modulus:   n
    ])
  end


  @doc """
  Convert a `t:BSV.Crypto.RSA.PublicKey.t/0` to a native erlang public key.

  ## Examples

      iex> public_key = BSV.Crypto.RSA.PublicKey.from_erlang(BSV.Test.rsa_public_key)
      ...>
      ...> BSV.Crypto.RSA.PublicKey.to_erlang(public_key)
      ...> |> length
      2
  """
  def to_erlang(public_key) do
    [
      public_key.public_exponent,
      public_key.public_modulus
    ]
  end
  
end