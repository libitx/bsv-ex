defmodule BSV.ScriptTest do
  use ExUnit.Case, async: true
  alias BSV.Script

  @p2pkh_asm "OP_DUP OP_HASH160 5ae866af9de106847de6111e5f1faa168b2be689 OP_EQUALVERIFY OP_CHECKSIG"
  @p2pkh_hex "76a9145ae866af9de106847de6111e5f1faa168b2be68988ac"
  @p2pkh_script Script.from_binary!(@p2pkh_hex, encoding: :hex)
  @univ_hex "006a04554e495616a16570726f746f6e63616c6c656469742e7069636b734d66015901637d95c5be99732eed66d512571bfb89d80c1f611a4ee0f41c80485dc49d3390fa2576dfea581298526a1dfe16e66420a4a843342dd9f0958e2673231bcbab7dd12541f0eadff452d953cab9bc0e294dcfd0a00c0e84ebcdd4093bc4ede87f83974e9ed9d2f993cdd1abfc82a6aedf327bb2b42deebce741ae0b30ce901a6c296fb23636aeac2bdecdd347fd179577a3b55854b028991d4e345c91d12bf53af488605018d9d45fc3685aad3f18896ab69bc960bfd3850a73d1fb52b9c3708e93f0d83d3f7a80e5f5446d77ebc1e0a693f55eb4dd4bb48ad27b016d42e0ffc2a68ca92627cd23f6f3d6c27a4b4ab570bc40e5e48c0febeea16c01dc96dcc2f1f830b9630f49dc66a5c79ef3261f17be18ba59013c9b94103a5fa6bd3268d21ba3f6df5316ffb53b221ae0c5c1556d699f04eb9d60ab580c7f26f1a7577f6c26708211973ae3b2319019651510ff13985aa65bf54fdafbd2d2f8344685ae2cc5c3270b207301f63c82a463616c67674131323847434d6269764c13a57768ed8b4ce54977822a636b696463454b316374616750f02379c1cecbfcb6247c0bf25501cbf2f6"

  doctest Script

  describe "Script.from_asm/1" do
    test "parses ASM encoded p2pkh script" do
      assert {:ok, %Script{chunks: chunks}} = Script.from_asm(@p2pkh_asm)
      assert [:OP_DUP, :OP_HASH160, _pubkey_hash, :OP_EQUALVERIFY, :OP_CHECKSIG] = chunks
    end

    test "returns error with invalid ASM" do
      assert {:error, _error} = Script.from_asm("OP_RETURN xyz OP_0")
    end
  end

  describe "Script.from_asm!/1" do
    test "parses ASM encoded p2pkh script" do
      assert %Script{chunks: chunks} = Script.from_asm!(@p2pkh_asm)
      assert [:OP_DUP, :OP_HASH160, _pubkey_hash, :OP_EQUALVERIFY, :OP_CHECKSIG] = chunks
    end

    test "raises error with invalid ASM" do
      assert_raise BSV.DecodeError, ~r/error decoding/i, fn ->
        assert {:error, _error} = Script.from_asm!("OP_RETURN xyz OP_0")
      end
    end
  end

  describe "Script.from_binary/2" do
    test "parses hex encoded p2pkh script" do
      assert {:ok, %Script{chunks: chunks}} = Script.from_binary(@p2pkh_hex, encoding: :hex)
      assert [:OP_DUP, :OP_HASH160, _pubkey_hash, :OP_EQUALVERIFY, :OP_CHECKSIG] = chunks
    end

    test "parses hex encoded UNIV script" do
      assert {:ok, %Script{chunks: chunks}} = Script.from_binary(@univ_hex, encoding: :hex)
      assert [:OP_FALSE, :OP_RETURN, "UNIV" | _rest] = chunks
      assert length(chunks) == 7
    end
  end

  describe "Script.push/2" do
    setup do
      %{script: %Script{chunks: [:OP_FALSE, :OP_RETURN]}}
    end

    test "pushes an opcode into the script by atom", %{script: script} do
      assert %Script{chunks: chunks} = Script.push(script, :OP_CODESEPARATOR)
      assert [:OP_FALSE, :OP_RETURN, :OP_CODESEPARATOR] = chunks
    end

    test "pushes an opcode into the script by integer", %{script: script} do
      assert %Script{chunks: chunks} = Script.push(script, 171)
      assert [:OP_FALSE, :OP_RETURN, <<171, 0>>] = chunks
    end

    test "pushes an binary into the script", %{script: script} do
      assert %Script{chunks: chunks} = Script.push(script, "hello world")
      assert [:OP_FALSE, :OP_RETURN, "hello world"] = chunks
    end
  end

  describe "Script.size/1" do
    test "returns the size of the given script" do
      assert Script.size(@p2pkh_script) == 25
    end
  end

  describe "Script.to_asm/1" do
    test "serialises p2pkh script as ASM string" do
      script = %Script{chunks: [:OP_DUP, :OP_HASH160, <<90, 232, 102, 175, 157, 225, 6, 132, 125, 230, 17, 30, 95, 31, 170, 22, 139, 43, 230, 137>>, :OP_EQUALVERIFY, :OP_CHECKSIG]}
      assert Script.to_asm(script) == @p2pkh_asm
    end
  end

  describe "Script.to_binary/1" do
    test "serialises p2pkh script as hex string" do
      script = %Script{chunks: [:OP_DUP, :OP_HASH160, <<90, 232, 102, 175, 157, 225, 6, 132, 125, 230, 17, 30, 95, 31, 170, 22, 139, 43, 230, 137>>, :OP_EQUALVERIFY, :OP_CHECKSIG]}
      assert Script.to_binary(script, encoding: :hex) == @p2pkh_hex
    end
  end

end
