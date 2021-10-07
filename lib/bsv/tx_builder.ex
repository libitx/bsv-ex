defmodule BSV.TxBuilder do
  @moduledoc """
  TODO
  """
  alias BSV.{Address, Contract, Script, Tx, TxOut, UTXO}
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
        {reverse_bin(a.hash), a.index} < {reverse_bin(b.hash), b.index}
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

    # Second pass on populating inputs with actual sigs
    inputs
    |> Enum.with_index()
    |> Enum.reduce(append_change(builder, tx), fn {contract, vin}, tx ->
      txin = contract
      |> Contract.put_ctx({tx, vin})
      |> Contract.to_txin()

      update_in(tx.inputs, & List.replace_at(&1, vin, txin))
    end)
  end

  # Appends the changescript if sufficient change after fee
  defp append_change(%{change_script: %Script{} = script} = builder, %Tx{} = tx) do
    change = input_sum(builder) - output_sum(builder)
    fee = Tx.calc_required_fee(tx, builder.options.rates)
    txout = %TxOut{script: script}
    extra_fee = ceil(TxOut.size(txout) * builder.options.rates.mine.standard)
    txout = Map.put(txout, :satoshis, change - (fee+extra_fee))
    dust_limit = dust_threshold(txout, builder.options.rates)

    if txout.satoshis >= dust_limit do
      Tx.add_output(tx, txout)
    else
      tx
    end
  end

  defp append_change(_, %Tx{} = tx), do: tx

  # TODO
  # See: https://github.com/bitcoin-sv/bitcoin-sv/blob/master/src/primitives/transaction.h#L188-L208
  defp dust_threshold(%TxOut{} = txout, %{relay: rates}),
    do: 3 * floor((TxOut.size(txout) + 148) * rates.standard)

end
