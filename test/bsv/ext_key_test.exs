defmodule BSV.ExtKeyTest do
  use ExUnit.Case, async: true
  alias BSV.ExtKey
  alias BSV.Mnemonic

  @test_words "decorate autumn pulp gas emerge just clay initial toss raccoon festival series"
  @test_seed "5bd995f07cbaeeb8c1fb4d52db5884471ae80b82f7c07094bfc77b2f4742a76a1d72d25ad58d011ecff16b1b9b0ae225e2fc084cad91a176527b4bca50047025"
  @test_xprv "xprv9s21ZrQH143K3qcbMJpvTQQQ1zRCPaZjXUD1zPouMDtKY9QQQ9DskzrZ3Cx38GnYXpgY2awCmJfz2QXkpxLN3Pp2PmUddbnrXziFtArpZ5v"
  @test_xpub "xpub661MyMwAqRbcGKh4TLMvpYM8a2Fgo3Hath8cnnDWuZRJQwjYwgY8JoB2tTgiTDdwf4rdGvgUpGhGNH54Ycb8vegrhHVVpdfYCdBBii94CLF"
  @extkey %BSV.ExtKey{
    chain_code: <<178, 208, 232, 46, 183, 65, 27, 66, 14, 172, 46, 66, 222, 84, 220, 98, 70, 249, 25, 3, 50, 209, 218, 236, 96, 142, 211, 79, 59, 166, 41, 106>>,
    child_index: 0,
    depth: 0,
    fingerprint: <<0, 0, 0, 0>>,
    privkey: %BSV.PrivKey{
      compressed: true,
      d: <<219, 231, 28, 56, 5, 76, 224, 63, 77, 224, 151, 38, 251, 136, 26, 87, 11, 186, 248, 245, 84, 56, 152, 11, 115, 35, 148, 32, 239, 241, 174, 90>>
    },
    pubkey: %BSV.PubKey{
      compressed: true,
      point: %Curvy.Point{
        x: 81914731537127506607736443451065612706836400740211682375254444777841949022440,
        y: 84194918502426421393864928067925727177552578328971362502574621746528696729690
      }
    },
    version: <<4, 136, 173, 228>>
  }
  @vectors File.read!("test/vectors/bip39.json") |> Jason.decode!()

  doctest ExtKey

  describe "ExtKey.from_seed/2" do
    test "creates extkey from binary seed" do
      assert {:ok, %ExtKey{} = extkey} = Mnemonic.to_seed(@test_words) |> ExtKey.from_seed()
      assert ExtKey.to_string(extkey) == @test_xprv
      assert ExtKey.to_public(extkey) |> ExtKey.to_string() == @test_xpub
    end

    test "creates extkey from hex encoded seed" do
      assert {:ok, %ExtKey{} = extkey} = ExtKey.from_seed(@test_seed, encoding: :hex)
      assert ExtKey.to_string(extkey) == @test_xprv
      assert ExtKey.to_public(extkey) |> ExtKey.to_string() == @test_xpub
    end

    test "returns error if seed is too small or too big" do
      assert {:error, _error} = BSV.Util.rand_bytes(15) |> ExtKey.from_seed()
      assert {:error, _error} = BSV.Util.rand_bytes(65) |> ExtKey.from_seed()
    end
  end

  describe "ExtKey.from_seed!/2" do
    test "creates extkey from binary seed" do
      assert %ExtKey{} = extkey = Mnemonic.to_seed(@test_words) |> ExtKey.from_seed!()
      assert ExtKey.to_string(extkey) == @test_xprv
      assert ExtKey.to_public(extkey) |> ExtKey.to_string() == @test_xpub
    end

    test "creates extkey from hex encoded seed" do
      assert %ExtKey{} = extkey = ExtKey.from_seed!(@test_seed, encoding: :hex)
      assert ExtKey.to_string(extkey) == @test_xprv
      assert ExtKey.to_public(extkey) |> ExtKey.to_string() == @test_xpub
    end

    test "raises error if seed is too small or too big" do
      assert_raise BSV.DecodeError, ~r/invalid seed length/i, fn ->
        BSV.Util.rand_bytes(15) |> ExtKey.from_seed!()
      end
      assert_raise BSV.DecodeError, ~r/invalid seed length/i, fn ->
        BSV.Util.rand_bytes(65) |> ExtKey.from_seed!()
      end
    end
  end

  describe "ExtKey.from_string/1" do
    test "decodes xprv into a key" do
      assert {:ok, %ExtKey{} = extkey} = ExtKey.from_string(@test_xprv)
      assert ExtKey.to_string(extkey) == @test_xprv
      assert ExtKey.to_public(extkey) |> ExtKey.to_string() == @test_xpub
    end

    test "decodes xpub into a key" do
      assert {:ok, %ExtKey{} = extkey} = ExtKey.from_string(@test_xpub)
      assert is_nil(extkey.privkey)
      assert ExtKey.to_public(extkey) |> ExtKey.to_string() == @test_xpub
    end

    test "returns error with invalid xprv or xpub" do
      assert {:error, _error} = ExtKey.from_string("xprvNotAnXprv")
      assert {:error, _error} = ExtKey.from_string("xpubNotAnXpub")
    end
  end

  describe "ExtKey.from_string!/1" do
    test "decodes xprv into a key" do
      assert %ExtKey{} = extkey = ExtKey.from_string!(@test_xprv)
      assert ExtKey.to_string(extkey) == @test_xprv
      assert ExtKey.to_public(extkey) |> ExtKey.to_string() == @test_xpub
    end

    test "decodes xpub into a key" do
      assert %ExtKey{} = extkey = ExtKey.from_string!(@test_xpub)
      assert is_nil(extkey.privkey)
      assert ExtKey.to_public(extkey) |> ExtKey.to_string() == @test_xpub
    end

    test "raises error with invalid xprv or xpub" do
      assert_raise BSV.DecodeError, ~r/invalid xprv/i, fn ->
        ExtKey.from_string!("xprvNotAnXprv")
      end

      assert_raise BSV.DecodeError, ~r/invalid xpub/i, fn ->
        ExtKey.from_string!("xpubNotAnXpub")
      end
    end

    test "bip39 english test vectors" do
      for v <- @vectors["english"] do
        assert {:ok, extkey} = ExtKey.from_seed(v["seed"], encoding: :hex)
        assert ExtKey.to_string(extkey) == v["bip32_xprv"]
      end
    end
  end

  describe "ExtKey.to_public/1" do
    test "converts private extkey to public extkey" do
      assert %ExtKey{} = extkey = ExtKey.from_string!(@test_xprv) |> ExtKey.to_public()
      assert is_nil(extkey.privkey)
      assert extkey.version == <<4, 136, 178, 30>>
    end
  end

  describe "ExtKey.to_string/1" do
    test "returns xprv of private extkey" do
      assert %ExtKey{} = extkey = ExtKey.from_string!(@test_xprv)
      assert ExtKey.to_string(extkey) == @test_xprv
    end

    test "returns xpub of public extkey" do
      assert %ExtKey{} = extkey = ExtKey.from_string!(@test_xprv) |> ExtKey.to_public()
      assert ExtKey.to_string(extkey) == @test_xpub
    end
  end

  describe "ExtKey.derive/2" do
    setup do
      master = ExtKey.from_seed!(@test_seed, encoding: :hex)
      %{priv: master, pub: ExtKey.to_public(master)}
    end

    test "derives correct bip32 nodes from master priv key", %{priv: master} do
      [
        {"m/0", "02758be3c7d9a7028f830bf0c137d5a80cd4e2f38cc2fcba6b63c53b55356dfbef", "L3ceudRGyhoQjTthSk83cfEKsnzHPqXPAMe728D3tm1SBFHitBwh"},
        {"m/5", "02f0e67692af41c180f2c83f9a422c30549ad32aa6b0f13d11c7f1625156f82d64", "L3XTiN6ooACyVFYfHnaiv1UZyz1SAZ6JM1hmP9hkHCt98MdKWytK"},
        {"m/10", "035a27e57af33f8e18ee52e0590c02c9cf041f6addb9c267a5b34eed112eed40e1", "L21GVFWJYq79ArVXMX3zbjW1AFiaaAvoMCRCoFg9tBgPDW5cQove"},
        {"m/15", "0244e04f421077e0dc48b1f5ea56416bfc7d364f7e3f60722e76984a12be6a9953", "KwvtQ1eUP5EdF6k6mQviUSoZotvpYeiUdemKwSMGpe76LGV9avmc"}
      ] |> Enum.each(fn {path, pubkey, wif} ->
        assert %ExtKey{} = node = ExtKey.derive(master, path)
        assert BSV.PubKey.to_binary(node.pubkey, encoding: :hex) == pubkey
        assert BSV.PrivKey.to_wif(node.privkey) == wif
      end)
    end

    test "derives correct bip32 nodes from master pub key", %{pub: master} do
      [
        {"M/0", "02758be3c7d9a7028f830bf0c137d5a80cd4e2f38cc2fcba6b63c53b55356dfbef"},
        {"M/5", "02f0e67692af41c180f2c83f9a422c30549ad32aa6b0f13d11c7f1625156f82d64"},
        {"M/10", "035a27e57af33f8e18ee52e0590c02c9cf041f6addb9c267a5b34eed112eed40e1"},
        {"M/15", "0244e04f421077e0dc48b1f5ea56416bfc7d364f7e3f60722e76984a12be6a9953"}
      ] |> Enum.each(fn {path, pubkey} ->
        assert %ExtKey{} = node = ExtKey.derive(master, path)
        assert BSV.PubKey.to_binary(node.pubkey, encoding: :hex) == pubkey
      end)
    end

    test "derives correct bip44 nodes from master priv key", %{priv: master} do
      account = ExtKey.derive(master, "m/44'/0'/0'/0")
      assert ExtKey.to_string(account) == "xprvA1RdrGBCqcpUbBgZ2morRPu4SwindxTuSi7GLun1WZddUQq3c8bnUmzTLuNHoYDD8FkytWaJsXawSFBz7t9jY5gYYVG4hcs9k7s9bV4WzFn"
      assert ExtKey.to_public(account) |> ExtKey.to_string() == "xpub6EQzFmi6fzNmofm28oLrnXqnzyZH3RBkow2s9JBd4uAcMDAC9fv32aJwCBPn9ovGi1xbjQhBP6XMkbYCQ4py7QHjyxepAcK3Qo3V6moAwAJ"

      [
        {"m/0", "039bb356dd5fe893296182da6af34deef37f435ebb4212f3c8073feed722b797e6", "KwMJSp6vrMhjHCy76Lgr8NyV6gMBZ69XpyZ6bksMX2cHaqU68m5L"},
        {"m/5", "02783246d5ffecea6cdc7b6c260824a0e7cfe478df2e30c9adf6527e1b9087c1a2", "KxkB8HJ2M6GvqeMkY1UEmFzFncACvkZg58gkRYD95NwYjxqJEAXH"},
        {"m/10", "039dc8d9c946c662d64bc265e67260b0ac0d447adaba3dedc646505aa5029944ad", "L4mAoyb9oN6SEa5wYrUp9zJDatDJHaRgmEhNcPGWHamjwQJAr5eE"},
        {"m/15", "0339db294ebb2df7bf99f3bd492141adef8acfe0d16fdc6825a84d9c0217f68aab", "L37A3mMWZjFcXGvWKR1nkcaYMPx657HBz8W6LPDCBGFzJRPhCpUN"}
      ] |> Enum.each(fn {path, pubkey, wif} ->
        assert %ExtKey{} = node = ExtKey.derive(account, path)
        assert BSV.PubKey.to_binary(node.pubkey, encoding: :hex) == pubkey
        assert BSV.PrivKey.to_wif(node.privkey) == wif
      end)
    end

    test "derives correct bip44 nodes from master pub key", %{priv: master} do
      account = ExtKey.derive(master, "m/44'/0'/0'/0") |> ExtKey.to_public()
      assert ExtKey.to_public(account) |> ExtKey.to_string() == "xpub6EQzFmi6fzNmofm28oLrnXqnzyZH3RBkow2s9JBd4uAcMDAC9fv32aJwCBPn9ovGi1xbjQhBP6XMkbYCQ4py7QHjyxepAcK3Qo3V6moAwAJ"

      [
        {"M/0", "039bb356dd5fe893296182da6af34deef37f435ebb4212f3c8073feed722b797e6"},
        {"M/5", "02783246d5ffecea6cdc7b6c260824a0e7cfe478df2e30c9adf6527e1b9087c1a2"},
        {"M/10", "039dc8d9c946c662d64bc265e67260b0ac0d447adaba3dedc646505aa5029944ad"},
        {"M/15", "0339db294ebb2df7bf99f3bd492141adef8acfe0d16fdc6825a84d9c0217f68aab"}
      ] |> Enum.each(fn {path, pubkey} ->
        assert %ExtKey{} = node = ExtKey.derive(account, path)
        assert BSV.PubKey.to_binary(node.pubkey, encoding: :hex) == pubkey
      end)
    end

    test "cannot derive private child from public", %{pub: master} do
      assert_raise ArgumentError, ~r/cannot derive private/i, fn ->
        ExtKey.derive(master, "m/44'")
      end
    end

    test "cannot derive hardened public child", %{priv: master} do
      assert_raise ArgumentError, ~r/cannot derive hardened/i, fn ->
        ExtKey.derive(master, "M/44'")
      end
    end
  end

end
