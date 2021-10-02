defmodule BSV.Contract.P2PKH do
  @moduledoc """
  Pay to Public Key Hash contract.
  """
  use BSV.Contract
  alias BSV.{PubKey}

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
    |> signature(keypair.privkey)
    |> push(PubKey.to_binary(keypair.pubkey))
  end

end
