defmodule BSV.BlockTest do
  use ExUnit.Case
  alias BSV.{Block, Util, Transaction}
  doctest BSV.Block

  test "parse/2 with extra data" do
    {block, <<0xFF, 0xEE>>} =
      Block.parse(
        "010000006FE28C0AB6F1B372C1A6A246AE63F74F931E8365E15A089C68D6190000000000982051FD1E4BA744BBBE680E1FEE14677BA1A3C3540BF7B1CDB606E857233E0E61BC6649FFFF001D01E36299FFEE",
        false,
        encoding: :hex
      )

    assert Util.encode(block.hash, :hex) ==
             "00000000839a8e6886ab5951d76f411475428afc90947ee320161bbf18eb6048"

    assert block.transactions == nil
  end

  test "parse/2 with transactions" do
    {block, <<0xFF, 0xEE>>} =
      Block.parse(
        "010000006FE28C0AB6F1B372C1A6A246AE63F74F931E8365E15A089C68D6190000000000982051FD1E4BA744BBBE680E1FEE14677BA1A3C3540BF7B1CDB606E857233E0E61BC6649FFFF001D01E362990101000000010000000000000000000000000000000000000000000000000000000000000000FFFFFFFF0704FFFF001D0104FFFFFFFF0100F2052A0100000043410496B538E853519C726A2C91E61EC11600AE1390813A627C66FB8BE7947BE63C52DA7589379515D4E0A604F8141781E62294721166BF621E73A82CBF2342C858EEAC00000000FFEE",
        true,
        encoding: :hex
      )

    assert Util.encode(block.hash, :hex) ==
             "00000000839a8e6886ab5951d76f411475428afc90947ee320161bbf18eb6048"

    assert length(block.transactions) == 1

    assert hd(block.transactions) |> Transaction.get_txid() ==
             "0e3e2357e806b6cdb1f70b54c3a3a17b6714ee1f0e68bebb44a74b1efd512098"
  end

  test "parse/2 without transactions using blob that includes them" do
    {block, rest} =
      Block.parse(
        "010000006FE28C0AB6F1B372C1A6A246AE63F74F931E8365E15A089C68D6190000000000982051FD1E4BA744BBBE680E1FEE14677BA1A3C3540BF7B1CDB606E857233E0E61BC6649FFFF001D01E362990101000000010000000000000000000000000000000000000000000000000000000000000000FFFFFFFF0704FFFF001D0104FFFFFFFF0100F2052A0100000043410496B538E853519C726A2C91E61EC11600AE1390813A627C66FB8BE7947BE63C52DA7589379515D4E0A604F8141781E62294721166BF621E73A82CBF2342C858EEAC00000000FFEE",
        false,
        encoding: :hex
      )

    assert Util.encode(rest, :hex) ==
             "0101000000010000000000000000000000000000000000000000000000000000000000000000ffffffff0704ffff001d0104ffffffff0100f2052a0100000043410496b538e853519c726a2c91e61ec11600ae1390813a627c66fb8be7947be63c52da7589379515d4e0a604f8141781e62294721166bf621e73a82cbf2342c858eeac00000000ffee"

    assert Util.encode(block.hash, :hex) ==
             "00000000839a8e6886ab5951d76f411475428afc90947ee320161bbf18eb6048"

    assert block.transactions == nil
  end

  test "parse/2 transactions but with blob that does not include them" do
    assert_raise FunctionClauseError, fn ->
      Block.parse(
        "010000006FE28C0AB6F1B372C1A6A246AE63F74F931E8365E15A089C68D6190000000000982051FD1E4BA744BBBE680E1FEE14677BA1A3C3540BF7B1CDB606E857233E0E61BC6649FFFF001D01E36299",
        true,
        encoding: :hex
      )
    end

    assert_raise MatchError, fn ->
      Block.parse(
        "010000006FE28C0AB6F1B372C1A6A246AE63F74F931E8365E15A089C68D6190000000000982051FD1E4BA744BBBE680E1FEE14677BA1A3C3540BF7B1CDB606E857233E0E61BC6649FFFF001D01E36299FFEE",
        true,
        encoding: :hex
      )
    end
  end

  test "serialize/1" do
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
                 <<0, 0, 0, 0, 0, 25, 214, 104, 156, 8, 90, 225, 101, 131, 30, 147, 79, 247, 99,
                   174, 70, 162, 166, 193, 114, 179, 241, 182, 10, 140, 226, 111>>,
               timestamp: ~U[2009-01-09 02:54:25Z],
               transactions: nil,
               version: 1
             })
  end

  test "serialize/1 with transactions" do
    binary_block =
      Util.decode(
        "010000006FE28C0AB6F1B372C1A6A246AE63F74F931E8365E15A089C68D6190000000000982051FD1E4BA744BBBE680E1FEE14677BA1A3C3540BF7B1CDB606E857233E0E61BC6649FFFF001D01E362990101000000010000000000000000000000000000000000000000000000000000000000000000FFFFFFFF0704FFFF001D0104FFFFFFFF0100F2052A0100000043410496B538E853519C726A2C91E61EC11600AE1390813A627C66FB8BE7947BE63C52DA7589379515D4E0A604F8141781E62294721166BF621E73A82CBF2342C858EEAC00000000",
        :hex
      )

    parsed_block = %BSV.Block{
      bits: <<255, 255, 0, 29>>,
      hash:
        <<0, 0, 0, 0, 131, 154, 142, 104, 134, 171, 89, 81, 215, 111, 65, 20, 117, 66, 138, 252,
          144, 148, 126, 227, 32, 22, 27, 191, 24, 235, 96, 72>>,
      merkle_root:
        <<152, 32, 81, 253, 30, 75, 167, 68, 187, 190, 104, 14, 31, 238, 20, 103, 123, 161, 163,
          195, 84, 11, 247, 177, 205, 182, 6, 232, 87, 35, 62, 14>>,
      nonce: <<1, 227, 98, 153>>,
      previous_block:
        <<0, 0, 0, 0, 0, 25, 214, 104, 156, 8, 90, 225, 101, 131, 30, 147, 79, 247, 99, 174, 70,
          162, 166, 193, 114, 179, 241, 182, 10, 140, 226, 111>>,
      timestamp: ~U[2009-01-09 02:54:25Z],
      transactions: [
        %BSV.Transaction{
          change_index: nil,
          change_script: nil,
          fee: nil,
          inputs: [
            %BSV.Transaction.Input{
              output_index: 4_294_967_295,
              output_txid: "0000000000000000000000000000000000000000000000000000000000000000",
              script: %BSV.Script{chunks: [<<255, 255, 0, 29>>, <<4>>]},
              sequence: 4_294_967_295,
              utxo: nil
            }
          ],
          lock_time: 0,
          outputs: [
            %BSV.Transaction.Output{
              satoshis: 5_000_000_000,
              script: %BSV.Script{
                chunks: [
                  <<4, 150, 181, 56, 232, 83, 81, 156, 114, 106, 44, 145, 230, 30, 193, 22, 0,
                    174, 19, 144, 129, 58, 98, 124, 102, 251, 139, 231, 148, 123, 230, 60, 82,
                    218, 117, 137, 55, 149, 21, 212, 224, 166, 4, 248, 20, 23, 129, 230, 34, 148,
                    114, 17, 102, 191, 98, 30, 115, 168, 44, 191, 35, 66, 200, 88, 238>>,
                  :OP_CHECKSIG
                ]
              }
            }
          ],
          version: 1
        }
      ],
      version: 1
    }

    assert binary_block == Block.serialize(parsed_block, true)
    assert Util.encode(binary_block, :hex) == Block.serialize(parsed_block, true, encoding: :hex)

    assert Util.encode(binary_block, :base64) ==
             Block.serialize(parsed_block, true, encoding: :base64)
  end

  test "serialize/1 without transactions using struct that includes them" do
    binary_block =
      Util.decode(
        "010000006FE28C0AB6F1B372C1A6A246AE63F74F931E8365E15A089C68D6190000000000982051FD1E4BA744BBBE680E1FEE14677BA1A3C3540BF7B1CDB606E857233E0E61BC6649FFFF001D01E36299",
        :hex
      )

    assert binary_block ==
             Block.serialize(%BSV.Block{
               bits: <<255, 255, 0, 29>>,
               hash:
                 <<0, 0, 0, 0, 131, 154, 142, 104, 134, 171, 89, 81, 215, 111, 65, 20, 117, 66,
                   138, 252, 144, 148, 126, 227, 32, 22, 27, 191, 24, 235, 96, 72>>,
               merkle_root:
                 <<152, 32, 81, 253, 30, 75, 167, 68, 187, 190, 104, 14, 31, 238, 20, 103, 123,
                   161, 163, 195, 84, 11, 247, 177, 205, 182, 6, 232, 87, 35, 62, 14>>,
               nonce: <<1, 227, 98, 153>>,
               previous_block:
                 <<0, 0, 0, 0, 0, 25, 214, 104, 156, 8, 90, 225, 101, 131, 30, 147, 79, 247, 99,
                   174, 70, 162, 166, 193, 114, 179, 241, 182, 10, 140, 226, 111>>,
               timestamp: ~U[2009-01-09 02:54:25Z],
               transactions: [
                 %BSV.Transaction{
                   change_index: nil,
                   change_script: nil,
                   fee: nil,
                   inputs: [
                     %BSV.Transaction.Input{
                       output_index: 4_294_967_295,
                       output_txid:
                         "0000000000000000000000000000000000000000000000000000000000000000",
                       script: %BSV.Script{chunks: [<<255, 255, 0, 29>>, <<4>>]},
                       sequence: 4_294_967_295,
                       utxo: nil
                     }
                   ],
                   lock_time: 0,
                   outputs: [
                     %BSV.Transaction.Output{
                       satoshis: 5_000_000_000,
                       script: %BSV.Script{
                         chunks: [
                           <<4, 150, 181, 56, 232, 83, 81, 156, 114, 106, 44, 145, 230, 30, 193,
                             22, 0, 174, 19, 144, 129, 58, 98, 124, 102, 251, 139, 231, 148, 123,
                             230, 60, 82, 218, 117, 137, 55, 149, 21, 212, 224, 166, 4, 248, 20,
                             23, 129, 230, 34, 148, 114, 17, 102, 191, 98, 30, 115, 168, 44, 191,
                             35, 66, 200, 88, 238>>,
                           :OP_CHECKSIG
                         ]
                       }
                     }
                   ],
                   version: 1
                 }
               ],
               version: 1
             })
  end

  test "serialize/1 with transactions but struct without them fails" do
    assert_raise FunctionClauseError, fn ->
      Block.serialize(
        %BSV.Block{
          bits: <<255, 255, 0, 29>>,
          hash:
            <<0, 0, 0, 0, 131, 154, 142, 104, 134, 171, 89, 81, 215, 111, 65, 20, 117, 66, 138,
              252, 144, 148, 126, 227, 32, 22, 27, 191, 24, 235, 96, 72>>,
          merkle_root:
            <<152, 32, 81, 253, 30, 75, 167, 68, 187, 190, 104, 14, 31, 238, 20, 103, 123, 161,
              163, 195, 84, 11, 247, 177, 205, 182, 6, 232, 87, 35, 62, 14>>,
          nonce: <<1, 227, 98, 153>>,
          previous_block:
            <<0, 0, 0, 0, 0, 25, 214, 104, 156, 8, 90, 225, 101, 131, 30, 147, 79, 247, 99, 174,
              70, 162, 166, 193, 114, 179, 241, 182, 10, 140, 226, 111>>,
          timestamp: ~U[2009-01-09 02:54:25Z],
          transactions: nil,
          version: 1
        },
        true
      )
    end
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
          <<0, 0, 0, 0, 0, 25, 214, 104, 156, 8, 90, 225, 101, 131, 30, 147, 79, 247, 99, 174, 70,
            162, 166, 193, 114, 179, 241, 182, 10, 140, 226, 111>>,
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
          <<0, 0, 0, 0, 0, 25, 214, 104, 156, 8, 90, 225, 101, 131, 30, 147, 79, 247, 99, 174, 70,
            162, 166, 193, 114, 179, 241, 182, 10, 140, 226, 111>>,
        timestamp: ~U[2009-01-09 02:54:25Z],
        transactions: nil,
        version: 1
      })

    assert id == "00000000839a8e6886ab5951d76f411475428afc90947ee320161bbf18eb6048"
  end
end
