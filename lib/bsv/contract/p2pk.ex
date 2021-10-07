defmodule BSV.Contract.P2PK do
  @moduledoc """
  Pay to Public Key contract.

  P2PK scripts are used to lock Bitcoin to a [`public key`](`t:BSV.PubKey.t/0`).
  The Bitcoin can later be unlocked using the corresponding private key.

  ## Lock parameters

  * `:pubkey` - A `t:BSV.PubKey.t/0` struct.

  ## Unlock parameters

  * `:privkey` - A `t:BSV.PrivKey.t/0` struct.

  ## Examples

      iex> contract = P2PK.lock(1000, %{pubkey: @keypair.pubkey})
      iex> Contract.to_script(contract)
      %Script{chunks: [
        <<3, 248, 31, 140, 139, 144, 245, 236, 6, 238, 66, 69, 234, 177, 102, 232, 175, 144, 63, 199, 58, 109, 215, 54, 54, 104, 126, 240, 39, 135, 10, 190, 57>>,
        :OP_CHECKSIG
      ]}

      iex> contract = P2PK.unlock(%UTXO{}, %{privkey: @keypair.privkey})
      iex> Contract.to_script(contract)
      %Script{chunks: [
        <<0::568>> # signatures are zero'd out until the transaction context is attached
      ]}
  """
  use BSV.Contract
  alias BSV.{PrivKey, PubKey}

  @impl true
  def locking_script(ctx, %{pubkey: %PubKey{} = pubkey}) do
    ctx
    |> push(PubKey.to_binary(pubkey))
    |> op_checksig
  end

  @impl true
  def unlocking_script(ctx, %{privkey: %PrivKey{} = privkey}) do
    signature(ctx, privkey)
  end

end
