defmodule BSV.Script do
  @moduledoc """
  TODO
  """
  alias BSV.OpCode
  import BSV.Util, only: [decode: 2, encode: 2]

  defstruct chunks: []

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    chunks: list(atom() | binary())
  }

  @doc """
  TODO
  """
  @spec from_asm(binary()) :: t()
  def from_asm(data) when is_binary(data) do
    chunks = data
    |> String.split(" ")
    |> Enum.map(&parse_asm_chunk/1)

    struct(__MODULE__, chunks: chunks)
  end

  @doc """
  TODO
  """
  @spec from_binary(binary(), keyword()) :: t()
  def from_binary(data, opts \\ []) when is_binary(data) do
    encoding = Keyword.get(opts, :encoding)

    chunks = data
    |> decode(encoding)
    |> parse_bytes()

    struct(__MODULE__, chunks: chunks)
  end

  @doc """
  TODO
  """
  @spec push(t(), atom() | integer() | binary()) :: t()
  def push(%__MODULE__{} = script, data)
    when is_atom(data) or is_integer(data)
  do
    case OpCode.get(data) do
      {opcode, _num} ->
        push_chunk(script, opcode)

      nil ->
        raise "Invalid OpCode: #{data}"
    end
  end

  def push(%__MODULE__{} = script, data) when is_binary(data),
    do: push_chunk(script, data)

  @doc """
  TODO
  """
  @spec to_asm(t()) :: binary()
  def to_asm(%__MODULE__{chunks: chunks}) do
    chunks
    |> Enum.map(&serialize_asm_chunk/1)
    |> Enum.join(" ")
  end

  @doc """
  TODO
  """
  @spec to_binary(t(), keyword()) :: binary()
  def to_binary(%__MODULE__{chunks: chunks}, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)

    chunks
    |> serialize_chunks()
    |> encode(encoding)
  end

  # TODO
  defp parse_asm_chunk(<<"OP_", _::binary>> = chunk),
    do: String.to_existing_atom(chunk)

  defp parse_asm_chunk("-1"), do: :OP_1NEGATE
  defp parse_asm_chunk("0"), do: :OP_0
  defp parse_asm_chunk(chunk), do: decode(chunk, :hex)

  # TODO
  defp parse_bytes(data, chunks \\ [])

  defp parse_bytes(<<>>, chunks), do: Enum.reverse(chunks)

  defp parse_bytes(<<op::integer, data::binary>>, chunks)
    when op > 0 and op < 76
  do
    <<chunk::bytes-size(op), data::binary>> = data
    parse_bytes(data, [chunk | chunks])
  end

  defp parse_bytes(<<76, size::integer, data::binary>>, chunks) do
    <<chunk::bytes-size(size), data::binary>> = data
    parse_bytes(data, [chunk | chunks])
  end

  defp parse_bytes(<<77, size::little-16, data::binary>>, chunks) do
    <<chunk::bytes-size(size), data::binary>> = data
    parse_bytes(data, [chunk | chunks])
  end

  defp parse_bytes(<<78, size::little-32, data::binary>>, chunks) do
    <<chunk::bytes-size(size), data::binary>> = data
    parse_bytes(data, [chunk | chunks])
  end

  defp parse_bytes(<<op::integer, data::binary>>, chunks) do
    case OpCode.get(op) do
      {opcode, _num} ->
        parse_bytes(data, [opcode | chunks])

      nil ->
        raise "Invalid OpCode: #{op}"
    end
  end

  # TODO
  defp push_chunk(%__MODULE__{} = script, data),
    do: update_in(script.chunks, & Enum.concat(&1, [data]))

  # TODO
  defp serialize_asm_chunk(:OP_1NEGATE), do: "-1"
  defp serialize_asm_chunk(chunk) when chunk in [:OP_0, :OP_FALSE], do: "0"
  defp serialize_asm_chunk(chunk) when is_atom(chunk), do: Atom.to_string(chunk)
  defp serialize_asm_chunk(chunk) when is_binary(chunk), do: encode(chunk, :hex)

  # TODO
  defp serialize_chunks(chunks, data \\ <<>>)

  defp serialize_chunks([], data), do: data

  defp serialize_chunks([chunk | chunks], data) when is_atom(chunk) do
    {_opcode, opnum} = OpCode.get(chunk)
    serialize_chunks(chunks, <<data::binary, opnum::integer>>)
  end

  defp serialize_chunks([chunk | chunks], data) when is_binary(chunk) do
    suffix = case byte_size(chunk) do
      op when op > 0 and op < 76 ->
        <<op::integer, chunk::binary>>
      len when len < 0x100 ->
        <<76::integer, len::integer, chunk::binary>>
      len when len < 0x10000 ->
        <<77::integer, len::little-16, chunk::binary>>
      len when len < 0x100000000 ->
        <<78::integer, len::little-32, chunk::binary>>
      op -> << op::integer >>
    end
    serialize_chunks(chunks, data <> suffix)
  end

end
