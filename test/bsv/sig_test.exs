defmodule BSV.SigTest do
  use ExUnit.Case, async: true
  alias BSV.Sig
  alias BSV.{OutPoint, PrivKey, PubKey, Script, Tx, TxIn, TxOut, Util}

  @prev_txout %TxOut{
    satoshis: 50000,
    script: %Script{chunks: [
      :OP_DUP,
      :OP_HASH160,
      <<47, 105, 50, 137, 102, 179, 60, 141, 131, 76, 2, 71, 24, 254, 231, 1, 101, 139, 55, 71>>,
      :OP_EQUALVERIFY,
      :OP_CHECKSIG
    ]}
  }
  @prev_tx %Tx{outputs: [@prev_txout]}
  @test_txin %TxIn{
    outpoint: %OutPoint{
      hash: Tx.get_hash(@prev_tx),
      vout: 0
    },
    script: %Script{}
  }
  @test_tx %Tx{inputs: [@test_txin]}
  @test_sighash "b8424e696736e3c45eb2da7d0d61bc3571ebdc977aea5cc764229c1f3c3d173b"
  @test_privkey PrivKey.from_wif!("KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF")
  @test_signature "MEUCIQDjRz9K3GUXhKU2HV3/fQXIz6L4+A6RxKKEsL+N4CPgCAIgSI6qg/XCyTsqNLWIG77OrKobfBsDt95g71EnSbSh3DZB"
  @vectors_abc File.read!("test/vectors/sighash.abc.json") |> Jason.decode!()
  @vectors_btc File.read!("test/vectors/sighash.btc.json") |> Jason.decode!()

  doctest Sig

  describe "Sig.sighash/4" do
    test "must return the correct sighash" do
      sighash = Sig.sighash(@test_tx, 0, @prev_txout, 65)
      |> Util.encode(:hex)
      assert sighash == @test_sighash
    end

    test "Bitcoin ABC test vectors" do
      [_ | vectors] = @vectors_abc
      for [rawtx, script, vin, sighash_type, sighash] <- vectors do
        tx = Tx.from_binary!(rawtx, encoding: :hex)
        subscript = Script.from_binary!(script, encoding: :hex)
        txout = %TxOut{script: subscript}

        res = Sig.sighash(tx, vin, txout, sighash_type)
        |> Util.reverse_bin()
        |> Base.encode16(case: :lower)
        assert res == sighash
      end
    end

    # need to implement Flags SCRIPT_ENABLE_SIGHASH_FORKID so can force legacy sighash
    @tag :pending
    test "Bitcoin Core test vectors" do
      [_ | vectors] = @vectors_btc
      for [rawtx, script, vin, sighash_type, sighash] <- vectors do
        tx = Tx.from_binary!(rawtx, encoding: :hex)
        subscript = Script.from_binary!(script, encoding: :hex)
        txout = %TxOut{script: subscript}

        res = Sig.sighash(tx, vin, txout, sighash_type)
        |> Util.reverse_bin()
        |> Base.encode16(case: :lower)
        assert res == sighash
      end
    end
  end

  describe "Sig.sign/5" do
    test "must return the correct signature" do
      signature = Sig.sign(@test_tx, 0, @prev_txout, @test_privkey)
      assert is_binary(signature)
      assert Base.encode64(signature) == @test_signature
    end
  end

  describe "Sig.verify/5" do
    test "must verify the signature" do
      assert Sig.verify(@test_signature, @test_tx, 0, @prev_txout, PubKey.from_privkey(@test_privkey))
    end
  end

end
