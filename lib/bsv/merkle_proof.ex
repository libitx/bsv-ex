defmodule BSV.MerkleProof do
  @moduledoc """
  The MerkleProof module implements the [BSV TCS Merkle proof standard](https://tsc.bitcoinassociation.net/standards/merkle-proof-standardised-format/).

  Merkle proofs are fundamental to the Simplified Payment Verification (SPV)
  model that underpins bitcoin scaling. Assuming we have stored block headers
  from the blockchain, given a transaction and `t:BSV.MerkleProof.t/0`, we can
  verify the transaction is contained in a block without downloading the entire
  block.

  The TSC Merkle proof standard describes a way of serialising a Merkle proof
  in a binary or json format, so network participants can share the proofs in
  a standardised format.
  """
  use Bitwise
  alias BSV.{BlockHeader, Hash, Serializable, Tx, VarInt}
  import BSV.Util, only: [decode: 2, encode: 2]

  defstruct flags: 0, index: nil, subject: nil, target: nil, nodes: []

  @typedoc "Merkle proof struct"
  @type t() :: %__MODULE__{
    flags: integer(),
    index: non_neg_integer(),
    subject: Tx.t() | Tx.hash(),
    target: BlockHeader.t() | binary(),
    nodes: list(Tx.hash())
  }

  defguard is_txid?(flags) when (flags &&& 0x01) == 0
  defguard is_tx?(flags) when (flags &&& 0x01) == 1
  defguard targets_block_hash?(flags) when (flags &&& (0x04 ||| 0x02)) == 0
  defguard targets_block_header?(flags) when (flags &&& (0x04 ||| 0x02)) == 2
  defguard targets_merkle_root?(flags) when (flags &&& (0x04 ||| 0x02)) == 4

  @doc """
  Parses the given binary into a `t:BSV.MerkleProof.t/0`.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.
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
  Parses the given binary into a `t:BSV.MerkleProof.t/0`.

  As `from_binary/2` but returns the result or raises an exception.
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
  Calculates and returns the result of hashing all of the transaction hashes
  contained in the Merkle proof into a tree-like structure known as a Merkle tree.
  """
  @spec calc_merkle_root(t()) :: binary()
  def calc_merkle_root(%__MODULE__{index: index, subject: %Tx{} = tx, nodes: nodes}),
    do: hash_nodes(Tx.get_hash(tx), index, nodes)

  def calc_merkle_root(%__MODULE__{index: index, subject: tx_hash, nodes: nodes})
    when is_binary(tx_hash),
    do: hash_nodes(tx_hash, index, nodes)

  # Iterates over and hashes the tx hashes
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

  @doc """
  Serialises the given `t:BSV.MerkleProof.t/0` into a binary.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally encode the binary with either the `:base64` or `:hex` encoding scheme.
  """
  @spec to_binary(t()) :: binary()
  def to_binary(%__MODULE__{} = merkle_proof, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)

    merkle_proof
    |> Serializable.serialize()
    |> encode(encoding)
  end


  defimpl Serializable do
    defguard is_txid?(flags) when (flags &&& 0x01) == 0
    defguard is_tx?(flags) when (flags &&& 0x01) == 1
    defguard targets_block_hash?(flags) when (flags &&& (0x04 ||| 0x02)) == 0
    defguard targets_block_header?(flags) when (flags &&& (0x04 ||| 0x02)) == 2
    defguard targets_merkle_root?(flags) when (flags &&& (0x04 ||| 0x02)) == 4

    @impl true
    def parse(merkle_proof, data) do
      with <<flags::integer, data::binary>> <- data,
           {:ok, index, data} <- VarInt.parse_int(data),
           {:ok, subject, data} <- parse_subject(data, flags),
           {:ok, target, data} <- parse_target(data, flags),
           {:ok, nodes_num, data} <- VarInt.parse_int(data),
           {:ok, nodes, rest} <- parse_nodes(data, nodes_num)
      do
        {:ok, struct(merkle_proof, [
          flags: flags,
          index: index,
          subject: subject,
          target: target,
          nodes: nodes
        ]), rest}
      else
        {:error, error} ->
          {:error, error}

        _data ->
          {:error, :invalid_merkle_proof}
      end
    end

    @impl true
    def serialize(%{flags: flags, nodes: nodes} = merkle_proof) do
      index = VarInt.encode(merkle_proof.index)
      tx_or_id = serialize_subject(merkle_proof.subject)
      target = serialize_target(merkle_proof.target)
      nodes_data = Enum.reduce(nodes, VarInt.encode(length(nodes)), &serialize_node/2)

      <<
        flags::integer,
        index::binary,
        tx_or_id::binary,
        target::binary,
        nodes_data::binary
      >>
    end

    # Parses the tx or tx hash as per the given flags
    defp parse_subject(data, flags) when is_tx?(flags) do
      with {:ok, rawtx, data} <- VarInt.parse_data(data),
           {:ok, tx} <- Tx.from_binary(rawtx)
      do
        {:ok, tx, data}
      end
    end

    defp parse_subject(data, flags) when is_txid?(flags) do
      with <<txid::binary-size(32), data::binary>> <- data do
        {:ok, txid, data}
      end
    end

    # # Parses the target as per the given flags
    defp parse_target(data, flags) when targets_block_header?(flags) do
      with {:ok, block_header, data} <- Serializable.parse(%BlockHeader{}, data) do
        {:ok, block_header, data}
      end
    end

    defp parse_target(data, _flags) do
      <<hash::binary-size(32), data::binary>> = data
      {:ok, hash, data}
    end

    # Parses the list of nodes
    defp parse_nodes(data, num, nodes \\ [])

    defp parse_nodes(data, num, nodes) when length(nodes) == num,
      do: {:ok, Enum.reverse(nodes), data}

    defp parse_nodes(<<0, hash::binary-size(32), data::binary>>, num, nodes),
      do: parse_nodes(data, num, [hash | nodes])

    defp parse_nodes(<<1, data::binary>>, num, nodes),
      do: parse_nodes(data, num, ["*" | nodes])

    # Serialised the tx or tx hash
    defp serialize_subject(%Tx{} = tx) do
      tx
      |> Tx.to_binary()
      |> VarInt.encode_binary()
    end

    defp serialize_subject(tx_hash), do: tx_hash

    # Serialise the target header or hash
    defp serialize_target(%BlockHeader{} = header),
      do: BlockHeader.to_binary(header)

    defp serialize_target(target), do: target

    # Serialises the lists of nodes
    defp serialize_node("*", data), do: data <> <<1>>
    defp serialize_node(<<hash::binary-size(32)>>, data),
      do: data <> <<0, hash::binary>>
  end

end
