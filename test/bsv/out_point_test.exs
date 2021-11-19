defmodule BSV.OutPointTest do
  use ExUnit.Case, async: true
  alias BSV.OutPoint

  @outpoint_bin <<94, 27, 177, 168, 195, 168, 13, 203, 237, 27, 8, 189, 85, 231,
    30, 76, 58, 78, 0, 69, 187, 162, 218, 189, 139, 22, 16, 62, 255, 43, 176, 98, 2, 0, 0, 0>>
  @outpoint %OutPoint{
    hash: <<94, 27, 177, 168, 195, 168, 13, 203, 237, 27, 8, 189, 85, 231,
      30, 76, 58, 78, 0, 69, 187, 162, 218, 189, 139, 22, 16, 62, 255, 43, 176, 98>>,
    vout: 2
  }
  @null_outpoint %OutPoint{
    hash: <<0::256>>,
    vout: 0xFFFFFFFF
  }

  doctest OutPoint

  describe "OutPoint.from_binary/2" do
    test "parses binary outpoint" do
      assert {:ok, outpoint} = OutPoint.from_binary(@outpoint_bin)
      assert outpoint == @outpoint
    end
  end

  describe "OutPoint.from_binary!/2" do
    test "parses binary outpoint" do
      assert %OutPoint{vout: 2} = OutPoint.from_binary!(@outpoint_bin)
    end
  end

  describe "OutPoint.get_txid/1" do
    test "returns txid from outpoint" do
      assert txid = OutPoint.get_txid(@outpoint)
      assert txid == "62b02bff3e10168bbddaa2bb45004e3a4c1ee755bd081bedcb0da8c3a8b11b5e"
    end
  end

  describe "OutPoint.is_null?/1" do
    test "checks of outpoint is null" do
      refute OutPoint.is_null?(@outpoint)
      assert OutPoint.is_null?(@null_outpoint)
    end
  end

  describe "OutPoint.to_binary/2" do
    test "serialises the outpoint" do
      assert OutPoint.to_binary(@outpoint) == @outpoint_bin
      outpoint_hex = OutPoint.to_binary(@null_outpoint, encoding: :hex)
      assert outpoint_hex == "0000000000000000000000000000000000000000000000000000000000000000ffffffff"
    end
  end

end
