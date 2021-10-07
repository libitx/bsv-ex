defmodule BSV.Contract.P2PKH do
  @moduledoc """
  Pay to Public Key Hash contract.

  P2PKH scripts are used to lock Bitcoin to an [`address`](`t:BSV.Address.t/0`).
  The Bitcoin can later be unlocked using the private key corresponding to the
  address.

  ## Lock parameters

  * `:address` - A `t:BSV.Address.t/0` struct.

  ## Unlock parameters

  * `:keypair` - A `t:BSV.KeyPair.t/0` struct.

  ## Examples

      iex> contract = P2PKH.lock(1000, %{address: Address.from_pubkey(@keypair.pubkey)})
      iex> Contract.to_script(contract)
      %Script{chunks: [
        :OP_DUP,
        :OP_HASH160,
        <<83, 143, 209, 121, 200, 190, 15, 40, 156, 115, 14, 51, 181, 246, 163, 84, 27, 233, 102, 143>>,
        :OP_EQUALVERIFY,
        :OP_CHECKSIG
      ]}

      iex> contract = P2PKH.unlock(%UTXO{}, %{keypair: @keypair})
      iex> Contract.to_script(contract)
      %Script{chunks: [
        <<0::568>>, # signatures are zero'd out until the transaction context is attached
        <<3, 248, 31, 140, 139, 144, 245, 236, 6, 238, 66, 69, 234, 177, 102, 232, 175, 144, 63, 199, 58, 109, 215, 54, 54, 104, 126, 240, 39, 135, 10, 190, 57>>
      ]}
  """
  use BSV.Contract
  alias BSV.PubKey

  @impl true
  def locking_script(ctx, %{address: address}) do
    ctx
    |> op_dup
    |> op_hash160
    |> push(address.pubkey_hash)
    |> op_equalverify
    |> op_checksig
  end

  @impl true
  def unlocking_script(ctx, %{keypair: keypair}) do
    ctx
    |> sig(keypair.privkey)
    |> push(PubKey.to_binary(keypair.pubkey))
  end

end
