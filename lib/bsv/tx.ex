defmodule BSV.Tx do
  @moduledoc """
  A Tx is a data structure representing a Bitcoin transaction.

  A Tx consists of a version number, a list of inputs, list of outputs, and a
  locktime value.

  A Bitcoin transaction is used to transfer custody of Bitcoins. It can also be
  used for smart contracts, recording and timestamping data, and many other
  functionalities.

  The Tx module is used for parsing and serialising transaction data. Use the
  `BSV.TxBuilder` module for building transactions.
  """
  alias BSV.{Hash, OutPoint, Serializable, TxIn, TxOut, VarInt}
  import BSV.Util, only: [decode: 2, encode: 2, reverse_bin: 1]

  defstruct version: 1, inputs: [], outputs: [], lock_time: 0

  @typedoc "Tx struct"
  @type t() :: %__MODULE__{
    version: non_neg_integer(),
    inputs: list(TxIn.t()),
    outputs: list(TxOut.t()),
    lock_time: non_neg_integer()
  }

  @typedoc """
  Tx hash

  Result of hashing the transaction data through the SHA-256 algorithm twice.
  """
  @type hash() :: <<_::256>>

  @typedoc """
  TXID

  Result of reversing and hex-encoding the `t:BSV.Tx.hash/0`.
  """
  @type txid() :: String.t()

  @doc """
  Adds the given `t:BSV.TxIn.t/0` to the transaction.
  """
  @spec add_input(t(), TxIn.t()) :: t()
  def add_input(%__MODULE__{} = tx, %TxIn{} = txin),
    do: update_in(tx.inputs, & &1 ++ [txin])

  @doc """
  Adds the given `t:BSV.TxOut.t/0` to the transaction.
  """
  @spec add_output(t(), TxOut.t()) :: t()
  def add_output(%__MODULE__{} = tx, %TxOut{} = txout),
    do: update_in(tx.outputs, & &1 ++ [txout])

  @doc """
  Returns true if the given `t:BSV.Tx.t/0` is a coinbase transaction (the first
  transaction in a block, containing the miner block reward).
  """
  @spec is_coinbase?(t()) :: boolean()
  def is_coinbase?(%__MODULE__{inputs: [txin]}),
    do: OutPoint.is_null?(txin.outpoint)

  def is_coinbase?(%__MODULE__{}), do: false

  @doc """
  Parses the given binary into a `t:BSV.Tx.t/0`.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally decode the binary with either the `:base64` or `:hex` encoding scheme.
  """
  @spec from_binary(binary(), keyword()) :: {:ok, t()} | {:error, term()}
  def from_binary(data, opts \\ []) when is_binary(data) do
    encoding = Keyword.get(opts, :encoding)

    with {:ok, data} <- decode(data, encoding),
         {:ok, tx, _rest} <- Serializable.parse(%__MODULE__{}, data)
    do
      {:ok, tx}
    end
  end

  @doc """
  Parses the given binary into a `t:BSV.Tx.t/0`.

  As `from_binary/2` but returns the result or raises an exception.
  """
  @spec from_binary!(binary(), keyword()) :: t()
  def from_binary!(data, opts \\ []) when is_binary(data) do
    case from_binary(data, opts) do
      {:ok, tx} ->
        tx

      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  Returns the `t:BSV.Tx.hash/0` of the given transaction.
  """
  @spec get_hash(t()) :: hash()
  def get_hash(%__MODULE__{} = tx) do
    tx
    |> to_binary()
    |> Hash.sha256_sha256()
  end

  @doc """
  Returns the number of bytes of the given `t:BSV.Tx.t/0`.
  """
  @spec get_size(t()) :: non_neg_integer()
  def get_size(%__MODULE__{} = tx),
    do: to_binary(tx) |> byte_size()

  @doc """
  Returns the `t:BSV.Tx.txid/0` of the given transaction.
  """
  @spec get_txid(t()) :: txid()
  def get_txid(%__MODULE__{} = tx) do
    tx
    |> get_hash()
    |> reverse_bin()
    |> encode(:hex)
  end

  @doc """
  Serialises the given `t:BSV.TxIn.t/0` into a binary.

  ## Options

  The accepted options are:

  * `:encoding` - Optionally encode the binary with either the `:base64` or `:hex` encoding scheme.
  """
  @spec to_binary(t()) :: binary()
  def to_binary(%__MODULE__{} = tx, opts \\ []) do
    encoding = Keyword.get(opts, :encoding)

    tx
    |> Serializable.serialize()
    |> encode(encoding)
  end

  defimpl Serializable do
    @impl true
    def parse(tx, data) do
      with <<version::little-32, data::binary>> <- data,
           {:ok, inputs, data} <- VarInt.parse_items(data, TxIn),
           {:ok, outputs, data} <- VarInt.parse_items(data, TxOut),
           <<lock_time::little-32, rest::binary>> = data
      do
        {:ok, struct(tx, [
          version: version,
          inputs: inputs,
          outputs: outputs,
          lock_time: lock_time
        ]), rest}
      end
    end

    @impl true
    def serialize(%{version: version, inputs: inputs, outputs: outputs, lock_time: lock_time}) do
      inputs_data = Enum.reduce(inputs, VarInt.encode(length(inputs)), fn input, data ->
        data <> Serializable.serialize(input)
      end)
      outputs_data = Enum.reduce(outputs, VarInt.encode(length(outputs)), fn output, data ->
        data <> Serializable.serialize(output)
      end)

      <<
        version::little-32,
        inputs_data::binary,
        outputs_data::binary,
        lock_time::little-32
      >>
    end
  end

end
