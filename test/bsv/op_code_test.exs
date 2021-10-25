defmodule BSV.OpCodeTest do
  use ExUnit.Case, async: true
  alias BSV.OpCode
  doctest OpCode

  describe "OpCode.all/0" do
    test "returns a map of Op Codes" do
      assert is_map(OpCode.all())
    end
  end

  describe "OpCode.to_atom/1" do
    test "converts integers to atoms" do
      assert OpCode.to_atom(0) == :OP_FALSE
      assert OpCode.to_atom(96) == :OP_16
      assert OpCode.to_atom(97) == :OP_NOP
    end

    test "returns nil if invalid op code" do
      assert OpCode.to_atom(1) == nil
    end
  end

  describe "OpCode.to_atom!/1" do
    test "raises error if invalid op code" do
      assert_raise BSV.DecodeError, ~r/invalid op code/i, fn ->
        OpCode.to_atom!(1)
      end
    end
  end

  describe "OpCode.to_integer/1" do
    test "converts integers to atoms" do
      assert OpCode.to_integer(:OP_0) == 0
      assert OpCode.to_integer(:OP_16) == 96
      assert OpCode.to_integer(:OP_NOP) == 97
    end

    test "returns nil if invalid op code" do
      assert OpCode.to_integer(:OP_FOO) == nil
    end
  end

  describe "OpCode.to_integer!/1" do
    test "raises error if invalid op code" do
      assert_raise BSV.DecodeError, ~r/invalid op code/i, fn ->
        OpCode.to_integer!(:OP_FOO)
      end
    end
  end


end
