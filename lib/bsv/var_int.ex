defmodule BSV.VarInt do
  @moduledoc """
  A VarInt is an integer encoded as a variable length binary value. It is a
  format used throughout Bitcoin to represent the length of binary data in a
  compact form.
  """
  alias BSV.Serializable

  @max_int64 18_446_744_073_709_551_615

  @doc """
  Decodes the given VarInt binary into an integer.

  ## Examples

      iex> BSV.VarInt.decode(<<253, 4, 1>>)
      {:ok, 260}

      iex> BSV.VarInt.decode(<<254, 0, 225, 245, 5>>)
      {:ok, 100_000_000}
  """
  @spec decode(binary()) :: {:ok, integer()} | {:error, term()}
  def decode(data) when is_binary(data) do
    with {:ok, int, _rest} <- parse_int(data), do: {:ok, int}
  end

  @doc """
  TODO
  """
  @spec decode!(binary()) :: integer()
  def decode!(data) when is_binary(data) do
    case decode(data) do
      {:ok, int} ->
        int
      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  TODO

  ## Examples

      iex> BSV.VarInt.decode_binary(<<5, 104, 101, 108, 108, 111>>)
      {:ok, "hello"}
  """
  @spec decode_binary(binary()) :: {:ok, binary()} | {:error, term()}
  def decode_binary(data) when is_binary(data) do
    with {:ok, data, _rest} <- parse_data(data), do: {:ok, data}
  end

  @doc """
  TODO
  """
  @spec decode_binary!(binary()) :: binary()
  def decode_binary!(data) when is_binary(data) do
    case decode_binary(data) do
      {:ok, data} ->
        data
      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  Encodes the given integer into a VarInt binary.

  ## Examples

      iex> BSV.VarInt.encode(260)
      <<253, 4, 1>>

      iex> BSV.VarInt.encode(100_000_000)
      <<254, 0, 225, 245, 5>>
  """
  @spec encode(integer()) :: binary()
  def encode(int)
    when is_integer(int)
    and int >= 0 and int <= @max_int64
  do
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

  @doc """
  TODO
  """
  @spec encode_binary(binary()) :: binary()
  def encode_binary(data)
    when is_binary(data)
    and byte_size(data) <= @max_int64
  do
    size = byte_size(data) |> encode()
    size <> data
  end

  @doc """
  TODO

  ## Examples

      iex> BSV.VarInt.parse_data(<<5, 104, 101, 108, 108, 111, 1, 2, 3>>)
      {:ok, "hello", <<1, 2, 3>>}
  """
  @spec parse_data(binary()) :: {:ok, binary(), binary()} | {:error, term()}
  def parse_data(<<253, int::little-16, data::bytes-size(int), rest::binary>>),
    do: {:ok, data, rest}
  def parse_data(<<254, int::little-32, data::bytes-size(int), rest::binary>>),
    do: {:ok, data, rest}
  def parse_data(<<255, int::little-64, data::bytes-size(int), rest::binary>>),
    do: {:ok, data, rest}
  def parse_data(<<int::integer, data::bytes-size(int), rest::binary>>),
    do: {:ok, data, rest}
  def parse_data(<<_data::binary>>),
    do: {:error, :invalid_varint}

  @doc """
  TODO

  ## Examples

      iex> BSV.VarInt.parse_int(<<5, 104, 101, 108, 108, 111, 1, 2, 3>>)
      {:ok, 5, <<104, 101, 108, 108, 111, 1, 2, 3>>}
  """
  @spec parse_int(binary()) :: {:ok, integer(), binary()} | {:error, term()}
  def parse_int(<<253, int::little-16, rest::binary>>), do: {:ok, int, rest}
  def parse_int(<<254, int::little-32, rest::binary>>), do: {:ok, int, rest}
  def parse_int(<<255, int::little-64, rest::binary>>), do: {:ok, int, rest}
  def parse_int(<<int::integer, rest::binary>>), do: {:ok, int, rest}
  def parse_int(<<_data::binary>>),
    do: {:error, :invalid_varint}

  @doc """
  TODO
  """
  @spec parse_items(binary(), Serializable.t()) ::
    {:ok, list(Serializable.t()), binary()} |
    {:error, term()}
  def parse_items(data, target) when is_binary(data) and is_atom(target) do
    with {:ok, int, data} <- parse_int(data) do
      parse_items(data, int, target)
    end
  end

  # TODO
  defp parse_items(data, num, target, result \\ [])

  defp parse_items(data, num, _target, result) when length(result) == num,
    do: {:ok, Enum.reverse(result), data}

  defp parse_items(data, num, target, result) do
    with {:ok, item, data} <- Serializable.parse(target, data) do
      parse_items(data, num, target, [item | result])
    end
  end

end
