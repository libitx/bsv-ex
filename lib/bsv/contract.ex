defmodule BSV.Contract do
  @moduledoc """
  TODO
  """
  alias BSV.{Script, Tx, TxIn, TxOut, UTXO}

  defstruct ctx: nil, mfa: nil, opts: [], script: %Script{}

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    ctx: {Tx.t(), non_neg_integer(), TxOut.t()} | nil,
    mfa: {module(), atom(), list()},
    opts: keyword(),
    script: Script.t()
  }

  defmacro __using__(_) do
    quote do
      alias BSV.Contract
      import Contract.Helpers

      @behaviour Contract

      @doc """
      TODO
      """
      @spec init(atom(), map(), keyword()) :: Contract.t()
      def init(function_name, %{} = params, opts \\ []) when is_atom(function_name) do
        %Contract{
          mfa: {__MODULE__, function_name, [params]},
          opts: opts
        }
      end


      @doc """
      TODO
      """
      @spec lock(non_neg_integer(), map(), keyword()) :: {:ok, TxOut.t()} | {:error, term()}
      def lock(satoshis, %{} = params, opts \\ []) do
        :locking_script
        |> init(params, opts)
        |> Contract.lock(satoshis)
      end

      @doc """
      TODO
      """
      @spec unlock(UTXO.t(), {Tx.t(), non_neg_integer()}, map(), keyword()) :: {:ok, TxIn.t()} | {:error, term()}
      def unlock(%UTXO{txout: txout} = utxo, {%Tx{} = tx, vin} = _context, %{} = params, opts \\ []) do
        :unlocking_script
        |> init(params, opts)
        |> Map.put(:ctx, {tx, vin, txout})
        |> Contract.unlock(utxo)
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

  @doc """
  TODO
  """
  @spec lock(t(), non_neg_integer()) :: {:ok, TxOut.t()} | {:error, term()}
  def lock(%__MODULE__{mfa: {mod, fun, args}} = contract, satoshis) do
    try do
      %{script: script} = apply(mod, fun, [contract | args])
      {:ok, %TxOut{satoshis: satoshis, script: script}}
    rescue
      _e ->
        {:error, {:argument_error, args}}
    end
  end

  @doc """
  TODO
  """
  @spec unlock(t(), UTXO.t()) :: {:ok, TxIn.t()} | {:error, term()}
  def unlock(%__MODULE__{mfa: {mod, fun, args}} = contract, %UTXO{outpoint: outpoint}) do
    try do
      %{script: script} = apply(mod, fun, [contract | args])
      sequence = Keyword.get(contract.opts, :sequence, 0xFFFFFFFF)

      {:ok, %TxIn{prev_out: outpoint, script: script, sequence: sequence}}
    rescue
      _e ->
        {:error, {:argument_error, args}}
    end
  end

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
  def script_size(%__MODULE__{mfa: {mod, fun, args}} = contract) do
    %{script: script} = apply(mod, fun, [contract | args])
    script
    |> Script.to_binary()
    |> byte_size()
  end




end
