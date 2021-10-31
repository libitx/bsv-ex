defmodule BSV.UTXO do
  @moduledoc """
  A UTXO is a data structure representing an unspent transaction output.

  A UTXO consists of a `t:BSV.OutPoint.t/0` and the `t:BSV.TxOut.t/0` itself.
  UTXOs are used in the `BSV.TxBuilder` module to create transaction inputs.
  """
  alias BSV.{OutPoint, Script, Tx, TxOut}
  import BSV.Util, only: [decode: 2, reverse_bin: 1]

  defstruct outpoint: nil, txout: nil

  @typedoc "UTXO struct"
  @type t() :: %__MODULE__{
    outpoint: OutPoint.t(),
    txout: TxOut.t()
  }

  @doc """
  Builds a `t:BSV.UTXO.t/0` from the given map of params. Useful for building
  UTXO's from JSON APIs.

  Returns the result in an `:ok` / `:error` tuple pair.

  ## Params

  The required params are:

  * `txid` - Transaction ID
  * `vout` - Vector of the output in a transaction. Also accepts `outputIndex`
  * `satoshis` - Number of satoshis. Also accepts `amount`
  * `script` - Hex-encoded locking script

  ## Examples

      iex> UTXO.from_params(%{
      ...>   "txid" => "5e3014372338f079f005eedc85359e4d96b8440e7dbeb8c35c4182e0c19a1a12",
      ...>   "vout" => 0,
      ...>   "satoshis" => 15399,
      ...>   "script" => "76a91410bdcba3041b5e5517a58f2e405293c14a7c70c188ac"
      ...> })
      {:ok, %UTXO{
        outpoint: %OutPoint{
          hash: <<18, 26, 154, 193, 224, 130, 65, 92, 195, 184, 190, 125, 14, 68, 184, 150, 77, 158, 53, 133, 220, 238, 5, 240, 121, 240, 56, 35, 55, 20, 48, 94>>,
          vout: 0
        },
        txout: %TxOut{
          satoshis: 15399,
          script: %Script{chunks: [
            :OP_DUP,
            :OP_HASH160,
            <<16, 189, 203, 163, 4, 27, 94, 85, 23, 165, 143, 46, 64, 82, 147, 193, 74, 124, 112, 193>>,
            :OP_EQUALVERIFY,
            :OP_CHECKSIG
          ]}
        }
      }}
  """
  @spec from_params(map()) :: {:ok, t()} | {:error, term()}
  def from_params(%{"txid" => txid, "script" => script} = params) do
    with {:ok, hash} <- decode(txid, :hex),
         {:ok, vout} <- take_any_param(params, ["vout", "outputIndex"]),
         {:ok, satoshis} <- take_any_param(params, ["satoshis", "amount"]),
         {:ok, script} <- Script.from_binary(script, encoding: :hex)

    do
      outpoint = struct(OutPoint, hash: reverse_bin(hash), vout: vout)
      txout = struct(TxOut, satoshis: satoshis, script: script)
      {:ok, struct(__MODULE__, outpoint: outpoint, txout: txout)}
    end
  end

  @doc """
  Builds a `t:BSV.UTXO.t/0` from the given map of params.

  As `from_params/1` but returns the result or raises an exception.
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
  Builds a `t:BSV.UTXO.t/0` from the given transaction and vout index. Useful
  for building UTXO's when you already have the full transaction being spent
  from.
  """
  @spec from_tx(Tx.t(), TxOut.vout()) :: TxOut.t() | nil
  def from_tx(%Tx{outputs: outputs} = tx, vout) when vout < length(outputs) do
    with %TxOut{} = txout <- Enum.at(outputs, vout) do
      outpoint = %OutPoint{hash: Tx.get_hash(tx), vout: vout}
      %__MODULE__{outpoint: outpoint, txout: txout}
    end
  end

  # Takes the first value from the list of keys on the given map of params
  defp take_any_param(params, keys) do
    case Map.take(params, keys) |> Map.values() do
      [value | _] ->
        {:ok, value}
      _ ->
        {:error, {:param_not_found, keys}}
    end
  end

end
