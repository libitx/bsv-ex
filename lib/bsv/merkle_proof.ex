defmodule BSV.MerkleProof do
  @moduledoc """
  TODO
  """
  use Bitwise
  alias BSV.{Hash, Serializable, Tx, VarInt}
  import BSV.Util, only: [decode: 2, encode: 2]

  defstruct flags: 0, index: nil, tx_hash: nil, target: nil, nodes: []

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    flags: integer(),
    index: non_neg_integer(),
    tx_hash: Tx.hash(),
    target: binary(),
    nodes: list(Tx.hash())
  }

  defguard is_txid?(flags) when (flags &&& 0x01) == 0
  defguard is_tx?(flags) when (flags &&& 0x01) == 1
  defguard targets_block_hash?(flags) when (flags &&& (0x04 ||| 0x02)) == 0
  defguard targets_block_header?(flags) when (flags &&& (0x04 ||| 0x02)) == 2
  defguard targets_merkle_root?(flags) when (flags &&& (0x04 ||| 0x02)) == 2

  @doc """
  TODO
  """
  @spec from_binary(binary(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_binary(data, opts \\ []) when is_binary(data) do
    encoding = Keyword.get(opts, :encoding)

    with {:ok, data} <- decode(data, encoding),
         {:ok, merkle_proof, _rest} <- Serializable.parse(%__MODULE__{}, data)
    do
      {:ok, merkle_proof}
    end
  end

  @doc """
  TODO
  """
  @spec from_binary!(binary(), keyword()) :: t()
  def from_binary!(data, opts \\ []) when is_binary(data) do
    case from_binary(data, opts) do
      {:ok, merkle_proof} ->
        merkle_proof

      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  TODO
  """
  @spec calc_merkle_root(t()) :: binary()
  def calc_merkle_root(%__MODULE__{index: index, tx_hash: tx_hash, nodes: nodes}),
    do: hash_nodes(tx_hash, index, nodes)

  # TODO
  defp hash_nodes(hash, _index, []), do: hash

  defp hash_nodes(hash, index, ["*" | rest]) when rem(index, 2) == 0,
    do: hash_nodes(hash, index, [hash | rest])

  defp hash_nodes(_hash, index, ["*" | _rest]) when rem(index, 2) == 1,
    do: raise "invalid nodes"

  defp hash_nodes(hash, index, [node | rest]) when rem(index, 2) == 0 do
    Hash.sha256_sha256(hash <> node)
    |> hash_nodes(floor(index / 2), rest)
  end

  defp hash_nodes(hash, index, [node | rest]) when rem(index, 2) == 1 do
    Hash.sha256_sha256(node <> hash)
    |> hash_nodes(floor(index / 2), rest)
  end



  defimpl Serializable do
    defguard is_txid?(flags) when (flags &&& 0x01) == 0
    defguard is_tx?(flags) when (flags &&& 0x01) == 1
    defguard targets_block_hash?(flags) when (flags &&& (0x04 ||| 0x02)) == 0
    defguard targets_block_header?(flags) when (flags &&& (0x04 ||| 0x02)) == 2
    defguard targets_merkle_root?(flags) when (flags &&& (0x04 ||| 0x02)) == 2

    @impl true
    def parse(merkle_proof, data) do
      with <<flags::integer, data::binary>> <- data,
           {:ok, index, data} <- VarInt.parse_int(data),
           {:ok, tx_hash, data} <- parse_tx_or_txid(data, flags),
           {:ok, target, data} <- parse_target(data, flags),
           {:ok, nodes_num, data} <- VarInt.parse_int(data),
           {:ok, nodes} <- parse_nodes(data, nodes_num)
      do
        {:ok, struct(merkle_proof, [
          flags: flags,
          index: index,
          tx_hash: tx_hash,
          target: target,
          nodes: nodes
        ]), <<>>}
      end
    end

    # TODO
    defp parse_tx_or_txid(data, flags) when is_txid?(flags) do
      <<txid::binary-size(32), data::binary>> = data
      {:ok, txid, data}
    end

    defp parse_tx_or_txid(data, flags) when is_tx?(flags) do
      with {:ok, rawtx, data} <- VarInt.parse_data(data) do
        {:ok, Hash.sha256_sha256(rawtx), data}
      end
    end

    # TODO
    defp parse_target(data, flags) when targets_block_header?(flags) do
      <<block_header::binary-size(80), data::binary>> = data
      {:ok, block_header, data}
    end

    defp parse_target(data, _flags) do
      <<hash::binary-size(32), data::binary>> = data
      {:ok, hash, data}
    end

    # TODO
    defp parse_nodes(data, num, nodes \\ [])

    defp parse_nodes(_data, num, nodes) when length(nodes) == num,
      do: {:ok, Enum.reverse(nodes)}

    defp parse_nodes(<<0, hash::binary-size(32), data::binary>>, num, nodes) do
      parse_nodes(data, num, [hash | nodes])
    end

    defp parse_nodes(<<1, data::binary>>, num, nodes) do
      parse_nodes(data, num, ["*" | nodes])
    end

  end

end
