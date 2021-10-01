defmodule BSV.Tx do
  @moduledoc """
  TODO
  """
  alias BSV.{Hash, Script, Serializable, TxIn, TxOut, VarInt}
  import BSV.Util, only: [decode: 2, encode: 2, reverse_bin: 1]

  defstruct version: 1, inputs: [], outputs: [], lock_time: 0

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    version: non_neg_integer(),
    inputs: list(TxIn.t()),
    outputs: list(TxOut.t()),
    lock_time: non_neg_integer()
  }

  @typedoc "TODO"
  @type hash() :: <<_::256>>

  @typedoc "TODO"
  @type txid() :: String.t()

  @doc """
  TODO
  """
  @spec add_input(t(), TxIn.t()) :: t()
  def add_input(%__MODULE__{} = tx, %TxIn{} = txin),
    do: update_in(tx.inputs, & &1 ++ [txin])

  @doc """
  TODO
  """
  @spec add_output(t(), TxOut.t()) :: t()
  def add_output(%__MODULE__{} = tx, %TxOut{} = txout),
    do: update_in(tx.outputs, & &1 ++ [txout])

  @doc """
  TODO
  """
  @spec coinbase?(t()) :: boolean()
  def coinbase?(%__MODULE__{inputs: [txin]}), do: TxIn.coinbase?(txin)
  def coinbase?(%__MODULE__{}), do: false

  @doc """
  TODO
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
  TODO
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
  TODO
  """
  @spec get_hash(t()) :: hash()
  def get_hash(%__MODULE__{} = tx) do
    tx
    |> to_binary()
    |> Hash.sha256_sha256()
  end

  @doc """
  TODO
  """
  @spec get_txid(t()) :: txid()
  def get_txid(%__MODULE__{} = tx) do
    tx
    |> get_hash()
    |> reverse_bin()
    |> encode(:hex)
  end

  @doc """
  TODO
  """
  @spec sort(t()) :: t()
  def sort(%__MODULE__{} = tx) do
    tx
    |> update_in([:inputs], fn inputs ->
      Enum.sort(inputs, fn %{prev_out: a}, %{prev_out: b} ->
        {reverse_bin(a.hash), a.index} < {reverse_bin(b.hash), b.index}
      end)
    end)
    |> update_in([:outputs], fn outputs ->
      Enum.sort(outputs, fn a, b ->
        script_a = Script.to_binary(a.script)
        script_b = Script.to_binary(b.script)
        {a.satoshis, script_a} < {b.satoshis, script_b}
      end)
    end)
  end

  @doc """
  TODO
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
