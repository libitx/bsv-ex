defmodule BSV.Contract.OpCodeHelpersTest do
  use ExUnit.Case, async: true
  alias BSV.Contract.{Helpers, OpCodeHelpers}
  alias BSV.{Contract, VM}

  describe "op_if/3" do
    test "evaluates handle_if if top stack element is true" do
      %{script: script} = %Contract{}
      |> Helpers.push(<<1>>)
      |> OpCodeHelpers.op_if(&Helpers.push(&1, "true"), &Helpers.push(&1, "false"))

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == ["true"]
    end

    test "evaluates handle_else if top stack element is false" do
      %{script: script} = %Contract{}
      |> Helpers.push(<<0>>)
      |> OpCodeHelpers.op_if(&Helpers.push(&1, "true"), &Helpers.push(&1, "false"))

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == ["false"]
    end
  end

  describe "op_notif/3" do
    test "evaluates handle_if if top stack element is false" do
      %{script: script} = %Contract{}
      |> Helpers.push(<<0>>)
      |> OpCodeHelpers.op_notif(&Helpers.push(&1, "true"), &Helpers.push(&1, "false"))

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == ["true"]
    end

    test "evaluates handle_else if top stack element is true" do
      %{script: script} = %Contract{}
      |> Helpers.push(<<1>>)
      |> OpCodeHelpers.op_notif(&Helpers.push(&1, "true"), &Helpers.push(&1, "false"))

      assert {:ok, vm} = VM.eval(%VM{}, script)
      assert vm.stack == ["false"]
    end
  end

end
