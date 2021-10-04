defmodule BSV.Contract.P2PKHTest do
  use ExUnit.Case, async: true
  alias BSV.Contract.P2PKH
  alias BSV.{Address, Contract, KeyPair, PrivKey, Script, TxOut, UTXO}

  @wif "KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF"
  @keypair KeyPair.from_privkey(PrivKey.from_wif!(@wif))
  doctest P2PKH

  describe "lock/2" do
    test "locks satoshis to an address" do
      contract = P2PKH.lock(1000, %{address: Address.from_pubkey(@keypair.pubkey)})
      assert %TxOut{satoshis: 1000, script: script} = Contract.to_txout(contract)
      assert %Script{chunks: [:OP_DUP, :OP_HASH160, _pubkeyhash, :OP_EQUALVERIFY, :OP_CHECKSIG]} = script
    end

    test "raises an error if the arguments are not valid" do
      assert_raise ArgumentError, fn ->
        P2PKH.lock(1000, %{address: "not address"}) |> Contract.to_txout()
      end
    end
  end

  describe "unlock/2" do
    test "unlocks UTXO with given keypair" do
      contract = P2PKH.unlock(%UTXO{}, %{keypair: @keypair})
      assert %Script{chunks: [<<_::binary-71>>, <<_::binary-33>>]} = Contract.to_script(contract)
    end

    test "raises an error if the arguments are not valid" do
      assert_raise ArgumentError, fn ->
        P2PKH.unlock(%UTXO{}, %{keypair: "not keypair"}) |> Contract.to_script()
      end
    end
  end

end
