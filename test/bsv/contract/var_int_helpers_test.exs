defmodule BSV.Contract.VarIntHelpersTest do
  use ExUnit.Case, async: true
  alias BSV.Contract.{Helpers, VarIntHelpers}
  alias BSV.{Contract, ScriptNum, VarInt, VM}

  describe "get_varint/3" do
    test "gets the varint from the top stack element and places on top" do
      Enum.each([32, 320, 320_000], fn bytes ->
        data = :crypto.strong_rand_bytes(bytes)
        |> VarInt.encode_binary()

        %{script: script} = %Contract{}
        |> Helpers.push(data)
        |> VarIntHelpers.get_varint()

        assert {:ok, vm} = VM.eval(%VM{}, script)
        assert vm.stack == [ScriptNum.encode(bytes), data]
      end)
    end
  end

  describe "read_varint/3" do
    test "gets the varint data from the top stack element and places on top" do
      Enum.each([32, 320, 320_000], fn bytes ->
        data = :crypto.strong_rand_bytes(bytes)

        %{script: script} = %Contract{}
        |> Helpers.push(VarInt.encode_binary(data) <> <<0,0,0,0>>)
        |> VarIntHelpers.read_varint()

        assert {:ok, vm} = VM.eval(%VM{}, script)
        assert vm.stack == [data, <<0, 0, 0, 0>>]
      end)
    end
  end

  describe "trim_varint/3" do
    test "trims the varint from the leading bytes of the top stack item" do
      Enum.each([32, 320, 320_000], fn bytes ->
        data = :crypto.strong_rand_bytes(bytes)

        %{script: script} = %Contract{}
        |> Helpers.push(VarInt.encode_binary(data))
        |> VarIntHelpers.trim_varint()

        assert {:ok, vm} = VM.eval(%VM{}, script)
        assert vm.stack == [data]
      end)
    end
  end
end
