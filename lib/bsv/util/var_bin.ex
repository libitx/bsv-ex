defmodule BSV.Util.VarBin do
  @moduledoc """
  Module for parsing and serializing variable length binary data as integers,
  binaries and structs.
  """


  @doc """
  Parses the given binary into an integer. Returns a tuple containing the
  decoded integer and any remaining binary data.

  ## Examples

      iex> BSV.Util.VarBin.parse_int(<<253, 4, 1>>)
      {260, ""}

      iex> BSV.Util.VarBin.parse_int(<<254, 0, 225, 245, 5>>)
      {100_000_000, ""}
  """
  @spec parse_int(binary) :: {integer, binary}
  def parse_int(<<253, size::little-16, data::binary>>), do: {size, data}
  def parse_int(<<254, size::little-32, data::binary>>), do: {size, data}
  def parse_int(<<255, size::little-64, data::binary>>), do: {size, data}
  def parse_int(<<size::integer, data::binary>>), do: {size, data}


  @doc """
  Serializes the given integer into a binary.

  ## Examples

      iex> BSV.Util.VarBin.serialize_int(260)
      <<253, 4, 1>>

      iex> BSV.Util.VarBin.serialize_int(100_000_000)
      <<254, 0, 225, 245, 5>>
  """
  @spec serialize_int(integer) :: binary
  def serialize_int(int) when int < 253, do: <<int::integer>>
  def serialize_int(int) when int < 0x10000, do: <<253, int::little-16>>
  def serialize_int(int) when int < 0x100000000, do: <<254, int::little-32>>
  def serialize_int(int), do: <<255, int::little-64>>


  @doc """
  Parses the given binary into a chunk of binary data, using the first byte(s)
  to determing the size of the chunk. Returns a tuple containing the chunk and
  any remaining binary data.

  ## Examples

      iex> BSV.Util.VarBin.parse_bin(<<5, 104, 101, 108, 108, 111>>)
      {"hello", ""}
  """
  @spec parse_bin(binary) :: {binary, binary}
  def parse_bin(data) do
    {size, data} = parse_int(data)
    <<bin::bytes-size(size), data::binary>> = data
    {bin, data}
  end


  @doc """
  Prefixes the given binary with a variable length integer to indicate the size
  of the following binary,

  ## Examples

      iex> BSV.Util.VarBin.serialize_bin("hello")
      <<5, 104, 101, 108, 108, 111>>
  """
  @spec serialize_bin(binary) :: binary
  def serialize_bin(data) do
    size = data
    |> byte_size
    |> serialize_int
    size <> data
  end


  @doc """
  Parses the given binary into a list of parsed structs, using the first byte(s)
  to determine the number of items, and calling the given callback to parse each
  repsective chunk of data.

  Returns a tuple containing a list of parsed items and any remaining binary data.

  ## Examples

      BSV.Util.VarBin.parse_items(data, &BSV.Transaction.Input.parse/1)
      {[
        %BSV.Transaction.Input{},
        %BSV.Transaction.Input{}
      ], ""}
  """
  @spec parse_items(binary, function) :: {list, binary}
  def parse_items(data, callback) when is_function(callback) do
    {size, data} = parse_int(data)
    parse_items(data, size, [], callback)
  end

  defp parse_items(data, 0, items, _cb), do: {Enum.reverse(items), data}

  defp parse_items(data, size, items, cb) do
    {item, data} = cb.(data)
    parse_items(data, size-1, [item | items], cb)
  end


  @doc """
  Serializes the given list of items into a binary, first by prefixing the
  binary with a variable length integer to indicate the number of items, and
  then by calling the given callback to serialize each respective item.

  ## Examples

      [
        %BSV.Transaction.Input{},
        %BSV.Transaction.Input{}
      ]
      |> BSV.Util.VarBin.serialize_items(data, &BSV.Transaction.Input.serialize/1)
      << data >>
  """
  @spec serialize_items(list, function) :: binary
  def serialize_items(items, callback) when is_function(callback) do
    size = length(items) |> serialize_int
    serialize_items(items, size, callback)
  end

  defp serialize_items([], data, _cb), do: data

  defp serialize_items([item | items], data, callback) do
    bin = callback.(item)
    serialize_items(items, data <> bin, callback)
  end

end
