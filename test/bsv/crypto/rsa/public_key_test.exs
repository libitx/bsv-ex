defmodule BSV.Crypto.RSA.PublicKeyTest do
  use ExUnit.Case
  doctest BSV.Crypto.RSA.PublicKey

  setup_all do
    priv_key = BSV.Crypto.RSA.PrivateKey.from_sequence(BSV.Test.rsa_key)
    %{
      pub_key: BSV.Crypto.RSA.PrivateKey.get_public_key(priv_key)
    }
  end


  describe "BSV.Crypto.RSA.PublicKey.from_sequence/1 and BSV.Crypto.RSA.PublicKey.as_sequence/1" do
    test "must convert to and from sequence", ctx do
      key = ctx.pub_key
      |> BSV.Crypto.RSA.PublicKey.as_sequence
      |> BSV.Crypto.RSA.PublicKey.from_sequence
      assert key == ctx.pub_key
    end
  end


  describe "BSV.Crypto.RSA.PublicKey.from_raw/1 and BSV.Crypto.RSA.PublicKey.as_raw/1" do
    test "must convert to and from raw key", ctx do
      key = ctx.pub_key
      |> BSV.Crypto.RSA.PublicKey.as_raw
      |> BSV.Crypto.RSA.PublicKey.from_raw
      assert key == ctx.pub_key
    end
  end

end
