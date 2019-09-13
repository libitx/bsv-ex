defmodule BSV.Crypto.RSATest do
  use ExUnit.Case
  doctest BSV.Crypto.RSA

  setup_all do
    priv_key = BSV.Crypto.RSA.PrivateKey.from_sequence(BSV.Test.rsa_key)
    %{
      priv_key: priv_key,
      pub_key: BSV.Crypto.RSA.PrivateKey.get_public_key(priv_key)
    }
  end


  describe "BSV.Crypto.RSA.generate_key/0" do
    test "must generate new private key" do
      private_key = BSV.Crypto.RSA.generate_key
      assert private_key.__struct__ == BSV.Crypto.RSA.PrivateKey
    end
  end


  describe "BSV.Crypto.RSA.encrypt/3 and BSV.Crypto.RSA.decrypt/3" do
    test "encryption with public key and decryption with private key", ctx do
      result = "hello world"
      |> BSV.Crypto.RSA.encrypt(ctx.pub_key)
      |> BSV.Crypto.RSA.decrypt(ctx.priv_key)
      assert result == "hello world"
    end

    test "encryption with private key and decryption with public key", ctx do
      result = "hello world"
      |> BSV.Crypto.RSA.encrypt(ctx.priv_key)
      |> BSV.Crypto.RSA.decrypt(ctx.pub_key)
      assert result == "hello world"
    end

    test "must encrypt and return a binary", ctx do
      enc_data = BSV.Crypto.RSA.encrypt("hello world", ctx.pub_key)
      assert enc_data != "hello world"
      assert byte_size(enc_data) == 256
    end

    test "must return specifified encoding", ctx do
      enc_data = BSV.Crypto.RSA.encrypt("hello world", ctx.pub_key, encoding: :hex)
      assert String.match?(enc_data, ~r/^[a-f0-9]+$/i)
    end
  end


  describe "BSV.Crypto.RSA.sign/3 and BSV.Crypto.RSA.verify/4" do
    test "sign with private key and veryify with public key", ctx do
      result = "hello world"
      |> BSV.Crypto.RSA.sign(ctx.priv_key)
      |> BSV.Crypto.RSA.verify("hello world", ctx.pub_key)
      assert result == true
    end

    test "return false with incorrect message", ctx do
      result = "hello world"
      |> BSV.Crypto.RSA.sign(ctx.priv_key)
      |> BSV.Crypto.RSA.verify("goodbye world", ctx.pub_key)
      assert result == false
    end

    test "must sign and return a binary", ctx do
      sig = BSV.Crypto.RSA.sign("hello world", ctx.priv_key)
      assert byte_size(sig) == 256
    end

    test "must return with specified encoding", ctx do
      sig = BSV.Crypto.RSA.sign("hello world", ctx.priv_key, encoding: :hex)
      assert String.match?(sig, ~r/^[a-f0-9]+$/i)
    end
  end

end
