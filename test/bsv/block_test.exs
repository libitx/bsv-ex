defmodule BSV.BlockTest do
  use ExUnit.Case, async: true
  alias BSV.Block

  @block_hex "010000006fe28c0ab6f1b372c1a6a246ae63f74f931e8365e15a089c68d6190000000000982051fd1e4ba744bbbe680e1fee14677ba1a3c3540bf7b1cdb606e857233e0e61bc6649ffff001d01e362990101000000010000000000000000000000000000000000000000000000000000000000000000ffffffff0704ffff001d0104ffffffff0100f2052a0100000043410496b538e853519c726a2c91e61ec11600ae1390813a627c66fb8be7947be63c52da7589379515d4e0a604f8141781e62294721166bf621e73a82cbf2342c858eeac00000000"

  @block %Block{
    header: %BSV.BlockHeader{
      bits: 486604799,
      merkle_root: <<152, 32, 81, 253, 30, 75, 167, 68, 187, 190, 104, 14, 31,
        238, 20, 103, 123, 161, 163, 195, 84, 11, 247, 177, 205, 182, 6, 232, 87,
        35, 62, 14>>,
      nonce: 2573394689,
      prev_hash: <<111, 226, 140, 10, 182, 241, 179, 114, 193, 166, 162, 70, 174,
        99, 247, 79, 147, 30, 131, 101, 225, 90, 8, 156, 104, 214, 25, 0, 0, 0, 0,
        0>>,
      time: 1231469665,
      version: 1
    },
    txns: [
      %BSV.Tx{
        inputs: [
          %BSV.TxIn{
            outpoint: %BSV.OutPoint{
              hash: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0>>,
              vout: 4294967295
            },
            script: %BSV.Script{
              chunks: [],
              coinbase: <<4, 255, 255, 0, 29, 1, 4>>
            },
            sequence: 4294967295
          }
        ],
        lock_time: 0,
        outputs: [
          %BSV.TxOut{
            satoshis: 5000000000,
            script: %BSV.Script{
              chunks: [
                <<4, 150, 181, 56, 232, 83, 81, 156, 114, 106, 44, 145, 230, 30,
                  193, 22, 0, 174, 19, 144, 129, 58, 98, 124, 102, 251, 139, 231,
                  148, 123, 230, 60, 82, 218, 117, 137, 55, 149, 21, 212, 224,
                  166, 4, 248, 20, 23, 129, 230, 34, 148, 114, 17, 102, 191, 98,
                  30, 115, 168, 44, 191, 35, 66, 200, 88, 238>>,
                :OP_CHECKSIG
              ],
              coinbase: nil
            }
          }
        ],
        version: 1
      }
    ]
  }

  doctest Block

  describe "Block.calc_merkle_root/1" do
    test "calculates the correct merkle root of the block" do
      merkle_root = Block.calc_merkle_root(@block)
      assert merkle_root == @block.header.merkle_root
    end
  end

  describe "Block.from_binary/2" do
    test "parses hex encoded block" do
      assert {:ok, block} = Block.from_binary(@block_hex, encoding: :hex)
      assert block == @block
    end

    test "returns error with invalid block" do
      assert {:error, _error} = Block.from_binary("010000006FE28C0AB6F1B372C1A6A246AE63", encoding: :hex)
    end
  end

  describe "Block.from_binary!/2" do
    test "parses hex encoded block" do
      assert block = Block.from_binary!(@block_hex, encoding: :hex)
      assert block == @block
    end

    test "raises error with invalid binary" do
      assert_raise BSV.DecodeError, ~r/invalid block/i, fn ->
        Block.from_binary!("010000006FE28C0AB6F1B372C1A6A246AE63", encoding: :hex)
      end
    end
  end

  describe "Block.to_binary/2" do
    test "serialises block as hex encoded string" do
      assert block = Block.to_binary(@block, encoding: :hex)
      assert block == @block_hex
    end
  end

  describe "Block.validate_merkle_root/1" do
    test "validates the merkle root of the block" do
      assert Block.validate_merkle_root(@block)
      incorrect = put_in(@block.header.merkle_root, <<0,0,0,0>>)
      refute Block.validate_merkle_root(incorrect)
    end
  end

end
