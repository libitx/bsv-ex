defmodule BSV.MessageTest do
  use ExUnit.Case
  doctest BSV.Message

  setup_all do
    keys = BSV.KeyPair.generate
    %{
      pub_key: keys.public_key,
      priv_key: keys.private_key,
      address: BSV.KeyPair.get_address(keys)
    }
  end


  describe "BSV.Message.sign/3 and BSV.Message.verify/4" do
    test "sign with private key and veryify with public key", ctx do
      result = "hello world"
      |> BSV.Message.sign(ctx.priv_key)
      |> BSV.Message.verify("hello world", ctx.pub_key)
      assert result == true
    end

    test "sign with private key and veryify with address", ctx do
      result = "hello world"
      |> BSV.Message.sign(ctx.priv_key)
      |> BSV.Message.verify("hello world", ctx.address)
      assert result == true
    end

    test "return false with incorrect message", ctx do
      result = "hello world"
      |> BSV.Message.sign(ctx.priv_key)
      |> BSV.Message.verify("goodbye world", ctx.pub_key)
      assert result == false
    end

    test "must sign and return a binary", ctx do
      sig = BSV.Message.sign("hello world", ctx.priv_key, encoding: false)
      assert byte_size(sig) == 65
    end

    test "must return with specified encoding", ctx do
      sig = BSV.Message.sign("hello world", ctx.priv_key, encoding: :hex)
      assert String.match?(sig, ~r/^[a-f0-9]+$/i)
    end
  end


  describe "External messages" do
    test "verify signature from random bsv address 1" do
      addr = "1Kgb4RGd7kVxmy85qF2V7RuyqnddCabBpc"
      sig = "IOKYfXRrvFGa43gxBiqsTVq8SYZGVbBo4IRD5Sw285weNwABWwCgHx/uxiIh1T7ucOunBXUPSanU61z7vkMFqi4="
      assert BSV.Message.verify(sig, "Hello world.", addr)
    end

    test "verify signature from random bsv address 2" do
      addr = "172uDK9ov8pPshwM4gGExZVBqUPVk4NK2F"
      sig = "HwIB0nCuTgDHnKG0uoWVPWMTaO3XOa6MtvkuZYDr4hOqZ8T78qOIa3afqIVltZahsKTtpEErnflgvQVVPIk+YJQ="
      assert BSV.Message.verify(sig, "Hello world.", addr)
    end

    test "verify signature from random bsv address 3" do
      addr = "14GpJNKfb6yvhjeBXQVJRmGKx1Syg4kxLG"
      sig = "INX0XYbxs8ZW+mwTem198w0L/JvZkYUb/KikUt/fIf9+bSKaMijQD0nQso/RA5n6NrzZu5ok3lpgE3VzJPPS3Yk="
      assert BSV.Message.verify(sig, "Hello world.", addr)
    end
  end

end
