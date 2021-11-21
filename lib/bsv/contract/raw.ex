defmodule BSV.Contract.Raw do
  @moduledoc """
  The Raw Script contract provides a mechanism through which pre-built scripts
  can be used with the `BSV.TxBuilder` module.

  ## Examples

      iex> builder = %TxBuilder{
      ...>   outputs: [
      ...>     Raw.lock(10_000, %{script: Script.from_binary!(@p2pkh_hex, encoding: :hex)})
      ...>   ]
      ...> }
      iex> TxBuilder.to_tx(builder)
      %BSV.Tx{
        inputs: [],
        outputs: [
          %BSV.TxOut{
            satoshis: 10000,
            script: %BSV.Script{
              chunks: [
                :OP_DUP,
                :OP_HASH160,
                <<16, 189, 203, 163, 4, 27, 94, 85, 23, 165, 143, 46, 64, 82, 147, 193, 74, 124, 112, 193>>,
                :OP_EQUALVERIFY,
                :OP_CHECKSIG
              ],
              coinbase: nil
            }
          }
        ]
      }
  """
  use BSV.Contract
  alias BSV.Script

  @impl true
  def locking_script(ctx, %{script: %Script{} = script}) do
    Map.put(ctx, :script, script)
  end

  @impl true
  def unlocking_script(ctx, %{script: %Script{} = script}) do
    Map.put(ctx, :script, script)
  end

end
