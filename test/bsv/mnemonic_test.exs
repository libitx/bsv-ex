defmodule BSV.MnemonicTest do
  use ExUnit.Case, async: true
  alias BSV.Mnemonic
  doctest Mnemonic

  @test_entropy <<201, 197, 63, 127, 178, 20, 22, 189, 181, 107, 9, 241, 195, 111, 121, 147>>
  @test_words "six clarify that goddess door gain stick gentle vault bread taxi champion"
  @test_seed "23c406db4d7f9abd318746e4edcc06290973f65cd9eb610d28f5260bdbdf907bace3de7f968d83622c4871fd99777b61611bae18046bc2dbb415f7f1799a43e0"
  @test_seed2 "266f2ea4cd63fd190c3f46b35e6a7da63691c8dc2aa9e57fd362674555c5339f2839e54da6530c547653e263978726a775a16209c3cf80ac23cc2594bebd2301"

  describe "Mnemonic.wordlist/0" do
    test "contains 2048 words" do
      assert length(Mnemonic.wordlist()) == 2048
    end
  end

  describe "Mnemonic.new/1" do
    test "creates random 12 word seed" do
      words = Mnemonic.new()
      assert is_binary(words)
      assert length(String.split(words, " ")) == 12
    end

    test "creates random 15 word seed" do
      words = Mnemonic.new(160)
      assert length(String.split(words, " ")) == 15
    end

    test "creates random 24 word seed" do
      words = Mnemonic.new(256)
      assert length(String.split(words, " ")) == 24
    end
  end

  describe "Mnemonic.from_entropy/1" do
    test "returns mnemonic from entropy bytes" do
      assert Mnemonic.from_entropy(@test_entropy) == @test_words
    end
  end

  describe "Mnemonic.to_entropy/1" do
    test "returns binary entropy from mnemonic" do
      assert Mnemonic.to_entropy(@test_words) == @test_entropy
    end
  end

  describe "Mnemonic.to_seed/2" do
    test "returns binary seed" do
      seed = Mnemonic.to_seed(@test_words)
      assert is_binary(seed)
      assert byte_size(seed) == 64
    end

    test "returns hex seed" do
      seed = Mnemonic.to_seed(@test_words, encoding: :hex)
      assert seed == @test_seed
    end

    test "returns passphrase secured hex seed" do
      seed = Mnemonic.to_seed(@test_words, passphrase: "testing", encoding: :hex)
      assert seed == @test_seed2
    end
  end

end
