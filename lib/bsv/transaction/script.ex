defmodule BSV.Transaction.Script do
  @moduledoc """
  Module for the construction, parsing and serialization of transactions to and
  from binary data.

  ## Examples

      iex> %BSV.Transaction.Script{}
      ...> |> BSV.Transaction.Script.push(:OP_0)
      ...> |> BSV.Transaction.Script.push(:OP_RETURN)
      ...> |> BSV.Transaction.Script.push("hello world")
      ...> |> BSV.Transaction.Script.serialize(encoding: :hex)
      "006a0b68656c6c6f20776f726c64"

      iex> "006a0b68656c6c6f20776f726c64"
      ...> |> BSV.Transaction.Script.parse(encoding: :hex)
      %BSV.Transaction.Script{
        chunks: [:OP_0, :OP_RETURN, "hello world"]
      }
  """
  alias BSV.Util

  defstruct chunks: []

  @typedoc "Bitcoin Script"
  @type t :: %__MODULE__{
    chunks: list
  }

  @op_codes %{
    # push value
    OP_FALSE: 0,
    OP_0: 0,
    OP_PUSHDATA1: 76,
    OP_PUSHDATA2: 77,
    OP_PUSHDATA4: 78,
    OP_1NEGATE: 79,
    OP_RESERVED: 80,
    OP_TRUE: 81,
    OP_1: 81,
    OP_2: 82,
    OP_3: 83,
    OP_4: 84,
    OP_5: 85,
    OP_6: 86,
    OP_7: 87,
    OP_8: 88,
    OP_9: 89,
    OP_10: 90,
    OP_11: 91,
    OP_12: 92,
    OP_13: 93,
    OP_14: 94,
    OP_15: 95,
    OP_16: 96,

    # control
    OP_NOP: 97,
    OP_VER: 98,
    OP_IF: 99,
    OP_NOTIF: 100,
    OP_VERIF: 101,
    OP_VERNOTIF: 102,
    OP_ELSE: 103,
    OP_ENDIF: 104,
    OP_VERIFY: 105,
    OP_RETURN: 106,

    # stack ops
    OP_TOALTSTACK: 107,
    OP_FROMALTSTACK: 108,
    OP_2DROP: 109,
    OP_2DUP: 110,
    OP_3DUP: 111,
    OP_2OVER: 112,
    OP_2ROT: 113,
    OP_2SWAP: 114,
    OP_IFDUP: 115,
    OP_DEPTH: 116,
    OP_DROP: 117,
    OP_DUP: 118,
    OP_NIP: 119,
    OP_OVER: 120,
    OP_PICK: 121,
    OP_ROLL: 122,
    OP_ROT: 123,
    OP_SWAP: 124,
    OP_TUCK: 125,

    # splice ops
    OP_CAT: 126,
    OP_SPLIT: 127,
    OP_NUM2BIN: 128,
    OP_BIN2NUM: 129,
    OP_SIZE: 130,

    # bit logic
    OP_INVERT: 131,
    OP_AND: 132,
    OP_OR: 133,
    OP_XOR: 134,
    OP_EQUAL: 135,
    OP_EQUALVERIFY: 136,
    OP_RESERVED1: 137,
    OP_RESERVED2: 138,

    # numeric
    OP_1ADD: 139,
    OP_1SUB: 140,
    OP_2MUL: 141,
    OP_2DIV: 142,
    OP_NEGATE: 143,
    OP_ABS: 144,
    OP_NOT: 145,
    OP_0NOTEQUAL: 146,

    OP_ADD: 147,
    OP_SUB: 148,
    OP_MUL: 149,
    OP_DIV: 150,
    OP_MOD: 151,
    OP_LSHIFT: 152,
    OP_RSHIFT: 153,

    OP_BOOLAND: 154,
    OP_BOOLOR: 155,
    OP_NUMEQUAL: 156,
    OP_NUMEQUALVERIFY: 157,
    OP_NUMNOTEQUAL: 158,
    OP_LESSTHAN: 159,
    OP_GREATERTHAN: 160,
    OP_LESSTHANOREQUAL: 161,
    OP_GREATERTHANOREQUAL: 162,
    OP_MIN: 163,
    OP_MAX: 164,

    OP_WITHIN: 165,

    # crypto
    OP_RIPEMD160: 166,
    OP_SHA1: 167,
    OP_SHA256: 168,
    OP_HASH160: 169,
    OP_HASH256: 170,
    OP_CODESEPARATOR: 171,
    OP_CHECKSIG: 172,
    OP_CHECKSIGVERIFY: 173,
    OP_CHECKMULTISIG: 174,
    OP_CHECKMULTISIGVERIFY: 175,

    OP_CHECKLOCKTIMEVERIFY: 177,
    OP_CHECKSEQUENCEVERIFY: 178,

    # expansion
    OP_NOP1: 176,
    OP_NOP2: 177,
    OP_NOP3: 178,
    OP_NOP4: 179,
    OP_NOP5: 180,
    OP_NOP6: 181,
    OP_NOP7: 182,
    OP_NOP8: 183,
    OP_NOP9: 184,
    OP_NOP10: 185,

    # template matching params
    OP_PUBKEYHASH: 253,
    OP_PUBKEY: 254,
    OP_INVALIDOPCODE: 255
  }


  @doc """
  Returns a map of all OP codes.
  """
  @spec op_codes :: map
  def op_codes, do: @op_codes


  @doc """
  Returns a tuple caintaining the OP code and OP code byte number, depending on
  the given OP code name or integer.

  ## Examples

      iex> BSV.Transaction.Script.get_op_code :OP_RETURN
      {:OP_RETURN, 106}

      iex> BSV.Transaction.Script.get_op_code "op_return"
      {:OP_RETURN, 106}

      iex> BSV.Transaction.Script.get_op_code 106
      {:OP_RETURN, 106}

      iex> BSV.Transaction.Script.get_op_code :UNKNOWN_CODE
      nil
  """
  @spec get_op_code(integer | atom | String.t) :: {atom, integer}
  def get_op_code(val) when is_atom(val) do
    opnum = @op_codes[val]
    if opnum, do: {val, opnum}, else: nil
  end

  def get_op_code(val) when is_integer(val),
    do: Enum.find(@op_codes, fn {_k, v} -> v == val end)

  def get_op_code(val) when is_binary(val),
    do: val |> String.upcase |> String.to_atom |> get_op_code
  

  @doc """
  Parses the given binary into a transaction script.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      iex> "76a9146afc0d6bb578282ac0f6ad5c5af2294c1971210888ac"
      ...> |> BSV.Transaction.Script.parse(encoding: :hex)
      %BSV.Transaction.Script{
        chunks: [
          :OP_DUP,
          :OP_HASH160,
          <<106, 252, 13, 107, 181, 120, 40, 42, 192, 246, 173, 92, 90, 242, 41, 76, 25, 113, 33, 8>>,
          :OP_EQUALVERIFY,
          :OP_CHECKSIG
        ]
      }
  """
  def parse(data, options \\ []) do
    encoding = Keyword.get(options, :encoding)
    Util.decode(data, encoding)
    |> parse_chunks([])
  end

  defp parse_chunks(<<>>, chunks),
    do: struct(__MODULE__, chunks: Enum.reverse(chunks))

  defp parse_chunks(<<op::integer, data::binary>>, chunks)
    when op > 0 and op < 76
  do
    <<chunk::bytes-size(op), data::binary>> = data
    parse_chunks(data, [chunk | chunks])
  end

  defp parse_chunks(<<76, size::integer, data::binary>>, chunks) do
    <<chunk::bytes-size(size), data::binary>> = data
    parse_chunks(data, [chunk | chunks])
  end

  defp parse_chunks(<<77, size::little-16, data::binary>>, chunks) do
    <<chunk::bytes-size(size), data::binary>> = data
    parse_chunks(data, [chunk | chunks])
  end

  defp parse_chunks(<<78, size::little-32, data::binary>>, chunks) do
    <<chunk::bytes-size(size), data::binary>> = data
    parse_chunks(data, [chunk | chunks])
  end

  defp parse_chunks(<<op::integer, data::binary>>, chunks) do
    {opcode, _opnum} = get_op_code(op)
    parse_chunks(data, [opcode | chunks])
  end


  @doc """
  Pushes a chunk into the given transaction script. The chunk can be any binary
  value or OP code.

  ## Examples

      iex> %BSV.Transaction.Script{}
      ...> |> BSV.Transaction.Script.push(:OP_DUP)
      ...> |> BSV.Transaction.Script.push(:OP_HASH160)
      ...> |> BSV.Transaction.Script.push(<<106, 252, 13, 107, 181, 120, 40, 42, 192, 246, 173, 92, 90, 242, 41, 76, 25, 113, 33, 8>>)
      ...> |> BSV.Transaction.Script.push(:OP_EQUALVERIFY)
      ...> |> BSV.Transaction.Script.push(:OP_CHECKSIG)
      %BSV.Transaction.Script{
        chunks: [
          :OP_DUP,
          :OP_HASH160,
          <<106, 252, 13, 107, 181, 120, 40, 42, 192, 246, 173, 92, 90, 242, 41, 76, 25, 113, 33, 8>>,
          :OP_EQUALVERIFY,
          :OP_CHECKSIG
        ]
      }
  """
  def push(%__MODULE__{} = script, data)
    when is_atom(data) or is_integer(data)
  do
    with {opcode, _opnum} <- get_op_code(data) do
      push_chunk(script, opcode)
    else
      _err -> raise "Invalid OP Code"
    end
  end

  def push(%__MODULE__{} = script, data) when is_binary(data),
    do: push_chunk(script, data)

  defp push_chunk(%__MODULE__{} = script, data) do
    chunks = Enum.concat(script.chunks, [data])
    Map.put(script, :chunks, chunks)
  end


  @doc """
  Serialises the given script into a binary.

  ## Options

  The accepted options are:

  * `:encode` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      iex> %BSV.Transaction.Script{}
      ...> |> BSV.Transaction.Script.push(:OP_DUP)
      ...> |> BSV.Transaction.Script.push(:OP_HASH160)
      ...> |> BSV.Transaction.Script.push(<<106, 252, 13, 107, 181, 120, 40, 42, 192, 246, 173, 92, 90, 242, 41, 76, 25, 113, 33, 8>>)
      ...> |> BSV.Transaction.Script.push(:OP_EQUALVERIFY)
      ...> |> BSV.Transaction.Script.push(:OP_CHECKSIG)
      ...> |> BSV.Transaction.Script.serialize(encoding: :hex)
      "76a9146afc0d6bb578282ac0f6ad5c5af2294c1971210888ac"
  """
  def serialize(%__MODULE__{} = script, options \\ []) do
    encoding = Keyword.get(options, :encoding)
    serialize_chunks(script.chunks, <<>>)
    |> Util.encode(encoding)
  end

  defp serialize_chunks([], data), do: data

  defp serialize_chunks([chunk | chunks], data) when is_atom(chunk) do
    {_opcode, opnum} = get_op_code(chunk)
    serialize_chunks(chunks, <<data::binary, opnum::integer>>)
  end

  defp serialize_chunks([chunk | chunks], data) when is_binary(chunk) do
    suffix = case byte_size(chunk) do
      op when op > 0 and op < 76 ->
        <<op::integer, chunk::binary>>
      len when len < 76 ->
        <<76::integer, chunk::binary>>
      len when len < 77 ->
        <<77::integer, chunk::binary>>
      len when len < 78 ->
        <<78::integer, chunk::binary>>
      op -> << op::integer >>
    end
    serialize_chunks(chunks, data <> suffix)
  end

end