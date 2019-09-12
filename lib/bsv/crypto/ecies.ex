defmodule BSV.Crypto.ECIES do
  @moduledoc """
  TODOC
  """
  alias BSV.Util
  alias BSV.Crypto.Hash
  alias BSV.Crypto.AES
  alias BSV.Crypto.ECDSA
  alias BSV.Crypto.ECDSA.PrivateKey

  @named_curve :secp256k1


  def generate_secret(public_key, private_key, options \\ []) do
    named_curve = Keyword.get(options, :named_curve, @named_curve)
    :crypto.compute_key(:ecdh, public_key, private_key, named_curve)
  end


  def encrypt(data, public_key, options \\ []) do
    encoding = Keyword.get(options, :encoding)
    iv = Keyword.get(options, :iv, Util.random_bytes(16))

    # 1. Create ephemeral keypair
    {ephemeral_pubkey, ephemeral_privkey} = case Keyword.get(options, :ephemeral_keys) do
      {_pub, _priv} = keypair -> keypair
      %PrivateKey{} = keypair -> {keypair.public_key, keypair.private_key}
      _ -> ECDSA.generate_key_pair
    end

    epriv_bn = :binary.decode_unsigned(ephemeral_privkey)
    pub_bn = :binary.decode_unsigned(public_key)
    p = pub_bn * epriv_bn
    <<x::bytes-size(32), _y::binary>> = :binary.encode_unsigned(p)
    <<ke::bytes-size(32), _km::bytes-size(32)>> = Hash.sha512(x)

    encoded_message = AES.encrypt(data, :cbc, ke, iv: iv)

    ephemeral_pubkey <> iv <> encoded_message
    |> Util.encode(encoding)
  end


  def decrypt(data, private_key, options \\ []) do
    _encoding = Keyword.get(options, :encoding)
    <<
      ephemeral_pubkey::bytes-size(65),
      iv::bytes-size(16),
      encoded_message::binary
    >> = data

    


  end
end