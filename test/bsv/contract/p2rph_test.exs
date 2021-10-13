defmodule BSV.Contract.P2RPHTest do
  use ExUnit.Case, async: true
  alias BSV.Contract.P2RPH
  alias BSV.{Contract, KeyPair, PrivKey, Script, UTXO}

  @wif "KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF"
  @keypair KeyPair.from_privkey(PrivKey.from_wif!(@wif))
  doctest P2RPH

end
