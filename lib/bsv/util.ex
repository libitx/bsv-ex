defmodule BSV.Util do
  @moduledoc """
  Collection of shared helper functions, used frequently throughout the library.
  """

  @typedoc "Binary encoding format"
  @type encoding() :: :base64 | :hex

  @doc """
  Decodes the given binary data using the specified `t:BSV.Util.encoding/0`.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Examples

      iex> BSV.Util.decode("aGVsbG8gd29ybGQ=", :base64)
      {:ok, "hello world"}

      iex> BSV.Util.decode("68656c6c6f20776f726c64", :hex)
      {:ok, "hello world"}
  """
  @spec decode(binary(), encoding()) :: {:ok, binary()} | {:error, term()}
  def decode(data, encoding) do
    case do_decode(data, encoding) do
      {:ok, data} ->
        {:ok, data}
      :error ->
        {:error, {:invalid_encoding, encoding}}
    end
  end

  # Decodes the binary
  defp do_decode(data, :base64), do: Base.decode64(data)
  defp do_decode(data, :hex), do: Base.decode16(data, case: :mixed)
  defp do_decode(data, _), do: {:ok, data}

  @doc """
  Decodes the given binary data using the specified `t:BSV.Util.encoding/0`.

  As `decode/2` but returns the result or raises an exception.
  """
  @spec decode!(binary(), encoding()) :: binary()
  def decode!(data, encoding) do
    case decode(data, encoding) do
      {:ok, data} ->
        data
      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  Encodes the given binary data using the specified `t:BSV.Util.encoding/0`.

  ## Examples

      iex> BSV.Util.encode("hello world", :base64)
      "aGVsbG8gd29ybGQ="

      iex> BSV.Util.encode("hello world", :hex)
      "68656c6c6f20776f726c64"
  """
  @spec encode(binary(), encoding()) :: binary()
  def encode(data, :base64), do: Base.encode64(data)
  def encode(data, :hex), do: Base.encode16(data, case: :lower)
  def encode(data, _), do: data

  @doc """
  Returns a binary containing the specified number of random bytes.
  """
  @spec rand_bytes(integer()) :: binary()
  def rand_bytes(bytes) when is_integer(bytes),
    do: :crypto.strong_rand_bytes(bytes)

  @doc """
  Reverses the bytes of the given binary data.

  ## Examples

      iex> BSV.Util.reverse_bin("abcdefg")
      "gfedcba"

      iex> BSV.Util.reverse_bin(<<1, 2, 3, 0>>)
      <<0, 3, 2, 1>>
  """
  @spec reverse_bin(binary()) :: binary()
  def reverse_bin(data) when is_binary(data) do
    data
    |> :binary.bin_to_list()
    |> Enum.reverse()
    |> :binary.list_to_bin()
  end

end
