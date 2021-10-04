defmodule BSV.Contract do
  @moduledoc """
  TODO
  """
  alias BSV.{Script, Tx, TxIn, TxOut, UTXO}

  defstruct ctx: nil, mfa: nil, opts: [], subject: nil, script: %Script{}

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    ctx: {Tx.t(), non_neg_integer()} | nil,
    mfa: {module(), atom(), list()},
    opts: keyword(),
    subject: non_neg_integer() | UTXO.t(),
    script: Script.t()
  }

  defmacro __using__(_) do
    quote do
      alias BSV.Contract
      import Contract.Helpers

      @behaviour Contract

      @doc """
      Returns a locking script contract with the given parameters.
      """
      @spec lock(non_neg_integer(), map(), keyword()) :: Contract.t()
      def lock(satoshis, %{} = params, opts \\ []) do
        struct(Contract, [
          mfa: {__MODULE__, :locking_script, [params]},
          opts: opts,
          subject: satoshis
        ])
      end

      @doc """
      Returns an unlocking script contract with the given parameters.
      """
      @spec unlock(UTXO.t(), map(), keyword()) :: Contract.t()
      def unlock(%UTXO{} = utxo, %{} = params, opts \\ []) do
        struct(Contract, [
          mfa: {__MODULE__, :unlocking_script, [params]},
          opts: opts,
          subject: utxo
        ])
      end
    end
  end

  @doc """
  TODO
  """
  @callback locking_script(t(), map()) :: t()

  @doc """
  TODO
  """
  @callback unlocking_script(t(), map()) :: t()

  @optional_callbacks unlocking_script: 2

  @doc """
  TODO
  """
  @spec put_ctx(t(), Tx.t(), non_neg_integer()) :: t()
  def put_ctx(%__MODULE__{} = contract, %Tx{} = tx, vin) when is_integer(vin),
    do: Map.put(contract, :ctx, {tx, vin})

  @doc """
  TODO
  """
  @spec script_push(t(), atom() | integer() | binary()) :: t()
  def script_push(%__MODULE__{} = contract, val),
    do: update_in(contract.script, & Script.push(&1, val))

  @doc """
  TODO
  """
  @spec script_size(t()) :: non_neg_integer()
  def script_size(%__MODULE__{} = contract) do
    contract
    |> to_script()
    |> Script.to_binary()
    |> byte_size()
  end

  @doc """
  TODO
  """
  @spec to_script(t()) :: Script.t()
  def to_script(%__MODULE__{mfa: {mod, fun, args}} = contract) do
    %{script: script} = apply(mod, fun, [contract | args])
    script
  end

  @doc """
  TODO
  """
  @spec to_txin(t()) :: TxIn.t()
  def to_txin(%__MODULE__{subject: %UTXO{outpoint: outpoint}} = contract) do
    sequence = Keyword.get(contract.opts, :sequence, 0xFFFFFFFF)
    script = to_script(contract)
    struct(TxIn, prev_out: outpoint, script: script, sequence: sequence)
  end

  @doc """
  TODO
  """
  @spec to_txout(t()) :: TxOut.t()
  def to_txout(%__MODULE__{subject: satoshis} = contract)
    when is_integer(satoshis)
  do
    script = to_script(contract)
    struct(TxOut, satoshis: satoshis, script: script)
  end

end
