defmodule BSV.TxInTest do
  use ExUnit.Case, async: true
  alias BSV.TxIn
  alias BSV.{OutPoint, Script}

  @txin_hex "5e1bb1a8c3a80dcbed1b08bd55e71e4c3a4e0045bba2dabd8b16103eff2bb062020000006b4830450221008861eda0220f1398701f28020bb61a6cbb36d7467a568f84d0809b59d8b07a580220718bee3962e867132e058ed224607ad345183629a6d4429de8bba1899f0e34ee4121036d2280f540164e6a1fc5b272b2eb4b09b61d6144df474b837d36fbb054e984b7ffffffff"
  @txin_script %Script{chunks: [
    <<48, 69, 2, 33, 0, 136, 97, 237, 160, 34, 15, 19, 152, 112, 31, 40, 2, 11,
      182, 26, 108, 187, 54, 215, 70, 122, 86, 143, 132, 208, 128, 155, 89, 216,
      176, 122, 88, 2, 32, 113, 139, 238, 57, 98, 232, 103, 19, 46, 5, 142, 210,
      36, 96, 122, 211, 69, 24, 54, 41, 166, 212, 66, 157, 232, 187, 161, 137,
      159, 14, 52, 238, 65>>,
    <<3, 109, 34, 128, 245, 64, 22, 78, 106, 31, 197, 178, 114, 178, 235, 75, 9,
      182, 29, 97, 68, 223, 71, 75, 131, 125, 54, 251, 176, 84, 233, 132, 183>>
  ]}
  @outpoint_hash <<94, 27, 177, 168, 195, 168, 13, 203, 237, 27, 8, 189, 85, 231,
    30, 76, 58, 78, 0, 69, 187, 162, 218, 189, 139, 22, 16, 62, 255, 43, 176, 98>>

  doctest TxIn

  describe "TxIn.from_binary/2" do
    test "parses hex encoded p2pkh txin" do
      assert {:ok, %TxIn{script: script} = txin} = TxIn.from_binary(@txin_hex, encoding: :hex)
      assert txin.outpoint.hash == @outpoint_hash
      assert txin.outpoint.vout == 2
      assert script == @txin_script
    end
  end

  describe "TxIn.from_binary!/2" do
    test "parses hex encoded p2pkh txin" do
      assert %TxIn{script: script} = txin = TxIn.from_binary!(@txin_hex, encoding: :hex)
      assert txin.outpoint.hash == @outpoint_hash
      assert txin.outpoint.vout == 2
      assert script == @txin_script
    end
  end

  describe "TxIn.get_size/2" do
    test "returns byte size of the txout" do
      txin = %TxIn{
        outpoint: %OutPoint{hash: @outpoint_hash, vout: 2},
        script: @txin_script
      }
      assert TxIn.get_size(txin) == 148
    end
  end

  describe "TxIn.to_binary/2" do
    test "serialises p2pkh txin as hex string" do
      txin = %TxIn{
        outpoint: %OutPoint{hash: @outpoint_hash, vout: 2},
        script: @txin_script
      }
      assert TxIn.to_binary(txin, encoding: :hex) == @txin_hex
    end
  end

end
