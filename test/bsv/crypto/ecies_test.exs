defmodule BSV.Crypto.ECIESTest do
  use ExUnit.Case
  doctest BSV.Crypto.ECIES

  setup_all do
    keys = BSV.Wallet.KeyPair.generate
    %{
      pub_key: keys.public_key,
      priv_key: keys.private_key
    }
  end

  
  describe "BSV.Crypto.ECIES.encrypt/3 and BSV.Crypto.ECIES.decrypt/3" do
    test "encryption with public key and decryption with private key", ctx do
      result = "hello world"
      |> BSV.Crypto.ECIES.encrypt(ctx.pub_key)
      |> BSV.Crypto.ECIES.decrypt(ctx.priv_key)
      assert result == "hello world"
    end

    test "must encrypt and return a binary", ctx do
      enc_data = BSV.Crypto.ECIES.encrypt("hello world", ctx.pub_key)
      assert enc_data != "hello world"
      assert byte_size(enc_data) >= 85
    end

    test "must return specifified encoding", ctx do
      enc_data = BSV.Crypto.ECIES.encrypt("hello world", ctx.pub_key, encoding: :hex)
      assert String.match?(enc_data, ~r/^[a-f0-9]+$/i)
    end
  end


  describe "External messages" do
    test "decrypt message from bsv.js" do
      keys = BSV.Test.bsv_keys |> BSV.Wallet.KeyPair.from_ecdsa_key
      data = "QklFMQMtEGxuc+iWInmjAwv6TXBZeH9qSGAygd86Cl3uM8xR7HDRahwebjAI05NEaSsXdGU7uwDZB01idKa9V1kaAkavijnrlUXIkaaIZ1jxn+LzUy0PxUCx7MlNO24XHlHUoRA="
      msg = BSV.Crypto.ECIES.decrypt(data, keys.private_key, encoding: :base64)
      assert msg == "Yes, today is FRIDAY!"
    end

    test "decrypt message from Electrum" do
      keys = BSV.Test.bsv_keys |> BSV.Wallet.KeyPair.from_ecdsa_key
      data = "QklFMQMtfEIACPib3IMLXziejcfFhP6ljTbudAzTs1fnsc8QDU2fIenGbSH0XXUBfERf4DgYnrh7gmH98GymM2oHUkXoaVXpOWnwd5h+VtydSUDM0r4HO5RwwfIOUmfsLmNQ+t0="
      msg = BSV.Crypto.ECIES.decrypt(data, keys.private_key, encoding: :base64)
      assert msg == "It's friday today!"
    end
  end

end
