defmodule BSV.Crypto.ECDSA.Key do
  @moduledoc """
  ECDSA Key module.
  """
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

  @typedoc "Erlang ECDSA Public Key sequence"
  @type point :: {
    :ECPoint,
    binary
  }


  @doc """
  Convert a `t:BSV.Crypto.ECDSA.Key.sequence/0` to a `t:BSV.Crypto.ECDSA.Key.t/0`.

  ## Examples

      iex> ecdsa_key = BSV.Crypto.ECDSA.Key.from_sequence(BSV.Test.ecdsa_key)
      ...> (%BSV.Crypto.ECDSA.Key{} = ecdsa_key) == ecdsa_key
      true
  """
  @spec from_sequence(BSV.Crypto.ECDSA.sequence) :: BSV.Crypto.ECDSA.Key.t
  def from_sequence(ecdsa_key_sequence) do
    struct(__MODULE__, [
      version: elem(ecdsa_key_sequence, 1),
      private_key: elem(ecdsa_key_sequence, 2),
      parameters: elem(ecdsa_key_sequence, 3),
      public_key: elem(ecdsa_key_sequence, 4)
    ])
  end


  @doc """
  Convert a `t:BSV.Crypto.ECDSA.Key.t/0` to a `t:BSV.Crypto.ECDSA.Key.sequence/0`.

  ## Examples

      iex> ecdsa_key = BSV.Crypto.ECDSA.Key.from_sequence(BSV.Test.ecdsa_key)
      ...>
      ...> BSV.Crypto.ECDSA.Key.as_sequence(ecdsa_key)
      ...> |> is_tuple
      true
  """
  @spec as_sequence(BSV.Crypto.ECDSA.Key.t) :: BSV.Crypto.ECDSA.Key.sequence
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
  Convert a `t:BSV.Crypto.ECDSA.Key.t/0` to a `t:BSV.Crypto.ECDSA.Key.sequence/0`.

  ## Examples

      iex> ecdsa_key = BSV.Crypto.ECDSA.Key.from_sequence(BSV.Test.ecdsa_key)
      ...>
      ...> BSV.Crypto.ECDSA.Key.get_point(ecdsa_key)
      ...> |> is_tuple
      true
  """
  @spec get_point(BSV.Crypto.ECDSA.Key.t) :: BSV.Crypto.ECDSA.Key.point
  def get_point(ecdsa_key) do
    {
      :ECPoint,
      ecdsa_key.public_key
    }
  end
  
end