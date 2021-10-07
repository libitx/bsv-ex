defmodule BSV.Contract.P2MS do
  @moduledoc """
  Pay to Multi Signature contract.

  P2PK scripts are used to lock Bitcoin to a multiple [`public keys`](`t:BSV.PubKey.t/0`).
  The Bitcoin can later be unlocked using the specified threshold of
  corresponding private keys.

  ## Lock parameters

  * `:pubkeys` - List of `t:BSV.PubKey.t/0` structs.
  * `:threshold` - Threshold of required signatures.

  ## Unlock parameters

  * `:privkeys` - List of `t:BSV.PrivKey.t/0` structs.

  ## Examples

      iex> contract = P2MS.lock(1000, %{pubkeys: @pubkeys, threshold: 2})
      iex> Contract.to_script(contract)
      %Script{chunks: [
        :OP_2,
        <<2, 148, 83, 173, 92, 5, 192, 13, 32, 255, 52, 204, 49, 136, 138, 176, 156, 149, 52, 201, 230, 182, 195, 34, 84, 148, 33, 110, 190, 94, 109, 106, 32>>,
        <<3, 232, 222, 19, 142, 204, 19, 161, 243, 84, 197, 85, 103, 159, 51, 211, 169, 138, 154, 133, 20, 69, 88, 63, 180, 94, 123, 42, 101, 231, 172, 96, 245>>,
        <<2, 180, 138, 62, 127, 140, 27, 86, 215, 147, 254, 50, 182, 67, 69, 93, 3, 111, 66, 45, 196, 228, 10, 63, 227, 25, 171, 151, 208, 44, 54, 157, 124>>,
        :OP_3,
        :OP_CHECKMULTISIG
      ]}

      iex> contract = P2MS.unlock(%UTXO{}, %{privkeys: @privkeys})
      iex> Contract.to_script(contract)
      %Script{chunks: [
        :OP_0,
        <<0::568>>, # signatures are zero'd out until the transaction context is attached
        <<0::568>>
      ]}
  """
  use BSV.Contract
  alias BSV.PubKey

  @impl true
  def locking_script(ctx, %{pubkeys: pubkeys, threshold: threshold})
    when is_list(pubkeys)
  do
    ctx
    |> push(threshold)
    |> push_all(Enum.map(pubkeys, &PubKey.to_binary/1))
    |> push(length(pubkeys))
    |> op_checkmultisig
  end

  @impl true
  def unlocking_script(ctx, %{privkeys: privkeys}) when is_list(privkeys) do
    ctx
    |> op_0
    |> multi_sig(privkeys)
  end

end
