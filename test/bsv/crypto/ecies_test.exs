defmodule BSV.Crypto.ECIESTest do
  use ExUnit.Case
  
  test "foo" do
    key = BSV.Crypto.ECDSA.generate_key
    res = BSV.Crypto.ECIES.encrypt("hello world", key.private_key)

    IO.inspect res
    IO.inspect res |> Base.encode16
    IO.inspect res |> Base.encode64
  end

end
