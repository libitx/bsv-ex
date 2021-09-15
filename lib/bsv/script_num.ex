defmodule BSV.ScriptNum do
  @moduledoc """
  TODO
  """
  use Bitwise
  import BSV.Util, only: [reverse_bin: 1]

  @doc """
  TODO

      iex> BSV.ScriptNum.decode(<<100>>)
      100

      iex> BSV.ScriptNum.decode(<<160, 134, 1>>)
      100_000

      iex> BSV.ScriptNum.decode(<<0, 232, 118, 72, 23>>)
      100_000_000_000

      iex> BSV.ScriptNum.decode(<<65, 65, 54, 208, 140, 94, 210, 191, 59, 160, 72, 175, 230, 220, 174, 186, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0>>)
      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
  """
  @spec decode(binary()) :: integer()
  def decode(<<>>), do: 0
  def decode(bin) when is_binary(bin) do
    bin
    |> reverse_bin()
    |> decode_num()
  end

  # TODO
  defp decode_num(<<n, bin::binary >>)
    when (n &&& 0x80) != 0,
    do: -1 * decode_num(<<bxor(n, 0x80)>> <> bin)

  defp decode_num(bin),
    do: :binary.decode_unsigned(bin, :big)

  @doc """
  TODO

  ## Examples

      iex> BSV.ScriptNum.encode(100)
      <<100>>

      iex> BSV.ScriptNum.encode(100_000)
      <<160, 134, 1>>

      iex> BSV.ScriptNum.encode(100_000_000_000)
      <<0, 232, 118, 72, 23>>

      iex> BSV.ScriptNum.encode(0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141)
      <<65, 65, 54, 208, 140, 94, 210, 191, 59, 160, 72, 175, 230, 220, 174, 186, 254, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 255, 0>>
  """
  @spec encode(number()) :: binary()
  def encode(0), do: <<>>
  def encode(n) when is_number(n) do
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
