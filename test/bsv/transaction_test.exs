defmodule BSV.TransactionTest do
  use ExUnit.Case
  doctest BSV.Transaction

  setup_all do
    %{
      tx1: "02000000027bb22176433bb45bacede86a43764f98c7023f1a79b00138e3d3ea610716a8f1010000006b483045022100c7036739f47361398bd115dbe9302fdc456d75f83fb38e531f4a445c8385138a022006f68ca095a35886f3eb217f416650490a3f0a279f8dc564d0222c884002f85841210232b357c5309644cf4aa72b9b2d8bfe58bdf2515d40119318d5cb51ef378cae7effffffff197725400c9846a19a03cfd151bd089b9ec3e90ecbfa72b9c5448d52b2baae43020000006b483045022100b23044350aaaafb08480fee7addadde918c2b5515b66a3c445be05ca809ce290022044c89daa88303522cb72830ab71d1411da65f0a58dca43fcd998f80df3794cc441210282d7e568e56f59e01a4edae297ac26caabc4684971ac6c7558c91c0fa84002f7ffffffff03efbee82f000000001976a914c4263eb96d88849f498d139424b59a0cba1005e888ac010c1dfa000000001976a9146cbff9881ac47da8cb699e4543c28f9b3d6941da88ac404b4c00000000001976a914f7899faf1696892e6cb029b00c713f044761f03588ac00000000"
    }
  end


  describe "BSV.Transaction.parse/2" do
    test "must parse into Transaction", ctx do
      {tx, ""} = BSV.Transaction.parse(ctx.tx1, encoding: :hex)
      assert length(tx.inputs) == 2
      assert length(tx.outputs) == 3
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

end
