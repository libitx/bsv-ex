defmodule BSV.UTXO do
  @moduledoc """
  TODO
  """
  alias BSV.{OutPoint, Script, Tx, TxOut}
  import BSV.Util, only: [decode: 2, reverse_bin: 1]

  defstruct outpoint: nil, txout: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    outpoint: OutPoint.t(),
    txout: TxOut.t()
  }

  @doc """
  TODO
  """
  @spec from_params(map()) :: {:ok, t()} | {:error, term()}
  def from_params(%{"txid" => txid, "script" => script} = params) do
    with {:ok, hash} <- decode(txid, :hex),
         {:ok, vout} <- take_any_param(params, ["vout", "outputIndex"]),
         {:ok, satoshis} <- take_any_param(params, ["satoshis", "amount"]),
         {:ok, script} <- Script.from_binary(script, encoding: :hex)

    do
      outpoint = struct(OutPoint, hash: reverse_bin(hash), index: vout)
      txout = struct(TxOut, satoshis: satoshis, script: script)
      {:ok, struct(__MODULE__, outpoint: outpoint, txout: txout)}
    end
  end

  @doc """
  TODO
  """
  @spec from_params!(map()) :: t()
  def from_params!(%{} = params) do
    case from_params(params) do
      {:ok, utxo} ->
        utxo

      {:error, error} ->
        raise BSV.DecodeError, error
    end
  end

  @doc """
  TODO
  """
  @spec from_tx(Tx.t(), non_neg_integer()) :: TxOut.t() | nil
  def from_tx(%Tx{outputs: outputs} = tx, vout) do
    with %TxOut{} = txout <- Enum.at(outputs, vout) do
      outpoint = %OutPoint{hash: Tx.get_hash(tx), index: vout}
      %__MODULE__{outpoint: outpoint, txout: txout}
    end
  end

  # TODO
  defp take_any_param(params, keys) do
    case Map.take(params, keys) |> Map.values() do
      [value | _] ->
        {:ok, value}
      _ ->
        {:error, {:param_not_found, keys}}
    end
  end

end
