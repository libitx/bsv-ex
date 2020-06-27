defmodule BSV.UtilTest do
  use ExUnit.Case
  doctest BSV.Util
  alias BSV.Util

  describe "Util.reverse_bin/1" do
    test "must reverse binary with leading zero" do
      assert Util.reverse_bin(<<0,1,2,3>>) == <<3,2,1,0>>
    end

    test "must reverse binary with training zero" do
      assert Util.reverse_bin(<<1,2,3,0>>) == <<0,3,2,1>>
    end
  end

end
