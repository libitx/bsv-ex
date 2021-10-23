defmodule BSV.PubKeyTest do
  use ExUnit.Case, async: true
  alias BSV.PubKey
  alias BSV.PrivKey

  @pubkey_bin_comp <<3, 248, 31, 140, 139, 144, 245, 236, 6, 238, 66, 69, 234, 177,
    102, 232, 175, 144, 63, 199, 58, 109, 215, 54, 54, 104, 126, 240, 39, 135,
    10, 190, 57>>
  @pubkey_bin <<4, 248, 31, 140, 139, 144, 245, 236, 6, 238, 66, 69, 234, 177,
    102, 232, 175, 144, 63, 199, 58, 109, 215, 54, 54, 104, 126, 240, 39, 135,
    10, 190, 57, 1, 135, 135, 125, 5, 134, 136, 158, 82, 54, 184, 224, 42, 2,
    75, 140, 90, 22, 8, 122, 233, 116, 221, 100, 93, 180, 96, 132, 105, 242,
    152, 151>>
  @pubkey_hey "03f81f8c8b90f5ec06ee4245eab166e8af903fc73a6dd73636687ef027870abe39"
  @pubkey %PubKey{
    compressed: true,
    point: %Curvy.Point{
      x: 112229328714845468078961951285525025245993969218674417992740440691709714284089,
      y: 691772308660403791193362590139379363593914935665750098177712560871566383255
    }
  }

  doctest PubKey

  describe "PubKey.from_binary/2" do
    test "wraps a compressed pubkey binary" do
      assert {:ok, pubkey} = PubKey.from_binary(@pubkey_bin_comp)
      assert pubkey.point == @pubkey.point
      assert pubkey.compressed
    end

    test "wraps an uncompressed pubkey binary" do
      assert {:ok, pubkey} = PubKey.from_binary(@pubkey_bin)
      assert pubkey.point == @pubkey.point
      refute pubkey.compressed
    end

    test "decodes a hex pubkey" do
      assert {:ok, pubkey} = PubKey.from_binary(@pubkey_hey, encoding: :hex)
      assert pubkey.point == @pubkey.point
      assert pubkey.compressed
    end

    test "returns error with invalid binary" do
      assert {:error, _error} = PubKey.from_binary("notapubkey")
    end
  end

  describe "PubKey.from_binary!/2" do
    test "wraps a compressed pubkey binary" do
      pubkey = PubKey.from_binary!(@pubkey_bin_comp)
      assert pubkey.point == @pubkey.point
      assert pubkey.compressed
    end

    test "wraps an uncompressed pubkey binary" do
      pubkey = PubKey.from_binary!(@pubkey_bin)
      assert pubkey.point == @pubkey.point
      refute pubkey.compressed
    end

    test "decodes a hex pubkey" do
      pubkey = PubKey.from_binary!(@pubkey_hey, encoding: :hex)
      assert pubkey.point == @pubkey.point
      assert pubkey.compressed
    end

    test "raises error with invalid binary" do
      assert_raise BSV.DecodeError, ~r/invalid pubkey/i, fn ->
        PubKey.from_binary!("notapubkey")
      end
    end
  end

  describe "PubKey.from_privkey/1" do
    setup do
      privkey = PrivKey.from_wif!("KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF")
      privkey2 = PrivKey.from_wif!("5JH9eTJyj6bYopGhBztsDd4XvAbFNQkpZEw8AXYoQePtK1r86nu")
      %{privkey: privkey, privkey2: privkey2}
    end

    test "casts compressed privkey as pubkey", %{privkey: privkey} do
      assert %PubKey{} = pubkey = PubKey.from_privkey(privkey)
      assert privkey.compressed
      assert pubkey.compressed
    end

    test "casts uncompressed privkey as pubkey", %{privkey2: privkey} do
      assert %PubKey{} = pubkey = PubKey.from_privkey(privkey)
      refute privkey.compressed
      refute pubkey.compressed
    end
  end

  describe "PubKey.to_binary/2" do
    test "returns the raw private key binary" do
      pubkey = PubKey.to_binary(@pubkey)
      assert pubkey == @pubkey_bin_comp
    end

    test "returns the raw private key as hex" do
      pubkey = PubKey.to_binary(@pubkey, encoding: :hex)
      assert pubkey == @pubkey_hey
    end
  end

end
