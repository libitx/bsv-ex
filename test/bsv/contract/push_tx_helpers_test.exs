defmodule BSV.Contract.PushTxHelpersTest do
  use ExUnit.Case, async: true
  alias BSV.Contract.{Helpers, PushTxHelpers}
  alias BSV.{Contract, Hash, OutPoint, Script, ScriptNum, Sig, Tx, TxIn, TxOut, UTXO, VM}

  @prev_txout %TxOut{
    satoshis: 50000,
    script: %Script{chunks: [
      :OP_DUP,
      :OP_HASH160,
      <<47, 105, 50, 137, 102, 179, 60, 141, 131, 76, 2, 71, 24, 254, 231, 1, 101, 139, 55, 71>>,
      :OP_EQUALVERIFY,
      :OP_CHECKSIG
    ]}
  }
  @test_txin %TxIn{
    outpoint: %OutPoint{
      hash: Tx.get_hash(%Tx{outputs: [@prev_txout]}),
      vout: 0
    },
    script: %Script{}
  }
  @test_tx %Tx{inputs: [@test_txin]}
  @preimage Sig.preimage(@test_tx, 0, @prev_txout, 0x41)

  describe "PushTxHelpers helpers" do
    setup do
      contract = Helpers.push(%Contract{}, @preimage)
      {:ok, contract: contract}
    end

    test "get_version/1 puts tx version on top of stack", %{contract: contract} do
      %{script: script} = PushTxHelpers.get_version(contract)
      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [ScriptNum.encode(1), @preimage]
    end

    test "get_prevouts_hash/1 puts prev outpoints hash on top of stack", %{contract: contract} do
      %{script: script} = PushTxHelpers.get_prevouts_hash(contract)
      hash = OutPoint.to_binary(@test_txin.outpoint)
      |> Hash.sha256_sha256()

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [hash, @preimage]
    end

    test "get_sequence_hash/1 puts txin sequence hash on top of stack", %{contract: contract} do
      %{script: script} = PushTxHelpers.get_sequence_hash(contract)
      hash = Hash.sha256_sha256(<<@test_txin.sequence::little-32>>)

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [hash, @preimage]
    end

    test "get_outpoint/1 puts txin outpoint on top of stack", %{contract: contract} do
      %{script: script} = PushTxHelpers.get_outpoint(contract)
      data = OutPoint.to_binary(@test_txin.outpoint)

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [data, @preimage]
    end

    test "get_script/1 puts prev txout script on top of stack", %{contract: contract} do
      %{script: script} = PushTxHelpers.get_script(contract)
      data = Script.to_binary(@prev_txout.script)

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [data, @preimage]
    end

    test "get_satoshis/1 puts txin satoshis on top of stack", %{contract: contract} do
      %{script: script} = PushTxHelpers.get_satoshis(contract)

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [ScriptNum.encode(50000), @preimage]
    end

    test "get_sequence/1 puts txin sequence on top of stack", %{contract: contract} do
      %{script: script} = PushTxHelpers.get_sequence(contract)

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [ScriptNum.encode(0xFFFFFFFF), @preimage]
    end

    test "get_outputs_hash/1 puts tx outputs hash on top of stack", %{contract: contract} do
      %{script: script} = PushTxHelpers.get_outputs_hash(contract)

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [Hash.sha256_sha256(<<>>), @preimage]
    end

    test "get_lock_time/1 puts tx locktime on top of stack", %{contract: contract} do
      %{script: script} = PushTxHelpers.get_lock_time(contract)

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [ScriptNum.encode(0), @preimage]
    end

    test "get_sighash_type/1 puts tx sighash type on top of stack", %{contract: contract} do
      %{script: script} = PushTxHelpers.get_sighash_type(contract)

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [ScriptNum.encode(0x41), @preimage]
    end
  end

  describe "push_tx/1" do
    test "pushes the tx preimage onto the stack" do
      %{script: script} = PushTxHelpers.push_tx(%Contract{ctx: {@test_tx, 0}, subject: %UTXO{
        outpoint: @test_txin.outpoint,
        txout: @prev_txout
      }})

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [@preimage]
    end

    test "pushes zero bytes placeholder onto the stack without context" do
      %{script: script} = PushTxHelpers.push_tx(%Contract{})

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [<<0::1448>>]
    end
  end

  defmodule TestContract do
    use BSV.Contract
    import BSV.Contract.PushTxHelpers

    def locking_script(ctx, %{optimized: true, extra_bytes: true}) do
      ctx
      |> push(<<0>>)
      |> op_drop()
      |> check_tx_opt()
    end

    def locking_script(ctx, %{optimized: true}) do
      ctx
      |> check_tx_opt()
    end

    def locking_script(ctx, %{verify: true}) do
      ctx
      |> check_tx!()
      |> push("foo")
    end

    def locking_script(ctx, %{}) do
      ctx
      |> check_tx()
    end

    def unlocking_script(ctx, %{}) do
      ctx
      |> push_tx()
    end
  end

  describe "TestContract" do
    test "simulates full check tx" do
      assert {:ok, vm} = Contract.simulate(TestContract, %{}, %{})
      assert VM.valid?(vm)
    end

    test "simulates full check tx verify" do
      assert {:ok, vm} = Contract.simulate(TestContract, %{verify: true}, %{})
      assert VM.valid?(vm)
      assert vm.stack == ["foo"]
    end

    test "simulates optimal check tx" do
      assert {:ok, vm} = Contract.simulate(TestContract, %{optimized: true}, %{})
      assert VM.valid?(vm)
    end

    test "optimal check tx has 50% chance of not working" do
      assert {:ok, vm} = Contract.simulate(TestContract, %{optimized: true, extra_bytes: true}, %{})
      refute VM.valid?(vm)
    end
  end

end
