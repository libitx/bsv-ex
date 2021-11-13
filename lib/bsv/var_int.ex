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

  Returns the result in an `:ok` / `:error` tuple pair.

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
  Decodes the given VarInt binary into an integer.

  As `decode/1` but returns the result or raises an exception.
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
  Returns a binary of the length specified by the VarInt in the first bytes of
  the binary. Any remaining bytes are ignored.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Examples

      iex> BSV.VarInt.decode_binary(<<5, 104, 101, 108, 108, 111, 99, 99>>)
      {:ok, "hello"}
  """
  @spec decode_binary(binary()) :: {:ok, binary()} | {:error, term()}
  def decode_binary(data) when is_binary(data) do
    with {:ok, data, _rest} <- parse_data(data), do: {:ok, data}
  end

  @doc """
  Returns a binary of the length specified by the VarInt in the first bytes of
  the binary.

  As `decode_binary/1` but returns the result or raises an exception.
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
  Prepends the given binary with a VarInt representing the length of the binary.

  ## Examples

      iex> BSV.VarInt.encode_binary("hello")
      <<5, 104, 101, 108, 108, 111>>
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
  Parses the given binary, returning a tuple with a binary of the length
  specified by the VarInt in the first bytes of the binary, and a binary of any
  remaining bytes.

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
  Parses the given binary, returning a tuple with an integer decoded from the
  VarInt in the first bytes of the binary, and a binary of any remaining bytes.

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
  Parses the given binary into a list of the length specified by the VarInt in
  the first bytes of the binary. Each item is parsed according to the specified
  `Serializable.t/0`.
  """
  @spec parse_items(binary(), Serializable.t()) ::
    {:ok, list(Serializable.t()), binary()} |
    {:error, term()}
  def parse_items(data, mod) when is_binary(data) and is_atom(mod) do
    with {:ok, int, data} <- parse_int(data) do
      parse_items(data, int, mod)
    end
  end

  # Parses items from the data binary until the correct number have been parsed
  defp parse_items(data, num, mod, result \\ [])

  defp parse_items(data, num, _mod, result) when length(result) == num,
    do: {:ok, Enum.reverse(result), data}

  defp parse_items(data, num, mod, result) do
    with {:ok, item, data} <- Serializable.parse(struct(mod), data) do
      parse_items(data, num, mod, [item | result])
    end
  end

end
