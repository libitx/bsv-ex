defmodule BSV.BlockHeaderTest do
  use ExUnit.Case, async: true
  alias BSV.BlockHeader

  @block_header_hex "0100000005050505050505050505050505050505050505050505050505050505050505050909090909090909090909090909090909090909090909090909090909090909020000000300000004000000"
  @block_header %BlockHeader{
    version: 1,
    prev_hash: <<5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5>>,
    merkle_root: <<9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9>>,
    time: 2,
    bits: 3,
    nonce: 4
  }

  doctest BlockHeader

  describe "BlockHeader.from_binary/2" do
    test "parses hex encoded block header" do
      assert {:ok, header} = BlockHeader.from_binary(@block_header_hex, encoding: :hex)
      assert header == @block_header
    end

    test "returns error with invalid header" do
      assert {:error, _error} = BlockHeader.from_binary("010000000505050505050505050505050505", encoding: :hex)
    end
  end

  describe "BlockHeader.from_binary!/2" do
    test "parses hex encoded block header" do
      assert header = BlockHeader.from_binary!(@block_header_hex, encoding: :hex)
      assert header == @block_header
    end

    test "raises error with invalid binary" do
      assert_raise BSV.DecodeError, ~r/invalid block header/i, fn ->
        BlockHeader.from_binary!("010000000505050505050505050505050505", encoding: :hex)
      end
    end
  end

  describe "BlockHeader.to_binary/2" do
    test "serialises block header as hex encoded string" do
      assert header = BlockHeader.to_binary(@block_header, encoding: :hex)
      assert header == @block_header_hex
    end
  end

end
