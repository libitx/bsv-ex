defmodule BSV.Contract.OpReturnTest do
  use ExUnit.Case, async: true
  alias BSV.Contract.OpReturn
  alias BSV.{Contract, Script}
  doctest OpReturn

  describe "lock/2" do
    test "takes a single data binary parameter" do
      contract = OpReturn.lock(0, %{data: "hello world"})
      assert %Script{chunks: [:OP_FALSE, :OP_RETURN, "hello world"]} = Contract.to_script(contract)
    end

    test "takes a list of data binary parameters" do
      contract = OpReturn.lock(0, %{data: ["hello", "world"]})
      assert %Script{chunks: [:OP_FALSE, :OP_RETURN, "hello", "world"]} = Contract.to_script(contract)
    end

    test "takes a mixed list of parameters" do
      contract = OpReturn.lock(0, %{data: ["hello", "world", :OP_10, 100_000]})
      assert %Script{chunks: [:OP_FALSE, :OP_RETURN, "hello", "world", :OP_10, <<160, 134, 1>>]} = Contract.to_script(contract)
    end
  end

end
