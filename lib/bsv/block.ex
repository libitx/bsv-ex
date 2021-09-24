defmodule BSV.Block do
  @moduledoc """
  TODO
  """
  alias BSV.{BlockHeader, Serializable, Tx, VarInt}
  import BSV.Util, only: [decode: 2, encode: 2]

  defstruct header: nil, txns: []

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    header: BlockHeader.t(),
    txns: list(Tx.t())
  }

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
