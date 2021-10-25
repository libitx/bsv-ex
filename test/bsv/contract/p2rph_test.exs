defmodule BSV.Contract.P2RPHTest do
  use ExUnit.Case, async: true
  alias BSV.Contract.P2RPH
  alias BSV.{Contract, KeyPair, PrivKey, Script, UTXO, VM}

  @wif "KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF"
  @keypair KeyPair.from_privkey(PrivKey.from_wif!(@wif))
  doctest P2RPH

  describe "Contract.simulate/3" do
    setup do
      k = P2RPH.generate_k()
      {:ok, k: k, r: P2RPH.get_r(k)}
    end

    test "evaluates as valid if signed with correct key", ctx do
      assert {:ok, vm} = Contract.simulate(P2RPH, %{r: ctx.r}, %{k: ctx.k, keypair: KeyPair.new()})
      assert VM.valid?(vm)
    end

    test "evaluates as invalid if used with with incorrect k", ctx do
      assert {:error, vm} = Contract.simulate(P2RPH, %{r: ctx.r}, %{k: P2RPH.generate_k(), keypair: KeyPair.new()})
      refute VM.valid?(vm)
    end
  end

end
