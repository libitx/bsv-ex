defmodule BSV.Crypto.RSA.PrivateKeyTest do
  use ExUnit.Case
  @moduletag :rsa
  doctest BSV.Crypto.RSA.PrivateKey

  setup_all do
    priv_key = BSV.Crypto.RSA.PrivateKey.from_sequence(BSV.Test.rsa_key)
    %{
      priv_key: priv_key
    }
  end


  describe "BSV.Crypto.RSA.PrivateKey.from_sequence/1 and BSV.Crypto.RSA.PrivateKey.as_sequence/1" do
    test "must convert to and from sequence", ctx do
      key = ctx.priv_key
      |> BSV.Crypto.RSA.PrivateKey.as_sequence
      |> BSV.Crypto.RSA.PrivateKey.from_sequence
      assert key == ctx.priv_key
    end
  end


  describe "BSV.Crypto.RSA.PrivateKey.from_raw/1 and BSV.Crypto.RSA.PrivateKey.as_raw/1" do
    test "must convert to and from raw key", ctx do
      key = ctx.priv_key
      |> BSV.Crypto.RSA.PrivateKey.as_raw
      |> BSV.Crypto.RSA.PrivateKey.from_raw
      assert key == ctx.priv_key
    end
  end

end
