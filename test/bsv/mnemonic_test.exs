defmodule BSV.MnemonicTest do
  use ExUnit.Case, async: true
  alias BSV.Mnemonic

  @entropy <<201, 197, 63, 127, 178, 20, 22, 189, 181, 107, 9, 241, 195, 111, 121, 147>>
  @mnemonic "six clarify that goddess door gain stick gentle vault bread taxi champion"
  @seed "23c406db4d7f9abd318746e4edcc06290973f65cd9eb610d28f5260bdbdf907bace3de7f968d83622c4871fd99777b61611bae18046bc2dbb415f7f1799a43e0"
  @vectors File.read!("test/vectors/bip39.json") |> Jason.decode!()

  doctest Mnemonic

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
      assert Mnemonic.from_entropy(@entropy) == @mnemonic
    end

    test "bip39 english test vectors" do
      for v <- @vectors["english"] do
        entropy = Base.decode16!(v["entropy"], case: :mixed)
        mnemonic = Mnemonic.from_entropy(entropy)
        seed = Mnemonic.to_seed(mnemonic, passphrase: v["passphrase"], encoding: :hex)

        assert mnemonic == v["mnemonic"]
        assert seed == v["seed"]
      end
    end
  end

  describe "Mnemonic.to_entropy/1" do
    test "returns binary entropy from mnemonic" do
      assert Mnemonic.to_entropy(@mnemonic) == @entropy
    end
  end

  describe "Mnemonic.to_seed/2" do
    test "returns binary seed" do
      seed = Mnemonic.to_seed(@mnemonic)
      assert is_binary(seed)
      assert byte_size(seed) == 64
    end

    test "returns hex seed" do
      seed = Mnemonic.to_seed(@mnemonic, encoding: :hex)
      assert seed == @seed
    end

    test "returns passphrase secured hex seed" do
      seed = Mnemonic.to_seed(@mnemonic, passphrase: "testing", encoding: :hex)
      refute seed == @seed
    end
  end

  describe "Mnemonic.wordlist/0" do
    test "contains 2048 words" do
      assert length(Mnemonic.wordlist()) == 2048
    end
  end

end
