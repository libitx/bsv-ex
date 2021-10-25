defmodule BSV.MerkleProofTest do
  use ExUnit.Case, async: true
  alias BSV.MerkleProof
  doctest MerkleProof

  @merkle_proof_hex "000cef65a4611570303539143dabd6aa64dbd0f41ed89074406dc0e7cd251cf1efff69f17b44cfe9c2a23285168fe05084e1254daa5305311ed8cd95b19ea6b0ed7505008e66d81026ddb2dae0bd88082632790fc6921b299ca798088bef5325a607efb9004d104f378654a25e35dbd6a539505a1e3ddbba7f92420414387bb5b12fc1c10f00472581a20a043cee55edee1c65dd6677e09903f22992062d8fd4b8d55de7b060006fcc978b3f999a3dbb85a6ae55edc06dd9a30855a030b450206c3646dadbd8c000423ab0273c2572880cdc0030034c72ec300ec9dd7bbc7d3f948a9d41b3621e39"
  @merkle_proof %BSV.MerkleProof{
    flags: 0,
    index: 12,
    nodes: [
      <<142, 102, 216, 16, 38, 221, 178, 218, 224, 189, 136, 8, 38, 50, 121, 15, 198, 146, 27, 41, 156, 167, 152, 8, 139, 239, 83, 37, 166, 7, 239, 185>>,
      <<77, 16, 79, 55, 134, 84, 162, 94, 53, 219, 214, 165, 57, 80, 90, 30, 61, 219, 186, 127, 146, 66, 4, 20, 56, 123, 181, 177, 47, 193, 193, 15>>,
      <<71, 37, 129, 162, 10, 4, 60, 238, 85, 237, 238, 28, 101, 221, 102, 119, 224, 153, 3, 242, 41, 146, 6, 45, 143, 212, 184, 213, 93, 231, 176, 96>>,
      <<111, 204, 151, 139, 63, 153, 154, 61, 187, 133, 166, 174, 85, 237, 192, 109, 217, 163, 8, 85, 160, 48, 180, 80, 32, 108, 54, 70, 218, 219, 216, 192>>,
      <<66, 58, 176, 39, 60, 37, 114, 136, 12, 220, 0, 48, 3, 76, 114, 236, 48, 14, 201, 221, 123, 188, 125, 63, 148, 138, 157, 65, 179, 98, 30, 57>>
    ],
    subject: <<239, 101, 164, 97, 21, 112, 48, 53, 57, 20, 61, 171, 214, 170, 100, 219, 208, 244, 30, 216, 144, 116, 64, 109, 192, 231, 205, 37, 28, 241, 239, 255>>,
    target: <<105, 241, 123, 68, 207, 233, 194, 162, 50, 133, 22, 143, 224, 80, 132, 225, 37, 77, 170, 83, 5, 49, 30, 216, 205, 149, 177, 158, 166, 176, 237, 117>>

  }
  @merkle_root <<112, 47, 97, 187, 145, 58, 194, 6, 62, 15, 42, 237, 109, 147, 61, 51, 134, 35, 77, 165, 200, 235, 158, 48, 228, 152, 239, 210, 95, 183, 203, 150>>

  describe "MerkleProof.from_binary/2" do
    test "parses hex encoded Merkle proof" do
      assert {:ok, proof} = MerkleProof.from_binary(@merkle_proof_hex, encoding: :hex)
      assert proof == @merkle_proof
    end

    test "returns error with invalid proof" do
      assert {:error, _error} = MerkleProof.from_binary("000cef65a4611570303539143dabd6aa64db", encoding: :hex)
    end
  end

  describe "MerkleProof.from_binary!/2" do
    test "parses hex encoded Merkle proof" do
      assert %MerkleProof{} = MerkleProof.from_binary!(@merkle_proof_hex, encoding: :hex)
    end

    test "returns error with invalid proof" do
      assert_raise BSV.DecodeError, ~r/invalid merkle proof/i, fn ->
        MerkleProof.from_binary!("000cef65a4611570303539143dabd6aa64db", encoding: :hex)
      end
    end
  end

  describe "MerkleProof.calc_merkle_root/1" do
    test "calculates the correct merkle proof" do
      assert MerkleProof.calc_merkle_root(@merkle_proof) == @merkle_root
    end
  end

  describe "MerkleProof.to_binary/2" do
    test "serialises the proof as hex string" do
      assert MerkleProof.to_binary(@merkle_proof, encoding: :hex) == @merkle_proof_hex
    end
  end



end
