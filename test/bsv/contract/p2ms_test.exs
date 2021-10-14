defmodule BSV.Contract.P2MSTest do
  use ExUnit.Case, async: true
  alias BSV.Contract.P2MS
  alias BSV.{Contract, ExtKey, Script, TxOut, UTXO, VM}

  @test_xprv "xprv9s21ZrQH143K3qcbMJpvTQQQ1zRCPaZjXUD1zPouMDtKY9QQQ9DskzrZ3Cx38GnYXpgY2awCmJfz2QXkpxLN3Pp2PmUddbnrXziFtArpZ5v"
  @master_key ExtKey.from_string!(@test_xprv)
  @keys Enum.map(1..3, & ExtKey.derive(@master_key, "m/#{&1}"))
  @pubkeys Enum.map(@keys, & &1.pubkey)
  @privkeys Enum.take(@keys, 2) |> Enum.map(& &1.privkey)
  doctest P2MS

  describe "lock/2" do
    test "locks satoshis to a threshold of pubkeys" do
      contract = P2MS.lock(1000, %{pubkeys: @pubkeys, threshold: 2})
      assert %TxOut{satoshis: 1000, script: script} = Contract.to_txout(contract)
      assert %Script{chunks: [:OP_2, <<_::binary-33>>, <<_::binary-33>>, <<_::binary-33>>, :OP_3, :OP_CHECKMULTISIG]} = script
    end

    test "raises an error if the arguments are not valid" do
      assert_raise FunctionClauseError, fn ->
        P2MS.lock(1000, %{pubkeys: ["not pubkeys"]}) |> Contract.to_txout()
      end
    end
  end

  describe "unlock/2" do
    test "unlocks UTXO with given privkey" do
      contract = P2MS.unlock(%UTXO{}, %{privkeys: @privkeys})
      assert %Script{chunks: [:OP_0, <<_::binary-71>>, <<_::binary-71>>]} = Contract.to_script(contract)
    end

    test "raises an error if the arguments are not valid" do
      assert_raise FunctionClauseError, fn ->
        P2MS.unlock(%UTXO{}, %{privkeys: ["not privkey"]}) |> Contract.to_script()
      end
    end
  end

  describe "Contract.test_run/3" do
    test "evaluates as truthy" do
      assert {:ok, vm} = Contract.test_run(P2MS, %{pubkeys: @pubkeys, threshold: 2}, %{privkeys: @privkeys})
      assert VM.valid?(vm)
    end
  end

end
