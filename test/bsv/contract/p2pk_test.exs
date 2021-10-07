defmodule BSV.Contract.P2PKTest do
  use ExUnit.Case, async: true
  alias BSV.Contract.P2PK
  alias BSV.{Contract, KeyPair, PrivKey, Script, TxOut, UTXO}

  @wif "KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF"
  @keypair KeyPair.from_privkey(PrivKey.from_wif!(@wif))
  doctest P2PK

  describe "lock/2" do
    test "locks satoshis to an address" do
      contract = P2PK.lock(1000, %{pubkey: @keypair.pubkey})
      assert %TxOut{satoshis: 1000, script: script} = Contract.to_txout(contract)
      assert %Script{chunks: [<<_::binary-33>>, :OP_CHECKSIG]} = script
    end

    test "raises an error if the arguments are not valid" do
      assert_raise FunctionClauseError, fn ->
        P2PK.lock(1000, %{pubkey: "not pubkey"}) |> Contract.to_txout()
      end
    end
  end

  describe "unlock/2" do
    test "unlocks UTXO with given privkey" do
      contract = P2PK.unlock(%UTXO{}, %{privkey: @keypair.privkey})
      assert %Script{chunks: [<<_::binary-71>>]} = Contract.to_script(contract)
    end

    test "raises an error if the arguments are not valid" do
      assert_raise FunctionClauseError, fn ->
        P2PK.unlock(%UTXO{}, %{privkey: "not privkey"}) |> Contract.to_script()
      end
    end
  end

end
