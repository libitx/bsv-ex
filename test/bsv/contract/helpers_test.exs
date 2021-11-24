defmodule BSV.Contract.HelpersTest do
  use ExUnit.Case, async: true
  alias BSV.Contract.Helpers
  alias BSV.{Contract, Util, VM}

  describe "reverse_bin/2" do
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
        |> Helpers.reverse_bin(byte_size(vector))

        assert {:ok, vm} = VM.eval(%VM{}, script)
        assert List.first(vm.stack) == Util.reverse_bin(vector)
      end)
    end
  end

end
