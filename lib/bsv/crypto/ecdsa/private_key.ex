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

  @typedoc "Erlang ECDSA Private Key sequence"
  @type sequence :: {
    :ECPrivateKey,
    integer,
    binary,
    tuple,
    binary
  }


  @doc """
  Convert a `t:BSV.Crypto.ECDSA.PrivateKey.sequence/0` to a `t:BSV.Crypto.ECDSA.PrivateKey.t/0`.

  ## Examples

      iex> ecdsa_key = BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> (%BSV.Crypto.ECDSA.PrivateKey{} = ecdsa_key) == ecdsa_key
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
    {
      :ECPrivateKey,
      ecdsa_key.version,
      ecdsa_key.private_key,
      ecdsa_key.parameters,
      ecdsa_key.public_key
    }
  end


  @doc """
  Convert a `t:BSV.Crypto.ECDSA.PrivateKey.t/0` to a `t:BSV.Crypto.ECDSA.PrivateKey.sequence/0`.

  ## Examples

      iex> public_key = BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Crypto.ECDSA.PrivateKey.get_public_key
      ...> (%BSV.Crypto.ECDSA.PublicKey{} = public_key) == public_key
      true
  """
  @spec get_public_key(BSV.Crypto.ECDSA.PrivateKey.t) :: BSV.Crypto.ECDSA.PublicKey.t
  def get_public_key(ecdsa_key) do
    %PublicKey{
      point: ecdsa_key.public_key
    }
  end
  
end