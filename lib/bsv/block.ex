defmodule BSV.Block do
  @moduledoc """
  A block is a data structure consisting of a `t:BSV.BlockHeader.t/0` and a list
  of [`transactions`](`t:BSV.Tx.t/0`).

  TODO
  """
  alias BSV.{BlockHeader, Hash, Serializable, Tx, VarInt}
  import BSV.Util, only: [decode: 2, encode: 2]

  defstruct header: nil, txns: []

  @typedoc "Block struct"
  @type t() :: %__MODULE__{
    header: BlockHeader.t(),
    txns: list(Tx.t())
  }

  @typedoc """
  Merkle root - the result of hashing all of the transactions contained in the
  block into a tree-like structure known as a Merkle tree.
  """
  @type merkle_root() :: <<_::256>>

  @doc """
  Calculates and returns the result of hashing all of the transactions contained
  in the block into a tree-like structure known as a Merkle tree.
  """
  @spec calc_merkle_root(t()) :: merkle_root()
  def calc_merkle_root(%__MODULE__{txns: txns}) do
    txns
    |> Enum.map(&Tx.get_hash/1)
    |> hash_nodes()
  end

  # Iterates over the list of tx hashes and further hashes them together until
  # the merkle root is calvulated
  defp hash_nodes([hash]), do: hash

  defp hash_nodes(nodes) when rem(length(nodes), 2) == 1,
    do: hash_nodes(nodes ++ List.last(nodes))

  defp hash_nodes(nodes) do
    nodes
    |> Enum.chunk_every(2)
    |> Enum.map(fn [a, b] -> Hash.sha256_sha256(a <> b) end)
    |> hash_nodes()
  end

  @doc """
  Parses the given binary into a `t:BSV.Block.t/0`.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.
  """
  @spec from_binary(binary(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_binary(data, opts \\ []) when is_binary(data) do
    encoding = Keyword.get(opts, :encoding)

    with {:ok, data} <- decode(data, encoding),
         {:ok, block, _rest} <- Serializable.parse(%__MODULE__{}, data)
    do
      {:ok, block}
    end
  end

  @doc """
  Parses the given binary into a `t:BSV.Block.t/0`.

  As `from_binary/1` but returns the result or raises an exception.
  """
  @spec from_binary!(binary(), keyword()) :: t()
  def from_binary!(data, opts \\ []) when is_binary(data) do
    case from_binary(data, opts) do
      {:ok, block} ->
        block

      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  Serialises the given `t:BSV.Block.t/0` into a binary.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally encode the binary with either the `:base64` or `:hex` encoding scheme.
  """
  @spec to_binary(t()) :: binary()
  def to_binary(%__MODULE__{} = block, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)

    block
    |> Serializable.serialize()
    |> encode(encoding)
  end

  @doc """
  Calculates the `t:BSV.Block.merkle_root/0` of the given block and compares the
  result to the value contained the `t:BSV.BlockHeader.t/0`.
  """
  @spec validate_merkle_root(t()) :: boolean()
  def validate_merkle_root(%__MODULE__{header: header} = block),
    do: calc_merkle_root(block) == (header && header.merkle_root)


  defimpl Serializable do
    @impl true
    def parse(block, data) do
      with {:ok, header, data} <- Serializable.parse(%BlockHeader{}, data),
           {:ok, txns, rest} <- VarInt.parse_items(data, Tx)
      do
        {:ok, struct(block, [
          header: header,
          txns: txns,
        ]), rest}
      end
    end

    @impl true
    def serialize(%{header: header, txns: txns}) do
      header_data = Serializable.serialize(header)
      txns_data = Enum.reduce(txns, VarInt.encode(length(txns)), fn tx, data ->
        data <> Serializable.serialize(tx)
      end)

      <<
        header_data::binary,
        txns_data::binary
      >>
    end
  end

end
