defmodule BSV.SigHashTest do
  use ExUnit.Case, async: true
  alias BSV.SigHash
  alias BSV.{OutPoint, Script, Tx, TxIn, TxOut, Util}
  doctest SigHash

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
    prev_out: %OutPoint{
      hash: Tx.get_hash(@prev_tx),
      index: 0
    },
    script: %Script{}
  }
  @test_tx %Tx{inputs: [@test_txin]}
  @test_sighash "b8424e696736e3c45eb2da7d0d61bc3571ebdc977aea5cc764229c1f3c3d173b"

  describe "SigHash.sighash/4" do
    test "must return the correct sighash" do
      sighash = BSV.SigHash.sighash(@test_tx, @test_txin, @prev_txout, 65)
      |> Util.encode(:hex)
      assert sighash == @test_sighash
    end
  end

end
