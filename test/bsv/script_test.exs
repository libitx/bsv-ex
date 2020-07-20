defmodule BSV.ScriptTest do
  use ExUnit.Case
  alias BSV.Script
  doctest BSV.Script

  test "serialize/2 works with coinbase script" do
    assert "keep calm and BSV on" == Script.serialize(%Script{coinbase: "keep calm and BSV on"})
  end

  test "serialize/2 fails if both chunks and coinbase are set" do
    assert_raise FunctionClauseError, fn ->
      Script.serialize(%Script{coinbase: "keep calm and BSV on", chunks: [:OP_1]})
    end
  end

  test "is_coinbase/1 fails if both chunks and coinbase are set" do
    assert_raise FunctionClauseError, fn ->
      Script.is_coinbase(%Script{coinbase: "keep calm and BSV on", chunks: [:OP_1]})
    end
  end
end
