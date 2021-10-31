defmodule BSV.TxOutTest do
  use ExUnit.Case, async: true
  alias BSV.TxOut
  alias BSV.Script

  @txout_hex "efbee82f000000001976a9145ae866af9de106847de6111e5f1faa168b2be68988ac"
  @txout_script %Script{chunks: [
    :OP_DUP,
    :OP_HASH160,
    <<90, 232, 102, 175, 157, 225, 6, 132, 125, 230, 17, 30, 95, 31, 170, 22, 139, 43, 230, 137>>,
    :OP_EQUALVERIFY,
    :OP_CHECKSIG
  ]}

  doctest TxOut

  describe "TxOut.from_binary/2" do
    test "parses hex encoded p2pkh txout" do
      assert {:ok, %TxOut{script: script} = txout} = TxOut.from_binary(@txout_hex, encoding: :hex)
      assert txout.satoshis == 803782383
      assert script == @txout_script
    end
  end

  describe "TxOut.from_binary!/2" do
    test "parses hex encoded p2pkh txout" do
      assert %TxOut{script: script} = txout = TxOut.from_binary!(@txout_hex, encoding: :hex)
      assert txout.satoshis == 803782383
      assert script == @txout_script
    end
  end

  describe "TxOut.get_size/2" do
    test "returns byte size of the txout" do
      txout = %TxOut{satoshis: 803782383, script: @txout_script}
      assert TxOut.get_size(txout) == 34
    end
  end

  describe "TxOut.to_binary/2" do
    test "serialises p2pkh txout as hex string" do
      txout = %TxOut{satoshis: 803782383, script: @txout_script}
      assert TxOut.to_binary(txout, encoding: :hex) == @txout_hex
    end
  end

end
