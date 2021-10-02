defmodule BSV.UTXO do
  @moduledoc """
  TODO
  """
  alias BSV.{OutPoint, Tx, TxOut}

  defstruct outpoint: nil, txout: nil

  @typedoc "TODO"
  @type t() :: %__MODULE__{
    outpoint: OutPoint.t(),
    txout: TxOut.t()
  }

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

end
