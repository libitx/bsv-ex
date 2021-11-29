defmodule BSV.Contract.HelpersTest do
  use ExUnit.Case, async: true
  alias BSV.Contract.{Helpers, OpCodeHelpers}
  alias BSV.{Contract, Util, VM}

  describe "decode_uint/2" do
    test "casts the top stack element to a script numbers" do
      %{script: script} = %Contract{}
      |> Helpers.each([<<24>>, <<24::little-32>>, <<4000000000::little-32>>], fn num, c ->
        c
        |> Helpers.push(num)
        |> Helpers.decode_uint()
      end)

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [<<0, 40, 107, 238, 0>>, <<24>>, <<24>>]
    end
  end

  describe "each/3" do
    test "iterates over the given enumerable calling the function on each" do
      %{script: script} = %Contract{}
      |> Helpers.push("")
      |> Helpers.each(["foo", "bar", "baz"], fn el, c ->
        c
        |> Helpers.push(el)
        |> OpCodeHelpers.op_cat()
      end)

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == ["foobarbaz"]
    end
  end

  describe "push/2" do
    test "pushes different data types onto the stack" do
      %{script: script} = %Contract{}
      |> Helpers.push("foo")
      |> Helpers.push(:OP_16)
      |> Helpers.push(-12345)

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [<<57, 176>>, <<16>>, "foo"]
    end
  end

  describe "repeat/3" do
    test "iterates over the given integer calling the function on each" do
      %{script: script} = %Contract{}
      |> Helpers.push("")
      |> Helpers.repeat(3, fn i, c ->
        c
        |> Helpers.push(<<i>>)
        |> OpCodeHelpers.op_cat()
      end)

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == [<<0, 1, 2>>]
    end
  end

  describe "reverse/2" do
    test "reverses the binary on top of the stack" do
      binaries = [
        <<1,2,3,4,5>>,
        <<1,2,3,4,5,6,7,8>>,
        <<1,2,3,4,5,6,7,8,9,10,11,12>>,
        <<1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16>>,
        <<1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25>>,
        <<1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32>>,
        <<1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34>>,
        :crypto.strong_rand_bytes(560)
      ]

      Enum.each(binaries, fn vector ->
        %{script: script} = %Contract{}
        |> Contract.script_push(vector)
        |> Helpers.reverse(byte_size(vector))

        assert {:ok, vm} = VM.eval(%VM{}, script)
        assert List.first(vm.stack) == Util.reverse_bin(vector)
      end)
    end
  end

  describe "slice/3" do
    test "slices bytes from the top of the stack with positive start index" do
      data = <<1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16>>
      contract = Contract.script_push(%Contract{}, data)

      Enum.each([{0, 2}, {4, 4}, {13, 2}], fn {start, length} ->
        %{script: script} = Helpers.slice(contract, start, length)
        assert {:ok, vm} = VM.eval(%VM{}, script)
        assert List.first(vm.stack) == binary_part(data, start, length)
      end)
    end

    test "slices bytes from the top of the stack with negative start index" do
      data = <<1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16>>
      contract = Contract.script_push(%Contract{}, data)

      Enum.each([{-4, 4}, {-13, 2}], fn {start, length} ->
        %{script: script} = Helpers.slice(contract, start, length)
        assert {:ok, vm} = VM.eval(%VM{}, script)
        assert List.first(vm.stack) == binary_part(data, byte_size(data) + start, length)
      end)
    end
  end

  describe "trim/2" do
    test "trims leading bytes from the top of the stack" do
      data = <<1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16>>
      contract = Contract.script_push(%Contract{}, data)

      Enum.each([2, 4, 8, 13], fn bytes ->
        %{script: script} = Helpers.trim(contract, bytes)
        assert {:ok, vm} = VM.eval(%VM{}, script)
        assert List.first(vm.stack) == binary_part(data, bytes, byte_size(data) - bytes)
      end)
    end

    test "trims trailing bytes from the top of the stack" do
      data = <<1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16>>
      contract = Contract.script_push(%Contract{}, data)

      Enum.each([-2, -4, -8, -13], fn bytes ->
        %{script: script} = Helpers.trim(contract, bytes)
        assert {:ok, vm} = VM.eval(%VM{}, script)
        assert List.first(vm.stack) == binary_part(data, 0, byte_size(data) + bytes)
      end)
    end
  end

end
