defmodule BSV.OutPoint do
  @moduledoc """
  TODO
  """
  alias BSV.{Serializable, Tx}
  import BSV.Util, only: [decode: 2, encode: 2, reverse_bin: 1]

  @coinbase_hash <<0::256>>
  @coinbase_sequence 0xFFFFFFFF

  defstruct hash: nil, index: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    hash: binary(),
    index: vout()
  }

  @typedoc "TODO"
  @type vout() :: non_neg_integer()

  @doc """
  TODO
  """
  @spec from_binary(binary(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_binary(data, opts \\ []) when is_binary(data) do
    encoding = Keyword.get(opts, :encoding)

    with {:ok, data} <- decode(data, encoding),
         {:ok, outpoint, _rest} <- Serializable.parse(%__MODULE__{}, data)
    do
      {:ok, outpoint}
    end
  end

  @doc """
  TODO
  """
  @spec from_binary!(binary(), keyword()) :: t()
  def from_binary!(data, opts \\ []) when is_binary(data) do
    case from_binary(data, opts) do
      {:ok, outpoint} ->
        outpoint

      {:error, error} ->
         raise BSV.DecodeError, error
    end
  end

  @doc """
  TODO
  """
  @spec get_txid(t()) :: Tx.txid()
  def get_txid(%__MODULE__{hash: hash}),
    do: hash |> reverse_bin() |> encode(:hex)

  @doc """
  TODO
  """
  @spec null?(t()) :: boolean()
  def null?(%__MODULE__{hash: @coinbase_hash, index: @coinbase_sequence}), do: true
  def null?(%__MODULE__{}), do: false

  @doc """
  TODO
  """
  @spec to_binary(t()) :: binary()
  def to_binary(%__MODULE__{} = outpoint, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)

    outpoint
    |> Serializable.serialize()
    |> encode(encoding)
  end

  defimpl Serializable do
    @impl true
    def parse(outpoint, data) do
      with <<hash::bytes-32, index::little-32, rest::binary>> <- data do
        {:ok, struct(outpoint, [
          hash: hash,
          index: index
        ]), rest}
      end
    end

    @impl true
    def serialize(%{hash: hash, index: index}),
      do: <<hash::binary, index::little-32>>
  end
end
