defmodule BSV.Block do
  @moduledoc """
  Module for the construction, parsing and serialization of Bitcoin block headers.
  """
  use Bitwise
  alias BSV.Crypto.Hash
  alias BSV.Util
  alias BSV.Util.VarBin
  alias BSV.Transaction

  @enforce_keys [:version, :previous_block, :merkle_root, :timestamp, :bits, :nonce]

  @typedoc "A Bitcoin block."
  defstruct [
    :hash,
    :version,
    :previous_block,
    :merkle_root,
    :timestamp,
    :bits,
    :nonce,
    :transactions
  ]

  @type t :: %__MODULE__{
          hash: binary() | nil,
          version: non_neg_integer(),
          previous_block: binary(),
          merkle_root: binary(),
          timestamp: DateTime.t(),
          bits: binary(),
          nonce: binary(),
          transactions: [Transaction.t()] | nil
        }

  @doc """
  Parse the given binary into a block. Returns a tuple containing the
  parsed block and the remaining binary data.

  ## Arguments

  * `include_transactions` - will attempt to parse transactions that follow the block header in the
     binary. Disabled by default.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      iex> raw = "010000006FE28C0AB6F1B372C1A6A246AE63F74F931E8365E15A089C68D6190000000000982051FD1E4BA744BBBE680E1FEE14677BA1A3C3540BF7B1CDB606E857233E0E61BC6649FFFF001D01E36299"
      iex> {block, ""} = raw |> Base.decode16!() |> BSV.Block.parse()
      iex> Base.encode16(block.hash)
      "00000000839A8E6886AB5951D76F411475428AFC90947EE320161BBF18EB6048"
      iex> {block, ""} = raw |> BSV.Block.parse(false, encoding: :hex)
      iex> Base.encode16(block.hash)
      "00000000839A8E6886AB5951D76F411475428AFC90947EE320161BBF18EB6048"
  """
  @spec parse(binary, boolean, keyword) :: {__MODULE__.t(), binary}
  def parse(data, include_transactions \\ false, options \\ []) do
    encoding = Keyword.get(options, :encoding)

    <<block_bytes::binary-size(80), rest::binary>> = data |> Util.decode(encoding)

    <<version::little-size(32), previous_block::binary-size(32), merkle_root::binary-size(32),
      timestamp::little-size(32), bits::binary-size(4), nonce::binary-size(4)>> = block_bytes

    {transactions, rest} =
      if include_transactions do
        rest |> VarBin.parse_items(&Transaction.parse/1)
      else
        {nil, rest}
      end

    {%__MODULE__{
       hash: block_bytes |> Hash.sha256_sha256() |> Util.reverse_bin(),
       version: version,
       previous_block: previous_block |> Util.reverse_bin(),
       merkle_root: merkle_root,
       timestamp: DateTime.from_unix!(timestamp),
       bits: bits,
       nonce: nonce,
       transactions: transactions
     }, rest}
  end

  @doc """
  Serialises the given block into a binary.

  ## Arguments

  * `include_transactions` - will add transactions into the serialized binary. Disabled by default.

  ## Options

  The accepted options are:

  * `:encode` - Optionally encode the returned binary with either the `:base64` or `:hex` encoding scheme.

  ## Examples

      BSV.Block.serialize(input)
      <<binary>>
  """
  @spec serialize(__MODULE__.t(), boolean, keyword) :: binary
  def serialize(block, include_transactions \\ false, options \\ [])

  def serialize(%__MODULE__{} = block, false, options) do
    encoding = Keyword.get(options, :encoding)

    timestamp = DateTime.to_unix(block.timestamp)

    (<<block.version::little-size(32)>> <>
       (block.previous_block |> Util.reverse_bin()) <>
       block.merkle_root <>
       <<timestamp::little-size(32)>> <>
       block.bits <>
       block.nonce)
    |> Util.encode(encoding)
  end

  def serialize(%__MODULE__{transactions: transactions} = block, true, options)
      when is_list(transactions) do
    encoding = Keyword.get(options, :encoding)

    (serialize(block, false) <>
       (transactions |> VarBin.serialize_items(&Transaction.serialize/1)))
    |> Util.encode(encoding)
  end

  @doc """
  Gets the block id (hash in the hex form).

  Examples

      iex> raw = "010000006FE28C0AB6F1B372C1A6A246AE63F74F931E8365E15A089C68D6190000000000982051FD1E4BA744BBBE680E1FEE14677BA1A3C3540BF7B1CDB606E857233E0E61BC6649FFFF001D01E36299"
      iex> {block, ""} = BSV.Block.parse(raw, false, encoding: :hex)
      iex> BSV.Block.id(block)
      "00000000839a8e6886ab5951d76f411475428afc90947ee320161bbf18eb6048"
  """
  @spec id(__MODULE__.t()) :: String.t()
  def id(block) do
    case block.hash do
      nil ->
        block
        |> serialize()
        |> Hash.sha256_sha256()
        |> Util.reverse_bin()
        |> Util.encode(:hex)

      _ ->
        Util.encode(block.hash, :hex)
    end
  end

  @doc """
  Gets the block hash.

  ## Examples

      iex> raw = "010000006FE28C0AB6F1B372C1A6A246AE63F74F931E8365E15A089C68D6190000000000982051FD1E4BA744BBBE680E1FEE14677BA1A3C3540BF7B1CDB606E857233E0E61BC6649FFFF001D01E36299"
      iex> {block, ""} = BSV.Block.parse(raw, false, encoding: :hex)
      iex> BSV.Block.hash(block)
      <<0, 0, 0, 0, 131, 154, 142, 104, 134, 171, 89, 81, 215, 111, 65, 20, 117, 66, 138, 252, 144, 148, 126, 227, 32, 22, 27, 191, 24, 235, 96, 72>>
  """
  @spec hash(__MODULE__.t()) :: binary()
  def hash(transaction) do
    case transaction.hash do
      nil ->
        transaction
        |> serialize()
        |> Hash.sha256_sha256()
        |> Util.reverse_bin()

      _ ->
        transaction.hash
    end
  end

  @doc """
  Gets the previous block id.

  Examples

      iex> raw = "010000006FE28C0AB6F1B372C1A6A246AE63F74F931E8365E15A089C68D6190000000000982051FD1E4BA744BBBE680E1FEE14677BA1A3C3540BF7B1CDB606E857233E0E61BC6649FFFF001D01E36299"
      iex> {block, ""} = BSV.Block.parse(raw, false, encoding: :hex)
      iex> BSV.Block.previous_id(block)
      "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f"
  """
  @spec previous_id(__MODULE__.t()) :: String.t()
  def previous_id(block) do
    block.previous_block |> Util.encode(:hex)
  end
end
