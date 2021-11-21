defmodule BSV.TxBuilder do
  @moduledoc """
  TODO
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

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    inputs: list(Contract.t()),
    outputs: list(Contract.t()),
    change_script: Script.t() | nil,
    lock_time: non_neg_integer(),
    options: map()
  }

  @typedoc "TODO"
  @type fee_quote() :: %{
    mine: %{
      data: non_neg_integer(),
      standard: non_neg_integer()
    },
    relay: %{
      data: non_neg_integer(),
      standard: non_neg_integer()
    },
  } | %{
    data: non_neg_integer(),
    standard: non_neg_integer()
  } | non_neg_integer()

  @doc """
  TODO
  """
  @spec add_input(t(), Contract.t()) :: t()
  def add_input(%__MODULE__{} = builder, %Contract{mfa: {_, :unlocking_script, _}} = input),
    do: update_in(builder.inputs, & &1 ++ [input])

  @doc """
  TODO
  """
  @spec add_output(t(), Contract.t()) :: t()
  def add_output(%__MODULE__{} = builder, %Contract{mfa: {_, :locking_script, _}} = output),
    do: update_in(builder.outputs, & &1 ++ [output])

  @doc """
  TODO
  """
  @spec calc_required_fee(t(), fee_quote()) :: non_neg_integer()
  def calc_required_fee(builder, rates \\ @default_rates)

  def calc_required_fee(%__MODULE__{} = builder, rates) when is_integer(rates),
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
  TODO
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
  TODO
  """
  @spec input_sum(t()) :: integer()
  def input_sum(%__MODULE__{inputs: inputs}) do
    inputs
    |> Enum.map(& &1.subject.txout.satoshis)
    |> Enum.sum()
  end

  @doc """
  TODO
  """
  @spec output_sum(t()) :: integer()
  def output_sum(%__MODULE__{outputs: outputs}) do
    outputs
    |> Enum.map(& &1.subject)
    |> Enum.sum()
  end

  @doc """
  TODO
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
  TODO
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
