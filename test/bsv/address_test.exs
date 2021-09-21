defmodule BSV.AddressTest do
  use ExUnit.Case, async: true
  alias BSV.Address
  alias BSV.PubKey
  doctest Address

  @test_bytes <<3, 248, 31, 140, 139, 144, 245, 236, 6, 238, 66, 69, 234, 177,
    102, 232, 175, 144, 63, 199, 58, 109, 215, 54, 54, 104, 126, 240, 39, 135,
    10, 190, 57>>
  @test_key PubKey.from_binary!(@test_bytes)
  @test_address "18cqNbEBxkAttxcZLuH9LWhZJPd1BNu1A5"

  describe "Address.from_pubkey/1" do
    test "returns address from pubkey struct" do
      assert %Address{} = address = Address.from_pubkey(@test_key)
      assert Address.to_string(address) == @test_address
    end

    test "returns address from pubkey binary" do
      assert %Address{} = address = Address.from_pubkey(@test_bytes)
      assert Address.to_string(address) == @test_address
    end
  end

  describe "Address.from_string/1" do
    test "returns address from address string" do
      assert {:ok, %Address{}} = Address.from_string(@test_address)
    end

    test "returns error with testnet address" do
      assert {:error, _error} = Address.from_string("mo8nfeKAmmc9g56B4UFXARutAPDi1sr7tH")
    end

    test "returns error with invalid address" do
      assert {:error, _error} = Address.from_string("notanaddress")
    end
  end

  describe "Address.from_string!/1" do
    test "returns address from address string" do
      assert %Address{} = Address.from_string!(@test_address)
    end

    test "raises error with testnet address" do
      assert_raise BSV.DecodeError, ~r/invalid version byte/i, fn ->
        Address.from_string!("mo8nfeKAmmc9g56B4UFXARutAPDi1sr7tH")
      end
    end

    test "raises error with invalid address" do
      assert_raise BSV.DecodeError, ~r/invalid address/i, fn ->
        Address.from_string!("notanaddress")
      end
    end
  end

  describe "Address.to_string/1" do
    test "returns string from address" do
      address = @test_key |> Address.from_pubkey() |> Address.to_string()
      assert is_binary(address)
      assert address == @test_address
    end
  end

end
