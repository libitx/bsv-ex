defmodule BSV.TxTest do
  use ExUnit.Case, async: true
  alias BSV.Tx
  doctest Tx

  @tx1_hex "010000000160f61507c2560a0246b53b96e9a8d28f66d82a8b028204b820de6d10c608d8ad030000006a473044022031a761006d72db7a088a4336c50ea4ca5a8aa76cf355e9ae3866ed3994d0748802205abaa90be33ef7211575b933c0f0a688c3ae175ab55cd8e75f0e07364e4e76d6412103d878146ae9f687c95ac05395db7dfdf2698bdc246158f8672257aab631e4c65cffffffff0123020000000000001976a9142eab375745d7799792b5c5f8b5a9406b8ad55bcc88ac00000000"
  @tx2_hex "01000000010000000000000000000000000000000000000000000000000000000000000000ffffffff41031bc50a2f7461616c2e636f6d2f506c656173652070617920302e3520736174732f627974652c20696e666f407461616c2e636f6d0448aa01c3a015e815410100ffffffff01f072a32e000000001976a9147afaeecc8486abdc2473c48c711a57de958d4bcf88ac00000000"

  describe "Tx.from_binary/2" do
    test "parses hex encoded p2pkh tx" do
      assert {:ok, tx} = Tx.from_binary(@tx1_hex, encoding: :hex)
      assert length(tx.inputs) == 1
      assert length(tx.outputs) == 1
      refute Tx.is_coinbase?(tx)
    end

    test "parses hex encoded coinbase tx" do
      assert {:ok, tx} = Tx.from_binary(@tx2_hex, encoding: :hex)
      assert length(tx.inputs) == 1
      assert length(tx.outputs) == 1
      assert Tx.is_coinbase?(tx)
    end
  end

end
