defmodule BSV.TxBuilder do
  @moduledoc """
  A flexible and powerful transaction building module and API.

  The TxBuilder accepts inputs and outputs that are modules implementing the
  `BSV.Contract` behaviour. This abstraction makes for a succinct and elegant
  approach to building transactions. The `BSV.Contract` behaviour is flexible
  and can be used to define any kind of locking and unlocking script, not
  limited to a handful of standard transactions.

  ## Examples

  Because each input and output is prepared with all the information it needs,
  calling `to_tx/1` is all that is needed to build and sign the transaction.

      iex> utxo = UTXO.from_params!(%{
      ...>   "txid" => "5e3014372338f079f005eedc85359e4d96b8440e7dbeb8c35c4182e0c19a1a12",
      ...>   "vout" => 0,
      ...>   "satoshis" => 11000,
      ...>   "script" => "76a914538fd179c8be0f289c730e33b5f6a3541be9668f88ac"
      ...> })
      iex>
      iex> builder = %TxBuilder{
      ...>   inputs: [
      ...>     P2PKH.unlock(utxo, %{keypair: @keypair})
      ...>   ],
      ...>   outputs: [
      ...>     P2PKH.lock(10000, %{address: @address}),
      ...>     OpReturn.lock(0, %{data: ["hello", "world"]})
      ...>   ]
      ...> }
      iex>
      iex> tx = TxBuilder.to_tx(builder)
      iex> Tx.to_binary(tx, encoding: :hex)
      "0100000001121a9ac1e082415cc3b8be7d0e44b8964d9e3585dcee05f079f038233714305e000000006a47304402200f674ba40b14b8f85b751ad854244a4199008c5b491b076df2eb6c3efd0be4bf022004b48ef0e656ee1873d07cb3b06858970de702f63935df2fbe8816f1a5f15e1e412103f81f8c8b90f5ec06ee4245eab166e8af903fc73a6dd73636687ef027870abe39ffffffff0210270000000000001976a914538fd179c8be0f289c730e33b5f6a3541be9668f88ac00000000000000000e006a0568656c6c6f05776f726c6400000000"

  """
  alias BSV.{Address, Contract, Script, Tx, TxIn, TxOut, UTXO, VarInt}
  alias BSV.Contract.P2PKH
  import BSV.Util, only: [reverse_bin: 1]

  @default_rates %{
    mine: %{ data: 0.5, standard: 0.5 },
    relay: %{ data: 0.25, standard: 0.25 }
  }

  @default_opts %{
    rates: @default_rates,
    sort: false
  }

  defstruct inputs: [],
            outputs: [],
            change_script: nil,
            lock_time: 0,
            options: @default_opts

  @typedoc "TxBuilder struct"
  @type t() :: %__MODULE__{
    inputs: list(Contract.t()),
    outputs: list(Contract.t()),
    change_script: Script.t() | nil,
    lock_time: non_neg_integer(),
    options: map()
  }

  @typedoc """
  Fee quote

  A fee quote is a data structure representing miner fees. It can be either a
  single number representing satoshis per bytes, or a map with keys for both
  `:data` and `:standard` miner rates.
  """
  @type fee_quote() :: %{
    mine: %{
      data: number(),
      standard: number()
    },
    relay: %{
      data: number(),
      standard: number()
    },
  } | %{
    data: number(),
    standard: number()
  } | number()

  @doc """
  Adds the given unlocking script contract to the builder.
  """
  @spec add_input(t(), Contract.t()) :: t()
  def add_input(%__MODULE__{} = builder, %Contract{mfa: {_, :unlocking_script, _}} = input),
    do: update_in(builder.inputs, & &1 ++ [input])

  @doc """
  Adds the given locking script contract to the builder.
  """
  @spec add_output(t(), Contract.t()) :: t()
  def add_output(%__MODULE__{} = builder, %Contract{mfa: {_, :locking_script, _}} = output),
    do: update_in(builder.outputs, & &1 ++ [output])

  @doc """
  Calculates the required fee for the builder's transaction, optionally using
  the given `t:fee_quote/0`.

  When different `:data` and `:standard` rates are given, data outputs
  (identified by locking scripts beginning with `OP_FALSE OP_RETURN`) are
  calculated using the appropriate rate.
  """
  @spec calc_required_fee(t(), fee_quote()) :: non_neg_integer()
  def calc_required_fee(builder, rates \\ @default_rates)

  def calc_required_fee(%__MODULE__{} = builder, rates) when is_number(rates),
    do: calc_required_fee(builder, %{data: rates, standard: rates})

  def calc_required_fee(%__MODULE__{} = builder, %{mine: rates}),
    do: calc_required_fee(builder, rates)

  def calc_required_fee(%__MODULE__{inputs: inputs, outputs: outputs}, %{data: _, standard: _} = rates) do
    [
      {:standard, 4 + 4}, # version & locktime
      {:standard, length(inputs) |> VarInt.encode() |> byte_size()},
      {:standard, length(outputs) |> VarInt.encode() |> byte_size()}
    ]
    |> Kernel.++(Enum.map(inputs, & calc_script_fee(Contract.to_txin(&1))))
    |> Kernel.++(Enum.map(outputs, & calc_script_fee(Contract.to_txout(&1))))
    |> Enum.reduce(0, fn {type, bytes}, fee -> fee + ceil(rates[type] * bytes) end)
  end

  @doc """
  Sets the change script on the builder as a P2PKH locking script to the given
  address.
  """
  @spec change_to(t(), Address.t() | Address.address_str()) :: t()
  def change_to(%__MODULE__{} = builder, %Address{} = address) do
    script = P2PKH.lock(0, %{address: address})
    |> Contract.to_script()

    Map.put(builder, :change_script, script)
  end

  def change_to(%__MODULE__{} = builder, address) when is_binary(address),
    do: change_to(builder, Address.from_string!(address))

  @doc """
  Returns the sum of all inputs defined in the builder.
  """
  @spec input_sum(t()) :: integer()
  def input_sum(%__MODULE__{inputs: inputs}) do
    inputs
    |> Enum.map(& &1.subject.txout.satoshis)
    |> Enum.sum()
  end

  @doc """
  Returns the sum of all outputs defined in the builder.
  """
  @spec output_sum(t()) :: integer()
  def output_sum(%__MODULE__{outputs: outputs}) do
    outputs
    |> Enum.map(& &1.subject)
    |> Enum.sum()
  end

  @doc """
  Sorts the TxBuilder inputs and outputs according to [BIP-69](https://github.com/bitcoin/bips/blob/master/bip-0069.mediawiki).

  BIP-69 defines deterministic lexographical indexing of transaction inputs and
  outputs.
  """
  @spec sort(t()) :: t()
  def sort(%__MODULE__{} = builder) do
    builder
    |> Map.update!(:inputs, fn inputs ->
      Enum.sort(inputs, fn %{subject: %UTXO{outpoint: a}}, %{subject: %UTXO{outpoint: b}} ->
        {reverse_bin(a.hash), a.vout} < {reverse_bin(b.hash), b.vout}
      end)
    end)
    |> Map.update!(:outputs, fn outputs ->
      Enum.sort(outputs, fn a, b ->
        script_a = Contract.to_script(a)
        script_b = Contract.to_script(b)
        {a.subject, Script.to_binary(script_a)} < {b.subject, Script.to_binary(script_b)}
      end)
    end)
  end

  @doc """
  Builds and returns the signed transaction.
  """
  @spec to_tx(t()) :: Tx.t()
  def to_tx(%__MODULE__{inputs: inputs, outputs: outputs} = builder) do
    builder = if builder.options.sort == true, do: sort(builder), else: builder
    tx = struct(Tx, lock_time: builder.lock_time)

    # First pass on populating inputs will zero out signatures
    tx = Enum.reduce(inputs, tx, fn contract, tx ->
      Tx.add_input(tx, Contract.to_txin(contract))
    end)

    # Create outputs
    tx = Enum.reduce(outputs, tx, fn contract, tx ->
      Tx.add_output(tx, Contract.to_txout(contract))
    end)

    # Append change if required
    tx = case get_change_txout(builder) do
      %TxOut{} = txout ->
        Tx.add_output(tx, txout)
      _ ->
        tx
    end

    # Second pass on populating inputs with actual sigs
    Enum.reduce(Enum.with_index(inputs), tx, fn {contract, vin}, tx ->
      txin = contract
      |> Contract.put_ctx({tx, vin})
      |> Contract.to_txin()

      update_in(tx.inputs, & List.replace_at(&1, vin, txin))
    end)
  end

  # Returns change txout if script present and amount exceeds dust threshold
  defp get_change_txout(%{change_script: %Script{} = script} = builder) do
    change = input_sum(builder) - output_sum(builder)
    fee = calc_required_fee(builder, builder.options.rates)
    txout = %TxOut{script: script}
    extra_fee = ceil(TxOut.get_size(txout) * builder.options.rates.mine.standard)
    change = change - (fee + extra_fee)

    if change >= dust_threshold(txout, builder.options.rates) do
      Map.put(txout, :satoshis, change)
    end
  end

  defp get_change_txout(_builder), do: nil

  # Calculates the size of the given TxIn or TxOut
  defp calc_script_fee(%TxIn{} = txin) do
    {:standard, TxIn.get_size(txin)}
  end

  defp calc_script_fee(%TxOut{script: script} = txout) do
    case script.chunks do
      [:OP_FALSE, :OP_RETURN | _chunks] ->
        {:data, TxOut.get_size(txout)}
      _ ->
        {:standard, TxOut.get_size(txout)}
    end
  end

  # Returns the dust threshold of the given txout
  # See: https://github.com/bitcoin-sv/bitcoin-sv/blob/master/src/primitives/transaction.h#L188-L208
  defp dust_threshold(%TxOut{} = txout, %{relay: rates}),
    do: 3 * floor((TxOut.get_size(txout) + 148) * rates.standard)

end
