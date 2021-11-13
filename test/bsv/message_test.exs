defmodule BSV.MessageTest do
  use ExUnit.Case, async: true
  alias BSV.Message
  alias BSV.{Address, KeyPair, PrivKey}

  @alice_keypair KeyPair.new()
  @bob_keypair KeyPair.new()

  doctest Message

  setup_all do
    keypair = KeyPair.new()
    %{
      address: Address.from_pubkey(keypair.pubkey),
      keypair: keypair
    }
  end

  describe "Message.encrypt/3 and Message.decrypt/3" do
    test "encryption with public key and decryption with private key", %{keypair: keypair} do
      {:ok, result} = "hello world"
      |> Message.encrypt(keypair.pubkey)
      |> Message.decrypt(keypair.privkey)
      assert result == "hello world"
    end

    test "must encrypt and return a binary", %{keypair: keypair} do
      enc_data = Message.encrypt("hello world", keypair.pubkey)
      assert enc_data != "hello world"
      assert byte_size(enc_data) >= 85
    end

    test "must return specifified encoding", %{keypair: keypair} do
      enc_data = Message.encrypt("hello world", keypair.pubkey, encoding: :hex)
      assert String.match?(enc_data, ~r/^[a-f0-9]+$/i)
    end
  end

  describe "Message.decrypt/3 external messages" do
    setup do
      privkey = <<189, 138, 106, 93, 22, 48, 176, 218, 61, 84, 36, 235, 171, 24, 246, 159, 24, 34, 109, 50, 221, 28, 136, 78, 120, 184, 60, 221, 223, 131, 158, 44>>
      %{privkey: PrivKey.from_binary!(privkey)}
    end

    test "decrypt message from bsv.js", %{privkey: privkey} do
      data = "QklFMQMtEGxuc+iWInmjAwv6TXBZeH9qSGAygd86Cl3uM8xR7HDRahwebjAI05NEaSsXdGU7uwDZB01idKa9V1kaAkavijnrlUXIkaaIZ1jxn+LzUy0PxUCx7MlNO24XHlHUoRA="
      assert {:ok, msg} = Message.decrypt(data, privkey, encoding: :base64)
      assert msg == "Yes, today is FRIDAY!"
    end

    test "decrypt message from Electrum", %{privkey: privkey} do
      data = "QklFMQMtfEIACPib3IMLXziejcfFhP6ljTbudAzTs1fnsc8QDU2fIenGbSH0XXUBfERf4DgYnrh7gmH98GymM2oHUkXoaVXpOWnwd5h+VtydSUDM0r4HO5RwwfIOUmfsLmNQ+t0="
      assert {:ok, msg} = Message.decrypt(data, privkey, encoding: :base64)
      assert msg == "It's friday today!"
    end
  end

  describe "Message.sign/3 and Message.verify/4" do
    test "sign with private key and verify with public key", %{keypair: keypair} do
      result = "hello world"
      |> Message.sign(keypair.privkey)
      |> Message.verify("hello world", keypair.pubkey)
      assert result == true
    end

    test "sign with private key and verify with address", ctx do
      result = "hello world"
      |> Message.sign(ctx.keypair.privkey)
      |> Message.verify("hello world", ctx.address)
      assert result == true
    end

    test "return false with incorrect message", %{keypair: keypair} do
      result = "hello world"
      |> Message.sign(keypair.privkey)
      |> Message.verify("goodbye world", keypair.pubkey)
      assert result == false
    end

    test "must sign and return a binary", %{keypair: keypair} do
      sig = Message.sign("hello world", keypair.privkey, encoding: false)
      assert byte_size(sig) == 65
    end

    test "must return with specified encoding", %{keypair: keypair} do
      sig = Message.sign("hello world", keypair.privkey, encoding: :hex)
      assert String.match?(sig, ~r/^[a-f0-9]+$/i)
    end

    test "must return false when fake signature provided", %{keypair: keypair} do
      result = Message.verify("fakesig", "hello world", keypair.pubkey, encoding: false)
      assert result == false
    end
  end

  describe "Message.verify/4 external messages" do
    test "verify signature from random bsv address 1" do
      address = Address.from_string!("1Kgb4RGd7kVxmy85qF2V7RuyqnddCabBpc")
      sig = "IOKYfXRrvFGa43gxBiqsTVq8SYZGVbBo4IRD5Sw285weNwABWwCgHx/uxiIh1T7ucOunBXUPSanU61z7vkMFqi4="
      assert BSV.Message.verify(sig, "Hello world.", address)
    end

    test "verify signature from random bsv address 2" do
      address = Address.from_string!("172uDK9ov8pPshwM4gGExZVBqUPVk4NK2F")
      sig = "HwIB0nCuTgDHnKG0uoWVPWMTaO3XOa6MtvkuZYDr4hOqZ8T78qOIa3afqIVltZahsKTtpEErnflgvQVVPIk+YJQ="
      assert BSV.Message.verify(sig, "Hello world.", address)
    end

    test "verify signature from random bsv address 3" do
      address = Address.from_string!("14GpJNKfb6yvhjeBXQVJRmGKx1Syg4kxLG")
      sig = "INX0XYbxs8ZW+mwTem198w0L/JvZkYUb/KikUt/fIf9+bSKaMijQD0nQso/RA5n6NrzZu5ok3lpgE3VzJPPS3Yk="
      assert BSV.Message.verify(sig, "Hello world.", address)
    end
  end

end
