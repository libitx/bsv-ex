defmodule BSV.Util do
  @moduledoc """
  A collection of commonly used helper methods.
  """

  @doc """
  Encodes the given binary data with the specified encoding scheme.

  ## Options

  The accepted encoding schemes are:

  * `:base64` - Encodes the binary using Base64
  * `:hex` - Encodes the binary using Base16 (hexidecimal), using lower character case

  ## Examples

      iex> BSV.Util.encode("hello world", :base64)
      "aGVsbG8gd29ybGQ="

      iex> BSV.Util.encode("hello world", :hex)
      "68656c6c6f20776f726c64"
  """
  @spec encode(binary, atom) :: binary
  def encode(data, encoding) do
    case encoding do
      :base64 -> Base.encode64(data)
      :hex    -> Base.encode16(data, case: :lower)
      _       -> data
    end
  end


  @doc """
  Decodes the given binary data with the specified encoding scheme.

  ## Options

  The accepted encoding schemes are:

  * `:base64` - Encodes the binary using Base64
  * `:hex` - Encodes the binary using Base16 (hexidecimal), using lower character case

  ## Examples

      iex> BSV.Util.decode("aGVsbG8gd29ybGQ=", :base64)
      "hello world"

      iex> BSV.Util.decode("68656c6c6f20776f726c64", :hex)
      "hello world"
  """
  @spec decode(binary, atom) :: binary
  def decode(data, encoding) do
    case encoding do
      :base64 -> Base.decode64!(data)
      :hex    -> Base.decode16!(data, case: :mixed)
      _       -> data
    end
  end


  @doc """
  Generates random bits for the given number of bytes.

  ## Examples

      iex> iv = BSV.Util.random_bytes(16)
      ...> bit_size(iv)
      128
  """
  @spec random_bytes(integer) :: binary
  def random_bytes(bytes) when is_integer(bytes) do
    :crypto.strong_rand_bytes(bytes)
  end


  @doc """
  Encodes the given integer into a variable length binary.

  ## Examples

      iex> BSV.Util.varint(250)
      <<250>>

      iex> BSV.Util.varint(9128)
      <<253, 168, 35>>

      iex> BSV.Util.varint(389128)
      <<254, 8, 240, 5, 0>>

      iex> BSV.Util.varint(389128)
      <<254, 8, 240, 5, 0>>

      iex> BSV.Util.varint(51258291273926)
      <<255, 198, 64, 62, 128, 158, 46, 0, 0>>
  """
  def varint(int) when int < 253, do: <<int::integer>>
  def varint(int) when int < 0x10000, do: <<253, int::little-size(16)>>
  def varint(int) when int < 0x100000000, do: <<254, int::little-size(32)>>
  def varint(int), do: <<255, int::little-size(64)>>
  
end