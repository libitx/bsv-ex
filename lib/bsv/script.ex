defmodule BSV.Script do
  @moduledoc """
  Module for parsing, serialising and building Scripts.

  Script is the scripting language built into Bitcoin. Transaction outputs each
  contain a "locking script" which lock a number of satoshis. Transaction inputs
  contain an "unlocking script" which unlock the satoshis contained in a
  previous output. Both the unlocking script and previous locking script are
  concatenated in the following order:

      unlocking_script <> locking_script

  The entire script is evaluated and if it returns a truthy value, the output is
  unlocked and spent.
  """
  alias BSV.{OpCode, ScriptNum}
  import BSV.Util, only: [decode: 2, decode!: 2, encode: 2]

  defstruct chunks: [], coinbase: nil

  @typedoc "Script struct"
  @type t() :: %__MODULE__{
    chunks: list(chunk()),
    coinbase: nil | binary()
  }

  @typedoc "Script chunk"
  @type chunk() :: atom() | binary()

  @typedoc "Coinbase data"
  @type coinbase_data() :: %{
    height: integer(),
    data: binary(),
    nonce: binary()
  }

  @doc """
  Parses the given ASM encoded string into a `t:BSV.Script.t/0`.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Examples

      iex> Script.from_asm("OP_DUP OP_HASH160 5ae866af9de106847de6111e5f1faa168b2be689 OP_EQUALVERIFY OP_CHECKSIG")
      {:ok, %Script{chunks: [
        :OP_DUP,
        :OP_HASH160,
        <<90, 232, 102, 175, 157, 225, 6, 132, 125, 230, 17, 30, 95, 31, 170, 22, 139, 43, 230, 137>>,
        :OP_EQUALVERIFY,
        :OP_CHECKSIG
      ]}}
  """
  @spec from_asm(binary()) :: {:ok, t()} | {:error, term()}
  def from_asm(data) when is_binary(data) do
    chunks = data
    |> String.split(" ")
    |> Enum.map(&parse_asm_chunk/1)

    {:ok, struct(__MODULE__, chunks: chunks)}
  rescue
    _error ->
      {:error, {:invalid_encoding, :asm}}
  end

  @doc """
  Parses the given ASM encoded string into a `t:BSV.Script.t/0`.

  As `from_asm/1` but returns the result or raises an exception.
  """
  @spec from_asm!(binary()) :: t()
  def from_asm!(data) when is_binary(data) do
    case from_asm(data) do
      {:ok, script} ->
        script
      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  Parses the given binary into a `t:BSV.Script.t/0`.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      iex> Script.from_binary("76a9145ae866af9de106847de6111e5f1faa168b2be68988ac", encoding: :hex)
      {:ok, %Script{chunks: [
        :OP_DUP,
        :OP_HASH160,
        <<90, 232, 102, 175, 157, 225, 6, 132, 125, 230, 17, 30, 95, 31, 170, 22, 139, 43, 230, 137>>,
        :OP_EQUALVERIFY,
        :OP_CHECKSIG
      ]}}
  """
  @spec from_binary(binary(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_binary(data, opts \\ []) when is_binary(data) do
    encoding = Keyword.get(opts, :encoding)

    with {:ok, data} <- decode(data, encoding),
         {:ok, chunks} <- parse_bytes(data)
    do
      {:ok, struct(__MODULE__, chunks: chunks)}
    end
  end

  @doc """
  Parses the given binary into a `t:BSV.Script.t/0`.

  As `from_binary/2` but returns the result or raises an exception.
  """
  @spec from_binary!(binary(), keyword()) :: t()
  def from_binary!(data, opts \\ []) when is_binary(data) do
    case from_binary(data, opts) do
      {:ok, script} ->
        script
      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  Returns formatted coinbase data from the given Script.
  """
  @spec get_coinbase_data(t()) :: coinbase_data() | binary()
  def get_coinbase_data(%__MODULE__{coinbase: data}) when is_binary(data) do
    case data do
      <<n::integer, blknum::bytes-size(n), d::integer, data::bytes-size(d), nonce::binary>> ->
        %{
          block: BSV.ScriptNum.decode(blknum),
          data: data,
          nonce: nonce
        }
      data ->
        data
    end
  end

  @doc """
  Pushes a chunk into the `t:BSV.Script.t/0`.

  The chunk can be any binary value, `t:BSV.OpCode.t/0` or `t:integer/0`.
  Integer values will be encoded as a `t:BSV.ScriptNum.t/0`.

  ## Examples

      iex> %Script{}
      ...> |> Script.push(:OP_FALSE)
      ...> |> Script.push(:OP_RETURN)
      ...> |> Script.push("Hello world!")
      ...> |> Script.push(2021)
      %Script{chunks: [
        :OP_FALSE,
        :OP_RETURN,
        "Hello world!",
        <<229, 7>>
      ]}
  """
  @spec push(t(), atom() | integer() | binary()) :: t()
  def push(%__MODULE__{} = script, data) when is_atom(data) do
    opcode = OpCode.to_atom!(data)
    push_chunk(script, opcode)
  end

  def push(%__MODULE__{} = script, data) when is_binary(data),
    do: push_chunk(script, data)

  def push(%__MODULE__{} = script, data) when data in 0..16,
    do: push_chunk(script, String.to_atom("OP_#{ data }"))

  def push(%__MODULE__{} = script, data) when is_integer(data),
    do: push_chunk(script, ScriptNum.encode(data))

  @doc """
  Returns the size of the Script in bytes.

  ## Examples

      iex> Script.size(@p2pkh_script)
      25
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{} = script),
    do: to_binary(script) |> byte_size()

  @doc """
  Serialises the given `t:BSV.Script.t/0` into an ASM encoded string.

  ## Examples

      iex> Script.to_asm(@p2pkh_script)
      "OP_DUP OP_HASH160 5ae866af9de106847de6111e5f1faa168b2be689 OP_EQUALVERIFY OP_CHECKSIG"
  """
  @spec to_asm(t()) :: binary()
  def to_asm(%__MODULE__{chunks: chunks}) do
    chunks
    |> Enum.map(&serialize_asm_chunk/1)
    |> Enum.join(" ")
  end

  @doc """
  Serialises the given `t:BSV.Script.t/0` into a binary.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally encode the binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      iex> Script.to_binary(@p2pkh_script, encoding: :hex)
      "76a9145ae866af9de106847de6111e5f1faa168b2be68988ac"
  """
  @spec to_binary(t(), keyword()) :: binary()
  def to_binary(script, opts \\ [])

  def to_binary(%__MODULE__{chunks: [], coinbase: data}, opts)
    when is_binary(data)
  do
    encoding = Keyword.get(opts, :encoding)
    encode(data, encoding)
  end

  def to_binary(%__MODULE__{chunks: chunks}, opts) do
    encoding = Keyword.get(opts, :encoding)

    chunks
    |> serialize_chunks()
    |> encode(encoding)
  end

  # Parses the ASM chunk into a Script chunk
  defp parse_asm_chunk(<<"OP_", _::binary>> = chunk),
    do: String.to_existing_atom(chunk)

  defp parse_asm_chunk("-1"), do: :OP_1NEGATE
  defp parse_asm_chunk("0"), do: :OP_0
  defp parse_asm_chunk(chunk), do: decode!(chunk, :hex)

  # Parses the given binary into a list of Script chunks
  defp parse_bytes(data, chunks \\ [])

  defp parse_bytes(<<>>, chunks), do: {:ok, Enum.reverse(chunks)}

  defp parse_bytes(<<size::integer, chunk::bytes-size(size), data::binary>>, chunks)
    when size > 0 and size < 76
  do
    parse_bytes(data, [chunk | chunks])
  end

  defp parse_bytes(<<76, size::integer, chunk::bytes-size(size), data::binary>>, chunks) do
    parse_bytes(data, [chunk | chunks])
  end

  defp parse_bytes(<<77, size::little-16, chunk::bytes-size(size), data::binary>>, chunks) do
    parse_bytes(data, [chunk | chunks])
  end

  defp parse_bytes(<<78, size::little-32, chunk::bytes-size(size), data::binary>>, chunks) do
    parse_bytes(data, [chunk | chunks])
  end

  defp parse_bytes(<<op::integer, data::binary>>, chunks) do
    opcode = OpCode.to_atom!(op)
    parse_bytes(data, [opcode | chunks])
  end

  # Pushes the chunk onto the script
  defp push_chunk(%__MODULE__{} = script, data),
    do: update_in(script.chunks, & Enum.concat(&1, [data]))

  # Serilises the Script chunk as an ASM chunk
  defp serialize_asm_chunk(:OP_1NEGATE), do: "-1"
  defp serialize_asm_chunk(chunk) when chunk in [:OP_0, :OP_FALSE], do: "0"
  defp serialize_asm_chunk(chunk) when is_atom(chunk), do: Atom.to_string(chunk)
  defp serialize_asm_chunk(chunk) when is_binary(chunk), do: encode(chunk, :hex)

  # Serilises the list of Script chunks as a binary
  defp serialize_chunks(chunks, data \\ <<>>)

  defp serialize_chunks([], data), do: data

  defp serialize_chunks([chunk | chunks], data) when is_atom(chunk) do
    opcode = OpCode.to_integer(chunk)
    serialize_chunks(chunks, <<data::binary, opcode::integer>>)
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
