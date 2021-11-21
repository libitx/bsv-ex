defmodule BSV.Contract.P2RPHTest do
  use ExUnit.Case, async: true
  alias BSV.Contract.P2RPH
  alias BSV.{Contract, KeyPair, PrivKey, Script, TxOut, UTXO, VM}

  @wif "KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF"
  @keypair KeyPair.from_privkey(PrivKey.from_wif!(@wif))
  @k P2RPH.generate_k()
  @r P2RPH.get_r(@k)

  doctest P2RPH

  describe "lock/2" do
    test "locks satoshis to an R value" do
      contract = P2RPH.lock(1000, %{r: @r})
      assert %TxOut{satoshis: 1000, script: script} = Contract.to_txout(contract)
      assert %Script{chunks: [
        :OP_OVER,
        :OP_3,
        :OP_SPLIT,
        :OP_NIP,
        :OP_1,
        :OP_SPLIT,
        :OP_SWAP,
        :OP_SPLIT,
        :OP_DROP,
        :OP_HASH160,
        <<_::binary-20>>,
        :OP_EQUALVERIFY,
        :OP_TUCK,
        :OP_CHECKSIGVERIFY,
        :OP_CHECKSIG
      ]} = script
    end

    test "raises an error if the arguments are not valid" do
      assert_raise FunctionClauseError, fn ->
        P2RPH.lock(1000, %{r: 123}) |> Contract.to_txout()
      end
    end
  end

  describe "unlock/2" do
    test "unlocks UTXO with given K value" do
      contract = P2RPH.unlock(%UTXO{}, %{k: @k, keypair: @keypair})
      assert %Script{chunks: [<<_::binary-71>>, <<_::binary-71>>, <<_::binary-33>>]} = Contract.to_script(contract)
    end
  end

  describe "Contract.simulate/3" do
    test "evaluates as valid if signed with correct key" do
      assert {:ok, vm} = Contract.simulate(P2RPH, %{r: @r}, %{k: @k, keypair: KeyPair.new()})
      assert VM.valid?(vm)
    end

    test "evaluates as invalid if used with with incorrect k" do
      assert {:error, vm} = Contract.simulate(P2RPH, %{r: @r}, %{k: P2RPH.generate_k(), keypair: KeyPair.new()})
      refute VM.valid?(vm)
    end
  end

  describe "generate_k/0" do
    test "returns new random k value" do
      k = P2RPH.generate_k()
      assert is_binary(k)
      assert byte_size(k) == 32
    end
  end

  describe "get_r/1" do
    test "returns r value of given k value" do
      r = P2RPH.get_r(@k)
      assert is_binary(r)
      assert byte_size(r) in [32, 33]
    end
  end

end
