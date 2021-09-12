defmodule BSV.VarInt do
  @moduledoc """
  A VarInt is an integer encoded as a variable length binary value. It is a
  format used throughout Bitcoin to represent the length of binary data in a
  compact form.
  """

  @doc """
  Decodes the given VarInt binary into an integer.

  ## Examples

      iex> BSV.VarInt.decode(<<253, 4, 1>>)
      260

      iex> BSV.VarInt.decode(<<254, 0, 225, 245, 5>>)
      100_000_000
  """
  @spec decode(binary()) :: integer()
  def decode(<<int::integer>>), do: int
  def decode(<<253, int::little-16>>), do: int
  def decode(<<254, int::little-32>>), do: int
  def decode(<<255, int::little-64>>), do: int

  @doc """
  Encodes the given integer into a VarInt binary.

  ## Examples

      iex> BSV.VarInt.encode(260)
      <<253, 4, 1>>

      iex> BSV.VarInt.encode(100_000_000)
      <<254, 0, 225, 245, 5>>
  """
  @spec encode(integer()) :: binary()
  def encode(int) when is_integer(int) do
    case int do
      int when int < 254 ->
        <<int::integer>>
      int when int < 0x10000 ->
        <<253, int::little-16>>
      int when int < 0x100000000 ->
        <<254, int::little-32>>
      int ->
        <<255, int::little-64>>
    end
  end

end
