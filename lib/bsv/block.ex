defmodule BSV.Block do
  @moduledoc """
  TODO
  """
  alias BSV.{BlockHeader, Hash, Serializable, Tx, VarInt}
  import BSV.Util, only: [decode: 2, encode: 2]

  defstruct header: nil, txns: []

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    header: BlockHeader.t(),
    txns: list(Tx.t())
  }

  @typedoc "TODO"
  @type merkle_root() :: <<_::256>>

  @doc """
  TODO
  """
  @spec calc_merkle_root(t()) :: merkle_root()
  def calc_merkle_root(%__MODULE__{txns: txns}) do
    txns
    |> Enum.map(&Tx.get_hash/1)
    |> hash_nodes()
  end

  # TODO
  defp hash_nodes([hash]), do: hash

  defp hash_nodes(nodes) when rem(length(nodes), 2) == 1,
    do: hash_nodes(nodes ++ List.last(nodes))

  defp hash_nodes(nodes) do
    nodes
    |> Enum.chunk_every(2)
    |> Enum.map(& Hash.sha256_sha256(&1 <> &2))
    |> hash_nodes()
  end


  @doc """
  TODO
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
  TODO
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
  TODO
  """
  @spec to_binary(t()) :: binary()
  def to_binary(%__MODULE__{} = block, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)

    block
    |> Serializable.serialize()
    |> encode(encoding)
  end

  @doc """
  TODO
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
