defmodule BSV.ScriptNum do
  @moduledoc """
  A ScriptNum is an integer encoded as little-endian variable-length integers
  with the most significant bit determining the sign of the integer.

  Used in Bitcoin Script for arithmetic operations.
  """
  use Bitwise
  import BSV.Util, only: [reverse_bin: 1]

  @doc """
  Decodes the given ScriptNum binary into an integer.

  ## Examples

      iex> BSV.ScriptNum.decode(<<100>>)
      100

      iex> BSV.ScriptNum.decode(<<160, 134, 1>>)
      100_000

      iex> BSV.ScriptNum.decode(<<0, 232, 118, 72, 23>>)
      100_000_000_000
  """
  @spec decode(binary()) :: integer()
  def decode(<<>>), do: 0
  def decode(bin) when is_binary(bin) do
    bin
    |> reverse_bin()
    |> decode_num()
  end

  # Decodes the number
  defp decode_num(<<n, bin::binary >>)
    when (n &&& 0x80) != 0,
    do: -1 * decode_num(<<bxor(n, 0x80)>> <> bin)

  defp decode_num(bin),
    do: :binary.decode_unsigned(bin, :big)

  @doc """
  Encodes the given integer into a ScriptNum binary.

  ## Examples

      iex> BSV.ScriptNum.encode(100)
      <<100>>

      iex> BSV.ScriptNum.encode(100_000)
      <<160, 134, 1>>

      iex> BSV.ScriptNum.encode(100_000_000_000)
      <<0, 232, 118, 72, 23>>
  """
  @spec encode(number()) :: binary()
  def encode(0), do: <<>>
  def encode(n) when is_integer(n) do
    <<first, rest::binary>> = abs(n)
    |> :binary.encode_unsigned(:big)

    prefix = if (first &&& 0x80) == 0x80 do
      <<n < 0 && 0x80 || 0x00, first>>
    else
      <<n < 0 && bxor(first, 0x80) || first>>
    end

    reverse_bin(prefix <> rest)
  end

end
