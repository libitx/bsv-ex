defmodule BSV.Key do
  @moduledoc """
  TODOC
  """

  alias BSV.Crypto.ECDSA
  alias BSV.Crypto.Hash

  defstruct [:private_key, :public_key]

  @type t :: %__MODULE__{
    private_key: binary,
    public_key: binary
  }

  
  @doc """
  TODOC
  """
  def generate_key_pair(options \\ []) do
    ECDSA.generate_key_pair
    |> from_ecdsa_key(options)
  end


  @doc """
  TODOC
  """
  def from_ecdsa_key(key, options \\ []) do
    public_key = case Keyword.get(options, :compressed, true) do
      false -> key.public_key
      true -> compress_public_key(key.public_key)
    end

    struct(__MODULE__, [
      private_key: key.private_key,
      public_key: public_key
    ])
  end

  
  @doc """
  TODOC

  ## Examples

      iex> BSV.Crypto.ECDSA.Key.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Key.from_ecdsa_key
      ...> |> BSV.Key.get_address
      "18cqNbEBxkAttxcZLuH9LWhZJPd1BNu1A5"

      iex> BSV.Crypto.ECDSA.Key.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Key.from_ecdsa_key(compressed: false)
      ...> |> BSV.Key.get_address
      "1N5Cu7YUPQhcwZaQLDT5KnDpRVKzFDJxsf"
  """
  def get_address(key)

  def get_address(key = %__MODULE__{}), do: get_address(key.public_key)

  def get_address(public_key) when is_binary(public_key) do
    Hash.sha256_ripemd160(public_key)
    |> B58.encode58_check!(<<0>>)
  end


  @doc """
  TODOC

  ## Examples

      iex> BSV.Crypto.ECDSA.Key.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Key.from_ecdsa_key
      ...> |> BSV.Key.get_wif
      "KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF"

      iex> BSV.Crypto.ECDSA.Key.from_sequence(BSV.Test.ecdsa_key)
      ...> |> BSV.Key.from_ecdsa_key(compressed: false)
      ...> |> BSV.Key.get_wif
      "5JH9eTJyj6bYopGhBztsDd4XvAbFNQkpZEw8AXYoQePtK1r86nu"
  """
  def get_wif(key = %__MODULE__{}) do
    suffix = case byte_size(key.public_key) do
      33 -> <<0x01>>
      _ -> ""
    end

    (key.private_key <> suffix)
    |> B58.encode58_check!(<<0x80>>)
  end
    

  defp compress_public_key(<< _::size(8), x::size(256), y::size(256) >>) do
    prefix = case rem(y, 2) do
      0 -> 0x02
      _ -> 0x03
    end
    << prefix::size(8), x::size(256) >>
  end
  
end