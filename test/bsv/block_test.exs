defmodule BSV.BlockTest do
  use ExUnit.Case
  alias BSV.Block
  alias BSV.Util
  doctest BSV.Block

  test "parse/2 with extra data" do
    {block, <<0xFF, 0xEE>>} =
      Block.parse(
        "010000006FE28C0AB6F1B372C1A6A246AE63F74F931E8365E15A089C68D6190000000000982051FD1E4BA744BBBE680E1FEE14677BA1A3C3540BF7B1CDB606E857233E0E61BC6649FFFF001D01E36299FFEE",
        encoding: :hex
      )

    assert Util.encode(block.hash, :hex) ==
             "00000000839a8e6886ab5951d76f411475428afc90947ee320161bbf18eb6048"
  end

  test "serialize/1 " do
    binary_block =
      Util.decode(
        "010000006FE28C0AB6F1B372C1A6A246AE63F74F931E8365E15A089C68D6190000000000982051FD1E4BA744BBBE680E1FEE14677BA1A3C3540BF7B1CDB606E857233E0E61BC6649FFFF001D01E36299",
        :hex
      )

    assert binary_block ==
             Block.serialize(%Block{
               bits: <<255, 255, 0, 29>>,
               hash:
                 <<0, 0, 0, 0, 131, 154, 142, 104, 134, 171, 89, 81, 215, 111, 65, 20, 117, 66,
                   138, 252, 144, 148, 126, 227, 32, 22, 27, 191, 24, 235, 96, 72>>,
               merkle_root:
                 <<152, 32, 81, 253, 30, 75, 167, 68, 187, 190, 104, 14, 31, 238, 20, 103, 123,
                   161, 163, 195, 84, 11, 247, 177, 205, 182, 6, 232, 87, 35, 62, 14>>,
               nonce: <<1, 227, 98, 153>>,
               previous_block:
                 <<0, 0, 0, 0, 0, 25, 214, 104, 156, 8, 90, 225, 101, 131, 30, 147, 79, 247,
                   99, 174, 70, 162, 166, 193, 114, 179, 241, 182, 10, 140, 226, 111>>,
               timestamp: ~U[2009-01-09 02:54:25Z],
               transactions: nil,
               version: 1
             })
  end

  test "hash/1 without the pre-computed hash" do
    hash =
      Block.hash(%Block{
        bits: <<255, 255, 0, 29>>,
        hash: nil,
        merkle_root:
          <<152, 32, 81, 253, 30, 75, 167, 68, 187, 190, 104, 14, 31, 238, 20, 103, 123, 161, 163,
            195, 84, 11, 247, 177, 205, 182, 6, 232, 87, 35, 62, 14>>,
        nonce: <<1, 227, 98, 153>>,
        previous_block:
          <<0, 0, 0, 0, 0, 25, 214, 104, 156, 8, 90, 225, 101, 131, 30, 147, 79, 247,
            99, 174, 70, 162, 166, 193, 114, 179, 241, 182, 10, 140, 226, 111>>,
        timestamp: ~U[2009-01-09 02:54:25Z],
        transactions: nil,
        version: 1
      })

    assert hash ==
             <<0, 0, 0, 0, 131, 154, 142, 104, 134, 171, 89, 81, 215, 111, 65, 20, 117, 66, 138,
               252, 144, 148, 126, 227, 32, 22, 27, 191, 24, 235, 96, 72>>
  end

  test "id/1 without the pre-computed hash" do
    id =
      Block.id(%Block{
        bits: <<255, 255, 0, 29>>,
        hash: nil,
        merkle_root:
          <<152, 32, 81, 253, 30, 75, 167, 68, 187, 190, 104, 14, 31, 238, 20, 103, 123, 161, 163,
            195, 84, 11, 247, 177, 205, 182, 6, 232, 87, 35, 62, 14>>,
        nonce: <<1, 227, 98, 153>>,
        previous_block:
          <<0, 0, 0, 0, 0, 25, 214, 104, 156, 8, 90, 225, 101, 131, 30, 147, 79, 247,
            99, 174, 70, 162, 166, 193, 114, 179, 241, 182, 10, 140, 226, 111>>,
        timestamp: ~U[2009-01-09 02:54:25Z],
        transactions: nil,
        version: 1
      })

    assert id == "00000000839a8e6886ab5951d76f411475428afc90947ee320161bbf18eb6048"
  end
end
