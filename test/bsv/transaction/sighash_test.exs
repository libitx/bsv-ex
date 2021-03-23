defmodule BSV.Transaction.SignatureTest do
  use ExUnit.Case
  doctest BSV.Transaction.Signature
  alias BSV.Address
  alias BSV.KeyPair
  alias BSV.Transaction
  alias BSV.Transaction.Input
  alias BSV.Util

  # These tests are kinda rubbish
  # Use these tests in conjunction with bsv.js scripts and cross reference values
  # node test/js/sighash.js --require PATH_TO_BSV
  setup_all do
    keys    = BSV.Test.bsv_keys |> KeyPair.from_ecdsa_key
    address = keys |> Address.from_public_key |> Address.to_string

    prev_tx = %Transaction{}
    |> Transaction.spend_to(address, 50000)

    input = %Input{
      output_txid: Transaction.get_txid(prev_tx),
      output_index: 0,
      sequence: 0xFFFFFFFF,
      script: %BSV.Script{},
      utxo: List.first(prev_tx.outputs)
    }

    tx = %Transaction{}
    |> Transaction.add_input(input)

    %{
      keys: keys,
      tx: tx,
      sighash: "b8424e696736e3c45eb2da7d0d61bc3571ebdc977aea5cc764229c1f3c3d173b",
      signature: "304402204a664732e1aca7cd43916a049abf591130d41772a0d15493e01e3cedf5816a960220091b1b116142f74d763516a4558b56ae86f9ad32ff2da8d0067ae144886db1a1"
    }
  end


  describe "BSV.Transaction.Signature.sighash/4" do
    test "must return the correct sighash", ctx do
      sighash = BSV.Transaction.Signature.sighash(ctx.tx, 0, 65)
      |> Util.encode(:hex)
      assert sighash == ctx.sighash
    end
  end


  describe "BSV.Transaction.Signature.sign_input/4" do
    test "must return the correct sighash", ctx do
      signature = BSV.Transaction.Signature.sign_input(ctx.tx, 0, ctx.keys.private_key)
      |> elem(0)
      |> Util.encode(:hex)
      assert signature == ctx.signature
    end
  end

end
