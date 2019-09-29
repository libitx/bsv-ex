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
  Reverses the order of the given binary data.

  ## Examples

      iex> BSV.Util.reverse_bin("abcdefg")
      "gfedcba"
  """
  @spec reverse_bin(binary) :: binary
  def reverse_bin(data) do
    data
    |> :binary.decode_unsigned(:little)
    |> :binary.encode_unsigned(:big)
  end
  
end