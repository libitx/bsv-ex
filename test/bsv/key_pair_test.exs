defmodule BSV.KeyPairTest do
  use ExUnit.Case, async: true
  alias BSV.KeyPair
  alias BSV.PrivKey
  doctest KeyPair

  describe "KeyPair.new/1" do
    test "generates new random keypair" do
      assert %KeyPair{privkey: privkey, pubkey: pubkey} = KeyPair.new()
      assert byte_size(privkey.d) == 32
      assert privkey.compressed
      assert %Curvy.Point{} = pubkey.point
      assert pubkey.compressed
    end

    test "optionally generate uncompressed private key" do
      assert %KeyPair{privkey: privkey, pubkey: pubkey} = KeyPair.new(compressed: false)
      refute privkey.compressed
      refute pubkey.compressed
    end
  end

  describe "KeyPair.from_privkey/1" do
    setup do
      privkey = PrivKey.from_wif("KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF")
      privkey2 = PrivKey.from_wif("5JH9eTJyj6bYopGhBztsDd4XvAbFNQkpZEw8AXYoQePtK1r86nu")
      %{privkey: privkey, privkey2: privkey2}
    end

    test "casts compressed privkey as keypair", %{privkey: privkey_src} do
      assert %KeyPair{privkey: privkey, pubkey: pubkey} = KeyPair.from_privkey(privkey_src)
      assert privkey == privkey_src
      assert privkey.compressed
      assert pubkey.compressed
    end

    test "casts uncompressed privkey as keypair", %{privkey2: privkey_src} do
      assert %KeyPair{privkey: privkey, pubkey: pubkey} = KeyPair.from_privkey(privkey_src)
      assert privkey == privkey_src
      refute privkey.compressed
      refute pubkey.compressed
    end
  end

end
