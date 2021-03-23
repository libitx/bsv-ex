defmodule BSV.Util.ScriptNum do
  @moduledoc """
  Module for encoding and decoding numbers as compact script binaries.
  """
  use Bitwise
  alias BSV.Util

  @doc """
  Decodes the given binary as a number.
  """
  @spec decode(binary) :: integer()
  def decode(<<>>), do: 0
  def decode(bin) when is_binary(bin) do
    bin
    |> Util.reverse_bin()
    |> decode_number()
  end

  defp decode_number(<<n, bin::binary >>)
    when (n &&& 0x80) != 0,
    do: -1 * decode_number(<<n ^^^ 0x80>> <> bin)

  defp decode_number(bin),
    do: :binary.decode_unsigned(bin, :big)


  @doc """
  Encodes the given number as a binary.
  """
  @spec encode(number) :: binary
  def encode(0), do: <<>>
  def encode(n) when is_number(n) do
    <<first, rest::binary>> = abs(n) |> :binary.encode_unsigned(:big)

    prefix = if (first &&& 0x80) == 0x80 do
      <<n < 0 && 0x80 || 0x00, first>>
    else
      <<n < 0 && (first ^^^ 0x80) || first>>
    end

    Util.reverse_bin(prefix <> rest)
  end

  def encode(n, len) when is_number(n) do
    bin = abs(n) |> :binary.encode_unsigned(:big)
    <<first, rest::binary>> = case len - byte_size(bin) do
      pad when pad > 0 ->
        bin <> :binary.copy(<<0>>, pad)
      _ ->
        bin
    end

    prefix = if (first &&& 0x80) == 0x80 do
      <<n < 0 && 0x80 || 0x00, first>>
    else
      <<n < 0 && (first ^^^ 0x80) || first>>
    end

    Util.reverse_bin(prefix <> rest)
  end

end
