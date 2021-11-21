defmodule BSV.Contract.RawTest do
  use ExUnit.Case, async: true
  alias BSV.Contract.Raw
  alias BSV.{Contract, Script, TxBuilder, TxOut}

  @p2pkh_hex "76a91410bdcba3041b5e5517a58f2e405293c14a7c70c188ac"

  doctest Raw

  describe "lock/2" do
    test "takes a single script parameter" do
      contract = Raw.lock(1000, %{script: Script.from_binary!(@p2pkh_hex, encoding: :hex)})
      assert %TxOut{satoshis: 1000, script: script} = Contract.to_txout(contract)
      assert %Script{chunks: [:OP_DUP, :OP_HASH160, <<_::binary-20>>, :OP_EQUALVERIFY, :OP_CHECKSIG]} = script
    end

    test "raises an error if the arguments are not valid" do
      assert_raise FunctionClauseError, fn ->
        Raw.lock(1000, %{script: "not a script"}) |> Contract.to_txout()
      end
    end
  end

end
