defmodule BSV.TransactionTest do
  use ExUnit.Case
  doctest BSV.Transaction
  alias BSV.Script
  alias BSV.Transaction.{Input, Output}

  setup_all do
    %{
      tx1: "02000000027bb22176433bb45bacede86a43764f98c7023f1a79b00138e3d3ea610716a8f1010000006b483045022100c7036739f47361398bd115dbe9302fdc456d75f83fb38e531f4a445c8385138a022006f68ca095a35886f3eb217f416650490a3f0a279f8dc564d0222c884002f85841210232b357c5309644cf4aa72b9b2d8bfe58bdf2515d40119318d5cb51ef378cae7effffffff197725400c9846a19a03cfd151bd089b9ec3e90ecbfa72b9c5448d52b2baae43020000006b483045022100b23044350aaaafb08480fee7addadde918c2b5515b66a3c445be05ca809ce290022044c89daa88303522cb72830ab71d1411da65f0a58dca43fcd998f80df3794cc441210282d7e568e56f59e01a4edae297ac26caabc4684971ac6c7558c91c0fa84002f7ffffffff03efbee82f000000001976a914c4263eb96d88849f498d139424b59a0cba1005e888ac010c1dfa000000001976a9146cbff9881ac47da8cb699e4543c28f9b3d6941da88ac404b4c00000000001976a914f7899faf1696892e6cb029b00c713f044761f03588ac00000000",
      coinbase_tx1: "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff1d0379d5092f7376706f6f6c2e636f6d2f30e77996fe42f03db5bf080100ffffffff0163a64e25000000001976a91468888423f412b6b4166d61fe9e66a1aeff30df1f88ac00000000"
    }
  end


  describe "BSV.Transaction.parse/2" do
    test "must parse into Transaction", ctx do
      {tx, ""} = BSV.Transaction.parse(ctx.tx1, encoding: :hex)
      assert length(tx.inputs) == 2
      assert length(tx.outputs) == 3
       assert BSV.Transaction.is_coinbase(tx) == false

      Enum.each(tx.inputs, fn input ->
        assert Input.is_null(input) == false
        assert input.script.coinbase == nil
      end)
    end

    test "suceeds with a coinbase transaction", ctx do
      {tx, ""} = BSV.Transaction.parse(ctx.coinbase_tx1, encoding: :hex)
      assert BSV.Transaction.is_coinbase(tx) == true
      assert length(tx.inputs) == 1
      assert length(tx.outputs) == 1

      [input] = tx.inputs
      assert Input.is_null(input) == true
      assert input.script == %Script{coinbase: "\x03y\xD5\t/svpool.com/0\xE7y\x96\xFEB\xF0=\xB5\xBF\b\x01\0", chunks: []}
    end
  end


  describe "BSV.Transaction.serialize/2" do
    test "must serialize Transaction into binary", ctx do
      hex = BSV.Transaction.parse(ctx.tx1, encoding: :hex)
      |> elem(0)
      |> BSV.Transaction.serialize(encoding: :hex)
      assert hex == ctx.tx1
    end
  end


  describe "BSV.Transaction.get_txid/1" do
    test "must calcualte txid hash", ctx do
      txid = BSV.Transaction.parse(ctx.tx1, encoding: :hex)
      |> elem(0)
      |> BSV.Transaction.get_txid
      assert txid == "23aa811fd33115797ec2de4580fec173b6cc6e2a39011ae9c4ccea19dfdcef41"
    end
  end


  # Use these tests in conjunction with bsv.js scripts and cross reference values
  # node test/js/tx.js --require PATH_TO_BSV
  describe "Cross reference with bsv.js" do
    setup do
      keys    = BSV.Test.bsv_keys |> BSV.KeyPair.from_ecdsa_key
      address = keys |> BSV.Address.from_public_key |> BSV.Address.to_string

      prev_tx = %BSV.Transaction{}
      |> BSV.Transaction.spend_to(address, 10000)

      input = %Input{
        output_txid: BSV.Transaction.get_txid(prev_tx),
        output_index: 0,
        sequence: 0xFFFFFFFF,
        utxo: List.first(prev_tx.outputs)
      }

      output = %Output{
        script: %BSV.Script{
          chunks: [:OP_FALSE, :OP_RETURN, "hello world"]
        }
      }

      tx = %BSV.Transaction{}
      |> BSV.Transaction.spend_from(input)
      |> BSV.Transaction.add_output(output)
      |> BSV.Transaction.change_to(address)
      |> BSV.Transaction.sign(keys)

      %{
        keys: keys,
        address: address,
        tx: tx,

        bsv_change1: 9892,
        bsv_change2: 9000,
        bsv_txid1: "6eb93b815958f059f5b6367a9d41b174e339f230c47d335d2b55732ceced82c8",
        bsv_txid2: "7ca0de70bc3b9e3561e13345edb0fde0a376337b5bbc9866519075bbd8c6550b"
      }
    end

    test "must match change amount with bsv.js", ctx do
      change = BSV.Transaction.get_change_output(ctx.tx)
      assert change.satoshis == ctx.bsv_change1
    end

    test "must match txid amount with bsv.js", ctx do
      assert BSV.Transaction.get_txid(ctx.tx) == ctx.bsv_txid1
    end

    test "must match with bsv.js after changing fee", ctx do
      tx = BSV.Transaction.set_fee(ctx.tx, 1000)
      |> BSV.Transaction.sign(ctx.keys)

      change = BSV.Transaction.get_change_output(tx)
      assert change.satoshis == ctx.bsv_change2
      assert BSV.Transaction.get_txid(tx) == ctx.bsv_txid2
    end
  end

end

# 304402206372ed66cc9ba2e8e174d1bcccc83c85d85d314daa3c05b2bf00e2b5b3fa23f70220372a3e4326bb29094ecfac38797a8a383d2ed3e1bbd998744db6d142919d0e5141
# 0296207d8752d01b1cf8de77d258c02dd7280edc2bce9b59023311bbd395cbe93a

# 3045022100a65898bc041e2b1fa0a0dbb848d61d7e782cd0a7cba54315bf1c7d9032104ded0220475c5144c1a219d41e93f40b19f052a5ecc3c9811adc6065e1ae03e9f4fb8ed941
# 0296207d8752d01b1cf8de77d258c02dd7280edc2bce9b59023311bbd395cbe93a
