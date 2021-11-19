defmodule BSV.OutPoint do
  @moduledoc """
  An OutPoint is a data structure representing a reference to a single
  `t:BSV.TxOut.t/0`.

  An OutPoint consists of a 32 byte `t:BSV.Tx.hash/0` and 4 byte
  `t:BSV.TxOut.vout/0`.

  Conceptually, an OutPoint can be seen as an edge in a graph of Bitcoin
  transactions, linking inputs to previous outputs.
  """
  alias BSV.{Serializable, Tx, TxOut}
  import BSV.Util, only: [decode: 2, encode: 2, reverse_bin: 1]

  @coinbase_hash <<0::256>>
  @coinbase_sequence 0xFFFFFFFF

  defstruct hash: nil, vout: nil

  @typedoc "OutPoint struct"
  @type t() :: %__MODULE__{
    hash: Tx.hash(),
    vout: TxOut.vout()
  }

  @doc """
  Parses the given binary into a `t:BSV.OutPoint.t/0`.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.
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
  Parses the given binary into a `t:BSV.OutPoint.t/0`.

  As `from_binary/2` but returns the result or raises an exception.
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
  Returns the `t:BSV.Tx.txid/0` from the OutPoint.
  """
  @spec get_txid(t()) :: Tx.txid()
  def get_txid(%__MODULE__{hash: hash}),
    do: hash |> reverse_bin() |> encode(:hex)

  @doc """
  Checks if the given OutPoint is a null.

  The first transaction in a block is used to distrbute the block reward to
  miners. These transactions (known as Coinbase transactions) do not spend a
  previous output, and thus the OutPoint is null.
  """
  @spec is_null?(t()) :: boolean()
  def is_null?(%__MODULE__{hash: @coinbase_hash, vout: @coinbase_sequence}), do: true
  def is_null?(%__MODULE__{}), do: false

  @doc """
  Serialises the given `t:BSV.OutPoint.t/0` into a binary.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally encode the binary with either the `:base64` or `:hex` encoding scheme.
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
      with <<hash::bytes-32, vout::little-32, rest::binary>> <- data do
        {:ok, struct(outpoint, [
          hash: hash,
          vout: vout
        ]), rest}
      end
    end

    @impl true
    def serialize(%{hash: hash, vout: vout}),
      do: <<hash::binary, vout::little-32>>
  end
end
