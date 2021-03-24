defmodule BSV.ScriptTest do
  use ExUnit.Case
  alias BSV.Script
  doctest BSV.Script


  describe "parse/2" do
    test "parses asm script" do
      script = Script.parse("OP_DUP OP_HASH160 39a38792f05d651eeb43633cfd0083ede696597c OP_EQUALVERIFY OP_CHECKSIG", encoding: :asm)
      assert length(script.chunks) == 5
    end

    test "parses hex script" do
      script = Script.parse("76a91439a38792f05d651eeb43633cfd0083ede696597c88ac", encoding: :hex)
      assert length(script.chunks) == 5
    end
  end


  describe "serialize/2" do
    test "serlializes as ASM" do
      assert "OP_1 OP_2 OP_RETURN 68656c6c6f" == Script.serialize(%Script{chunks: [:OP_1, :OP_2, :OP_RETURN, "hello"]}, encoding: :asm)
    end

    test "works with coinbase script" do
      assert "keep calm and BSV on" == Script.serialize(%Script{coinbase: "keep calm and BSV on"})
    end

    test "fails if both chunks and coinbase are set" do
      assert_raise FunctionClauseError, fn ->
        Script.serialize(%Script{coinbase: "keep calm and BSV on", chunks: [:OP_1]})
      end
    end
  end

  test "is_coinbase/1 fails if both chunks and coinbase are set" do
    assert_raise FunctionClauseError, fn ->
      Script.is_coinbase(%Script{coinbase: "keep calm and BSV on", chunks: [:OP_1]})
    end
  end
end
