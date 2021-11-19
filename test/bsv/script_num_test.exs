defmodule BSV.ScriptNumTest do
  use ExUnit.Case, async: true
  alias BSV.ScriptNum
  doctest ScriptNum

  describe "ScriptNum.decode/1" do
    test "0x80 is negative 0" do
      assert BSV.ScriptNum.decode(<<0x80>>) == 0
    end

    test "0x81 is negative -1" do
      assert BSV.ScriptNum.decode(<<0x81>>) == -1
    end
  end

  describe "ScriptNum.encode/1" do
    test "positive 0 empty binary" do
      assert BSV.ScriptNum.encode(0) == <<>>
    end

    test "-1 is <<0x81>>" do
      assert BSV.ScriptNum.encode(-1) == <<0x81>>
    end
  end

end
