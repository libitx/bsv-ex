defmodule BSV.MessageTest do
  use ExUnit.Case
  doctest BSV.Util

  setup_all do
    keypair = BSV.Test.bsv_keys
    |> BSV.KeyPair.from_ecdsa_key
    %{
      keys: keypair
    }
  end

  test "foo", ctx do
    msg = "hello world"
    sig = BSV.Message.sign(msg, ctx.keys.private_key)
    IO.inspect Base.encode16(sig)
    s = BSV.DERSig.parse(sig)
    IO.inspect(s)
    IO.puts byte_size(s.r)
    IO.puts byte_size(s.s)


    assert BSV.Message.verify(sig, msg, ctx.keys.public_key)

    assert true
  end

end
