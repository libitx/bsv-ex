defmodule BSV.Crypto.RSA.PrivateKey do
  @moduledoc """
  RSA Private Key module.
  """

  @typedoc "RSA Private Key"
  @type t :: %__MODULE__{
    public_exponent: binary(),
    public_modulus: binary(),
    private_exponent: binary(),
    prime_factor_1: binary(),
    prime_factor_2: binary(),
    exponent_1: binary(),
    exponent_2: binary(),
    crt_coefficient: binary()
  }

  @enforce_keys [:public_exponent, :public_modulus, :private_exponent]
  defstruct [:public_exponent, :public_modulus, :private_exponent,
    :prime_factor_1, :prime_factor_2, :exponent_1, :exponent_2, :crt_coefficient]
  
  
  @doc """
  Convert a native erlang private key to a `t:BSV.Crypto.RSA.PrivateKey.t/0`.

  ## Examples

      iex> private_key = BSV.Crypto.RSA.PrivateKey.from_erlang(BSV.Test.rsa_private_key)
      ...> (%BSV.Crypto.RSA.PrivateKey{} = private_key) == private_key
      true
  """
  @spec from_erlang(list()) :: BSV.Crypto.RSA.private_key
  def from_erlang(params)

  def from_erlang([e, n, d]) do
    struct(__MODULE__, [
      public_exponent:  e,
      public_modulus:   n,
      private_exponent: d
    ])
  end

  def from_erlang([e, n, d, p1, p2, e1, e2, c]) do
    struct(__MODULE__, [
      public_exponent:  e,
      public_modulus:   n,
      private_exponent: d,
      prime_factor_1:   p1,
      prime_factor_2:   p2,
      exponent_1:       e1, 
      exponent_2:       e2, 
      crt_coefficient:  c
    ])
  end


  @doc """
  Convert a `t:BSV.Crypto.RSA.PrivateKey.t/0` to a native erlang private key.

  ## Examples

      iex> private_key = BSV.Crypto.RSA.PrivateKey.from_erlang(BSV.Test.rsa_private_key)
      ...>
      ...> BSV.Crypto.RSA.PrivateKey.to_erlang(private_key)
      ...> |> length
      8
  """
  def to_erlang(private_key) do
    [
      private_key.public_exponent,
      private_key.public_modulus,
      private_key.private_exponent,
      private_key.prime_factor_1,
      private_key.prime_factor_2,
      private_key.exponent_1,
      private_key.exponent_2,
      private_key.crt_coefficient
    ]
    |> Enum.reject(&is_nil/1)
  end
  
end