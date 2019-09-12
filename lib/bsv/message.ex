defmodule BSV.Message do

  alias BSV.DERSig
  alias BSV.Crypto.ECDSA
  alias BSV.Crypto.Hash

  
  @doc """
  TODOC
  """
  @spec sign(binary, BSV.KeyPair.t | binary) :: binary
  def sign(message, %BSV.KeyPair{} = keys) do
    sign(message, keys.private_key)
  end

  def sign(message, private_key) when is_binary(private_key) do
    message
    |> magic_prefix
    |> ECDSA.sign(private_key)
    |> DERSig.normalize
  end


  @doc """
  TODOC
  """
  @spec verify(binary, binary, BSV.KeyPair.t | binary) :: boolean
  def verify(sig, message, %BSV.KeyPair{} = keys) do
    verify(sig, message, keys.public_key)
  end

  def verify(sig, message, public_key) when is_binary(public_key) do
    sig = DERSig.normalize(sig)
    msg = magic_prefix(message)
    ECDSA.verify(sig, msg, public_key)
  end


  def magic_prefix(message) do
    prefix = "Bitcoin Signed Message:\n"
    <<byte_size(prefix), prefix::binary, byte_size(message), message::binary>>
    |> Hash.sha256_sha256
  end
  
end