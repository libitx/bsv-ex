defmodule BSV.Transaction.SignatureTest do
  use ExUnit.Case
  doctest BSV.Transaction.Signature
  alias BSV.Address
  alias BSV.KeyPair
  alias BSV.Transaction
  alias BSV.Transaction.Input
  alias BSV.Util

  # These tests are kinda rubbish. Have generated a sighash and signature using
  # bsv.js and want these tests to generate identical binary values.
  setup_all do
    keys    = BSV.Test.bsv_keys |> KeyPair.from_ecdsa_key
    address = keys |> Address.from_public_key |> Address.to_string

    prev_tx = %Transaction{}
    |> Transaction.spend_to(address, 50000)

    input = %Input{
      output_txid: Transaction.get_txid(prev_tx),
      output_index: 0,
      sequence: 0xFFFFFFFF,
      utxo: List.first(prev_tx.outputs)
    }

    tx = %Transaction{}
    |> Transaction.add_input(input)

    %{
      keys: keys,
      tx: tx,
      sighash: "3b173d3c1f9c2264c75cea7a97dceb7135bc610d7ddab25ec4e33667694e42b8",
      signature: "304402204a664732e1aca7cd43916a049abf591130d41772a0d15493e01e3cedf5816a960220091b1b116142f74d763516a4558b56ae86f9ad32ff2da8d0067ae144886db1a1"
    }
  end


  describe "BSV.Transaction.Signature.sighash/4" do
    test "must return the correct sighash", ctx do
      sighash = BSV.Transaction.Signature.sighash(ctx.tx, List.first(ctx.tx.inputs), 65)
      |> Util.encode(:hex)
      assert sighash == ctx.sighash
    end
  end


  describe "BSV.Transaction.Signature.sign_input/4" do
    test "must return the correct sighash", ctx do
      signature = BSV.Transaction.Signature.sign_input(ctx.tx, List.first(ctx.tx.inputs), ctx.keys.private_key)
      |> elem(0)
      |> Util.encode(:hex)
      assert signature == ctx.signature
    end
  end

end