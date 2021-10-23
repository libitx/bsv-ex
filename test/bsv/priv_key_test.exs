defmodule BSV.PrivKeyTest do
  use ExUnit.Case, async: true
  alias BSV.PrivKey

  @privkey_bin <<60, 255, 4, 99, 48, 136, 98, 46, 69, 153, 220, 46, 191, 132, 63,
    130, 206, 243, 70, 59, 145, 13, 52, 167, 82, 161, 54, 34, 171, 174, 55, 155>>
  @privkey %PrivKey{d: @privkey_bin}
  @privkey_hex "3cff04633088622e4599dc2ebf843f82cef3463b910d34a752a13622abae379b"
  @privkey_wif "KyGHAK8MNohVPdeGPYXveiAbTfLARVrQuJVtd3qMqN41UEnTWDkF"
  @privkey_wif2 "5JH9eTJyj6bYopGhBztsDd4XvAbFNQkpZEw8AXYoQePtK1r86nu"

  doctest PrivKey

  describe "PrivKey.new/1" do
    test "generates new random private key" do
      assert %PrivKey{} = privkey = PrivKey.new()
      assert byte_size(privkey.d) == 32
      assert privkey.compressed
    end

    test "optionally generate uncompressed private key" do
      assert %PrivKey{compressed: false} = PrivKey.new(compressed: false)
    end
  end

  describe "PrivKey.from_binary/2" do
    test "wraps an existing key binary" do
      d = @privkey_bin
      assert {:ok, %PrivKey{d: ^d}} = PrivKey.from_binary(d)
    end

    test "decodes an existing hex key" do
      assert {:ok, %PrivKey{d: d}} = PrivKey.from_binary(@privkey_hex, encoding: :hex)
      assert d == @privkey_bin
    end

    test "returns error with invalid binary" do
      assert {:error, _error} = PrivKey.from_binary("notaprivkey")
    end
  end

  describe "PrivKey.from_binary!/2" do
    test "wraps an existing key binary" do
      d = @privkey_bin
      assert %PrivKey{d: ^d} = PrivKey.from_binary!(d)
    end

    test "decodes an existing hex key" do
      assert %PrivKey{d: d} = PrivKey.from_binary!(@privkey_hex, encoding: :hex)
      assert d == @privkey_bin
    end

    test "raises error with invalid binary" do
      assert_raise BSV.DecodeError, ~r/invalid privkey/i, fn ->
        PrivKey.from_binary!("notaprivkey")
      end
    end
  end

  describe "PrivKey.from_wif/1" do
    test "decodes wif into a private key" do
      assert {:ok, %PrivKey{} = privkey} = PrivKey.from_wif(@privkey_wif)
      assert privkey.d == @privkey_bin
      assert privkey.compressed
    end

    test "decodes uncompressed wif into a private key" do
      assert {:ok, %PrivKey{} = privkey} = PrivKey.from_wif(@privkey_wif2)
      assert privkey.d == @privkey_bin
      refute privkey.compressed
    end

    test "returns error with invalid wif" do
      assert {:error, _error} = PrivKey.from_wif("notawif")
    end
  end

  describe "PrivKey.from_wif!/1" do
    test "decodes wif into a private key" do
      assert %PrivKey{} = privkey = PrivKey.from_wif!(@privkey_wif)
      assert privkey.d == @privkey_bin
      assert privkey.compressed
    end

    test "decodes uncompressed wif into a private key" do
      assert %PrivKey{} = privkey = PrivKey.from_wif!(@privkey_wif2)
      assert privkey.d == @privkey_bin
      refute privkey.compressed
    end

    test "raises error with invalid wif" do
      assert_raise BSV.DecodeError, ~r/invalid wif/i, fn ->
        PrivKey.from_wif!("notawif")
      end
    end
  end

  describe "PrivKey.to_binary/2" do
    test "returns the raw private key binary" do
      privkey = PrivKey.to_binary(@privkey)
      assert privkey == @privkey_bin
    end

    test "returns the raw private key as hex" do
      privkey = PrivKey.to_binary(@privkey, encoding: :hex)
      assert privkey == @privkey_hex
    end
  end

  describe "PrivKey.to_wif/1" do
    test "wif encodes the private key" do
      wif = PrivKey.to_wif(@privkey)
      assert wif == @privkey_wif
    end

    test "wif encodes the uncompressed private key" do
      wif =
        PrivKey.from_binary!(@privkey_bin, compressed: false)
        |> PrivKey.to_wif()
      assert wif == @privkey_wif2
    end
  end

end
