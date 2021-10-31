defmodule BSV.UTXOTest do
  use ExUnit.Case, async: true
  alias BSV.UTXO
  alias BSV.{OutPoint, Script, Tx, TxOut}

  @utxo %UTXO{
    outpoint: %OutPoint{
      hash: <<18, 26, 154, 193, 224, 130, 65, 92, 195, 184, 190, 125, 14, 68, 184, 150, 77, 158, 53, 133, 220, 238, 5, 240, 121, 240, 56, 35, 55, 20, 48, 94>>,
      vout: 0
    },
    txout: %TxOut{
      satoshis: 15399,
      script: %Script{chunks: [
        :OP_DUP,
        :OP_HASH160,
        <<16, 189, 203, 163, 4, 27, 94, 85, 23, 165, 143, 46, 64, 82, 147, 193, 74, 124, 112, 193>>,
        :OP_EQUALVERIFY,
        :OP_CHECKSIG
      ]}
    }
  }

  doctest UTXO

  describe "UTXO.from_params/1" do
    test "parses params with default keys" do
      assert {:ok, utxo} = UTXO.from_params(%{
        "txid" => "5e3014372338f079f005eedc85359e4d96b8440e7dbeb8c35c4182e0c19a1a12",
        "vout" => 0,
        "satoshis" => 15399,
        "script" => "76a91410bdcba3041b5e5517a58f2e405293c14a7c70c188ac"
      })
      assert utxo == @utxo
    end

    test "parses params with alternative keys" do
      assert {:ok, utxo} = UTXO.from_params(%{
        "txid" => "5e3014372338f079f005eedc85359e4d96b8440e7dbeb8c35c4182e0c19a1a12",
        "outputIndex" => 0,
        "amount" => 15399,
        "script" => "76a91410bdcba3041b5e5517a58f2e405293c14a7c70c188ac"
      })
      assert utxo == @utxo
    end

    test "returns error when param not found" do
      assert {:error, {:param_not_found, ["vout", "outputIndex"]}} = UTXO.from_params(%{
        "txid" => "5e3014372338f079f005eedc85359e4d96b8440e7dbeb8c35c4182e0c19a1a12",
        "script" => "76a91410bdcba3041b5e5517a58f2e405293c14a7c70c188ac"
      })
    end
  end

  describe "UTXO.from_params!/1" do
    test "parses params with default keys" do
      assert UTXO.from_params!(%{
        "txid" => "5e3014372338f079f005eedc85359e4d96b8440e7dbeb8c35c4182e0c19a1a12",
        "vout" => 0,
        "satoshis" => 15399,
        "script" => "76a91410bdcba3041b5e5517a58f2e405293c14a7c70c188ac"
      }) == @utxo
    end

    test "raises error when param not found" do
      assert_raise BSV.DecodeError, ~r/param not found/i, fn ->
        UTXO.from_params!(%{
          "txid" => "5e3014372338f079f005eedc85359e4d96b8440e7dbeb8c35c4182e0c19a1a12",
          "script" => "76a91410bdcba3041b5e5517a58f2e405293c14a7c70c188ac"
        })
      end
    end
  end

  describe "UTXO.from_tx/2" do
    test "creates UTXO from existing tx" do
      script = %Script{chunks: [:OP_12, :OP_EQUAL]}
      tx = Tx.add_output(%Tx{}, %TxOut{satoshis: 12345, script: script})
      assert %UTXO{
        outpoint: %OutPoint{vout: 0},
        txout: %TxOut{
          satoshis: 12345,
          script: %Script{chunks: [:OP_12, :OP_EQUAL]}
        }
      } = UTXO.from_tx(tx, 0)
    end
  end

end
