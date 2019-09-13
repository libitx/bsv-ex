defmodule BSV.Crypto.ECDSA.PublicKey do
  @moduledoc """
  ECDSA Private Key module.
  """
  defstruct [:point]

  @typedoc "ECDSA Public Key"
  @type t :: %__MODULE__{
    point: binary,
  }

  @typedoc "Erlang ECDSA Public Key sequence"
  @type point :: {
    :ECPoint,
    binary
  }


  @doc """
  Converts the given public key into a compressed binary

  ## Examples

      iex> public_key = BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Crypto.ECDSA.PrivateKey.get_public_key
      ...>
      ...> BSV.Crypto.ECDSA.PublicKey.compress(public_key)
      ...> |> byte_size
      33
  """
  @spec compress(BSV.Crypto.ECDSA.PublicKey.t | binary) :: binary
  def compress(<<_::size(8), x::size(256), y::size(256)>>) do
    prefix = case rem(y, 2) do
      0 -> 0x02
      _ -> 0x03
    end
    << prefix::size(8), x::size(256) >>
  end

  def compress(%__MODULE__{} = key), do: compress(key.point)

  def compress(<<pubkey::bytes-size(33)>>), do: pubkey


  @doc """
  Converts the given ECDSA public key struct to an Erlang EC point sequence.

  ## Examples

      iex> public_key = BSV.Crypto.ECDSA.PrivateKey.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Crypto.ECDSA.PrivateKey.get_public_key
      ...>
      ...> BSV.Crypto.ECDSA.PublicKey.as_sequence(public_key)
      ...> |> is_tuple
      true
  """
  @spec as_sequence(BSV.Crypto.ECDSA.PublicKey.t) :: BSV.Crypto.ECDSA.Key.sequence
  def as_sequence(public_key) do
    {
      :ECPoint,
      public_key.point
    }
  end
  
end